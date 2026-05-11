@echo off
setlocal EnableDelayedExpansion

echo.
echo ==========================================
echo   EU Economic Monitor
echo   Powered by Bruin + DuckDB
echo ==========================================
echo.

REM - 1. Check uv ------------------------------─
where uv >nul 2>&1
if errorlevel 1 (
    echo [ERROR] uv is not installed.
    echo.
    echo  Install uv ^(recommended^):
    echo    powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
    echo.
    echo  Then restart this terminal and re-run run.bat
    exit /b 1
)

REM - 2. Sync Python venv ---------------------------
echo [1/3] Syncing Python environment with uv ...
uv sync --quiet
if errorlevel 1 (
    echo [ERROR] uv sync failed. Check pyproject.toml for errors.
    exit /b 1
)
echo        Done.  (.venv created / updated)
echo.

REM - 3. Run Bruin pipeline --------------------------
echo [2/3] Running Bruin pipeline ...
echo.
bruin run bruin_pipeline
set PIPELINE_EXIT=%errorlevel%
echo.
if !PIPELINE_EXIT! neq 0 (
    echo [WARNING] Pipeline exited with code !PIPELINE_EXIT!.
    echo          Check the output above for details.
    echo.
    echo  You can still try starting the dashboard if partial data exists.
    echo  Press any key to continue to dashboard, or Ctrl+C to abort.
    pause >nul
) else (
    echo [OK] Pipeline completed successfully.
    echo.
)

REM - 4. Start Streamlit dashboard ----------------------─
echo [3/3] Starting Streamlit dashboard ...
echo.
echo ==========================================
echo.
echo   Dashboard: http://localhost:8501
echo.
echo   Press Ctrl+C to stop.
echo ==========================================
echo.
uv run streamlit run dashboard/app.py

endlocal
