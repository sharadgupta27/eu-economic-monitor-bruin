"""@bruin
name: eurostat_raw.inflation_annual
type: python
connection: duckdb-local

description: |
  Ingests HICP inflation annual average rate of change (prc_hicp_aind)
  from Eurostat API into DuckDB eurostat_raw schema.

@bruin"""

import os
import time
from datetime import date
from pathlib import Path

import duckdb
import pandas as pd
import eurostat


def connect_with_retry(db_path: str, retries: int = 10, delay: float = 2.0) -> duckdb.DuckDBPyConnection:
    for attempt in range(retries):
        try:
            return duckdb.connect(db_path)
        except duckdb.IOException as e:
            if attempt < retries - 1:
                time.sleep(delay)
            else:
                raise

_DEFAULT_DB = str(Path(__file__).parent.parent.parent.parent / "data" / "eurostat.duckdb")
DB_PATH = os.getenv("DUCKDB_PATH", _DEFAULT_DB)

COUNTRIES = os.getenv(
    "EUROSTAT_COUNTRIES",
    "DE,FR,IT,ES,PL,NL,BE,SE,AT,PT,FI,IE,CZ,RO,HU,DK,EL,SK"
).split(",")

START_YEAR = int(os.getenv("EUROSTAT_START_YEAR", "2000"))
END_YEAR = int(os.getenv("EUROSTAT_END_YEAR", "2023"))

COUNTRY_NAMES = {
    "AT": "Austria", "BE": "Belgium", "BG": "Bulgaria",
    "CY": "Cyprus", "CZ": "Czechia", "DE": "Germany",
    "DK": "Denmark", "EE": "Estonia", "EL": "Greece",
    "ES": "Spain", "FI": "Finland", "FR": "France",
    "HR": "Croatia", "HU": "Hungary", "IE": "Ireland",
    "IT": "Italy", "LT": "Lithuania", "LU": "Luxembourg",
    "LV": "Latvia", "MT": "Malta", "NL": "Netherlands",
    "PL": "Poland", "PT": "Portugal", "RO": "Romania",
    "SE": "Sweden", "SI": "Slovenia", "SK": "Slovakia",
}


def fetch_to_long(dataset_code: str, filter_pars: dict) -> pd.DataFrame:
    df = eurostat.get_data_df(dataset_code, filter_pars=filter_pars)
    if df is None or df.empty:
        return pd.DataFrame()
    year_cols = [c for c in df.columns if str(c).isdigit() and START_YEAR <= int(c) <= END_YEAR]
    dim_cols = [c for c in df.columns if c not in year_cols]
    df_long = df.melt(id_vars=dim_cols, value_vars=year_cols, var_name="year", value_name="value")
    df_long["year"] = pd.to_numeric(df_long["year"], errors="coerce").astype("Int64")
    df_long["value"] = pd.to_numeric(df_long["value"], errors="coerce")
    df_long = df_long.dropna(subset=["year", "value"])
    df_long["loaded_at"] = date.today()
    return df_long


def run():
    df_raw = fetch_to_long(
        "prc_hicp_aind",
        {"geo": COUNTRIES, "unit": ["RCH_A_AVG"], "coicop": ["CP00"]},
    )
    geo_col = next((c for c in df_raw.columns if "geo" in c.lower()), "geo")
    records = []
    for _, row in df_raw.iterrows():
        cc = str(row[geo_col]).strip()
        if cc not in COUNTRY_NAMES:
            continue
        records.append({
            "country_code": cc,
            "country_name": COUNTRY_NAMES[cc],
            "year": int(row["year"]),
            "unit": "RCH_A_AVG",
            "value": float(row["value"]),
            "loaded_at": row["loaded_at"],
        })
    df = pd.DataFrame(records)
    print(f"Fetched {len(df)} rows from Eurostat inflation dataset")

    conn = connect_with_retry(DB_PATH)
    conn.execute("CREATE SCHEMA IF NOT EXISTS eurostat_raw")
    conn.execute("CREATE OR REPLACE TABLE eurostat_raw.inflation_annual AS SELECT * FROM df")
    count = conn.execute("SELECT COUNT(*) FROM eurostat_raw.inflation_annual").fetchone()[0]
    conn.close()
    print(f"Loaded {count} rows into eurostat_raw.inflation_annual")


run()


import os
from datetime import date
import pandas as pd
import eurostat

COUNTRIES = os.getenv(
    "EUROSTAT_COUNTRIES",
    "DE,FR,IT,ES,PL,NL,BE,SE,AT,PT,FI,IE,CZ,RO,HU,DK,EL,SK"
).split(",")

START_YEAR = int(os.getenv("EUROSTAT_START_YEAR", "2000"))
END_YEAR = int(os.getenv("EUROSTAT_END_YEAR", "2023"))

COUNTRY_NAMES = {
    "AT": "Austria", "BE": "Belgium", "BG": "Bulgaria",
    "CY": "Cyprus", "CZ": "Czechia", "DE": "Germany",
    "DK": "Denmark", "EE": "Estonia", "EL": "Greece",
    "ES": "Spain", "FI": "Finland", "FR": "France",
    "HR": "Croatia", "HU": "Hungary", "IE": "Ireland",
    "IT": "Italy", "LT": "Lithuania", "LU": "Luxembourg",
    "LV": "Latvia", "MT": "Malta", "NL": "Netherlands",
    "PL": "Poland", "PT": "Portugal", "RO": "Romania",
    "SE": "Sweden", "SI": "Slovenia", "SK": "Slovakia",
}


def fetch_to_long(dataset_code: str, filter_pars: dict) -> pd.DataFrame:
    """Fetch data from Eurostat and reshape to long format."""
    df = eurostat.get_data_df(dataset_code, filter_pars=filter_pars)
    
    if df is None or df.empty:
        return pd.DataFrame()
    
    year_cols = [
        c for c in df.columns
        if str(c).isdigit() and START_YEAR <= int(c) <= END_YEAR
    ]
    dim_cols = [c for c in df.columns if c not in year_cols]
    
    df_long = df.melt(
        id_vars=dim_cols,
        value_vars=year_cols,
        var_name="year",
        value_name="value",
    )
    df_long["year"] = pd.to_numeric(df_long["year"], errors="coerce").astype("Int64")
    df_long["value"] = pd.to_numeric(df_long["value"], errors="coerce")
    df_long = df_long.dropna(subset=["year", "value"])
    df_long["loaded_at"] = date.today()
    
    return df_long


def materialize() -> pd.DataFrame:
    """Fetch inflation data from Eurostat API."""
    df = fetch_to_long(
        "prc_hicp_aind",
        {"geo": COUNTRIES, "unit": ["RCH_A_AVG"], "coicop": ["CP00"]},
    )
    
    geo_col = next((c for c in df.columns if "geo" in c.lower()), "geo")
    
    records = []
    for _, row in df.iterrows():
        cc = str(row[geo_col]).strip()
        if cc not in COUNTRY_NAMES:
            continue
        records.append({
            "country_code": cc,
            "country_name": COUNTRY_NAMES[cc],
            "year": int(row["year"]),
            "unit": "RCH_A_AVG",
            "value": float(row["value"]),
            "loaded_at": row["loaded_at"],
        })
    
    return pd.DataFrame(records)
