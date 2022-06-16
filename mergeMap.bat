@echo off
set /p id="Enter map name: "

remodel run mergeTCMaps.lua %id%
pause