#!/bin/bash

set -x -e
set -o pipefail

. ${RECIPE_DIR}/common.sh

#build with python will be removed from staging later on
./bootstrap.sh \
    --prefix="${PREFIX}"  \
    --with-icu="${PREFIX}"  \
    --with-toolset=${TOOLSET}  \
    --with-python="${PYTHON}" \
    --with-python-root="${PREFIX} : ${PREFIX}/include/python${PY_VER}m : ${PREFIX}/include/python${PY_VER}"


#this is needed for b2 in order to use conda toolchain instead of system one
cat <<EOF > ${SRC_DIR}/tools/build/src/site-config.jam
    using ${TOOLSET} : : $(basename ${CXX})
              : # options
                  <archiver>$(basename ${AR})
                  <cflags>"${CFLAGS}"
                  <cxxflags>"${CXXFLAGS}"
                  <linkflags>"${LDFLAGS}"
                  <ranlib>$(basename ${RANLIB})
              ;
EOF

./b2 -q \
    variant=release \
    debug-symbols=off \
    threading=multi \
    runtime-link=shared \
    link=static,shared \
    toolset=${TOOLSET} \
    include="${PREFIX}/include" \
    cxxflags="${CXXFLAGS}" \
    linkflags="${LDFLAGS}" \
    python=${PY_VER} \
    -j"${CPU_COUNT}" \
    stage