:: activate the build environment
call "%BUILD_PREFIX%\Scripts\activate.bat" "%BUILD_PREFIX%"

set LogFile=b2.install.log
set TempLog=b2.install.log.tmp
set LogTee=^> %TempLog%^&^& type %TempLog%^&^&type %TempLog%^>^>%LogFile%

.\b2 ^
  -q -d+2 ^
  --build-dir=buildboost-%VS_MAJOR% ^
  --prefix=%LIBRARY_PREFIX% ^
  toolset=msvc-%VS_MAJOR%.0 ^
  address-model=%ARCH% ^
  variant=release ^
  threading=multi ^
  link=static,shared ^
  -j%CPU_COUNT% ^
  --without-python ^
  install ^
  %LogTee%

:: Get the major_minor_patch version info, e.g. `1_61_1`. In
:: the past this has been just major_minor, so we do not just
:: replace all dots with underscores in case it changes again
for /F "tokens=1,2,3 delims=." %%a in ("%PKG_VERSION%") do (
   set MAJ=%%a
   set MIN=%%b
   set PAT=%%c
)
set MAJ_MIN_PAT_VER=%MAJ%_%MIN%_%PAT%

:: Install fix-up for a non version-specific boost include
move %LIBRARY_INC%\boost-%MAJ_MIN_PAT_VER%\boost %LIBRARY_INC%
if errorlevel 1 exit /b 1

:: Remove Python headers as we don't build Boost.Python.
if exist %LIBRARY_INC%\boost\python.hpp del %LIBRARY_INC%\boost\python.hpp
if exist %LIBRARY_INC%\boost\python rmdir /s /q %LIBRARY_INC%\boost\python

:: Move DLLs to LIBRARY_BIN
move %LIBRARY_LIB%\*vc%VS_MAJOR%0-mt-%MAJ_MIN_PAT_VER%.dll "%LIBRARY_BIN%"
if errorlevel 1 exit /b 1

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
  robocopy /E build   "%LIBRARY_PREFIX%\share\boost-build\src\build"
  robocopy /E kernel  "%LIBRARY_PREFIX%\share\boost-build\src\kernel"
  robocopy /E options "%LIBRARY_PREFIX%\share\boost-build\src\options"
  robocopy /E tools   "%LIBRARY_PREFIX%\share\boost-build\src\tools"
  robocopy /E util    "%LIBRARY_PREFIX%\share\boost-build\src\util"
popd
pushd tools\build
  copy *.jam "%LIBRARY_PREFIX%\share\boost-build"
popd
exit /b 0
