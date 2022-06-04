@echo off
chcp 65001

compile "%~dp0\_cheats_check.sp"
pause
cls
move "%~dp0\compiled\*.smx" "..\plugins"

pause
