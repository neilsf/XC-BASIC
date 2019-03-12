@echo off
set /p Build=<VERSION
if "%1" neq "/?" goto nohelp
echo.
echo xcbasic64 %Build%
echo This script compiles an XC-BASIC source to binary executable.
echo.
echo USAGE:
echo %0 infile.bas outfile.prg
echo.
GOTO:EOF
:nohelp
bin\win_x86_64\xcbasic64.exe %1 > %TEMP%\xcbtemp.asm && third_party\dasm-2.20.11\dasm.exe %TEMP%\xcbtemp.asm -o%2
del %TEMP%\xcbtemp.asm