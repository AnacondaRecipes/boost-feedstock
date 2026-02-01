@echo on

:: Check if this is ARM64 build - use CMake instead of b2
if "%ARCH%"=="arm64" goto :cmake_build

:: ============================================================
:: B2 BUILD (win-64 and other non-ARM64 platforms)
:: ============================================================

:: Write python configuration, see https://github.com/boostorg/build/issues/194
@echo using python > user-config.jam
@echo : %PY_DUMMY_VER% >> user-config.jam
@echo : %PYTHON:\=\\% >> user-config.jam
@echo : %PREFIX:\=\\%\\include >> user-config.jam
@echo : %PREFIX:\=\\%\\libs >> user-config.jam
@echo ; >> user-config.jam
xcopy /Y user-config.jam %USERPROFILE%

:: Start with bootstrap
call bootstrap.bat
if %ERRORLEVEL% neq 0 exit 1

:: bootstrap.bat turns off echo; turn it on again
@echo on

mkdir temp_prefix

set TOOLSET=msvc-%vc%.1
set B2_ADDRESS_MODEL=%ARCH%
set B2_ARCHITECTURE=x86
set B2_CONTEXT_IMPL=fcontext

:: Build step
.\b2 install ^
    --prefix=temp_prefix ^
    toolset=%TOOLSET%^
    address-model=%B2_ADDRESS_MODEL% ^
    architecture=%B2_ARCHITECTURE% ^
    context-impl=%B2_CONTEXT_IMPL% ^
    variant=release ^
    threading=multi ^
    link=shared ^
    cxxstd=20 ^
    -s NO_COMPRESSION=0 ^
    -s NO_ZLIB=0 ^
    -s NO_BZIP2=0 ^
    -s ZLIB_INCLUDE=%LIBRARY_INC% ^
    -s ZLIB_LIBPATH=%LIBRARY_LIB% ^
    -s ZLIB_BINARY=z ^
    -s BZIP2_INCLUDE=%LIBRARY_INC% ^
    -s BZIP2_LIBPATH=%LIBRARY_LIB% ^
    -s BZIP2_BINARY=libbz2 ^
    -s ZSTD_INCLUDE=%LIBRARY_INC% ^
    -s ZSTD_LIBPATH=%LIBRARY_LIB% ^
    -s ZSTD_BINARY=zstd ^
    --layout=system ^
    -j%CPU_COUNT%
if %ERRORLEVEL% neq 0 exit 1

:: Set BOOST_AUTO_LINK_NOMANGLE so that auto-linking uses system layout
echo &echo.                           >> temp_prefix\include\boost\config\user.hpp
echo #define BOOST_AUTO_LINK_NOMANGLE >> temp_prefix\include\boost\config\user.hpp

:: we package the (python-version-independent) headers here, whereas the libs
:: are done in build-py.bat (because we need to build per python version)
del temp_prefix\lib\boost_python*.lib
del temp_prefix\lib\boost_python*.dll
del temp_prefix\lib\boost_numpy*.lib
del temp_prefix\lib\boost_numpy*.dll
rmdir /s /q temp_prefix\lib\cmake\boost_python-%PKG_VERSION%
rmdir /s /q temp_prefix\lib\cmake\boost_numpy-%PKG_VERSION%

set MAX_NUMBER_OF_MEMBERS=200
erb boost\hana\detail\struct_macros.hpp.erb > temp_prefix\include\boost\hana\detail\struct_macros.hpp

goto :eof

:: ============================================================
:: CMAKE BUILD (win-arm64)
:: ============================================================
:cmake_build
@echo on
echo "Building Boost with CMake for ARM64"

mkdir temp_prefix
mkdir build

:: Configure CMake
:: - Use winfib for context implementation (fcontext asm has issues on ARM64 Windows)
:: - Exclude coroutine (uses fcontext directly) and mpi (no ARM64 support)
:: - Use system layout for library naming
cmake -G Ninja -B build -S . ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_INSTALL_PREFIX=temp_prefix ^
    -DBUILD_SHARED_LIBS=ON ^
    -DBOOST_INSTALL_LAYOUT=system ^
    -DBOOST_EXCLUDE_LIBRARIES=mpi;graph_parallel;coroutine ^
    -DBOOST_ENABLE_PYTHON=OFF ^
    -DBOOST_CONTEXT_IMPLEMENTATION=winfib ^
    -DBOOST_IOSTREAMS_ENABLE_ZLIB=ON ^
    -DBOOST_IOSTREAMS_ENABLE_BZIP2=ON ^
    -DBOOST_IOSTREAMS_ENABLE_ZSTD=ON ^
    -DZLIB_ROOT=%LIBRARY_PREFIX% ^
    -DBZIP2_ROOT=%LIBRARY_PREFIX% ^
    -Dzstd_ROOT=%LIBRARY_PREFIX%
if %ERRORLEVEL% neq 0 exit 1

:: Build
cmake --build build --config Release -j %CPU_COUNT%
if %ERRORLEVEL% neq 0 exit 1

:: Install
cmake --install build --config Release
if %ERRORLEVEL% neq 0 exit 1

:: Set BOOST_AUTO_LINK_NOMANGLE so that auto-linking uses system layout
echo &echo.                           >> temp_prefix\include\boost\config\user.hpp
echo #define BOOST_AUTO_LINK_NOMANGLE >> temp_prefix\include\boost\config\user.hpp

:: Remove Python libraries if any were built (they shouldn't be with BOOST_ENABLE_PYTHON=OFF)
del temp_prefix\lib\boost_python*.lib 2>nul
del temp_prefix\lib\boost_python*.dll 2>nul
del temp_prefix\lib\boost_numpy*.lib 2>nul
del temp_prefix\lib\boost_numpy*.dll 2>nul
del temp_prefix\bin\boost_python*.dll 2>nul
del temp_prefix\bin\boost_numpy*.dll 2>nul
rmdir /s /q temp_prefix\lib\cmake\boost_python-%PKG_VERSION% 2>nul
rmdir /s /q temp_prefix\lib\cmake\boost_numpy-%PKG_VERSION% 2>nul

:: Move DLLs from bin to lib for consistency with b2 output structure
:: (CMake puts DLLs in bin/, b2 puts them in lib/)
if exist temp_prefix\bin\*.dll (
    move temp_prefix\bin\*.dll temp_prefix\lib\
)

goto :eof
