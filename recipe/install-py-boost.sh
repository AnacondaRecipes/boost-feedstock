#!/bin/bash

set -x -e

# activate the build environment
. activate "${BUILD_PREFIX}"

# "stack" the host environment on top of the build env
mkdir -p "${PREFIX}/conda-meta"
touch "${PREFIX}/conda-meta/history"
unset CONDA_PATH_BACKUP
export CONDA_MAX_SHLVL=2
source ${BUILD_PREFIX}/bin/activate "${PREFIX}"

# remove any old builds of the python target
./b2 -q -d+2 --with-python --clean

./b2 -q -d+2 \
     python=${PY_VER} \
     -j${CPU_COUNT} \
     --with-python \
     cxxflags="${CXXFLAGS} -Wno-deprecated-declarations" \
     install | tee b2.install-py-${PY_VER}.log 2>&1

# boost.python, when driven via bjam always links to boost_python
# instead of boost_python3. It also does not add any specified
# --python-buildid; ping @stefanseefeld
if [[ ${PY_VER%.*} == 3 ]]; then
  pushd "${PREFIX}/lib"
    if [[ ${HOST} =~ .*darwin.* ]]; then
      ln -s libboost_python${PY_VER%.*}.dylib libboost_python.dylib
      ln -s libboost_numpy${PY_VER%.*}.dylib libboost_numpy.dylib
    else
      ln -s libboost_python${PY_VER%.*}.so libboost_python.so
      ln -s libboost_numpy${PY_VER%.*}.so libboost_numpy.so
    fi
  popd
fi
