/* @bruin

name: eurostat_processed.int_yoy_deltas
type: duckdb.sql
materialization:
   type: table

description: |
  Intermediate layer - calculates year-over-year changes and growth rates

columns:
  - name: country_code
    type: STRING
  - name: country_name
    type: STRING
  - name: reference_year
    type: INTEGER
  - name: reference_date
    type: DATE
  - name: gdp_meur
    type: FLOAT
  - name: gdp_beur
    type: FLOAT
  - name: gdp_yoy_change_meur
    type: FLOAT
    description: Year-over-year GDP change in millions
  - name: gdp_yoy_growth_pct
    type: FLOAT
    description: Real GDP growth rate (chain-linked volume, % change on previous year — sourced from Eurostat CLV_PCH_PRE)
  - name: unemployment_rate
    type: FLOAT
  - name: unem_yoy_change
    type: FLOAT
  - name: energy_intensity
    type: FLOAT
  - name: energy_yoy_change
    type: FLOAT
  - name: energy_yoy_improvement_pct
    type: FLOAT
  - name: inflation_rate
    type: FLOAT
  - name: inflation_yoy_change
    type: FLOAT

depends:
  - eurostat_processed.int_country_indicators

@bruin */

WITH lagged AS (
    SELECT
        country_code,
        country_name,
        reference_year,
        reference_date,
        gdp_meur,
        gdp_beur,
        gdp_real_growth_pct,
        unemployment_rate,
        energy_intensity,
        inflation_rate,

        -- Previous year values
        LAG(gdp_meur)           OVER w AS prev_gdp_meur,
        LAG(unemployment_rate)  OVER w AS prev_unemployment,
        LAG(energy_intensity)   OVER w AS prev_energy,
        LAG(inflation_rate)     OVER w AS prev_inflation
    FROM eurostat_processed.int_country_indicators
    WINDOW w AS (PARTITION BY country_code ORDER BY reference_year)
)

SELECT
    country_code,
    country_name,
    reference_year,
    reference_date,
    gdp_meur,
    gdp_beur,

    -- GDP YoY (nominal change in EUR for absolute deltas)
    ROUND(gdp_meur - prev_gdp_meur, 2)   AS gdp_yoy_change_meur,
    -- Real GDP growth rate (chain-linked volume, % change) — sourced directly from Eurostat
    gdp_real_growth_pct                   AS gdp_yoy_growth_pct,

    unemployment_rate,
    ROUND(unemployment_rate - prev_unemployment, 2)                                 AS unem_yoy_change,

    energy_intensity,
    ROUND(energy_intensity - prev_energy, 3)                                        AS energy_yoy_change,
    ROUND(
        (prev_energy - energy_intensity) / NULLIF(prev_energy, 0) * 100,
        2
    )                                                                               AS energy_yoy_improvement_pct,

    inflation_rate,
    ROUND(inflation_rate - prev_inflation, 2)                                       AS inflation_yoy_change

FROM lagged
