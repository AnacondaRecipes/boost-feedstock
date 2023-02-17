#!/bin/bash

set -x -e
set -o pipefail

. ${RECIPE_DIR}/set__ALL_OPTS.sh

./b2  \
     install | tee b2.install-libboost.log 2>&1

# Remove Python headers as we don't build Boost.Python.
if [[ -f "${PREFIX}/include/boost/python.hpp" ]]; then
  echo "Warning :: ${PREFIX}/include/boost/python.hpp exists when installing libboost, it should not"
  rm -f "${PREFIX}/include/boost/python.hpp"
  [[ -f "${PREFIX}/include/boost/python.hpp" ]] && rm -rf "${PREFIX}/include/boost/python"
fi

mkdir -p ${PREFIX}/bin
cp ./b2 "${PREFIX}/bin/b2" || exit 1
pushd "${PREFIX}/bin"
    cp -a b2 bjam || exit 1
popd

pushd tools/build/src
  for _dir in build kernel options tools util; do
    mkdir -p "${PREFIX}/share/boost-build/src/${_dir}"
    cp -rf ${_dir}/* "${PREFIX}/share/boost-build/src/${_dir}/"
  done
  cp -f build-system.jam "${PREFIX}/share/boost-build/src/"
popd
# pushd tools/build
#   ./bootstrap.sh --with-toolset=${TOOLSET_REAL}
  # We run bjam here so that b2 is not an open file, otherwise:
  #   common.copy $PREFIX/bin/b2
  #   cp: cannot create regular file '$PREFIX/bin/b2': Text file busy
#   bjam install \
#     --prefix=${PREFIX} \
#     toolset=${TOOLSET_REAL}
#   cp ${PREFIX}/bin/b2 ${PREFIX}/bin/bjam
# popd

# We have patched build-system.jam to use this file when
# the CONDA_PREFIX environment variable is set.
# mkdir -p "${PREFIX}/etc"
# cp ${SRC_DIR}/tools/build/src/site-config.jam "${PREFIX}/etc"

pushd tools/build
  ./bootstrap.sh \
    --with-toolset=${TOOLSET}
  # We need to delete this otherwise install will fail to overwrite due to it being open
  # (though why would it be open?!)
  rm -rf ${PREFIX}/bin/b2
  ls -l ${PREFIX}/bin/bjam
  ${PREFIX}/bin/bjam \
    "${_ALL_OPTS[@]}" \
    install 2>&1 | tee b2.build-final-bjam.log
  cp ${PREFIX}/bin/b2 ${PREFIX}/bin/bjam
popd

mkdir -p $PREFIX/share/boost-build/src/kernel/ || true
cp tools/build/src/site-config.jam ${PREFIX}/share/boost-build/src/kernel/
