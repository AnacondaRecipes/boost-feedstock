#!/bin/bash

set -x -e

. ${RECIPE_DIR}/common.sh

./b2 install

# Remove Python headers as we don't build Boost.Python.
rm -f "${PREFIX}/include/boost/python.hpp"
rm -rf "${PREFIX}/include/boost/python"
rm -f "${PREFIX}/lib/libboost_python*"

pushd tools/build
 ./bootstrap.sh --verbose  --cxx=${CXX} --cxxflags=${CXXFLAGS} ${TOOLSET}
 cp ./b2 ${PREFIX}/bin/b2
 cp ./b2 ${PREFIX}/bin/bjam
 ${PREFIX}/bin/b2 install --prefix=$PREFIX
popd

cp tools/build/src/site-config.jam ${PREFIX}/share/b2/src/kernel/
