echo on

:: set WITHOUTS=--without-python --with-atomic --without-chrono --without-container --without-context --without-contract --without-coroutine --without-date_time --without-exception --without-fiber --without-filesystem --without-graph --without-graph_parallel --without-iostreams --without-locale --without-log --without-math --without-mpi --without-program_options --without-random --without-regex --without-serialization --without-signals --without-stacktrace --without-system --without-test --without-thread --without-timer --without-type_erasure --without-wave
set WITHOUTS=--without-python

:: Get the major_minor_patch version info, e.g. `1_61_1`. In
:: the past this has been just major_minor, so we do not just
:: replace all dots with underscores in case it changes again
for /F "tokens=1,2,3 delims=." %%a in ("%PKG_VERSION%") do (
   set MAJ=%%a
   set MIN=%%b
   set PAT=%%c
)
set MAJ_MIN_PAT_VER=%MAJ%_%MIN%_%PAT%
set MAJ_MIN_VER=%MAJ%_%MIN%

set TOOLSET=msvc-%vc%.1
set TOOLSET2=vc%vc%1
if "%ARCH%"=="32" (
  set ARCH_STRING=x32
) else (
  set ARCH_STRING=x64
)
:: I would like to switch to this, but boost_python does not
:: work, it tries to link to boost_python.lib instead.
:: set LAYOUT=versioned
set LAYOUT=system

if "%CONDA_BUILD_DEBUG_BUILD_SYSTEM%"=="yes" (
  set DEBUG_FLAGS=-d+3 --debug
  :: set DEBUG_ROBOCOPY=
  set DEBUG_ROBOCOPY=/NFL /NDL
) else (
  set DEBUG_FLAGS=
  set DEBUG_ROBOCOPY=/NFL /NDL
)

.\b2                         ^
  -q %DEBUG_FLAGS%           ^
  --prefix=%LIBRARY_PREFIX%  ^
  --layout=%LAYOUT%          ^
  toolset=%TOOLSET%          ^
  address-model=%ARCH%       ^
  variant=release            ^
  threading=multi            ^
  link=static,shared         ^
  -j%CPU_COUNT%              ^
  %WITHOUTS%                 ^
  install                    ^
  > b2.install.log 2>&1
if errorlevel 1 (
  cat b2.install.log
  exit /b 1
)

:: Move DLLs to LIBRARY_BIN
move %LIBRARY_LIB%\boost*.dll "%LIBRARY_BIN%"
if errorlevel 1 exit 1

if "%LAYOUT%"=="versioned" (
  :: Install fix-up for a non version-specific boost include
  :: This tends to fail:
  :: move /y C:\opt\conda\conda-bld\bst-1.72.0_1\_h_env\Library\include\boost-1_72\boost C:\opt\conda\conda-bld\bst-1.72.0_1\_h_env\Library\include
  :: Access is denied.
  :: move /y %LIBRARY_INC%\boost-%MAJ_MIN_VER%\boost %LIBRARY_INC%
  if not exist %LIBRARY_INC%\boost mkdir %LIBRARY_INC%\boost
  robocopy /E %DEBUG_ROBOCOPY% %LIBRARY_INC%\boost-%MAJ_MIN_VER%\boost %LIBRARY_INC%\boost\
  rmdir /s /q %LIBRARY_INC%\boost-%MAJ_MIN_VER%\

  if not exist %PREFIX%\Library\include\boost\assert.hpp (
    echo "ERROR :: Failed to copy headers from %LIBRARY_INC%\boost-%MAJ_MIN_VER%\boost to %LIBRARY_INC%\boost"
    exit /b 1
  )
)

:: Remove Python headers as we don't build Boost.Python.
if exist %LIBRARY_INC%\boost\python.hpp del %LIBRARY_INC%\boost\python.hpp
if exist %LIBRARY_INC%\boost\python rmdir /s /q %LIBRARY_INC%\boost\python

copy .\b2.exe %LIBRARY_BIN%\b2.exe
if errorlevel 1 exit /b 1
copy .\b2.exe %LIBRARY_BIN%\bjam.exe
if errorlevel 1 exit /b 1

mkdir "%LIBRARY_PREFIX%\share\boost-build\src\build"
mkdir "%LIBRARY_PREFIX%\share\boost-build\src\kernel"
mkdir "%LIBRARY_PREFIX%\share\boost-build\src\options"
mkdir "%LIBRARY_PREFIX%\share\boost-build\src\tools"
mkdir "%LIBRARY_PREFIX%\share\boost-build\src\util"
pushd tools\build\src
  robocopy /E %DEBUG_ROBOCOPY% build   "%LIBRARY_PREFIX%\share\boost-build\src\build"
  robocopy /E %DEBUG_ROBOCOPY% kernel  "%LIBRARY_PREFIX%\share\boost-build\src\kernel"
  robocopy /E %DEBUG_ROBOCOPY% options "%LIBRARY_PREFIX%\share\boost-build\src\options"
  robocopy /E %DEBUG_ROBOCOPY% tools   "%LIBRARY_PREFIX%\share\boost-build\src\tools"
  robocopy /E %DEBUG_ROBOCOPY% util    "%LIBRARY_PREFIX%\share\boost-build\src\util"
  copy /y build-system.jam "%LIBRARY_PREFIX%\share\boost-build\src"
popd
pushd tools\build
  copy *.jam "%LIBRARY_PREFIX%\share\boost-build"
popd

exit /b 0
