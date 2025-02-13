#!/bin/bash
docker stop openssl_benchmark
docker rm openssl_benchmark
docker run -d -p 9500:80 --name openssl_benchmark web_openssl_benchmark
