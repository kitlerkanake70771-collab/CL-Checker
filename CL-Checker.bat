@echo off
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0CL-Checker.ps1"
