#!/usr/bin/env bash
if [ -z "$SNYK_TOKEN" ]; then
  echo "SNYK_TOKEN is not set, exiting"
  exit 1
fi

if [ -z "$SNYK_ORG_TOKEN" ]; then
  echo "SNYK_ORG_TOKEN is not set, exiting"
  exit 1
fi

curl -s -X GET "https://api.snyk.io/rest/custom_base_images?version=2022-08-21%7Eexperimental&org_id=${SNYK_ORG_TOKEN}&limit=100" \
        -H "Accept: application/vnd.api+json" \
        -H "Authorization: ${SNYK_TOKEN}" | jq -r '.data[].attributes | [.repository, .tag] | join(":")'
