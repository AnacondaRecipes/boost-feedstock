@echo on

:: see build-py.bat
if exist %SRC_DIR%\cf_%PY_VER%_%python_impl%_cmake\* (
    xcopy /E /Y %SRC_DIR%\cf_%PY_VER%_%python_impl%_cmake %LIBRARY_LIB%\cmake
)
