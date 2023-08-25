#!/bin/bash

set -x -e
set -o pipefail

. ${RECIPE_DIR}/common.sh

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
