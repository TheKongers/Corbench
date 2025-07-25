# Build stage
FROM golang:1.15-alpine AS builder

RUN apk add --no-cache git make

WORKDIR /src
COPY . .

RUN go build -o infra

# Runtime stage
FROM alpine:latest

RUN apk add --no-cache ca-certificates

COPY --from=builder /src/infra /bin/infra

ENTRYPOINT ["/bin/infra"]
