/* @bruin

name: eurostat_processed.mart_country_latest
type: duckdb.sql
materialization:
   type: table

description: |
  Latest available snapshot for each country - used for KPI cards
  and the EU choropleth map on the dashboard home page.

columns:
  - name: country_code
    type: STRING
  - name: country_name
    type: STRING
  - name: latest_year
    type: INTEGER
  - name: gdp_beur
    type: FLOAT
  - name: unemployment_rate
    type: FLOAT
  - name: energy_intensity
    type: FLOAT
  - name: inflation_rate
    type: FLOAT
  - name: gdp_yoy_growth_pct
    type: FLOAT
  - name: unem_yoy_change
    type: FLOAT
  - name: composite_score
    type: FLOAT
  - name: gdp_score
    type: FLOAT
  - name: unemployment_score
    type: FLOAT
  - name: energy_score
    type: FLOAT

depends:
  - eurostat_processed.int_country_indicators
  - eurostat_processed.int_yoy_deltas
  - eurostat_processed.mart_composite_economic_index

@bruin */

WITH latest_year AS (
    SELECT
        country_code,
        MAX(reference_year) AS latest_year
    FROM eurostat_processed.int_country_indicators
    WHERE gdp_meur IS NOT NULL
    GROUP BY country_code
)

SELECT
    i.country_code,
    i.country_name,
    i.reference_year                        AS latest_year,
    ROUND(i.gdp_beur, 2)                    AS gdp_beur,
    ROUND(i.unemployment_rate, 2)           AS unemployment_rate,
    ROUND(i.energy_intensity, 3)            AS energy_intensity,
    ROUND(i.inflation_rate, 2)              AS inflation_rate,
    ROUND(d.gdp_yoy_growth_pct, 2)          AS gdp_yoy_growth_pct,
    ROUND(d.unem_yoy_change, 2)             AS unem_yoy_change,
    ROUND(avg3.composite_score, 1)          AS composite_score,
    ROUND(avg3.gdp_score, 1)                AS gdp_score,
    ROUND(avg3.unemployment_score, 1)       AS unemployment_score,
    ROUND(avg3.energy_score, 1)            AS energy_score
FROM eurostat_processed.int_country_indicators i
JOIN latest_year ly
    ON i.country_code = ly.country_code
   AND i.reference_year = ly.latest_year
LEFT JOIN eurostat_processed.int_yoy_deltas d
    ON i.country_code = d.country_code
   AND i.reference_year = d.reference_year
LEFT JOIN eurostat_processed.mart_composite_economic_index c
    ON i.country_code = c.country_code
   AND i.reference_year = c.reference_year
-- 3-year average composite gives a more stable, representative performance score
LEFT JOIN (
    SELECT
        country_code,
        ROUND(AVG(composite_score), 1) AS composite_score,
        ROUND(AVG(gdp_score), 1)        AS gdp_score,
        ROUND(AVG(unemployment_score), 1) AS unemployment_score,
        ROUND(AVG(energy_score), 1)     AS energy_score
    FROM eurostat_processed.mart_composite_economic_index
    WHERE reference_year >= 2021
    GROUP BY country_code
) avg3
    ON i.country_code = avg3.country_code
QUALIFY ROW_NUMBER() OVER (PARTITION BY i.country_code ORDER BY i.reference_year DESC) = 1
