
%CXX% /MD /EHsc /D"BOOST_ALL_NO_LIB" /I %PREFIX%\Library\include test_iostreams_zlib.cpp libboost_exception.lib libboost_iostreams.lib  zlib.lib  /link /LIBPATH:%PREFIX%\Library\lib 
if errorlevel 1 exit /b 1
test_iostreams_zlib.exe
if errorlevel 1 exit /b 1