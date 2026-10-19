-- ========================================================================
-- 06_eda.sql
-- Run this after 05. To save the results to a file for the README:
--  mysql -u root -p bike_hire --table < sql/06_eda.sql > outputs/eda_results.txt
-- ========================================================================

USE bike_hire;

-- ========================================================================
-- Create window functions. Can work out how daily hires trend over the six
-- weeks. A 7 day rolling average smooths out weekday/weekend swings. 
-- LAG shows the change from the day before.
-- ========================================================================
SELECT
    journey_date,
    day_name,
    journeys,
    ROUND(AVG(journeys) OVER (ORDER BY journey_date
                              ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)) AS rolling_7_day_avg,
    journeys - LAG(journeys) OVER (ORDER BY journey_date) AS change_vs_prev_day
FROM daily_summary
ORDER BY journey_date;

-- ========================================================================
-- Create a CTE. Want to know if rain reduces hires. Split weekdays and 
-- weekends because commuters and leisure riders might react differently.
--  Excludes 29 Aug (bank holiday), 10-11 Sept (missing data due to 
--  formatting switch over), 12 Sept (data starts at 05:17) and 19 Sept
--  (this was the Queen's funeral)
-- ========================================================================
WITH typical_days AS (
    SELECT
        journeys,
        CASE WHEN day_name IN ('Saturday', 'Sunday') THEN 'Weekend' ELSE 'Weekday' END AS day_type,
        CASE WHEN is_wet_day = 1 THEN 'Wet (1mm+)' ELSE 'Dry' END AS weather
    FROM daily_summary
    WHERE journey_date NOT IN ('2022-08-29', '2022-09-10', '2022-09-11', '2022-09-12', '2022-09-19')
)
SELECT day_type, weather, COUNT(*) AS days, ROUND(AVG(journeys)) AS avg_journeys
FROM typical_days
GROUP BY day_type, weather
ORDER BY day_type, weather;

-- ========================================================================
-- Create a subquery. Want to know which stations are hotspots (3x average)
-- station departures
-- ========================================================================
SELECT start_station, COUNT(*) AS departures
FROM clean_journeys
GROUP BY start_station
HAVING COUNT(*) > 3 * (
    SELECT AVG(n)
    FROM (SELECT COUNT(*) AS n FROM clean_journeys GROUP BY start_station) AS per_station
)
ORDER BY departures DESC;