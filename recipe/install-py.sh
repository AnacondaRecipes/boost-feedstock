#!/bin/bash
set -ex

# see build-py.sh
if [[ -d $SRC_DIR/cf_${PY_VER}_${python_impl}_cmake ]] && [[ -n "$(ls -A $SRC_DIR/cf_${PY_VER}_${python_impl}_cmake 2>/dev/null)" ]]; then
    mv $SRC_DIR/cf_${PY_VER}_${python_impl}_cmake/* $PREFIX/lib/cmake
fi
