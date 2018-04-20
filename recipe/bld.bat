:: For VS2008 32-bit builds you probably need:
:: https://support.microsoft.com/en-us/help/976656/error-message-when-you-use-the-visual-c-2008-compiler-fatal-error-c185
:: http://thehotfixshare.net/board/index.php?showtopic=14050

:: Start with bootstrap
call bootstrap.bat vc%VS_MAJOR%

if errorlevel 1 exit /b 1

set LogFile=b2.build.log
set TempLog=b2.build.log.tmp
set LogTee=^> %TempLog%^&^& type %TempLog%^&^&type %TempLog%^>^>%LogFile%

:: Build step
.\b2 ^
  -q -d+2 ^
  --build-dir=bb-%VS_MAJOR% ^
  --prefix=%LIBRARY_PREFIX% ^
  toolset=msvc-%VS_MAJOR%.0 ^
  address-model=%ARCH% ^
  variant=release ^
  threading=multi ^
  link=static,shared ^
  -j%CPU_COUNT% ^
  --without-python ^
  --layout=system ^
  stage ^
  %LogTee%

if errorlevel 1 exit /b 1

:: Get the major minor version info (e.g. `1_61`)
python -c "import os; print('_'.join(os.environ['PKG_VERSION'].split('.')[:3]))" > temp.txt
set /p MAJ_MIN_VER=<temp.txt

:: Install fix-up for a non version-specific boost include
move %LIBRARY_INC%\boost-%MAJ_MIN_VER%\boost %LIBRARY_INC%
if errorlevel 1 exit /b 1

:: Remove Python headers as we don't build Boost.Python.
del %LIBRARY_INC%\boost\python.hpp
rmdir /s /q %LIBRARY_INC%\boost\python


:: Set BOOST_AUTO_LINK_NOMANGLE so that auto-linking uses system layout
echo &echo.                           >> %LIBRARY_INC%\boost\config\user.hpp
echo #define BOOST_AUTO_LINK_NOMANGLE >> %LIBRARY_INC%\boost\config\user.hpp

:: Move dll's to LIBRARY_BIN
move %LIBRARY_LIB%\*vc%VS_MAJOR%0-mt-%MAJ_MIN_VER%.dll "%LIBRARY_BIN%"
if errorlevel 1 exit /b 1
