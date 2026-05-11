# EU Economic Monitor - Bruin Pipeline

## Overview

This is a redesigned, simplified version of the EU Economic Monitor pipeline using [Bruin](https://getbruin.com), a modern data pipeline tool.

**Key Improvements:**
- ✅ Single tool (Bruin) replaces dlt + dbt + orchestration
- ✅ Simplified architecture without streaming complexity
- ✅ Native DuckDB integration (local, no cloud required)
- ✅ Built-in data quality checks
- ✅ Easier to maintain and understand

## Architecture

```
Eurostat API → Bruin Python Asset → DuckDB (Raw)
                                        ↓
                              Bruin SQL Assets (Staging)
                                        ↓
                              Bruin SQL Assets (Intermediate)
                                        ↓
                              Bruin SQL Assets (Marts)
                                        ↓
                              Streamlit Dashboard
```

## Prerequisites

1. Install Bruin CLI: https://getbruin.com/docs/getting-started/introduction/installation
2. Install uv: https://docs.astral.sh/uv/

## Setup

1. Configure environment variables:
```bash
export EUROSTAT_COUNTRIES=DE,FR,IT,ES,PL,NL,BE,SE,AT,PT,FI,IE,CZ,RO,HU,DK,EL,SK
export EUROSTAT_START_YEAR=2000
export EUROSTAT_END_YEAR=2023
export DUCKDB_PATH=data/eurostat.duckdb
```

2. Validate the pipeline:
```bash
bruin validate bruin_pipeline
```

3. Run the pipeline:
```bash
bruin run bruin_pipeline
```

4. Run specific asset:
```bash
bruin run bruin_pipeline/assets/staging/stg_gdp.sql
```

## Pipeline Structure

```
bruin_pipeline/
├── pipeline.yml                 # Pipeline configuration
├── .bruin.yml                   # Connections and environments
├── assets/
│   ├── ingestion/
│   │   ├── ingest_gdp.py       # Fetch GDP data
│   │   ├── ingest_unemployment.py
│   │   ├── ingest_energy.py
│   │   └── ingest_inflation.py
│   ├── staging/
│   │   ├── stg_gdp.sql         # Clean and standardize GDP
│   │   ├── stg_unemployment.sql
│   │   ├── stg_energy.sql
│   │   └── stg_inflation.sql
│   ├── intermediate/
│   │   ├── int_country_indicators.sql  # Join all indicators
│   │   └── int_yoy_deltas.sql          # Calculate YoY changes
│   └── marts/
│       ├── mart_gdp_trends.sql
│       ├── mart_unemployment_comparison.sql
│       ├── mart_energy_intensity.sql
│       ├── mart_country_latest.sql
│       └── mart_composite_economic_index.sql
```

## Data Flow

1. **Ingestion** (Python assets): Fetch data from Eurostat API and load into DuckDB raw tables
2. **Staging** (SQL assets): Clean and standardize raw data
3. **Intermediate** (SQL assets): Join and calculate metrics
4. **Marts** (SQL assets): Business-ready tables for dashboard

## Dashboard

The Streamlit dashboard queries DuckDB marts locally:

```bash
# From project root — runs pipeline then starts dashboard
run.bat

# Dashboard only (after pipeline has run)
start_dashboard.bat
```

## Commands Reference

```bash
# Validate pipeline
bruin validate bruin_pipeline

# Run entire pipeline
bruin run bruin_pipeline

# Run with date range
bruin run bruin_pipeline --start-date 2023-01-01 --end-date 2023-12-31

# Run specific asset
bruin run bruin_pipeline/assets/marts/mart_gdp_trends.sql

# Run asset with downstream dependencies
bruin run bruin_pipeline/assets/staging/stg_gdp.sql --downstream

# Check lineage
bruin lineage bruin_pipeline

# Format SQL files
bruin format bruin_pipeline

# Run with full refresh (truncate tables)
bruin run bruin_pipeline --full-refresh
```

## Removed Components

The Bruin redesign removes these components for simplicity:
- ❌ Redpanda/Kafka streaming (event-driven was over-engineered)
- ❌ Apache Flink (streaming processing not needed for batch daily updates)
- ❌ Apache Spark (unnecessary for current data volumes)
- ❌ Docker Compose (Bruin runs natively)
- ❌ Complex Makefile commands

## Benefits of Bruin Migration

1. **Simpler**: One tool instead of dlt + dbt + custom orchestration
2. **Faster**: Native execution without Docker overhead
3. **Easier debugging**: Single command to run and test
4. **Better DX**: Built-in validation, lineage, formatting
5. **Production-ready**: Scheduling, notifications, environments built-in
