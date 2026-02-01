@echo on

:: Check if this is ARM64 build - use CMake instead of b2
if "%ARCH%"=="arm64" goto :cmake_build

:: ============================================================
:: B2 BUILD (win-64 and other non-ARM64 platforms)
:: ============================================================

set TOOLSET=msvc-%vc%.1
set B2_ADDRESS_MODEL=%ARCH%
set B2_ARCHITECTURE=x86
set B2_CONTEXT_IMPL=fcontext

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

goto :eof

:: ============================================================
:: CMAKE BUILD (win-arm64)
:: ============================================================
:cmake_build
@echo on
echo "Building Boost.Python with CMake for ARM64 (install-py-boost)"

set PY_VER_ND=%PY_VER:.=%
set INSTLOC=%CD%\py-boost-inst-%PY_VER%-%ARCH%

mkdir build-py-boost

:: Configure CMake for Python libraries only
cmake -G Ninja -B build-py-boost -S . ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_INSTALL_PREFIX=%INSTLOC% ^
    -DBUILD_SHARED_LIBS=ON ^
    -DBOOST_INSTALL_LAYOUT=system ^
    -DBOOST_INCLUDE_LIBRARIES=python;numpy ^
    -DBOOST_ENABLE_PYTHON=ON ^
    -DBOOST_CONTEXT_IMPLEMENTATION=winfib ^
    -DPython_EXECUTABLE=%PYTHON% ^
    -DPython_ROOT_DIR=%PREFIX%
if %ERRORLEVEL% neq 0 exit /b 1

:: Build
cmake --build build-py-boost --config Release -j %CPU_COUNT%
if %ERRORLEVEL% neq 0 exit /b 1

:: Install to temp location
cmake --install build-py-boost --config Release
if %ERRORLEVEL% neq 0 exit /b 1

:: Copy/move files to final locations
if exist %INSTLOC%\include\boost\python (
    robocopy /E /NFL /NDL %INSTLOC%\include\boost\python %LIBRARY_INC%\boost\python\
)
if exist %INSTLOC%\include\boost\python.hpp (
    copy /y %INSTLOC%\include\boost\python.hpp %LIBRARY_INC%\boost\python\
)

:: Move libraries
move /y %INSTLOC%\lib\boost*.lib "%LIBRARY_LIB%" 2>nul
move /y %INSTLOC%\lib\libboost*.lib "%LIBRARY_LIB%" 2>nul

:: Move DLLs (CMake puts them in bin/)
if exist %INSTLOC%\bin\boost*.dll (
    move /y %INSTLOC%\bin\boost*.dll "%LIBRARY_BIN%"
)
if exist %INSTLOC%\lib\boost*.dll (
    move /y %INSTLOC%\lib\boost*.dll "%LIBRARY_BIN%"
)

goto :eof
  
