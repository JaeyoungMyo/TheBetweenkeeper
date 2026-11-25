@echo off
call "%~dp0godot.cmd" --headless --import >nul
call "%~dp0godot.cmd" %*
