#!/bin/bash

set -x -e

. ${RECIPE_DIR}/common.sh

# Create temp_prefix directory
mkdir -p temp_prefix

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
    --prefix=temp_prefix \
    install
