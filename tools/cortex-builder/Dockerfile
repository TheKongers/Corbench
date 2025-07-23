FROM --platform=linux/amd64 golang:1.24.3-bullseye

RUN mkdir -p /go/src/github.com

COPY ./build.sh /go/src/github.com/build.sh

RUN chmod +x /go/src/github.com/build.sh

ENTRYPOINT ["/go/src/github.com/build.sh"] 