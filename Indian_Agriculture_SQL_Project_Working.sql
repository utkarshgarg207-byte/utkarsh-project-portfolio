-- ============================================================
-- INDIAN AGRICULTURE & RAINFALL SQL ANALYSIS
-- ============================================================
--
-- Dataset: Indian Agriculture and Rainfall Data (1998-2017)
-- Records: 13,542
-- States/UTs: 33
-- Crops: 49
--
-- Objective:
-- Analyze agricultural area, rainfall, previous-year yield,
-- and binary target patterns using MySQL.
--
-- Tools:
-- MySQL 8.4.11
-- DBeaver Community
--
-- Key SQL concepts used:
-- Aggregations, CASE WHEN, CTEs, LAG(), DENSE_RANK(),
-- subqueries, correlation analysis, and SQL Views.
--
-- ============================================================


-- ============================================================
-- 1. DATABASE & TABLE SETUP
-- ============================================================
CREATE DATABASE indian_agriculture;
USE indian_agriculture;
CREATE TABLE agriculture_data (
    state VARCHAR(100) NOT NULL,
    crop VARCHAR(100) NOT NULL,
    year INT NOT NULL,
    area DECIMAL(15,2),
    annual DECIMAL(10,2),
    monsoon DECIMAL(10,2),
    prev_year_yield DECIMAL(10,2),
    target TINYINT,
    PRIMARY KEY (state, crop, year)
);

DESCRIBE agriculture_data;
-- ============================================================
-- 2. DATA VALIDATION & QUALITY CHECKS
-- ============================================================

SELECT COUNT(*) AS total_rows
FROM agriculture_data;

SELECT COUNT(*) AS missing_prev_year_yield
FROM agriculture_data
WHERE prev_year_yield IS NULL;

SELECT state, crop, year, COUNT(*) AS row_count
FROM agriculture_data
GROUP BY state, crop, year
HAVING COUNT(*) > 1;
SELECT
    MIN(year) AS first_year,
    MAX(year) AS last_year,
    COUNT(DISTINCT state) AS total_states,
    COUNT(DISTINCT crop) AS total_crops,
    COUNT(DISTINCT target) AS target_values
FROM agriculture_data;
SELECT
    target,
    COUNT(*) AS number_of_records
FROM agriculture_data
GROUP BY target
ORDER BY target;

-- ============================================================
-- 3. EXPLORATORY & DESCRIPTIVE ANALYSIS
-- ============================================================

SELECT
    target,
    AVG(area) AS avg_area,
    AVG(annual) AS avg_annual_rainfall,
    AVG(monsoon) AS avg_monsoon_rainfall,
    AVG(prev_year_yield) AS avg_prev_year_yield
FROM agriculture_data
GROUP BY target
ORDER BY target;
SELECT
    state,
    SUM(area) AS total_area
FROM agriculture_data
GROUP BY state
ORDER BY total_area DESC;
SELECT
    state,
    year,
    SUM(area) AS total_area
FROM agriculture_data
GROUP BY state, year
ORDER BY state, year;
SELECT
    state,
    year,
    SUM(area) AS total_area
FROM agriculture_data
GROUP BY state, year
ORDER BY total_area DESC
LIMIT 10;
-- ============================================================
-- 4. YEAR-OVER-YEAR & WINDOW FUNCTION ANALYSIS
-- ============================================================

SELECT
    state,
    year,
    SUM(area) AS total_area,
    LAG(SUM(area)) OVER (
        PARTITION BY state
        ORDER BY year
    ) AS previous_year_area
FROM agriculture_data
GROUP BY state, year
ORDER BY state, year;
SELECT
    state,
    year,
    SUM(area) AS total_area,
    LAG(SUM(area)) OVER (
        PARTITION BY state
        ORDER BY year
    ) AS previous_year_area,
    SUM(area) -
    LAG(SUM(area)) OVER (
        PARTITION BY state
        ORDER BY year
    ) AS area_change
FROM agriculture_data
GROUP BY state, year
ORDER BY state, year;
SELECT
    year,
    SUM(area) AS total_area
FROM agriculture_data
GROUP BY year
ORDER BY year;
SELECT
    year,
    SUM(area) AS total_area,
    LAG(SUM(area)) OVER (
        ORDER BY year
    ) AS previous_year_area,
    SUM(area) -
    LAG(SUM(area)) OVER (
        ORDER BY year
    ) AS area_change
FROM agriculture_data
GROUP BY year
ORDER BY year;
-- ============================================================
-- 5. CROP & STATE RANKING ANALYSIS
-- ============================================================

SELECT
    crop,
    SUM(area) AS total_area
FROM agriculture_data
GROUP BY crop
ORDER BY total_area DESC
LIMIT 10;
SELECT
    crop,
    AVG(area) AS avg_area
