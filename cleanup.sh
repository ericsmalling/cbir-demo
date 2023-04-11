#!/bin/bash
if [ -z "$SNYK_TOKEN" ]; then
  echo "SNYK_TOKEN is not set, exiting"
  exit 1
fi

if [ -z "$SNYK_ORG_TOKEN" ]; then
  echo "SNYK_ORG_TOKEN is not set, exiting"
  exit 1
fi

PROJECT_IDS=$(curl -s \
     --request POST \
     --header "Content-Type: application/json" \
     --header "Authorization: token ${SNYK_TOKEN}" \
     --data-binary "{
  \"filters\": {}
}" \
https://api.snyk.io/v1/org/${SNYK_ORG_TOKEN}/projects | jq -r '.projects[].id')

if [ -z "$PROJECT_IDS" ]; then
  echo "No projects found to delete"
else
  for ID in $PROJECT_IDS
  do
    echo "Deleting project: $ID"
    curl -s -X DELETE \
      --header "Content-Type: application/json" \
      --header "Authorization: token ${SNYK_TOKEN}" \
      "https://api.snyk.io/v1/org/${SNYK_ORG_TOKEN}/project/${ID}"
  done
fi

CBI_IDS=$(curl -s -X GET "https://api.snyk.io/rest/custom_base_images?version=2022-08-21%7Eexperimental&org_id=${SNYK_ORG_TOKEN}&limit=100"  -H "Accept: application/vnd.api+json"  -H "Authorization: ${SNYK_TOKEN}"  | jq -r .data[].id)

if [ -z "$CBI_IDS" ]; then
  echo "No CBIs found to delete"
else
  for ID in $CBI_IDS
  do
    echo "Deleting CBI: $ID"
    curl -s -X DELETE "https://api.snyk.io/rest/custom_base_images/${ID}?version=2022-08-21%7Eexperimental" \
     -H "Accept: application/vnd.api+json" \
     -H "Authorization: ${SNYK_TOKEN}"
  done
fi
