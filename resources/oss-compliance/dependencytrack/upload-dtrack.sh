#!/bin/bash

API_KEY="n5yfOMWb2MQbJXjZeN7Z9KvSu1qhktB5"

# curl -X "PUT" "http://localhost:8081/api/v1/bom" \
#      -H "Content-Type: application/json" \
#      -H "X-API-Key: ${API_KEY}" \
#      -d @output/merged.cdx

curl -X "POST" "http://localhost:8081/api/v1/bom" \
     -H 'Content-Type: multipart/form-data' \
     -H "X-Api-Key: ${API_KEY}" \
     -F "project=4a6b480e-8bde-4f4d-a3b8-b975887f7f36" \
     -F "bom=@output/merged.cyclonedx.json"

# curl -X "POST" "http://localhost:8081/api/v1/bom" \
#      -H 'Content-Type: multipart/form-data' \
#      -H "X-Api-Key: ${API_KEY}" \
#      -F "project=4a6b480e-8bde-4f4d-a3b8-b975887f7f36" \
#      -F "bom=@output/leda.cyclonedx.json"
