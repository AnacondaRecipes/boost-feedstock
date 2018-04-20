:: activate the build environment
call "%BUILD_PREFIX%\Scripts\activate.bat" "%BUILD_PREFIX%"

:: "stack" the host environment on top of the build env
set "CONDA_PATH_BACKUP="
set CONDA_MAX_SHLVL=2
call "%BUILD_PREFIX%\Scripts\activate.bat" "%PREFIX%"

set LogFile=b2.install-py-%PY_VER%.log
set TempLog=b2.install-py-%PY_VER%.log.tmp
set LogTee=^> %TempLog%^&^& type %TempLog%^&^&type %TempLog%^>^>%LogFile%

:: remove any old builds of the python target
.\b2 -q -d+2 --with-python --clean

.\b2 ^
  -q -d+2 ^
  --build-dir=buildboost-%VS_MAJOR% ^
  --prefix=%CD%\py-boost-install ^
  toolset=msvc-%VS_MAJOR%.0 ^
  address-model=%ARCH% ^
  variant=release ^
  threading=multi ^
  link=static,shared ^
  -j%CPU_COUNT% ^
  --with-python ^
  python=%PY_VER% ^
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
:: echo move %CD%\py-boost-install\include\boost-%MAJ_MIN_PAT_VER%\boost %LIBRARY_INC%\boost
move %CD%\py-boost-install\include\boost-%MAJ_MIN_PAT_VER%\boost\python %LIBRARY_INC%\boost\
move %CD%\py-boost-install\include\boost-%MAJ_MIN_PAT_VER%\boost\python.hpp %LIBRARY_INC%\boost\
if errorlevel 1 exit /b 1

:: Move DLL to LIBRARY_BIN
move %CD%\py-boost-install\lib\*vc%VS_MAJOR%0-mt-%MAJ_MIN_PAT_VER%.dll "%LIBRARY_BIN%"
move %CD%\py-boost-install\lib\*vc%VS_MAJOR%0-mt-%MAJ_MIN_PAT_VER%.lib "%LIBRARY_LIB%"
if errorlevel 1 exit /b 1
