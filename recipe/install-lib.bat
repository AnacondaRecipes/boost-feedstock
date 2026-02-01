@echo on

if [%PKG_NAME%] == [libboost-headers] (
    REM for libboost-headers, only the headers
    robocopy temp_prefix\include %LIBRARY_INC% /E >nul
    REM robocopy leaves non-zero exit status as sign of success; clear it
    echo "robocopy done"
) else if [%PKG_NAME%] == [libboost] (
    REM only the libraries (don't copy CMake metadata)
    move temp_prefix\lib\boost*.lib %LIBRARY_LIB%
    move temp_prefix\lib\libboost*.lib %LIBRARY_LIB%
    REM dll's go to LIBRARY_BIN
    REM CMake puts DLLs in lib/ after our post-build move in bld.bat
    move temp_prefix\lib\boost*.dll %LIBRARY_BIN%
    REM Also check bin/ in case CMake installed there (fallback)
    if exist temp_prefix\bin\boost*.dll (
        move temp_prefix\bin\boost*.dll %LIBRARY_BIN%
    )
) else (
    REM everything else (libboost-devel)
    xcopy /E /Y temp_prefix\lib %LIBRARY_LIB%
)
