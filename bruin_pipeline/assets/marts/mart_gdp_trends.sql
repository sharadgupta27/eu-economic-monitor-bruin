/* @bruin

name: eurostat_processed.mart_gdp_trends
type: duckdb.sql
materialization:
   type: table

description: |
  Mart table for GDP trends analysis with year-over-year metrics

columns:
  - name: country_code
    type: STRING
  - name: country_name
    type: STRING
  - name: reference_year
    type: INTEGER
  - name: reference_date
    type: DATE
  - name: gdp_beur
    type: FLOAT
  - name: gdp_meur
    type: FLOAT
  - name: gdp_yoy_change_meur
    type: FLOAT
  - name: gdp_yoy_growth_pct
    type: FLOAT

depends:
  - eurostat_processed.int_yoy_deltas

@bruin */

SELECT
    country_code,
    country_name,
    reference_year,
    reference_date,
    ROUND(gdp_beur, 3)             AS gdp_beur,
    ROUND(gdp_meur, 0)             AS gdp_meur,
    gdp_yoy_change_meur,
    gdp_yoy_growth_pct
FROM eurostat_processed.int_yoy_deltas
WHERE gdp_meur IS NOT NULL
