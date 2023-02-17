echo on

:: if exist C:\Users\builder\py-boost-%PY_VER%-before-clean rd /s /q C:\Users\builder\py-boost-%PY_VER%-before-clean > NUL
:: mkdir C:\Users\builder\py-boost-%PY_VER%-before-clean
:: xcopy %CD% C:\Users\builder\py-boost-%PY_VER%-before-clean /s /e /h /q /y

set INSTLOC=%CD%\py-boost-inst-%PY_VER%-%ARCH%

:: if exist C:\Users\builder\py-boost-%PY_VER%-after-clean rd /s /q C:\Users\builder\py-boost-%PY_VER%-after-clean > NUL
:: mkdir C:\Users\builder\py-boost-%PY_VER%-after-clean
:: xcopy %CD% C:\Users\builder\py-boost-%PY_VER%-after-clean /s /e /h /q /y

:: if exist C:\Users\builder\py-boost-%PY_VER%-after-build rd /s /q C:\Users\builder\py-boost-%PY_VER%-after-build > NUL
:: mkdir C:\Users\builder\py-boost-%PY_VER%-after-build

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
set PY_VER_ND=%PY_VER:.=%

if "%CONDA_BUILD_DEBUG_BUILD_SYSTEM%"=="yes" (
  set DEBUG_FLAGS=-d+3 --debug
  :: set DEBUG_ROBOCOPY=
  set DEBUG_ROBOCOPY=/NFL /NDL
) else (
  set DEBUG_FLAGS=
  set DEBUG_ROBOCOPY=/NFL /NDL
)

:: No idea, luckily it is far from slow.
for /L %%A IN (1,1,2) DO (
  .\b2 ^
    -q %DEBUG_FLAGS% ^
    --prefix=%INSTLOC% ^
    --layout=%LAYOUT% ^
    toolset=%TOOLSET% ^
    address-model=%ARCH% ^
    variant=release ^
    threading=multi ^
    link=static,shared ^
    -j1 ^
    --with-python ^
    --reconfigure ^
    python=%PY_VER% ^
    clean > py-boost-%PY_VER%-clean.log 2>&1
)

.\b2 ^
  -q %DEBUG_FLAGS% ^
  --prefix=%INSTLOC% ^
  --layout=%LAYOUT% ^
  toolset=%TOOLSET% ^
  address-model=%ARCH% ^
  variant=release ^
  threading=multi ^
  link=static,shared ^
  --with-python ^
  --reconfigure ^
  python=%PY_VER% ^
  install > py-boost-%PY_VER%-install.log 2>&1
if errorlevel 1 (
  cat py-boost-%PY_VER%-install.log
  exit /b 1
)

:: xcopy %CD% C:\Users\builder\py-boost-%PY_VER%-after-build /s /e /h /q /y

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

:: Not sure about this, shouldn't these go in share\cmake instead? If so then install-libboost.bat needs
:: fixing too.
mkdir %LIBRARY_LIB%\cmake
mkdir %LIBRARY_INC%\boost\python
move /y %INSTLOC%\lib\cmake "%LIBRARY_LIB%\cmake"
if errorlevel 1 exit /b 1

:: set DBGINFIX=-gd
set DBGINFIX=

set VERSIONED_FNAME_INFIX=%PY_VER_ND%-%TOOLSET2%-mt%DBGINFIX%-%ARCH_STRING%-%MAJ_MIN_VER%

if "%LAYOUT%"=="versioned" (
  :: Install fix-up for a non version-specific boost include
  :: move /y %INSTLOC%\include\boost-%MAJ_MIN_VER%\boost\python %LIBRARY_INC%\boost\
  robocopy /E %DEBUG_ROBOCOPY% %INSTLOC%\include\boost-%MAJ_MIN_VER%\boost\python %LIBRARY_INC%\boost\python\
  copy /y %INSTLOC%\include\boost-%MAJ_MIN_VER%\boost\python.hpp %LIBRARY_INC%\boost\python\

  :: Spent too long on this. Hopefully the clean command is now correct. If not you'll find objs that
  :: contain e.g. DEFAULT:python37.lib when linking to Python 3.6 and those need to be removed.
  if not exist %INSTLOC%\lib\boost_python%PY_VER_ND%-%TOOLSET2%-mt-%ARCH_STRING%-%MAJ_MIN_VER%.dll (
    echo ERROR :: Did not find %INSTLOC%\lib\boost_python%PY_VER_ND%-%TOOLSET2%-mt-%ARCH_STRING%-%MAJ_MIN_VER%.dll
    exit /b 1
  )
  if not exist %INSTLOC%\lib\boost_numpy%VERSIONED_FNAME_INFIX%.dll (
    echo ERROR :: Did not find %INSTLOC%\lib\boost_numpy%VERSIONED_FNAME_INFIX%.dll
    exit /b 1
  )
  :: Move DLLs to LIBRARY_BIN
  move /y %INSTLOC%\lib\*%TOOLSET2%-mt-%ARCH_STRING%-%MAJ_MIN_VER%.dll "%LIBRARY_BIN%"
  if errorlevel 1 exit /b 1
  move /y %INSTLOC%\lib\*%TOOLSET2%-mt-%ARCH_STRING%-%MAJ_MIN_VER%.lib "%LIBRARY_LIB%"
  if errorlevel 1 exit /b 1
) else (
  robocopy /E %DEBUG_ROBOCOPY% %INSTLOC%\include\boost\python %LIBRARY_INC%\boost\python\
  copy /y %INSTLOC%\include\boost\python.hpp %LIBRARY_INC%\boost\python\
  move /y %INSTLOC%\lib\boost*.lib "%LIBRARY_LIB%"
  copy /y "%LIBRARY_LIB%\boost_python%PY_VER_ND%.lib" "%LIBRARY_LIB%\boost_python.lib"
  copy /y "%LIBRARY_LIB%\boost_numpy%PY_VER_ND%.lib" "%LIBRARY_LIB%\boost_numpy.lib"

  :: python-boost just does not seem to care and always tries to link to versioned libs. Debugging this is
  :: painful.
  copy /y "%LIBRARY_LIB%\boost_python%PY_VER_ND%.lib" "%LIBRARY_LIB%\boost_python%VERSIONED_FNAME_INFIX%.lib"
  if errorlevel 1 exit /b 1
  copy /y "%LIBRARY_LIB%\boost_numpy%PY_VER_ND%.lib" "%LIBRARY_LIB%\boost_numpy%VERSIONED_FNAME_INFIX%.lib"
  if errorlevel 1 exit /b 1

  if errorlevel 1 exit /b 1
  move /y %INSTLOC%\lib\boost*.dll "%LIBRARY_BIN%"
  if errorlevel 1 exit /b 1
) 

:: remove any old builds of the python target
.\b2 ^
  -q %DEBUG_FLAGS% ^
  --prefix=%INSTLOC% ^
  --layout=%LAYOUT% ^
  address-model=%ARCH% ^
  variant=release ^
  threading=multi ^
  link=static,shared ^
  --with-python ^
  --reconfigure ^
  python=%PY_VER% ^
  clean python > py-boost-%PY_VER%-clean-final.log 2>&1
