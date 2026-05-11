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

REM Clear any conflicting VIRTUAL_ENV from other projects
set VIRTUAL_ENV=

REM Check for DuckDB data file; run ingestion pipeline if missing
if not exist "data\eurostat.duckdb" (
    echo   [INFO] data\eurostat.duckdb not found.
    echo   [INFO] Running Bruin ingestion pipeline first ...
    echo.
    call run.bat
    if errorlevel 1 (
        echo.
        echo [ERROR] Ingestion pipeline failed. Cannot start dashboard.
        exit /b 1
    )
    echo.
)

REM Recreate venv if trampoline scripts are stale/broken
if exist .venv (
    rmdir /s /q .venv
)
uv sync --quiet

echo   Dashboard: http://localhost:8501
echo.
echo   Press Ctrl+C to stop.
echo.

REM Run streamlit directly via venv Python to avoid uv trampoline issues
.venv\Scripts\python.exe -m streamlit run dashboard/app.py

endlocal
