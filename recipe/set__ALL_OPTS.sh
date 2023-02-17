#!/usr/bin/env bash

# DRY because we use this twice.
INCLUDE_PATH="${PREFIX}/include"
LIBRARY_PATH="${PREFIX}/lib"

LINKFLAGS="${LINKFLAGS} -L${LIBRARY_PATH}"
if [[ ${target_platform} =~ osx.* ]]; then
  export CXXFLAGS="${CXXFLAGS} -std=c++14 -stdlib=libc++"
  export LINKFLAGS="${LINKFLAGS} -std=c++14"
fi
declare -a _GENERIC_OPTS=()
if [[ ${CONDA_BUILD_DEBUG_BUILD_SYSTEM} == yes ]]; then
  _GENERIC_OPTS+=(-q -d+2)
fi
_GENERIC_OPTS+=(variant=release)
if [[ ${ARCH} == ppc64le ]]; then
  _GENERIC_OPTS+=(address-model="64")
  _GENERIC_OPTS+=(architecture=power)
elif [[ ${ARCH} == aarch64 ]]; then
  _GENERIC_OPTS+=(address-model="64")
  _GENERIC_OPTS+=(architecture=arm)
elif [[ ${ARCH} == s390x ]]; then
  _GENERIC_OPTS+=(address-model="64")
  _GENERIC_OPTS+=(architecture=s390x)
# This is osx-arm64
elif [[ ${ARCH} == arm64 ]]; then
  _GENERIC_OPTS+=(address-model="64")
  _GENERIC_OPTS+=(architecture=arm)
else
  _GENERIC_OPTS+=(address-model="${ARCH}")
  _GENERIC_OPTS+=(architecture=x86)
fi
_GENERIC_OPTS+=(debug-symbols=off)
# TODO :: Put the single threaded libraries into a separate library if we want this:
#         Some research (as of 1.71.0):
#         1. Homebrew provide single threaded too (threading=multi,single)
#            (https://github.com/Homebrew/homebrew-core/blob/master/Formula/boost.rb,
#             https://github.com/Homebrew/homebrew-core/blob/master/Formula/boost-python3.rb)
#             .. they do this for boost-python3's test; we do not (not do we want to):
#             https://github.com/Homebrew/homebrew-core/blob/e7c8239a8a7c9b4501c4a18a4028cae82e254984/Formula/boost-python3.rb#L90-L95
#             .. and this for boost-python (2)'s test:
#             https://github.com/Homebrew/homebrew-core/blob/e7c8239a8a7c9b4501c4a18a4028cae82e254984/Formula/boost-python.rb#L61-L67
#         2. Achlinux provide multi threaded-only
#            (https://git.archlinux.org/svntogit/packages.git/tree/trunk/PKGBUILD?h=packages/boost)
#         3. RStudio builds boost (1.69.0) with only threading=multi too
#            (https://github.com/rstudio/rstudio/blob/master/dependencies/common/install-boost)
# _GENERIC_OPTS+=(threading=multi,single)
_GENERIC_OPTS+=(threading=multi)
_GENERIC_OPTS+=(runtime-link=shared)
_GENERIC_OPTS+=(link=static,shared)
_GENERIC_OPTS+=(include="${INCLUDE_PATH}")
_GENERIC_OPTS+=(cxxflags="${CXXFLAGS} -Wno-deprecated-declarations")
_GENERIC_OPTS+=(linkflags="${LINKFLAGS}")
_GENERIC_OPTS+=(--layout=system)
_GENERIC_OPTS+=(--keep-going=false)
_GENERIC_OPTS+=(-j${CPU_COUNT})

declare -a _TP_OPTS=()
if [[ ${target_platform} =~ osx.* ]]; then
  _TP_OPTS+=(target-os=darwin)
  # _TP_OPTS+=(binary-format=mach-o)
  # _TP_OPTS+=(abi=sysv)
  _TP_OPTS+=(threading=multi)
fi

if [[ ${target_platform} =~ osx.* ]]; then
  # See this comment in tools/build/src/tools/darwin.jam
  # "# - The archive builder (libtool is the default as creating
  #  #   archives in darwin is complicated."
  ARCHIVER=${AR}
  # Maybe clang? Or clang-darwin100?
  TOOLSET=clang
  TOOLSET_VERSION=10.0.0
else
  TOOLSET=gcc
  TOOLSET_VERSION=7.3.0
  ARCHIVER=${AR}
fi
_TP_OPTS+=(toolset=${TOOLSET})

declare -a _ALL_OPTS=("${_GENERIC_OPTS[@]}" "${_TP_OPTS[@]}")
