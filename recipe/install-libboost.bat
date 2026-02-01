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

.\b2                              ^
  --prefix=%LIBRARY_PREFIX%       ^
  --layout=system                 ^
  toolset=%TOOLSET%               ^
  address-model=%B2_ADDRESS_MODEL% ^
  architecture=%B2_ARCHITECTURE%  ^
  context-impl=%B2_CONTEXT_IMPL%  ^
  variant=release                 ^
  threading=multi                 ^
  link=shared                     ^
  -j%CPU_COUNT%                   ^
  --without-python                ^
  install                    
  
if errorlevel 1 (
  exit /b 1
)

:: Remove Python headers as we don't build Boost.Python.
if exist %LIBRARY_INC%\boost\python.hpp del %LIBRARY_INC%\boost\python.hpp
if exist %LIBRARY_INC%\boost\python rmdir /s /q %LIBRARY_INC%\boost\python

pushd tools\build
call bootstrap.bat
:: install copies b2 into %LIBRARY_PREFIX%\share\b2.exe and src into  %LIBRARY_PREFIX%\share\.b2
b2 install --prefix=%LIBRARY_PREFIX%\share
popd

move %LIBRARY_PREFIX%\lib\boost_*.dll %LIBRARY_BIN%
move %LIBRARY_PREFIX%\share\.b2 %LIBRARY_PREFIX%\share\b2
copy %LIBRARY_PREFIX%\share\b2.exe %LIBRARY_BIN%\b2.exe
copy %LIBRARY_PREFIX%\share\b2.exe %LIBRARY_BIN%\bjam.exe

exit /b 0

:: ============================================================
:: CMAKE BUILD (win-arm64)
:: ============================================================
:cmake_build
@echo on
echo "Building Boost with CMake for ARM64 (install-libboost)"

mkdir build-libboost

:: Configure CMake
cmake -G Ninja -B build-libboost -S . ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% ^
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
if %ERRORLEVEL% neq 0 exit /b 1

:: Build
cmake --build build-libboost --config Release -j %CPU_COUNT%
if %ERRORLEVEL% neq 0 exit /b 1

:: Install
cmake --install build-libboost --config Release
if %ERRORLEVEL% neq 0 exit /b 1

:: Remove Python headers as we don't build Boost.Python.
if exist %LIBRARY_INC%\boost\python.hpp del %LIBRARY_INC%\boost\python.hpp
if exist %LIBRARY_INC%\boost\python rmdir /s /q %LIBRARY_INC%\boost\python

:: Move DLLs from bin to LIBRARY_BIN
if exist %LIBRARY_PREFIX%\bin\boost_*.dll (
    move %LIBRARY_PREFIX%\bin\boost_*.dll %LIBRARY_BIN%
)

exit /b 0
