ARG VERSION=v0.15.0-beta

FROM golang:1.15-alpine as builder

# Force Go to use the cgo based DNS resolver. This is required to ensure DNS
# queries required to connect to linked containers succeed.
ENV GODEBUG netdns=cgo

# Explicitly turn on the use of modules (until this becomes the default).
ENV GO111MODULE on

# Install dependencies and install/build lnd.
RUN apk add --no-cache --update alpine-sdk \
    git \
    make \
&& mkdir -p /go/src/github.com/lightningnetwork/loop \
&&  git clone --branch $VERSION --depth=1 https://github.com/lightninglabs/loop /go/src/github.com/lightningnetwork/loop \    
&&  cd /go/src/github.com/lightningnetwork/loop \
&&  make install

# Start a new, final image to reduce size.
FROM alpine as final

# Expose lnd ports (server, rpc).
EXPOSE 8081 11010

# Copy the binaries and entrypoint from the builder image.
COPY --from=builder /go/bin/loopd /bin/
COPY --from=builder /go/bin/loop /bin/

# Add bash.
RUN apk add --no-cache \
    bash \
    ca-certificates

ENTRYPOINT [ "/bin/loopd" ]
