/* @bruin

name: eurostat_processed.stg_gdp
type: duckdb.sql
materialization:
   type: view

description: |
  Staging layer for GDP annual data - cleans and standardizes raw GDP data

columns:
  - name: country_code
    type: STRING
    description: ISO 2-letter country code
  - name: country_name
    type: STRING
  - name: reference_year
    type: INTEGER
  - name: reference_date
    type: DATE
  - name: gdp_meur
    type: FLOAT
    description: GDP in millions of euros
  - name: gdp_beur
    type: FLOAT
    description: GDP in billions of euros
  - name: unit
    type: STRING
  - name: loaded_at
    type: DATE

depends:
  - eurostat_raw.gdp_annual

@bruin */

SELECT
    TRIM(country_code)                        AS country_code,
    TRIM(country_name)                        AS country_name,
    CAST(year AS INTEGER)                     AS reference_year,
    MAKE_DATE(CAST(year AS INTEGER), 1, 1)    AS reference_date,
    CAST(value AS DOUBLE)                     AS gdp_meur,
    ROUND(CAST(value AS DOUBLE) / 1000, 3)    AS gdp_beur,
    unit,
    loaded_at
FROM eurostat_raw.gdp_annual
WHERE value IS NOT NULL
  AND year IS NOT NULL
  AND country_code IS NOT NULL
  AND CAST(year AS INTEGER) BETWEEN 2000 AND 2030
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY TRIM(country_code), CAST(year AS INTEGER)
    ORDER BY loaded_at DESC
) = 1
