@echo off
title EyeXpert Web Prototype Launcher
cd /d "%~dp0"
echo =========================================================================
echo       EYEXPERT — SIH 2026 WEB PROTOTYPE
echo       Starting local web server on http://localhost:5000 ...
echo =========================================================================
start http://localhost:5000
python web_app.py
pause
