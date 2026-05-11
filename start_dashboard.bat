@echo off
setlocal

echo.
echo ==========================================
echo   EU Economic Monitor - Dashboard
echo ==========================================
echo.

where uv >nul 2>&1
if errorlevel 1 (
    echo [ERROR] uv is not installed.
    echo.
    echo  Install uv:
    echo    powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
    exit /b 1
)

REM Ensure venv exists with dependencies
uv sync --quiet

echo   Dashboard: http://localhost:8501
echo.
echo   Press Ctrl+C to stop.
echo.

uv run streamlit run dashboard/app.py

endlocal
