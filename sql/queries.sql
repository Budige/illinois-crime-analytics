-- ============================================================================
-- Illinois Crime Analytics - Analytical Queries
-- Author: Rakesh Budige
-- Date: January 2025
-- Purpose: Advanced SQL queries for crime data analysis
-- Database: PostgreSQL (uses window functions, CTEs)
-- ============================================================================

-- ============================================================================
-- QUERY 1: Crime Rate Per 100,000 Population by County
-- Purpose: Normalize crime counts by population for fair comparison
-- Demonstrates: JOIN, aggregation, calculated fields, type casting
-- ============================================================================

-- Calculate crime rate per 100,000 population for each county (2024)
SELECT 
    c.county_name,
    c.population,
    COUNT(ci.incident_id) AS total_reports,
    SUM(ci.incident_count) AS total_incidents,
    ROUND(
        SUM(ci.incident_count)::NUMERIC / c.population * 100000, 
        2
    ) AS crime_rate_per_100k,
    ROUND(
        SUM(ci.cleared_count)::NUMERIC / NULLIF(SUM(ci.incident_count), 0) * 100,
        2
    ) AS clearance_rate_pct
FROM counties c
LEFT JOIN crime_incidents ci 
    ON c.county_id = ci.county_id
WHERE EXTRACT(YEAR FROM ci.incident_date) = 2024
GROUP BY c.county_id, c.county_name, c.population
HAVING SUM(ci.incident_count) > 0
ORDER BY crime_rate_per_100k DESC
LIMIT 10;


-- ============================================================================
-- QUERY 2: Month-Over-Month Crime Trend Analysis
-- Purpose: Show how crime is changing month-to-month within each county
-- Demonstrates: CTE, window functions (LAG), PARTITION BY, date functions
-- ============================================================================

-- Analyze month-over-month crime trend using window functions
WITH monthly_counts AS (
    SELECT 
        ci.county_id,
        c.county_name,
        DATE_TRUNC('month', ci.incident_date) AS month,
        SUM(ci.incident_count) AS monthly_total
    FROM crime_incidents ci
    JOIN counties c ON ci.county_id = c.county_id
    WHERE ci.incident_date >= '2023-01-01'
    GROUP BY ci.county_id, c.county_name, DATE_TRUNC('month', ci.incident_date)
)
SELECT 
    county_name,
    month,
    monthly_total AS current_month,
    LAG(monthly_total) OVER (
        PARTITION BY county_id 
        ORDER BY month
    ) AS previous_month,
    monthly_total - LAG(monthly_total) OVER (
        PARTITION BY county_id 
        ORDER BY month
    ) AS absolute_change,
    ROUND(
        (monthly_total - LAG(monthly_total) OVER (
            PARTITION BY county_id 
            ORDER BY month
        ))::NUMERIC 
        / NULLIF(LAG(monthly_total) OVER (
            PARTITION BY county_id 
            ORDER BY month
        ), 0) * 100,
        2
    ) AS percent_change
FROM monthly_counts
WHERE month >= '2024-01-01'
ORDER BY county_name, month;


-- ============================================================================
-- QUERY 3: Top 3 Crime Types Per County (Ranking)
-- Purpose: Identify most common crimes in each county
-- Demonstrates: Subquery, DENSE_RANK(), window functions, PARTITION BY
-- ============================================================================

-- Rank crime types by frequency within each county (2024)
SELECT 
    county_name,
    crime_type,
    total_incidents,
    crime_rank,
    ROUND(percentage_of_county_crime, 2) AS pct_of_total
FROM (
    SELECT 
        c.county_name,
        ci.crime_type,
        SUM(ci.incident_count) AS total_incidents,
        DENSE_RANK() OVER (
            PARTITION BY c.county_id 
            ORDER BY SUM(ci.incident_count) DESC
        ) AS crime_rank,
        SUM(ci.incident_count)::NUMERIC / 
            SUM(SUM(ci.incident_count)) OVER (PARTITION BY c.county_id) * 100 
            AS percentage_of_county_crime
    FROM counties c
    JOIN crime_incidents ci ON c.county_id = ci.county_id
    WHERE EXTRACT(YEAR FROM ci.incident_date) = 2024
    GROUP BY c.county_id, c.county_name, ci.crime_type
) ranked_crimes
WHERE crime_rank <= 3
ORDER BY county_name, crime_rank;


