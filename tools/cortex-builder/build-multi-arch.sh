#!/bin/bash

# Set your Docker Hub username or organization
DOCKER_ORG="corbench"
IMAGE_NAME="cortex-builder"
TAG="latest"

# Enable Docker BuildKit
export DOCKER_BUILDKIT=1

# Create a new builder instance if it doesn't exist
docker buildx inspect multi-arch-builder &>/dev/null || docker buildx create --name multi-arch-builder --use

# Build and push the multi-architecture image
# Note: We're only building for amd64 since that's what your EKS runs on
docker buildx build --platform linux/amd64 \
  -t $DOCKER_ORG/$IMAGE_NAME:$TAG \
  -f Dockerfile \
  --push \
  .

echo "AMD64 image built and pushed successfully"