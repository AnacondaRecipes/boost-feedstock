@echo on

pushd ..\..\libs\python\example\tutorial
set TOOLSET=msvc-14.1
bjam hello cxxflags=-I%CONDA_PREFIX%\include --debug-configuration -d+2 release toolset=%TOOLSET% > cxxflags-hacked-working.log 2>&1
bin\%TOOLSET%\release\threading-multi\hello.exe | rg.exe "Hello World CXX"

