#!/bin/bash

set -x -e

# remove any old builds of the python target
./b2 -q -d+2 --with-python --clean

for PY_VER2 in 3.6 3.7 3.8; do
    ./b2 -q -d+2 \
        --with-python \
        python=${PY_VER} \
        --reconfigure \
        -j${CPU_COUNT} \
        cxxflags="${CXXFLAGS} -Wno-deprecated-declarations" \
        clean 2>&1 | tee py-boost-%PY_VER%-clean.log
done

./b2 -q -d+2 \
     --with-python \
     python=${PY_VER} \
    --reconfigure \
     -j${CPU_COUNT} \
     cxxflags="${CXXFLAGS} -Wno-deprecated-declarations" \
     install 2>&1 | tee py-boost-%PY_VER%-install.log

# boost.python, when driven via bjam always links to boost_python
# instead of boost_python3. It also does not add any specified
# --python-buildid; ping @stefanseefeld
pushd "${PREFIX}/lib"
  [[ -f libboost_python.a ]] || ln -s libboost_python${PY_VER//./}.a libboost_python.a
  [[ -f libboost_numpy.a ]] || ln -s libboost_numpy${PY_VER//./}.a libboost_numpy.a
  ln -s libboost_python${PY_VER//./}${SHLIB_EXT} libboost_python${SHLIB_EXT}
  ln -s libboost_numpy${PY_VER//./}${SHLIB_EXT} libboost_numpy${SHLIB_EXT}
popd
