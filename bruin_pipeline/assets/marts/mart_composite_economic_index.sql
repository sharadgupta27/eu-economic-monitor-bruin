/* @bruin

name: eurostat_processed.mart_composite_economic_index
type: duckdb.sql
materialization:
   type: table

description: |
  Composite Economic Index (0–100) combining GDP growth, unemployment, and energy efficiency.
  Higher scores indicate better overall economic performance.

columns:
  - name: country_code
    type: STRING
  - name: country_name
    type: STRING
  - name: reference_year
    type: INTEGER
  - name: reference_date
    type: DATE
  - name: gdp_score
    type: FLOAT
    description: Normalized GDP growth score (0-100)
  - name: unemployment_score
    type: FLOAT
    description: Inverted unemployment score (0-100, lower unemployment = higher score)
  - name: energy_score
    type: FLOAT
    description: Inverted energy intensity score (0-100, lower intensity = higher score)
  - name: composite_score
    type: FLOAT
    description: Average of three sub-scores

depends:
  - eurostat_processed.int_yoy_deltas

@bruin */

WITH raw AS (
    SELECT
        country_code,
        country_name,
        reference_year,
        reference_date,
        gdp_yoy_growth_pct,
        unemployment_rate,
        energy_intensity,

        -- Global min/max across ALL years and countries for stable, absolute normalisation
        -- (avoids inflation-driven nominal GDP spikes in single years dominating scores)
        MIN(gdp_yoy_growth_pct)  OVER () AS min_gdp_growth,
        MAX(gdp_yoy_growth_pct)  OVER () AS max_gdp_growth,
        MIN(unemployment_rate)   OVER () AS min_unem,
        MAX(unemployment_rate)   OVER () AS max_unem,
        MIN(energy_intensity)    OVER () AS min_energy,
        MAX(energy_intensity)    OVER () AS max_energy
    FROM eurostat_processed.int_yoy_deltas
    WHERE reference_year >= 2000
),

scored AS (
    SELECT
        country_code,
        country_name,
        reference_year,
        reference_date,

        ROUND(
            100 * (
                (gdp_yoy_growth_pct - min_gdp_growth) / 
                NULLIF(max_gdp_growth - min_gdp_growth, 0)
            ), 1
        ) AS gdp_score,

        ROUND(
            100 * (1 - (
                (unemployment_rate - min_unem) / 
                NULLIF(max_unem - min_unem, 0)
            )), 1
        ) AS unemployment_score,

        ROUND(
            100 * (1 - (
                (energy_intensity - min_energy) / 
                NULLIF(max_energy - min_energy, 0)
            )), 1
        ) AS energy_score

    FROM raw
)

SELECT
    country_code,
    country_name,
    reference_year,
    reference_date,
    COALESCE(gdp_score, 50)          AS gdp_score,
    COALESCE(unemployment_score, 50) AS unemployment_score,
    COALESCE(energy_score, 50)       AS energy_score,
    ROUND(
        (COALESCE(gdp_score, 50) + COALESCE(unemployment_score, 50) + COALESCE(energy_score, 50)) / 3,
        1
    )                                AS composite_score
FROM scored
