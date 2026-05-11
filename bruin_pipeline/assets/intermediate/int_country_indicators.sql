/* @bruin

name: eurostat_processed.int_country_indicators
type: duckdb.sql
materialization:
   type: table

description: |
  Intermediate layer - joins all economic indicators for each country-year

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
  - name: unemployment_rate
    type: FLOAT
  - name: energy_intensity
    type: FLOAT
  - name: inflation_rate
    type: FLOAT

depends:
  - eurostat_processed.stg_gdp
  - eurostat_processed.stg_unemployment
  - eurostat_processed.stg_energy
  - eurostat_processed.stg_inflation

@bruin */

SELECT
    g.country_code,
    g.country_name,
    g.reference_year,
    g.reference_date,
    g.gdp_meur,
    g.gdp_beur,
    g.gdp_real_growth_pct,
    u.unemployment_rate,
    e.energy_intensity,
    i.inflation_rate
FROM eurostat_processed.stg_gdp g
LEFT JOIN eurostat_processed.stg_unemployment u
    ON g.country_code = u.country_code
   AND g.reference_year = u.reference_year
LEFT JOIN eurostat_processed.stg_energy e
    ON g.country_code = e.country_code
   AND g.reference_year = e.reference_year
LEFT JOIN eurostat_processed.stg_inflation i
    ON g.country_code = i.country_code
   AND g.reference_year = i.reference_year
