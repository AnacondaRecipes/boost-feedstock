#!/usr/bin/env bash

set -e

# Debug: Check if Python headers are available
echo "Checking for Python headers..."
echo "PREFIX=$PREFIX"
echo "PY_VER=$PY_VER"

# List Python include directory
if [ -d "$PREFIX/include/python${PY_VER}" ]; then
    echo "Python include directory exists: $PREFIX/include/python${PY_VER}"
    ls -la "$PREFIX/include/python${PY_VER}/pyconfig.h" || echo "pyconfig.h not found!"
else
    echo "Python include directory not found!"
fi

# Also check for alternate locations
for dir in "$PREFIX/include/python${PY_VER}m" "$PREFIX/include/python${PY_VER}d"; do
    if [ -d "$dir" ]; then
        echo "Found alternate Python include directory: $dir"
        ls -la "$dir/pyconfig.h" || echo "pyconfig.h not found in $dir!"
    fi
done

pushd ../../libs/python/example/tutorial
  bjam -q -d+2 --debug-configuration
  python -c 'from __future__ import print_function; import hello_ext; print(hello_ext.greet())'
popd
