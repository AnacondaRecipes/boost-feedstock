echo on

set TOOLSET=msvc-%vc%.1

:: Set address-model and architecture for Boost.Build
:: ARCH is "64" on win-64 but "arm64" on win-arm64
if "%ARCH%"=="arm64" (
    set B2_ADDRESS_MODEL=64
    set B2_ARCHITECTURE=arm
    :: Use Windows Fibers for Boost.Context on ARM64 (no fcontext asm support)
    set B2_CONTEXT_IMPL=winfib
    :: Exclude libraries that don't support ARM64: coroutine (uses fcontext directly), mpi (no ARM64 support)
    set B2_ARM64_EXCLUSIONS=--without-coroutine --without-mpi
) else (
    set B2_ADDRESS_MODEL=%ARCH%
    set B2_ARCHITECTURE=x86
    set B2_CONTEXT_IMPL=fcontext
    set B2_ARM64_EXCLUSIONS=
)

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
  %B2_ARM64_EXCLUSIONS%           ^
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
