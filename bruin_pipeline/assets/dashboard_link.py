"""@bruin
name: eurostat_processed.pipeline_status
type: python
connection: duckdb-local

description: |
  Final pipeline asset - verifies all mart tables are populated
  and prints the Streamlit dashboard URL to the console.

@bruin"""

import os
from datetime import datetime, timezone
from pathlib import Path

import duckdb
import pandas as pd

# dashboard_link.py lives at bruin_pipeline/assets/dashboard_link.py
# 3 parents up = project root
_DEFAULT_DB = str(Path(__file__).parent.parent.parent / "data" / "eurostat.duckdb")
DB_PATH = os.getenv("DUCKDB_PATH", _DEFAULT_DB)
DASHBOARD_HOST = os.getenv("DASHBOARD_HOST", "localhost")
DASHBOARD_PORT = os.getenv("DASHBOARD_PORT", "8501")
DASHBOARD_URL = f"http://{DASHBOARD_HOST}:{DASHBOARD_PORT}"

MART_TABLES = {
    "mart_country_latest":          "eurostat_processed.mart_country_latest",
    "mart_gdp_trends":              "eurostat_processed.mart_gdp_trends",
    "mart_unemployment_comparison": "eurostat_processed.mart_unemployment_comparison",
    "mart_energy_intensity":        "eurostat_processed.mart_energy_intensity",
    "mart_composite_economic_index":"eurostat_processed.mart_composite_economic_index",
}


def run():
    conn = duckdb.connect(DB_PATH)

    row_counts: dict[str, int] = {}
    for name, table in MART_TABLES.items():
        try:
            count = conn.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
            row_counts[name] = count
        except Exception:
            row_counts[name] = 0

    total_rows = sum(row_counts.values())
    status = "ready" if all(v > 0 for v in row_counts.values()) else "partial"

    sep = "=" * 60
    print(sep)
    print("  Pipeline complete!")
    print(sep)
    for table, count in row_counts.items():
        indicator = "OK" if count > 0 else "EMPTY"
        print(f"  [{indicator}]  {table}: {count:,} rows")
    print()
    print(f"  Dashboard URL : {DASHBOARD_URL}")
    print()
    print("  To start the dashboard run:")
    print("    run.bat              # pipeline + dashboard")
    print("    start_dashboard.bat  # dashboard only")
    print(sep)

    df = pd.DataFrame([{
        "checked_at":                    datetime.now(timezone.utc).isoformat(),
        "status":                        status,
        "total_rows":                    total_rows,
        "dashboard_url":                 DASHBOARD_URL,
        "mart_country_latest_rows":      row_counts.get("mart_country_latest", 0),
        "mart_gdp_trends_rows":          row_counts.get("mart_gdp_trends", 0),
        "mart_unemployment_rows":        row_counts.get("mart_unemployment_comparison", 0),
        "mart_energy_intensity_rows":    row_counts.get("mart_energy_intensity", 0),
        "mart_composite_index_rows":     row_counts.get("mart_composite_economic_index", 0),
    }])

    conn.execute("CREATE SCHEMA IF NOT EXISTS eurostat_processed")
    conn.execute("CREATE OR REPLACE TABLE eurostat_processed.pipeline_status AS SELECT * FROM df")
    conn.close()


run()


import os
from datetime import datetime, timezone
from pathlib import Path

import duckdb
import pandas as pd

# Resolve absolute path: bruin runs assets from the pipeline dir, so we go up two levels
_DEFAULT_DB = str(Path(__file__).parent.parent.parent / "data" / "eurostat.duckdb")
DB_PATH = os.getenv("DUCKDB_PATH", _DEFAULT_DB)
DASHBOARD_HOST = os.getenv("DASHBOARD_HOST", "localhost")
DASHBOARD_PORT = os.getenv("DASHBOARD_PORT", "8501")
DASHBOARD_URL = f"http://{DASHBOARD_HOST}:{DASHBOARD_PORT}"

MART_TABLES = {
    "mart_country_latest":          "eurostat_processed.mart_country_latest",
    "mart_gdp_trends":              "eurostat_processed.mart_gdp_trends",
    "mart_unemployment_comparison": "eurostat_processed.mart_unemployment_comparison",
    "mart_energy_intensity":        "eurostat_processed.mart_energy_intensity",
    "mart_composite_economic_index":"eurostat_processed.mart_composite_economic_index",
}


def materialize():
    conn = duckdb.connect(DB_PATH, read_only=True)

    row_counts: dict[str, int] = {}
    for name, table in MART_TABLES.items():
        try:
            count = conn.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
            row_counts[name] = count
        except Exception:
            row_counts[name] = 0

    conn.close()

    total_rows = sum(row_counts.values())
    status = "ready" if all(v > 0 for v in row_counts.values()) else "partial"

    sep = "=" * 60
    print(sep)
    print("  Pipeline complete!")
    print(sep)
    for table, count in row_counts.items():
        indicator = "OK" if count > 0 else "EMPTY"
        print(f"  [{indicator}]  {table}: {count:,} rows")
    print()
    print(f"  Dashboard URL : {DASHBOARD_URL}")
    print()
    print("  To start the dashboard run:")
    print("    run.bat              # pipeline + dashboard")
    print("    start_dashboard.bat  # dashboard only")
    print(sep)

    return pd.DataFrame([{
        "checked_at":                    datetime.now(timezone.utc).isoformat(),
        "status":                        status,
        "total_rows":                    total_rows,
        "dashboard_url":                 DASHBOARD_URL,
        "mart_country_latest_rows":      row_counts.get("mart_country_latest", 0),
        "mart_gdp_trends_rows":          row_counts.get("mart_gdp_trends", 0),
        "mart_unemployment_rows":        row_counts.get("mart_unemployment_comparison", 0),
        "mart_energy_intensity_rows":    row_counts.get("mart_energy_intensity", 0),
        "mart_composite_index_rows":     row_counts.get("mart_composite_economic_index", 0),
    }])