FROM agriculture_data
GROUP BY crop
ORDER BY avg_area DESC
LIMIT 10;
SELECT
    year,
    AVG(annual) AS avg_annual_rainfall,
    AVG(monsoon) AS avg_monsoon_rainfall
FROM agriculture_data
GROUP BY year
ORDER BY year;
SELECT
    year,
    AVG(annual) AS avg_annual_rainfall,
    SUM(area) AS total_area
FROM agriculture_data
GROUP BY year
ORDER BY year;
-- ============================================================
-- 6. CORRELATION & RELATIONSHIP ANALYSIS
-- ============================================================

SELECT
    (
        COUNT(*) * SUM(avg_annual_rainfall * total_area)
        - SUM(avg_annual_rainfall) * SUM(total_area)
    )
    /
    SQRT(
        (
            COUNT(*) * SUM(avg_annual_rainfall * avg_annual_rainfall)
            - POW(SUM(avg_annual_rainfall), 2)
        )
        *
        (
            COUNT(*) * SUM(total_area * total_area)
            - POW(SUM(total_area), 2)
        )
    ) AS rainfall_area_correlation
FROM (
    SELECT
        year,
        AVG(annual) AS avg_annual_rainfall,
        SUM(area) AS total_area
    FROM agriculture_data
    GROUP BY year
) AS yearly_data;
-- ============================================================
-- 7. TARGET ANALYSIS
-- ============================================================

