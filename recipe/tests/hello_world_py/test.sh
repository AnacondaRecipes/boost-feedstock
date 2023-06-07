#!/usr/bin/env bash

set -e
pushd ../../libs/python/example/tutorial
  export CONDA_BUILD_SYSROOT=/opt/MacOSX10.10.sdk
  export CONDA_BUILD=1
  bjam cxxflags=-I${CONDA_PREFIX}/include --debug-configuration -d+2 release 2>&1 | tee pytest-bjam.log
  python -c 'from __future__ import print_function; import hello_ext; print(hello_ext.greet())'
popd
