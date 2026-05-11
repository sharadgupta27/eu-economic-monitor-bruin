/* @bruin

name: eurostat_processed.stg_inflation
type: duckdb.sql
materialization:
   type: view

description: |
  Staging layer for inflation rate data - cleans and standardizes

columns:
  - name: country_code
    type: STRING
  - name: country_name
    type: STRING
  - name: reference_year
    type: INTEGER
  - name: reference_date
    type: DATE
  - name: inflation_rate
    type: FLOAT
  - name: unit
    type: STRING
  - name: loaded_at
    type: DATE

depends:
  - eurostat_raw.inflation_annual

@bruin */

SELECT
    TRIM(country_code)                     AS country_code,
    TRIM(country_name)                     AS country_name,
    CAST(year AS INTEGER)                  AS reference_year,
    MAKE_DATE(CAST(year AS INTEGER), 1, 1) AS reference_date,
    CAST(value AS DOUBLE)                  AS inflation_rate,
    unit,
    loaded_at
FROM eurostat_raw.inflation_annual
WHERE value IS NOT NULL
  AND year IS NOT NULL
  AND country_code IS NOT NULL
  AND CAST(year AS INTEGER) BETWEEN 2000 AND 2030
