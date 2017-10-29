@ECHO OFF
REM Get a local want.exe built so it can then do a full build with itself
REM brcc32 and dcc32 must be in PATH already

echo Building minimal WANT...
echo.

copy ..\src\wantver.bootstrap.rc ..\src\wantver.rc
echo.

brcc32 -r ..\src\wantver.rc
echo.
if ERRORLEVEL 1 goto ERROR

brcc32 -r ..\src\license.rc
echo.
if ERRORLEVEL 1 goto ERROR

brcc32 -r ..\src\usage.rc
echo.
if ERRORLEVEL 1 goto ERROR

pushd ..\src

REM Copy template for each known version, don't forget to update
REM after a JCL update!
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld9.net.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld10.net.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld11.net.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jclc5.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jclc6.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld5.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld6.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld7.inc
REM copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jclcs1.inc
REM copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld8.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld9.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld10.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld11.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld12.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld14.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld15.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld16win32.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld16win64.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld17win32.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld17win64.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld18win32.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld18win64.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld19win32.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld19win64.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld20win32.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld20win64.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld21win32.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld21win64.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld22win32.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld22win64.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld23win32.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld23win64.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld24win32.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld24win64.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld25win32.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jcld25win64.inc
copy ..\lib\jcl\jcl\source\jcl.template.inc ..\lib\jcl\jcl\source\jclfpc.inc
echo.

md %TEMP%\want
echo.

dcc32 -Q -B -N%TEMP%\want -E%TEMP%\want -$O- -$J+ ..\src\want_min.dpr -I..\lib\jcl\jcl\source -Uelements;input;lib;tasks;win32;jal\lib\paszlib;jal\src;..\lib\Common;..\lib\dUnit\src;..\lib\jcl\jcl\source\common;..\lib\jcl\jcl\source\windows;..\lib\RegExpr\Source
echo.
if ERRORLEVEL 1 goto ERROR

echo Build complete.
echo.
echo.

%TEMP%\want\want_min.exe -b ..\want.xml %1 %2 %3 %4 %5 %6 %7 %8 %9
if ERRORLEVEL 1 goto ERROR

goto END

:ERROR
pause

:END
rd /s /q %TEMP%\want
popd
