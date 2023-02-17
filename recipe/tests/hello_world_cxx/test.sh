#!/usr/bin/env bash

# Works:
# cxxflags=-I${CONDA_PREFIX}/include
if [[ -d bin ]]; then
  rm -rf bin
fi
bjam hello cxxflags=-I${CONDA_PREFIX}/include --debug-configuration -d+2 release 2>&1 | tee cxxflags-hacked-working.log

echo "Testing hacked hello (should work)"
bin/**/release/hello | rg "Hello World CXX" || exit 1
mv bin bin.hacked-working
bjam hello --debug-configuration -d+2 release 2>&1 | tee cxxflags-unhacked-broken.log
echo "Testing un-hacked hello (should fail, unfortunately, cxxflags not being applied)"
bin/**/release/hello | rg "Hello World CXX" || exit 1
mv bin bin.unhacked-broken
