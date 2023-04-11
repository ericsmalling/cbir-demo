#!/bin/bash
if [ -z "$SNYK_TOKEN" ]; then
  echo "SNYK_TOKEN is not set, exiting"
  exit 1
fi

if [ -z "$SNYK_ORG_TOKEN" ]; then
  echo "SNYK_ORG_TOKEN is not set, exiting"
  exit 1
fi

function register_image {
  JSON_REQ="{ \"data\": { \"attributes\": { \"project_id\": \"${SNYK_PROJECT_ID}\", \"include_in_recommendations\": true"
  if $FIRST_RUN; then
    JSON_REQ="${JSON_REQ},\"versioning_schema\": { \"type\": \"${SCHEMA}\" }"
    FIRST_RUN=false
  fi
  JSON_REQ="${JSON_REQ}}, \"type\": \"custom_base_image\"}}"

    curl --location "https://api.snyk.io/rest/custom_base_images?version=2022-08-21%7Eexperimental" \
         --header "Content-Type: application/vnd.api+json" \
         --header "Authorization: Token ${SNYK_TOKEN}" \
         -d "${JSON_REQ}"
}

function pull_tag_and_register {
    if [ -z "$NEW_TAG" ]; then
      NEW_TAG=$tag
    fi
    docker pull $ORIG_IMAGE:$tag
    docker tag $ORIG_IMAGE:$tag $NEW_REPO/$NEW_IMAGE:$NEW_TAG
    docker push $NEW_REPO/$NEW_IMAGE:$NEW_TAG
    SNYK_PROJECT_ID=$(snyk container monitor $NEW_REPO/$NEW_IMAGE:${NEW_TAG} --org=${SNYK_ORG_TOKEN} --project-name="${NEW_IMAGE}:${NEW_TAG}" --json | jq -r '.uri' | cut -d'/' -f7)
    register_image
}

function register_multi_taged_images {
  FIRST_RUN=true
  for i in $TAG_SEQ; do
    tag=$(printf $TAG_PREFIX $i)
    if [ -n "$NEW_TAG_PATTERN" ]; then
      NEW_TAG=$(printf $NEW_TAG_PATTERN $i)
    else
      unset NEW_TAG
    fi
    pull_tag_and_register
  done
}

BUILD_CORRETTO=false
BUILD_DISTROLESS=false
BUILD_CHAINGUARD=false

case "$1" in
  corretto)
    BUILD_CORRETTO=true
    ;;
  distroless)
    BUILD_DISTROLESS=true
    ;;
  chainguard)
    BUILD_CHAINGUARD=true
    ;;
  all)
    BUILD_CORRETTO=true
    BUILD_DISTROLESS=true
    BUILD_CHAINGUARD=true
    ;;
  *)
    echo "Usage: $0 {corretto|distroless|chainguard|all}"
    exit 1
esac

if $BUILD_CORRETTO; then
  echo "Building corretto images"
  ORIG_IMAGE="amazoncorretto"
  TAG_SEQ=$(seq 0 6)
  TAG_PREFIX="17.0.%01d"
  NEW_IMAGE="my-java"
  NEW_REPO="repo.mycorp.com:5001"
  SCHEMA="semver"
  register_multi_taged_images
fi

if $BUILD_DISTROLESS; then
  echo "Building distroless images"
  ORIG_IMAGE="gcr.io/distroless/java"
  TAG_SEQ=$(seq 0 6)
  TAG_PREFIX="17.0.%01d"
  NEW_IMAGE="distroless-java"
  NEW_REPO="repo.mycorp.com:5001"
  SCHEMA="semver"
  register_multi_taged_images
fi

if $BUILD_CHAINGUARD; then
  echo "Building chainguard images"
  ORIG_IMAGE="cgr.dev/chainguard/jre"
  TAG_SEQ=$(seq 14 18)
  TAG_PREFIX="latest-202304%02d"
  NEW_IMAGE="cg-jre"
  NEW_REPO="repo.mycorp.com:5001"
  SCHEMA="date"
  NEW_TAG_PATTERN="202304%02d"
  register_multi_taged_images
fi
