#!/bin/bash

# Hints:
# http://boost.2283326.n4.nabble.com/how-to-build-boost-with-bzip2-in-non-standard-location-td2661155.html
# http://www.gentoo.org/proj/en/base/amd64/howtos/?part=1&chap=3
# http://www.boost.org/doc/libs/1_55_0/doc/html/bbv2/reference.html

# Hints for OSX:
# http://stackoverflow.com/questions/20108407/how-do-i-compile-boost-for-os-x-64b-platforms-with-stdlibc

set -x -e

INCLUDE_PATH="${PREFIX}/include"
LIBRARY_PATH="${PREFIX}/lib"

if [[ ${HOST} =~ .*darwin.* ]]; then
    TOOLSET=clang
elif [[ ${HOST} =~ .*linux.* ]]; then
    TOOLSET=gcc
fi

# http://www.boost.org/build/doc/html/bbv2/tasks/crosscompile.html
cat <<EOF > ${SRC_DIR}/tools/build/src/site-config.jam
using ${TOOLSET} : custom : ${CXX} ;
EOF

LINKFLAGS="${LINKFLAGS} -L${LIBRARY_PATH}"

./bootstrap.sh \
    --prefix="${PREFIX}" \
    --without-libraries=python \
    --with-toolset=cc \
    --with-icu="${PREFIX}" \
    | tee bootstrap.log 2>&1

# https://svn.boost.org/trac10/ticket/5917
# https://stackoverflow.com/a/5244844/1005215
sed -i.bak "s,cc,${TOOLSET},g" ${SRC_DIR}/project-config.jam

./b2 -q -d+2 \
     variant=release \
     address-model="${ARCH}" \
     architecture=x86 \
     debug-symbols=off \
     threading=multi \
     runtime-link=shared \
     link=static,shared \
     toolset=${TOOLSET}-custom \
     include="${INCLUDE_PATH}" \
     cxxflags="${CXXFLAGS} -Wno-deprecated-declarations" \
     linkflags="${LINKFLAGS}" \
     --layout=system \
     -j"${CPU_COUNT}" | tee b2.build.log 2>&1
