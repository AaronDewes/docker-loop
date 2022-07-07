ARG VERSION=v0.19.1-beta

FROM golang:1.18-alpine as builder

ARG VERSION

# Force Go to use the cgo based DNS resolver. This is required to ensure DNS
# queries required to connect to linked containers succeed.
ENV GODEBUG netdns=cgo

# Install dependencies and install/build loop.
RUN apk add --no-cache --update alpine-sdk \
    git \
    make \
&& mkdir -p /go/src/github.com/lightningnetwork/loop \
&&  git clone --depth=1 --branch $VERSION https://github.com/lightninglabs/loop /go/src/github.com/lightningnetwork/loop \
&&  cd /go/src/github.com/lightningnetwork/loop \
&&  make install

# Start a new, final image to reduce size.
FROM gcr.io/distroless/base as final

# Expose loop ports (server, rpc).
EXPOSE 8081 11010

# Copy the binaries and entrypoint from the builder image.
COPY --from=builder /go/bin/loopd /bin/
COPY --from=builder /go/bin/loop /bin/

ENTRYPOINT [ "/bin/loopd" ]
