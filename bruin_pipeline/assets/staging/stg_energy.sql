/* @bruin

name: eurostat_processed.stg_energy
type: duckdb.sql
materialization:
   type: view

description: |
  Staging layer for energy intensity data - cleans and standardizes

columns:
  - name: country_code
    type: STRING
  - name: country_name
    type: STRING
  - name: reference_year
    type: INTEGER
  - name: reference_date
    type: DATE
  - name: energy_intensity
    type: FLOAT
  - name: unit
    type: STRING
  - name: loaded_at
    type: DATE

depends:
  - eurostat_raw.energy_intensity

@bruin */

SELECT
    TRIM(country_code)                     AS country_code,
    TRIM(country_name)                     AS country_name,
    CAST(year AS INTEGER)                  AS reference_year,
    MAKE_DATE(CAST(year AS INTEGER), 1, 1) AS reference_date,
    CAST(value AS DOUBLE)                  AS energy_intensity,
    unit,
    loaded_at
FROM eurostat_raw.energy_intensity
WHERE value IS NOT NULL
  AND year IS NOT NULL
  AND country_code IS NOT NULL
  AND CAST(year AS INTEGER) BETWEEN 2000 AND 2030
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY TRIM(country_code), CAST(year AS INTEGER)
    ORDER BY loaded_at DESC
) = 1
