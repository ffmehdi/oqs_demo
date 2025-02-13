#!/bin/bash
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pushd ${__dir}/../

docker cp oqs_demo:/opt/openssl ./openssl/dist
tar cvf openssl_oqs.tar.gz openssl