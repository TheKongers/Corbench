### Cortex-Builder

This is used for building Cortex binaries from Pull Requests and running them on containers.  
This tool can be used to build binaries for the Pull Request being benchmarked or tested.

You can upload this docker image in the correct linux/amd64 archetecture used by this tool to dockerhub with the build-multi-arch.sh

### Building Docker Image to Upload

The [build-multi-arch.sh](./build-multi-arch.sh) script builds and pushes the cortex-builder docker image to dockerhub using the correct archetecture(linux/amd64).

### Built Binaries

The builder will automatically pull and create the cortex binary in the volume directory