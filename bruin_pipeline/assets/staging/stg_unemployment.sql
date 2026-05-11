/* @bruin

name: eurostat_processed.stg_unemployment
type: duckdb.sql
materialization:
   type: view

description: |
  Staging layer for unemployment rate data - cleans and standardizes

columns:
  - name: country_code
    type: STRING
  - name: country_name
    type: STRING
  - name: reference_year
    type: INTEGER
  - name: reference_date
    type: DATE
  - name: unemployment_rate
    type: FLOAT
  - name: unit
    type: STRING
  - name: age_group
    type: STRING
  - name: sex
    type: STRING
  - name: loaded_at
    type: DATE

depends:
  - eurostat_raw.unemployment_annual

@bruin */

SELECT
    TRIM(country_code)                     AS country_code,
    TRIM(country_name)                     AS country_name,
    CAST(year AS INTEGER)                  AS reference_year,
    MAKE_DATE(CAST(year AS INTEGER), 1, 1) AS reference_date,
    CAST(value AS DOUBLE)                  AS unemployment_rate,
    unit,
    age_group,
    sex,
    loaded_at
FROM eurostat_raw.unemployment_annual
WHERE value IS NOT NULL
  AND year IS NOT NULL
  AND country_code IS NOT NULL
  AND age_group = 'Y15-74'
  AND sex = 'T'
  AND CAST(year AS INTEGER) BETWEEN 2000 AND 2030
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY TRIM(country_code), CAST(year AS INTEGER)
    ORDER BY loaded_at DESC
) = 1
