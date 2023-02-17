#!/bin/bash

# Hints:
# http://boost.2283326.n4.nabble.com/how-to-build-boost-with-bzip2-in-non-standard-location-td2661155.html
# http://www.gentoo.org/proj/en/base/amd64/howtos/?part=1&chap=3
# http://www.boost.org/doc/libs/1_55_0/doc/html/bbv2/reference.html

# Hints for OSX:
# http://stackoverflow.com/questions/20108407/how-do-i-compile-boost-for-os-x-64b-platforms-with-stdlibc

set -x -e
set -o pipefail

. ${RECIPE_DIR}/set__ALL_OPTS.sh

echo "Compiling boost with TOOLSET: $TOOLSET"

if [[ ${target_platform} =~ osx.* ]]; then
  cp ${RECIPE_DIR}/xcode-select .
  chmod +x xcode-select
  PATH=${PWD}:${PATH}
fi

# cross-cxx toolset is available for cross-compiling, but does not appear to work
export BUILD_CXX=${CXX}
export BUILD_CXXFLAGS=${CXXFLAGS}
export BUILD_LDFLAGS=${LDFLAGS}


# http://www.boost.org/build/doc/html/bbv2/tasks/crosscompile.html
cat <<EOF > ${SRC_DIR}/tools/build/src/site-config.jam
using ${TOOLSET} : : ${CXX} ;
EOF

bash -x $PWD/bootstrap.sh \
    --prefix="${PREFIX}"  \
    --with-icu="${PREFIX}"  \
    --with-toolset=${TOOLSET}  \
    --without-libraries=python

# Archlinux emits this into project-config.jam (well, for python2.7 initially
# alongside the build of all the rest, then this is sedded into this file and
# a build of boost-python (into a different dir) is performed.
# if ! [ python.configured ]
# {
#    using python : 3.7 : "/usr" : /usr/include/python3.7m ;
# }

# The quotes around things with spaces are essential here:
for _SCJ in site-config.jam tools/build/src/site-config.jam; do
  cat << EOF > ${_SCJ}
  using ${TOOLSET} : ${TOOLSET_VERSION} : $(basename ${CXX})
              : # options
                  <archiver>$(basename ${ARCHIVER})
                  <cflags>"${CFLAGS}"
                  <cxxflags>"${CXXFLAGS}"
                  <linkflags>"${LDFLAGS}"
                  <ranlib>$(basename ${RANLIB})
              ;
EOF
done


# There is no configure target, however configuration does happen and
# can fail. Passing in a target that does not exist allows us to exit
# out very quickly when things go awry.

echo "Information :: Calling b2 with a fake target to catch early failures"

./b2 "${_ALL_OPTS[@]}" \
     target_does_not_exist 2>&1 > b2.prebuild-fake-fail.log 2>&1 || true

for _MSG in error: warning:; do
  if grep -q "^${_MSG}" b2.prebuild-fake-fail.log; then
    echo -e "\n\n***** $(echo ${_MSG::${#_MSG} - 1} | tr 'a-z' 'A-Z') *****"
    echo -e "\nThe following ${_MSG::${#_MSG} - 1} were found during the configuration stage of b2:\n"
    grep "^${_MSG}" b2.prebuild-fake-fail.log -A2 || true
    echo -e "\n\n***** $(echo ${_MSG::${#_MSG} - 1} | tr 'a-z' 'A-Z') *****\n"
    if [[ "${_MSG}" == "error:" ]]; then
      echo -e ".. stopping build.\n"
      exit 1
    else
      echo ".. ingoring."
    fi
  fi
done

echo "Information :: Calling b2 with no target to perform build"

./b2 "${_ALL_OPTS[@]}" \
     --without-python \
     -j"${CPU_COUNT}" \
     stage 2>&1 | tee b2.build.log

echo "Information :: build.sh finished"
