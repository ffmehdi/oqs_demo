# Multi-stage build: First the full builder image:

# define the alpine image version to use
ARG ALPINE_VERSION=3.21

# define the openssl tag to be used
ARG OPENSSL_TAG=openssl-3.4.1

# define the liboqs tag to be used
ARG LIBOQS_TAG=0.12.0

# define the oqsprovider tag to be used
ARG OQSPROVIDER_TAG=0.8.0

ARG INSTALLDIR_OPENSSL=/opt/openssl
ARG INSTALLDIR_LIBOQS=/opt/liboqs

# liboqs build type variant; maximum portability of image:
ARG LIBOQS_BUILD_DEFINES="-DOQS_DIST_BUILD=ON"

# Define the degree of parallelism when building the image; leave the number away only if you know what you are doing
ARG MAKE_DEFINES="-j 8"

# ARG SIG_ALG="dilithium3"

FROM alpine:${ALPINE_VERSION} AS buildopenssl
# Take in all global args
ARG OPENSSL_TAG
ARG INSTALLDIR_OPENSSL
ARG INSTALLDIR_LIBOQS
ARG LIBOQS_BUILD_DEFINES
ARG MAKE_DEFINES
# ARG SIG_ALG

LABEL version="2"
ENV DEBIAN_FRONTEND noninteractive

RUN apk update && apk upgrade

# Get all software packages required for builing openssl
RUN apk add build-base linux-headers \
            libtool automake autoconf \
            make \
            git wget

# get current openssl sources
RUN mkdir /optbuild && cd /optbuild && git clone --depth 1 --branch ${OPENSSL_TAG} https://github.com/openssl/openssl.git

# build OpenSSL3
WORKDIR /optbuild/openssl
RUN LDFLAGS="-Wl,-rpath -Wl,${INSTALLDIR_OPENSSL}/lib64" ./config shared --prefix=${INSTALLDIR_OPENSSL} && \
    make ${MAKE_DEFINES} && \
    make install && \
    if [ -d ${INSTALLDIR_OPENSSL}/lib64 ]; then ln -s ${INSTALLDIR_OPENSSL}/lib64 ${INSTALLDIR_OPENSSL}/lib; fi && \
    if [ -d ${INSTALLDIR_OPENSSL}/lib ]; then ln -s ${INSTALLDIR_OPENSSL}/lib ${INSTALLDIR_OPENSSL}/lib64; fi

FROM alpine:${ALPINE_VERSION} AS buildliboqs
# Take in all global args
ARG LIBOQS_TAG
ARG INSTALLDIR_OPENSSL
ARG INSTALLDIR_LIBOQS
ARG LIBOQS_BUILD_DEFINES
ARG MAKE_DEFINES
# ARG SIG_ALG

LABEL version="2"
ENV DEBIAN_FRONTEND noninteractive

# Get all software packages required for builing liboqs:
RUN apk add build-base linux-headers \
            libtool automake autoconf cmake ninja \
            make \
            git wget

# Get OpenSSL image (from cache)
COPY --from=buildopenssl ${INSTALLDIR_OPENSSL} ${INSTALLDIR_OPENSSL}

RUN mkdir /optbuild && cd /optbuild && git clone --depth 1 --branch ${LIBOQS_TAG} https://github.com/open-quantum-safe/liboqs

WORKDIR /optbuild/liboqs
RUN mkdir build && \
    cd build && \
    cmake -G"Ninja" .. -DOPENSSL_ROOT_DIR=${INSTALLDIR_OPENSSL} ${LIBOQS_BUILD_DEFINES} -DCMAKE_INSTALL_PREFIX=${INSTALLDIR_LIBOQS} && \
    ninja install

FROM alpine:${ALPINE_VERSION} AS buildoqsprovider
# Take in all global args
ARG OQSPROVIDER_TAG
ARG INSTALLDIR_OPENSSL
ARG INSTALLDIR_LIBOQS
ARG LIBOQS_BUILD_DEFINES
ARG MAKE_DEFINES
# ARG SIG_ALG

LABEL version="2"
ENV DEBIAN_FRONTEND noninteractive

# Get all software packages required for builing oqsprovider
RUN apk add build-base linux-headers \
            libtool cmake ninja \
            git wget

RUN mkdir /optbuild && cd /optbuild && git clone --depth 1 --branch ${OQSPROVIDER_TAG} https://github.com/open-quantum-safe/oqs-provider.git

# Get openssl32 and liboqs
COPY --from=buildopenssl ${INSTALLDIR_OPENSSL} ${INSTALLDIR_OPENSSL}
COPY --from=buildliboqs ${INSTALLDIR_LIBOQS} ${INSTALLDIR_LIBOQS}

# build & install provider (and activate by default)
WORKDIR /optbuild/oqs-provider
RUN liboqs_DIR=${INSTALLDIR_LIBOQS} cmake -DOPENSSL_ROOT_DIR=${INSTALLDIR_OPENSSL} -DCMAKE_BUILD_TYPE=Release -DOQS_KEM_ENCODERS=ON -DCMAKE_PREFIX_PATH=${INSTALLDIR_OPENSSL} -S . -B _build && \
    cmake --build _build && \
    cmake --install _build && \
    cp _build/lib/oqsprovider.so ${INSTALLDIR_OPENSSL}/lib64/ossl-modules && \
    sed -i "s/default = default_sect/default = default_sect\noqsprovider = oqsprovider_sect/g" ${INSTALLDIR_OPENSSL}/ssl/openssl.cnf && \
    sed -i "s/\[default_sect\]/\[default_sect\]\nactivate = 1\n\[oqsprovider_sect\]\nactivate = 1\n/g" ${INSTALLDIR_OPENSSL}/ssl/openssl.cnf && \
    sed -i "s/providers = provider_sect/providers = provider_sect\nssl_conf = ssl_sect\n\n\[ssl_sect\]\nsystem_default = system_default_sect\n\n\[system_default_sect\]\nGroups = \$ENV\:\:DEFAULT_GROUPS\n/g" ${INSTALLDIR_OPENSSL}/ssl/openssl.cnf && \
    sed -i "s/HOME\t\t\t= ./HOME           = .\nDEFAULT_GROUPS = kyber768/g" ${INSTALLDIR_OPENSSL}/ssl/openssl.cnf

WORKDIR ${INSTALLDIR_OPENSSL}/bin
# set path to use 'new' openssl. Dyn libs have been properly linked in to match
ENV PATH="${INSTALLDIR_OPENSSL}/bin:${PATH}"


## second stage: Only create minimal image without build tooling and intermediate build results generated above:
FROM alpine:${ALPINE_VERSION} AS dev
# Take in all global args
ARG INSTALLDIR_OPENSSL

# Only retain the ${INSTALLDIR_OPENSSL} contents in the final image
COPY --from=buildoqsprovider ${INSTALLDIR_OPENSSL} ${INSTALLDIR_OPENSSL}

RUN apk add bash
# set path to use 'new' openssl. Dyn libs have been properly linked in to match
ENV PATH="${INSTALLDIR_OPENSSL}/bin:${PATH}"
VOLUME /benchmark

WORKDIR /benchmark

ENTRYPOINT ["/benchmark/openssl_algos_speed_benchmark.sh"]
STOPSIGNAL SIGTERM