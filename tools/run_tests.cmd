@echo off
call "%~dp0godot.cmd" --headless --import >nul
call "%~dp0godot.cmd" --headless -s res://tests/run_tests.gd
