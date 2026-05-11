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
    description: Normalized GDP growth score (0-100), capped at ±15% to reduce post-crisis rebound distortion
  - name: unemployment_score
    type: FLOAT
    description: Inverted unemployment score (0-100, lower unemployment = higher score)
  - name: energy_score
    type: FLOAT
    description: Inverted energy intensity score (0-100, lower intensity = higher score)
  - name: inflation_score
    type: FLOAT
    description: Inverted inflation score (0-100, lower inflation = higher score)
  - name: composite_score
    type: FLOAT
    description: Weighted average of four sub-scores (25% each)

depends:
  - eurostat_processed.int_yoy_deltas

@bruin */

WITH raw AS (
    SELECT
        country_code,
        country_name,
        reference_year,
        reference_date,
        -- Cap GDP growth at ±15% to prevent post-crisis rebound years (e.g. 2021)
        -- from dominating the normalisation range and inflating scores for volatile economies
        GREATEST(-15.0, LEAST(15.0, gdp_yoy_growth_pct)) AS gdp_yoy_growth_pct,
        unemployment_rate,
        energy_intensity,
        inflation_rate,

        -- Global min/max across ALL years and countries for stable, absolute normalisation
        MIN(GREATEST(-15.0, LEAST(15.0, gdp_yoy_growth_pct))) OVER () AS min_gdp_growth,
        MAX(GREATEST(-15.0, LEAST(15.0, gdp_yoy_growth_pct))) OVER () AS max_gdp_growth,
        MIN(unemployment_rate)   OVER () AS min_unem,
        MAX(unemployment_rate)   OVER () AS max_unem,
        MIN(energy_intensity)    OVER () AS min_energy,
        MAX(energy_intensity)    OVER () AS max_energy,
        MIN(inflation_rate)      OVER () AS min_inflation,
        MAX(inflation_rate)      OVER () AS max_inflation
    FROM eurostat_processed.int_yoy_deltas
    WHERE reference_year >= 2000
),

scored AS (
    SELECT
        country_code,
        country_name,
        reference_year,
        reference_date,

        -- Higher GDP growth → higher score
        ROUND(
            100 * (
                (gdp_yoy_growth_pct - min_gdp_growth) /
                NULLIF(max_gdp_growth - min_gdp_growth, 0)
            ), 1
        ) AS gdp_score,

        -- Lower unemployment → higher score (inverted)
        ROUND(
            100 * (1 - (
                (unemployment_rate - min_unem) /
                NULLIF(max_unem - min_unem, 0)
            )), 1
        ) AS unemployment_score,

        -- Lower energy intensity → higher score (inverted)
        ROUND(
            100 * (1 - (
                (energy_intensity - min_energy) /
                NULLIF(max_energy - min_energy, 0)
            )), 1
        ) AS energy_score,

        -- Lower inflation → higher score (inverted); high inflation is a key economic negative
        ROUND(
            100 * (1 - (
                (inflation_rate - min_inflation) /
                NULLIF(max_inflation - min_inflation, 0)
            )), 1
        ) AS inflation_score

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
    COALESCE(inflation_score, 50)    AS inflation_score,
    ROUND(
        (
            COALESCE(gdp_score, 50) +
            COALESCE(unemployment_score, 50) +
            COALESCE(energy_score, 50) +
            COALESCE(inflation_score, 50)
        ) / 4,
        1
    )                                AS composite_score
FROM scored
