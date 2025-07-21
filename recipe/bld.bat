@echo on

:: Create temp_prefix directory
if not exist temp_prefix mkdir temp_prefix

:: Bootstrap b2
call bootstrap.bat

:: Build and install to temp_prefix
.\b2 install ^
    --prefix=temp_prefix ^
    toolset=msvc-%VS_MAJOR%.0 ^
    address-model=%ARCH% ^
    variant=release ^
    threading=multi ^
    runtime-link=shared ^
    link=static,shared ^
    --without-python ^
    -j%CPU_COUNT%

if errorlevel 1 exit 1