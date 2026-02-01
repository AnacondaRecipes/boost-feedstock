@echo on

:: Check if this is ARM64 build - use CMake instead of b2
if "%ARCH%"=="arm64" goto :cmake_build

:: ============================================================
:: B2 BUILD (win-64 and other non-ARM64 platforms)
:: ============================================================

:: Write python configuration, see https://github.com/boostorg/build/issues/194
@echo using python > user-config.jam
@echo : %PY_VER% >> user-config.jam
@echo : %PYTHON:\=\\% >> user-config.jam
@echo : %PREFIX:\=\\%\\include >> user-config.jam
@echo : %PREFIX:\=\\%\\libs >> user-config.jam
@echo ; >> user-config.jam
xcopy /Y user-config.jam %USERPROFILE%

:: clean up directory from bld.bat and reuse b2 built there
rmdir /s /q temp_prefix

mkdir build-py

set TOOLSET=msvc-%vc%.1
set B2_ADDRESS_MODEL=%ARCH%
set B2_ARCHITECTURE=x86
set B2_CONTEXT_IMPL=fcontext

:: Build step
.\b2 install ^
    --build-dir=build-py ^
    --prefix=%LIBRARY_PREFIX% ^
    toolset=%TOOLSET% ^
    address-model=%B2_ADDRESS_MODEL% ^
    architecture=%B2_ARCHITECTURE% ^
    context-impl=%B2_CONTEXT_IMPL% ^
    variant=release ^
    threading=multi ^
    link=shared ^
    --layout=system ^
    --with-python ^
    -j%CPU_COUNT%
if %ERRORLEVEL% neq 0 exit 1

:: clean up between builds for different python versions/implementations
rmdir /s /q build-py

:: Move dll's to LIBRARY_BIN
move %LIBRARY_LIB%\boost*.dll "%LIBRARY_BIN%"
if %ERRORLEVEL% neq 0 exit 1

:: remove CMake metadata from libboost-python; save it for libboost-python-dev
:: needs to be done separately per python version & implementation
mkdir %SRC_DIR%\cf_%PY_VER%_%python_impl%_cmake
move %LIBRARY_LIB%\cmake\boost_python-%PKG_VERSION% %SRC_DIR%\cf_%PY_VER%_%python_impl%_cmake\
move %LIBRARY_LIB%\cmake\boost_numpy-%PKG_VERSION% %SRC_DIR%\cf_%PY_VER%_%python_impl%_cmake\

goto :eof

:: ============================================================
:: CMAKE BUILD (win-arm64)
:: ============================================================
:cmake_build
@echo on
echo "Building Boost.Python with CMake for ARM64"

:: clean up directory from bld.bat
rmdir /s /q temp_prefix 2>nul
rmdir /s /q build 2>nul

mkdir build-py

:: Get Python version without dots for library naming
set PY_VER_ND=%PY_VER:.=%

:: Configure CMake for Python libraries only
cmake -G Ninja -B build-py -S . ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% ^
    -DBUILD_SHARED_LIBS=ON ^
    -DBOOST_INSTALL_LAYOUT=system ^
    -DBOOST_INCLUDE_LIBRARIES=python;numpy ^
    -DBOOST_ENABLE_PYTHON=ON ^
    -DBOOST_CONTEXT_IMPLEMENTATION=winfib ^
    -DPython_EXECUTABLE=%PYTHON% ^
    -DPython_ROOT_DIR=%PREFIX%
if %ERRORLEVEL% neq 0 exit 1

:: Build
cmake --build build-py --config Release -j %CPU_COUNT%
if %ERRORLEVEL% neq 0 exit 1

:: Install
cmake --install build-py --config Release
if %ERRORLEVEL% neq 0 exit 1

:: clean up between builds for different python versions/implementations
rmdir /s /q build-py

:: Move dll's from bin to LIBRARY_BIN (CMake puts DLLs in bin/)
if exist %LIBRARY_PREFIX%\bin\boost_python*.dll (
    move %LIBRARY_PREFIX%\bin\boost_python*.dll "%LIBRARY_BIN%"
)
if exist %LIBRARY_PREFIX%\bin\boost_numpy*.dll (
    move %LIBRARY_PREFIX%\bin\boost_numpy*.dll "%LIBRARY_BIN%"
)

:: Also check lib directory for DLLs
if exist %LIBRARY_LIB%\boost_python*.dll (
    move %LIBRARY_LIB%\boost_python*.dll "%LIBRARY_BIN%"
)
if exist %LIBRARY_LIB%\boost_numpy*.dll (
    move %LIBRARY_LIB%\boost_numpy*.dll "%LIBRARY_BIN%"
)

:: remove CMake metadata from libboost-python; save it for libboost-python-dev
:: needs to be done separately per python version & implementation
mkdir %SRC_DIR%\cf_%PY_VER%_%python_impl%_cmake
move %LIBRARY_LIB%\cmake\boost_python-%PKG_VERSION% %SRC_DIR%\cf_%PY_VER%_%python_impl%_cmake\
move %LIBRARY_LIB%\cmake\boost_numpy-%PKG_VERSION% %SRC_DIR%\cf_%PY_VER%_%python_impl%_cmake\

goto :eof
