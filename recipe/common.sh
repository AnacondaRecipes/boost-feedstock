#!/bin/bash
# work-around for https://github.com/bfgroup/b2/issues/405
echo "using python" > user-config.jam
echo ": $PY_VER" >> user-config.jam
echo ": $PYTHON" >> user-config.jam
echo ": $PREFIX/include/python$PY_VER" >> user-config.jam
echo ": $PREFIX/lib" >> user-config.jam
echo ";" >> user-config.jam
# see https://www.boost.org/build/doc/html/bbv2/overview/configuration.html
export BOOST_BUILD_PATH=$SRC_DIR

if [[ "${target_platform}" == osx* ]]; then
    TOOLSET=clang
elif [[ "${target_platform}" == linux* ]]; then
    TOOLSET=gcc
fi