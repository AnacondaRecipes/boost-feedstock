#!/bin/bash

set -x -e

. ${RECIPE_DIR}/common.sh

#./b2 install
./b2 -q \
    variant=release \
    debug-symbols=off \
    threading=multi \
    runtime-link=shared \
    link=static,shared \
    toolset=${TOOLSET} \
    cxxflags="${CXXFLAGS}" \
    linkflags="${LDFLAGS}" \
    python=${PY_VER} \
    -j"${CPU_COUNT}" \
    install

# Remove Python headers as we don't build Boost.Python.
rm -f "${PREFIX}/include/boost/python.hpp"
rm -rf "${PREFIX}/include/boost/python"
rm -f "${PREFIX}/lib/libboost_python*"

#build b2 engine
pushd tools/build
 ./bootstrap.sh --verbose  --cxx=${CXX} --cxxflags=${CXXFLAGS} ${TOOLSET}
 #install copies b2 into $PREFIX/bin and shared dir into $PREFIX/share
 ./b2 install --prefix=$PREFIX
 cp ${PREFIX}/bin/b2 ${PREFIX}/bin/bjam
popd

cp tools/build/src/site-config.jam ${PREFIX}/share/b2/src/kernel/
