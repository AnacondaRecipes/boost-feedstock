@echo on

:: Create temp_prefix directory
if not exist temp_prefix mkdir temp_prefix

:: Bootstrap b2
call bootstrap.bat

:: Build and install to temp_prefix
b2 -q ^
    variant=release ^
    debug-symbols=off ^
    threading=multi ^
    runtime-link=shared ^
    link=static,shared ^
    address-model=%ARCH% ^
    architecture=x86 ^
    cxxflags="%CXXFLAGS%" ^
    linkflags="%LDFLAGS%" ^
    --without-python ^
    -j%CPU_COUNT% ^
    --prefix=temp_prefix ^
    install

if errorlevel 1 exit 1