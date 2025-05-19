#!/bin/bash

# Check pod status first
echo "Checking pod status..."
kubectl get pods

# Get detailed pod information for debugging
echo "\nDetailed pod information:"
kubectl describe pods | tee output-single-pod/pod-details.log

# Check if all pods are ready
POD_STATUS=$(kubectl get pods --no-headers | grep "vllm" | awk '{print $2}' | sort | uniq)
if [[ "$POD_STATUS" != "1/1" ]]; then
    echo "\nError: Not all pods are ready. Current status:"
    kubectl get pods
    echo "\nPod logs for debugging:"
    kubectl logs --all-containers=true --prefix -l app=vllm | tee output-single-pod/pod-logs.log
    exit 1
fi

# Send a request to fetch the available models and save the response to a file
echo "\nSending request to models endpoint..."
result_model=$(curl -v http://"$1":"$2"/v1/models 2>&1 | tee output-single-pod/models-single-pod.json)

# Check if the response is empty
if [[ -z "$result_model" ]]; then
    echo "Error: Failed to retrieve model list. Response is empty."
    echo "Full curl output saved to output-single-pod/models-single-pod.json"
    exit 1
fi

# Send a request to generate a text completion and save the response to a file
echo "\nSending completion request..."
result_query=$(curl -v -X POST http://"$1":"$2"/v1/completions \
    -H "Content-Type: application/json" \
    -d '{"model": "facebook/opt-125m", "prompt": "Once upon a time,", "max_tokens": 10}' 2>&1 \
    | tee output-single-pod/query-single-pod.json)

# Check if the response is empty
if [[ -z "$result_query" ]]; then
    echo "Error: Failed to retrieve query response. Response is empty."
    echo "Full curl output saved to output-single-pod/query-single-pod.json"
    exit 1
fi

echo "Requests were successful."