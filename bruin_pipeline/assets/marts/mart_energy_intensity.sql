/* @bruin

name: eurostat_processed.mart_energy_intensity
type: duckdb.sql
materialization:
   type: table

description: |
  Mart table for energy intensity trends and improvements

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
  - name: energy_yoy_change
    type: FLOAT
  - name: energy_yoy_improvement_pct
    type: FLOAT

depends:
  - eurostat_processed.int_yoy_deltas

@bruin */

SELECT
    country_code,
    country_name,
    reference_year,
    reference_date,
    ROUND(energy_intensity, 3)          AS energy_intensity,
    ROUND(energy_yoy_change, 3)         AS energy_yoy_change,
    ROUND(energy_yoy_improvement_pct, 2) AS energy_yoy_improvement_pct
FROM eurostat_processed.int_yoy_deltas
WHERE energy_intensity IS NOT NULL
