echo on

set TOOLSET=msvc-%vc%.1

:: Set address-model and architecture for Boost.Build
:: ARCH is "64" on win-64 but "arm64" on win-arm64
if "%ARCH%"=="arm64" (
    set B2_ADDRESS_MODEL=64
    set B2_ARCHITECTURE=arm
    :: Use Windows Fibers for Boost.Context on ARM64 (no fcontext asm support)
    set B2_CONTEXT_IMPL=winfib
) else (
    set B2_ADDRESS_MODEL=%ARCH%
    set B2_ARCHITECTURE=x86
    set B2_CONTEXT_IMPL=fcontext
)

set PY_VER_ND=%PY_VER:.=%
set INSTLOC=%CD%\py-boost-inst-%PY_VER%-%ARCH%
set DEBUG_ROBOCOPY=/NFL /NDL


.\b2                              ^
  --prefix=%INSTLOC%              ^
  --layout=system                 ^
  toolset=%TOOLSET%               ^
  address-model=%B2_ADDRESS_MODEL% ^
  architecture=%B2_ARCHITECTURE%  ^
  context-impl=%B2_CONTEXT_IMPL%  ^
  variant=release                 ^
  threading=multi                 ^
  link=static,shared              ^
  -j%CPU_COUNT%                   ^
  --with-python                   ^
  --reconfigure                   ^
  python=%PY_VER%                 ^
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
  
