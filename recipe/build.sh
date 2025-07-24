#!/bin/bash

set -x -e

. ${RECIPE_DIR}/common.sh

# Create temp_prefix directory
mkdir -p temp_prefix

# Configure the toolset to use conda compilers
cat <<EOF > ${SRC_DIR}/tools/build/src/site-config.jam
using ${TOOLSET} : : ${CXX} ;
EOF

# Bootstrap b2 without Python
./bootstrap.sh --prefix=temp_prefix --with-toolset=${TOOLSET} --without-libraries=python

# Build and install to temp_prefix without Python
./b2 -q \
    variant=release \
    debug-symbols=off \
    threading=multi \
    runtime-link=shared \
    link=static,shared \
    toolset=${TOOLSET} \
    cxxflags="${CXXFLAGS}" \
    linkflags="${LDFLAGS}" \
    --without-python \
    -j"${CPU_COUNT}" \
    # cxxstd=20 \
    --prefix=temp_prefix \
    install