-- ============================================================================
-- QUERY 4: Year-Over-Year Comparison
-- Purpose: Compare current year vs previous year crime statistics
-- Demonstrates: CTE, CASE statements, multiple aggregations
-- ============================================================================

-- Compare 2024 vs 2023 crime statistics by county
WITH yearly_stats AS (
    SELECT 
        c.county_name,
        EXTRACT(YEAR FROM ci.incident_date) AS year,
        SUM(ci.incident_count) AS total_incidents,
        SUM(ci.cleared_count) AS total_cleared
    FROM counties c
    JOIN crime_incidents ci ON c.county_id = ci.county_id
    WHERE EXTRACT(YEAR FROM ci.incident_date) IN (2023, 2024)
    GROUP BY c.county_name, EXTRACT(YEAR FROM ci.incident_date)
)
SELECT 
    county_name,
    MAX(CASE WHEN year = 2023 THEN total_incidents END) AS incidents_2023,
    MAX(CASE WHEN year = 2024 THEN total_incidents END) AS incidents_2024,
    MAX(CASE WHEN year = 2024 THEN total_incidents END) - 
        MAX(CASE WHEN year = 2023 THEN total_incidents END) AS absolute_change,
    ROUND(
        (MAX(CASE WHEN year = 2024 THEN total_incidents END)::NUMERIC - 
         MAX(CASE WHEN year = 2023 THEN total_incidents END)) /
        NULLIF(MAX(CASE WHEN year = 2023 THEN total_incidents END), 0) * 100,
        2
    ) AS yoy_change_pct
FROM yearly_stats
GROUP BY county_name
HAVING MAX(CASE WHEN year = 2023 THEN total_incidents END) IS NOT NULL
ORDER BY yoy_change_pct DESC;


-- ============================================================================
-- QUERY 5: Cumulative Crime Count (Running Total)
-- Purpose: Show cumulative crime trend over time
-- Demonstrates: Window functions with SUM OVER, ORDER BY in window
-- ============================================================================