SELECT
    crop,
    COUNT(*) AS total_records,
    SUM(CASE WHEN target = 1 THEN 1 ELSE 0 END) AS target_1_records,
    ROUND(
        100.0 * SUM(CASE WHEN target = 1 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS target_1_percentage
FROM agriculture_data
GROUP BY crop
ORDER BY target_1_percentage DESC;
SELECT
    state,
    COUNT(*) AS total_records,
    SUM(CASE WHEN target = 1 THEN 1 ELSE 0 END) AS target_1_records,
    ROUND(
        100.0 * SUM(CASE WHEN target = 1 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS target_1_percentage
FROM agriculture_data
GROUP BY state
ORDER BY target_1_percentage DESC;
-- ============================================================
-- 8. PREVIOUS-YEAR YIELD ANALYSIS
-- ============================================================

SELECT
    state,
    COUNT(prev_year_yield) AS yield_records,
    AVG(prev_year_yield) AS avg_prev_year_yield
FROM agriculture_data
GROUP BY state
ORDER BY avg_prev_year_yield DESC;
SELECT
    crop,
    COUNT(prev_year_yield) AS yield_records,
    ROUND(AVG(prev_year_yield), 2) AS avg_prev_year_yield
FROM agriculture_data
GROUP BY crop
ORDER BY avg_prev_year_yield DESC;
SELECT
    year,
    COUNT(prev_year_yield) AS yield_records,
    ROUND(AVG(prev_year_yield), 2) AS avg_prev_year_yield
FROM agriculture_data
GROUP BY year
ORDER BY year;
SELECT
    year,
    ROUND(AVG(prev_year_yield), 2) AS avg_prev_year_yield,
    ROUND(
        AVG(prev_year_yield) -
        LAG(AVG(prev_year_yield)) OVER (ORDER BY year),
        2
    ) AS year_over_year_change
FROM agriculture_data
GROUP BY year
ORDER BY year;
WITH yearly_yield AS (
    SELECT
        year,
        AVG(prev_year_yield) AS avg_prev_year_yield
    FROM agriculture_data
    GROUP BY year
),
yield_with_previous AS (
    SELECT
        year,
        avg_prev_year_yield,
        LAG(avg_prev_year_yield) OVER (
            ORDER BY year
        ) AS previous_year_yield
    FROM yearly_yield
)
SELECT
    year,
    ROUND(avg_prev_year_yield, 2) AS avg_prev_year_yield,
    ROUND(
        avg_prev_year_yield - previous_year_yield,
        2
    ) AS year_over_year_change,
 ROUND(
        100.0 * (avg_prev_year_yield - previous_year_yield)
        / previous_year_yield,
        2
    ) AS year_over_year_percentage_change
FROM yield_with_previous
ORDER BY year;
SELECT
    crop,
    COUNT(prev_year_yield) AS yield_records,
    ROUND(AVG(prev_year_yield), 2) AS avg_prev_year_yield
FROM agriculture_data
GROUP BY crop
ORDER BY avg_prev_year_yield DESC;
SELECT
    target,
    COUNT(prev_year_yield) AS yield_records,
    ROUND(AVG(prev_year_yield), 2) AS avg_prev_year_yield
FROM agriculture_data
GROUP BY target
ORDER BY target;
SELECT
    target,
    COUNT(*) AS total_records,
    ROUND(AVG(annual), 2) AS avg_annual_rainfall,
    ROUND(AVG(monsoon), 2) AS avg_monsoon_rainfall
FROM agriculture_data
GROUP BY target
ORDER BY target;
SELECT
    target,
    COUNT(*) AS total_records,
    ROUND(AVG(area), 2) AS avg_area
FROM agriculture_data
GROUP BY target
ORDER BY target;
SELECT
    state,
    crop,
    SUM(area) AS total_area
FROM agriculture_data
GROUP BY state, crop
ORDER BY total_area DESC
LIMIT 10;
WITH state_crop_area AS (
    SELECT
        state,
        crop,
        SUM(area) AS total_area
    FROM agriculture_data
    GROUP BY state, crop
),
ranked_crops AS (
    SELECT
        state,
        crop,
        total_area,
        DENSE_RANK() OVER (
            PARTITION BY state
            ORDER BY total_area DESC
        ) AS crop_rank
    FROM state_crop_area
)
SELECT
    state,
    crop,
    total_area,
    crop_rank
FROM ranked_crops
WHERE crop_rank <= 3
ORDER BY state, crop_rank;
SELECT
    (
        COUNT(*) * SUM(avg_annual_rainfall * avg_prev_year_yield)
        - SUM(avg_annual_rainfall) * SUM(avg_prev_year_yield)
    )
    /
    SQRT(
        (
            COUNT(*) * SUM(avg_annual_rainfall * avg_annual_rainfall)
            - POW(SUM(avg_annual_rainfall), 2)
        )
        *
        (
            COUNT(*) * SUM(avg_prev_year_yield * avg_prev_year_yield)
            - POW(SUM(avg_prev_year_yield), 2)
        )
    ) AS rainfall_yield_correlation
FROM (
    SELECT
        year,
        AVG(annual) AS avg_annual_rainfall,
        AVG(prev_year_yield) AS avg_prev_year_yield
    FROM agriculture_data
    GROUP BY year
) AS yearly_data;
SELECT
    state,
    COUNT(prev_year_yield) AS yield_records,
    ROUND(AVG(prev_year_yield), 2) AS avg_prev_year_yield,
    ROUND(MIN(prev_year_yield), 2) AS min_prev_year_yield,
    ROUND(MAX(prev_year_yield), 2) AS max_prev_year_yield
FROM agriculture_data
GROUP BY state
ORDER BY avg_prev_year_yield DESC;
WITH state_crop_yield AS (
    SELECT
        state,
        crop,
        COUNT(prev_year_yield) AS yield_records,
        AVG(prev_year_yield) AS avg_prev_year_yield
    FROM agriculture_data
    GROUP BY state, crop
),
ranked_crops AS (
    SELECT
        state,
        crop,
        yield_records,
        avg_prev_year_yield,
        DENSE_RANK() OVER (
            PARTITION BY state
            ORDER BY avg_prev_year_yield DESC
        ) AS yield_rank
    FROM state_crop_yield
)
SELECT
    state,
    crop,
    yield_records,
    ROUND(avg_prev_year_yield, 2) AS avg_prev_year_yield,
    yield_rank
FROM ranked_crops
WHERE yield_rank = 1
ORDER BY state;
-- ============================================================
-- 9. SQL VIEWS FOR REPORTING
-- ============================================================

CREATE VIEW yearly_agriculture_summary AS
SELECT
    year,
    COUNT(*) AS total_records,
    ROUND(SUM(area), 2) AS total_area,
    ROUND(AVG(annual), 2) AS avg_annual_rainfall,
    ROUND(AVG(monsoon), 2) AS avg_monsoon_rainfall,
    ROUND(AVG(prev_year_yield), 2) AS avg_prev_year_yield,
    SUM(CASE WHEN target = 1 THEN 1 ELSE 0 END) AS target_1_records,
    ROUND(
        100.0 * SUM(CASE WHEN target = 1 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS target_1_percentage
FROM agriculture_data
GROUP BY year;
SELECT *
FROM yearly_agriculture_summary
ORDER BY year;
CREATE VIEW state_agriculture_summary AS
SELECT
    state,
    COUNT(*) AS total_records,
    ROUND(SUM(area), 2) AS total_area,
    ROUND(AVG(area), 2) AS avg_area,
    ROUND(AVG(annual), 2) AS avg_annual_rainfall,
    ROUND(AVG(monsoon), 2) AS avg_monsoon_rainfall,
    ROUND(AVG(prev_year_yield), 2) AS avg_prev_year_yield,
    SUM(CASE WHEN target = 1 THEN 1 ELSE 0 END) AS target_1_records,
    ROUND(
        100.0 * SUM(CASE WHEN target = 1 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS target_1_percentage
FROM agriculture_data
GROUP BY state;
SELECT *
FROM state_agriculture_summary
ORDER BY total_area DESC;
