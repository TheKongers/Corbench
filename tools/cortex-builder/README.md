### Cortex-Builder

This is used for building Cortex binaries from Pull Requests and running them on containers.  
This tool can be used to build binaries for the Pull Request being benchmarked or tested.

### Building Docker Image

To build the Docker image for `cortex-builder`:

```
docker build -t prominfra/cortex-builder:master .
```

### Usage

The Cortex builder requires the following environment variables:

- `PR_NUMBER`: The GitHub Pull Request number to build
- `VOLUME_DIR`: Directory where built binaries will be copied
- `GITHUB_ORG`: GitHub organization (e.g., "cortexproject")
- `GITHUB_REPO`: GitHub repository name (e.g., "cortex")

### Example

```bash
docker run -e PR_NUMBER=1234 \
           -e VOLUME_DIR=/output \
           -e GITHUB_ORG=cortexproject \
           -e GITHUB_REPO=cortex \
           -v /host/output:/output \
           prominfra/cortex-builder:master
```

### Built Binaries

The builder will create the following binaries in the volume directory:

- `cortex`: The main Cortex binary
- `query-tee`: Query tee binary (if available)
- `thanosconvert`: Thanos converter binary (if available)

### Differences from Prometheus Builder

- Uses Cortex's specific build process with `make BUILD_IN_CONTAINER=false exes`
- Includes all necessary build dependencies for Cortex (protobuf, Node.js, etc.)
- Handles multiple Cortex binaries (cortex, query-tee, thanosconvert)
- Uses Cortex's build image requirements and Go version 