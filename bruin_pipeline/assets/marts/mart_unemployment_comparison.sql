/* @bruin

name: eurostat_processed.mart_unemployment_comparison
type: duckdb.sql
materialization:
   type: table

description: |
  Mart table for unemployment comparison across countries and years

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
  - name: unem_yoy_change
    type: FLOAT

depends:
  - eurostat_processed.int_yoy_deltas

@bruin */

SELECT
    country_code,
    country_name,
    reference_year,
    reference_date,
    ROUND(unemployment_rate, 2)  AS unemployment_rate,
    ROUND(unem_yoy_change, 2)    AS unem_yoy_change
FROM eurostat_processed.int_yoy_deltas
WHERE unemployment_rate IS NOT NULL