-- Calculate running total of crimes by month (2024)
SELECT 
    DATE_TRUNC('month', incident_date) AS month,
    SUM(incident_count) AS monthly_crimes,
    SUM(SUM(incident_count)) OVER (
        ORDER BY DATE_TRUNC('month', incident_date)
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_crimes,
    ROUND(
        AVG(SUM(incident_count)) OVER (
            ORDER BY DATE_TRUNC('month', incident_date)
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS moving_avg_3month
FROM crime_incidents
WHERE EXTRACT(YEAR FROM incident_date) = 2024
GROUP BY DATE_TRUNC('month', incident_date)
ORDER BY month;


-- ============================================================================
-- QUERY 6: Crime Clearance Rate by Region
-- Purpose: Calculate solve rates for different regions
-- Demonstrates: GROUP BY, CASE, percentage calculations
-- ============================================================================

-- Analyze clearance rates (solved crimes) by region
SELECT 
    c.region,
    ci.crime_type,
    SUM(ci.incident_count) AS total_incidents,
    SUM(ci.cleared_count) AS total_cleared,
    ROUND(
        SUM(ci.cleared_count)::NUMERIC / NULLIF(SUM(ci.incident_count), 0) * 100,
        2
    ) AS clearance_rate_pct,
    CASE 
        WHEN (SUM(ci.cleared_count)::NUMERIC / NULLIF(SUM(ci.incident_count), 0) * 100) > 30 
            THEN 'High Clearance'
        WHEN (SUM(ci.cleared_count)::NUMERIC / NULLIF(SUM(ci.incident_count), 0) * 100) > 15 
            THEN 'Medium Clearance'
        ELSE 'Low Clearance'
    END AS clearance_category
FROM counties c
JOIN crime_incidents ci ON c.county_id = ci.county_id
WHERE EXTRACT(YEAR FROM ci.incident_date) = 2024
GROUP BY c.region, ci.crime_type
HAVING SUM(ci.incident_count) > 100
ORDER BY c.region, clearance_rate_pct DESC;


-- ============================================================================
-- QUERY 7: Statistical Anomaly Detection
-- Purpose: Find counties with unusually high crime rates (3-sigma rule)
-- Demonstrates: Statistical functions, subqueries, WHERE filtering
-- ============================================================================

-- Detect counties with crime rates more than 3 standard deviations from mean
WITH crime_stats AS (
    SELECT 
        c.county_id,
        c.county_name,
        SUM(ci.incident_count)::NUMERIC / c.population * 100000 AS crime_rate_per_100k
    FROM counties c
    JOIN crime_incidents ci ON c.county_id = ci.county_id
    WHERE EXTRACT(YEAR FROM ci.incident_date) = 2024
    GROUP BY c.county_id, c.county_name, c.population
),
statistics AS (
    SELECT 
        AVG(crime_rate_per_100k) AS mean_rate,
        STDDEV(crime_rate_per_100k) AS stddev_rate
    FROM crime_stats
)
SELECT 
    cs.county_name,
    ROUND(cs.crime_rate_per_100k, 2) AS crime_rate,
    ROUND(s.mean_rate, 2) AS avg_rate,
    ROUND(
        (cs.crime_rate_per_100k - s.mean_rate) / NULLIF(s.stddev_rate, 0),
        2
    ) AS z_score,
    CASE 
        WHEN cs.crime_rate_per_100k > s.mean_rate + 3 * s.stddev_rate THEN 'High Outlier'
        WHEN cs.crime_rate_per_100k < s.mean_rate - 3 * s.stddev_rate THEN 'Low Outlier'
        ELSE 'Normal'
    END AS anomaly_status
FROM crime_stats cs
CROSS JOIN statistics s
WHERE ABS((cs.crime_rate_per_100k - s.mean_rate) / NULLIF(s.stddev_rate, 0)) > 2
ORDER BY ABS((cs.crime_rate_per_100k - s.mean_rate) / NULLIF(s.stddev_rate, 0)) DESC;


-- ============================================================================
-- QUERY 8: Power BI Export Query
-- Purpose: Create denormalized table optimized for Power BI dashboard
-- Demonstrates: Denormalization, EXTRACT functions, CASE transformations
-- ============================================================================

-- Export data optimized for Power BI visualization
CREATE TEMP TABLE powerbi_export AS
SELECT 
    ci.incident_date,
    EXTRACT(YEAR FROM ci.incident_date) AS year,
    EXTRACT(MONTH FROM ci.incident_date) AS month,
    TO_CHAR(ci.incident_date, 'Month YYYY') AS month_name,
    c.county_name,
    c.region,
    c.population,
    ci.crime_type,
    ci.incident_count,
    ci.cleared_count,
    CASE 
        WHEN ci.cleared_count > 0 THEN 'Cleared'
        ELSE 'Uncleared'
    END AS clearance_status,
    ROUND(
        ci.incident_count::NUMERIC / c.population * 100000, 
        2
    ) AS crime_rate_per_100k,
    ROUND(
        ci.cleared_count::NUMERIC / NULLIF(ci.incident_count, 0) * 100,
        2
    ) AS clearance_rate_pct
FROM crime_incidents ci
JOIN counties c ON ci.county_id = c.county_id
WHERE ci.incident_date >= '2020-01-01';

-- Export to CSV (PostgreSQL command-line)
-- \copy powerbi_export TO '/tmp/crime_data_powerbi.csv' CSV HEADER;

SELECT 'Power BI export table created with ' || COUNT(*) || ' records' AS status
FROM powerbi_export;


-- ============================================================================
-- QUERY PERFORMANCE NOTES
-- ============================================================================

-- To check query performance, prepend any query with EXPLAIN ANALYZE:
-- EXPLAIN ANALYZE SELECT ...

-- Index usage can be verified with:
-- SELECT schemaname, tablename, indexname, idx_scan 
-- FROM pg_stat_user_indexes 
-- WHERE schemaname = 'public'
-- ORDER BY idx_scan DESC;

-- ============================================================================
-- END OF ANALYTICAL QUERIES
-- ============================================================================
