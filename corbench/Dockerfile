FROM --platform=linux/amd64 golang:1.15-alpine

WORKDIR /corbench

RUN apk add git make

# Copy Makefiles and manifests
# Need 'cd' since ghActions ignores WORKDIR
# Need 'eval' to prevent bash keywords be run as commands
COPY ./ ./

RUN echo -e '#!/bin/sh\ncd /corbench\neval "$@"' >/bin/docker_entrypoint

RUN chmod u+x /bin/docker_entrypoint

ENTRYPOINT ["docker_entrypoint"]