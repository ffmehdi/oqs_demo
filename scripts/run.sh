#!/bin/bash
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
registry="${DOCKER_REGISTRY}"
if [ -z "$registry" ]; then
    container_name="oqs_openssl_benchmark"
else
    container_name="$registry/oqs_openssl_benchmark"
fi
${__dir}/stop.sh
pushd ${__dir}/../openssl
docker rm oqs_demo
docker run -d -v ../benchmark:/benchmark/ --name oqs_demo $container_name:latest