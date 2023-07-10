#!/bin/bash

set -x -e

. ${RECIPE_DIR}/common.sh

./b2 -q \
    variant=release \
    debug-symbols=off \
    threading=multi \
    runtime-link=shared \
    link=static,shared \
    toolset=${TOOLSET} \
    cxxflags="${CXXFLAGS}" \
    linkflags="${LDFLAGS}" \
    --with-python \
    python=${PY_VER} \
    -j"${CPU_COUNT}" \
    install


pushd "${PREFIX}/lib"
  [[ -f libboost_python.a ]] || ln -s libboost_python${PY_VER//./}.a libboost_python.a
  [[ -f libboost_numpy.a ]] || ln -s libboost_numpy${PY_VER//./}.a libboost_numpy.a
  ln -s libboost_python${PY_VER//./}${SHLIB_EXT} libboost_python${SHLIB_EXT}
  ln -s libboost_numpy${PY_VER//./}${SHLIB_EXT} libboost_numpy${SHLIB_EXT}
popd
