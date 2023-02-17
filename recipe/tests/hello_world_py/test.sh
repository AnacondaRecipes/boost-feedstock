#!/usr/bin/env bash

set -e
pushd ../../libs/python/example/tutorial
  export CONDA_BUILD_SYSROOT=/opt/MacOSX10.10.sdk
  export CONDA_BUILD=1
  bjam -q -d+2 --debug-configuration
  python -c 'from __future__ import print_function; import hello_ext; print(hello_ext.greet())'
popd
