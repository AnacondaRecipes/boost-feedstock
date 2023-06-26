#!/bin/bash

set -x -e
set -o pipefail

. ${RECIPE_DIR}/common.sh

./b2 install

# Remove Python headers as we don't build Boost.Python.
rm -f "${PREFIX}/include/boost/python.hpp"
rm -rf "${PREFIX}/include/boost/python"
rm -f "${PREFIX}/lib/libboost_python*"

#we want to support b2 & bjam also, so copy it
mkdir -p ${PREFIX}/bin
cp ./b2 "${PREFIX}/bin/b2" || exit 1
pushd "${PREFIX}/bin"
    cp -a b2 bjam || exit 1
popd

#b2/bjam requires its own enviroment, so copy it:
pushd tools/build/src
  for _dir in build kernel options tools util; do
    mkdir -p "${PREFIX}/share/boost-build/src/${_dir}"
    cp -rf ${_dir}/* "${PREFIX}/share/boost-build/src/${_dir}/"
  done
  cp -f build-system.jam "${PREFIX}/share/boost-build/src/"
popd

pushd tools/build
  echo "*********** CXX $CXX CXXFLAGS $CXXFLAGS TOOLSET $TOOLSET *************"
 ./bootstrap.sh --verbose  --cxx=${CXX} --cxxflags=${CXXFLAGS} ${TOOLSET}
 cp ./b2 "${PREFIX}/bin/b2_tools_build"
 ./b2 install --prefix=$PREFIX
popd

mkdir -p $PREFIX/share/boost-build/src/kernel/
cp tools/build/src/site-config.jam ${PREFIX}/share/boost-build/src/kernel/
cp tools/build/src/site-config.jam ${PREFIX}/share/b2/src/kernel/
