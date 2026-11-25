@echo off
if not defined GODOT for /d %%D in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_*") do for %%F in ("%%D\Godot*_console.exe") do set "GODOT=%%F"
if not defined GODOT (
echo Godot not found. Set GODOT.
exit /b 1
)
"%GODOT%" --path "%~dp0.." %*
