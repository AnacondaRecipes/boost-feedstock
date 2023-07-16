echo on

set TOOLSET=msvc-%vc%.1
set ARCH_STRING=x64
set LAYOUT=system

.\b2                         ^
  --prefix=%LIBRARY_PREFIX%  ^
  --layout=%LAYOUT%          ^
  toolset=%TOOLSET%          ^
  address-model=%ARCH%       ^
  variant=release            ^
  threading=multi            ^
  link=static,shared         ^
  -j%CPU_COUNT%              ^
  --without-python           ^
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

move %LIBRARY_PREFIX%\share\.b2 %LIBRARY_PREFIX%\share\b2
copy %LIBRARY_PREFIX%\share\b2.exe %LIBRARY_BIN%\b2.exe
copy %LIBRARY_PREFIX%\share\b2.exe %LIBRARY_BIN%\bjam.exe

exit /b 0
