echo on

set CC=clang
set CXX=clang++

set TOOLSET=%CC%

set ARCH_STRING=x64
set LAYOUT=system
set PY_VER_ND=%PY_VER:.=%
set INSTLOC=%CD%\py-boost-inst-%PY_VER%-%ARCH%
set DEBUG_ROBOCOPY=/NFL /NDL


.\b2                         ^
  --prefix=%INSTLOC%  ^
  --layout=%LAYOUT%          ^
  toolset=%TOOLSET%          ^
  address-model=%ARCH%       ^
  variant=release            ^
  threading=multi            ^
  link=static,shared         ^
  -j%CPU_COUNT%              ^
  --with-python              ^
  --reconfigure              ^
  python=%PY_VER%            ^
  install

  
if errorlevel 1 (
  exit /b 1
)

robocopy /E %DEBUG_ROBOCOPY% %INSTLOC%\include\boost\python %LIBRARY_INC%\boost\python\
copy /y %INSTLOC%\include\boost\python.hpp %LIBRARY_INC%\boost\python\
move /y %INSTLOC%\lib\boost*.lib "%LIBRARY_LIB%"
move /y %INSTLOC%\lib\boost*.lib "%LIBRARY_LIB%"
move /y %INSTLOC%\lib\libboost*.lib "%LIBRARY_LIB%"
move /y %INSTLOC%\lib\boost*.dll "%LIBRARY_BIN%"
  
