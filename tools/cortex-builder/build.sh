#!/bin/bash

DIR="/go/src/github.com/cortexproject/cortex"

if [[ -z $PR_NUMBER || -z $VOLUME_DIR || -z $GITHUB_ORG || -z $GITHUB_REPO ]]; then
    echo "ERROR:: environment variables not set correctly"
    exit 1;
fi

# Clone the repository with a shallow clone
echo ">> Cloning repository $GITHUB_ORG/$GITHUB_REPO (shallow clone)"
if ! git clone --depth 1 https://github.com/$GITHUB_ORG/$GITHUB_REPO.git $DIR; then
    echo "ERROR:: Cloning of repo $GITHUB_ORG/$GITHUB_REPO failed"
    exit 1;
fi

cd $DIR || exit 1

echo ">> Fetching Pull Request $GITHUB_ORG/$GITHUB_REPO/pull/$PR_NUMBER"
if ! git fetch origin pull/$PR_NUMBER/head:pr-branch; then
    echo "ERROR:: Fetching of PR $PR_NUMBER failed"
    exit 1;
fi

git checkout pr-branch

echo ">> Building Cortex binaries"
if ! make BUILD_IN_CONTAINER=false cmd/cortex/cortex; then
    echo "ERROR:: Building of Cortex binaries failed"
    exit 1;
fi

echo ">> Copy files to volume"
# Copy the main Cortex binary
if [ -f "./cmd/cortex/cortex-amd64" ]; then
    cp ./cmd/cortex/cortex-amd64 $VOLUME_DIR/cortex
elif [ -f "./cmd/cortex/cortex" ]; then
    cp ./cmd/cortex/cortex $VOLUME_DIR/cortex
else
    echo "ERROR:: Cortex binary not found"
    exit 1;
fi

echo ">> Cortex build completed successfully"