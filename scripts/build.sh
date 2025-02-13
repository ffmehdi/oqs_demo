#!/bin/bash
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
registry="${DOCKER_REGISTRY}"
if [ -z "$registry" ]; then
    container_name="oqs_openssl_benchmark"
else
    container_name="$registry/oqs_openssl_benchmark"
fi

pushd ${__dir}/../openssl
# Build
docker build . -t $container_name:latest
# Push to private registry
if [ -n "$registry" ]; then
    echo "Pushing to $registry"
    docker push $container_name:latest
fi