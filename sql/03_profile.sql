-- =========================================================================
-- 03_profile.sql
-- Explore the raw tables before cleaning the data. No changes to the data
-- are made. Should run each section on it's own. (Highlight -> Run Selected
-- Query). Results will be recorded in the README.
-- =========================================================================
USE bike_hire;
-- =========================================================================
-- ROW COUNTS AND DATE RANGE PER FILE
-- Want to make sure that the files actually cover the dates the names claim
-- Check there are no overlaps
-- =========================================================================
SELECT 'old' as fmt,
    source_file,
    COUNT(*) AS n_rows,
    MIN(STR_TO_DATE(start_date, '%d/%m/%Y %H:%i')) AS first_start,
    MAX(STR_TO_DATE(start_date, '%d/%m/%Y %H:%i')) AS last_start
FROM raw_journeys_old
GROUP BY source_file
UNION ALL
SELECT 'new',
    source_file,
    COUNT(*),
    MIN(STR_TO_DATE(start_date, '%d/%m/%Y %H:%i')),
    MAX(STR_TO_DATE(start_date, '%d/%m/%Y %H:%i'))
FROM raw_journeys_new
GROUP BY source_file
ORDER BY first_start;
-- =========================================================================
-- DUPLICATE JOURNEYS
-- =========================================================================
-- Duplicates within each format
SELECT 'old' as fmt,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT rental_id) AS distinct_ids,
    COUNT(*) - COUNT(DISTINCT rental_id) AS distinct_rows
FROM raw_journeys_old
UNION ALL
SELECT 'new',
    COUNT(*),
    COUNT(DISTINCT journey_number),
    COUNT(*) - COUNT(DISTINCT journey_number)
FROM raw_journeys_new;
-- Want to check if duplicates are exact copies or different rides with same ID
SELECT rental_id,
    COUNT(*) AS copies,
    COUNT(
        DISTINCT start_date,
        end_date,
        start_station_id,
        end_station_id,
        duration
    ) AS different_versions,
    GROUP_CONCAT(DISTINCT source_file) AS files
FROM raw_journeys_old
GROUP BY rental_id
HAVING COUNT(*) > 1
ORDER BY copies DESC
LIMIT 20;
SELECT journey_number,
    COUNT(*) AS copies,
    COUNT(
        DISTINCT start_date,
        end_date,
        start_station_number,
        end_station_number,
        total_duration_ms
    ) AS distinct_versions,
    GROUP_CONCAT(DISTINCT source_file) AS files
FROM raw_journeys_new
GROUP BY journey_number
HAVING COUNT(*) > 1
ORDER BY copies DESC
LIMIT 20;
-- Does the same journey appear in both formats (overlap at stwicth)?
SELECT COUNT(*) AS ids_in_both_formats
FROM raw_journeys_old o
    JOIN raw_journeys_new n ON o.rental_id = n.journey_number;
-- =========================================================================
-- Missing values (NULL or empty string)
-- =========================================================================
SELECT SUM(
        rental_id IS NULL
        OR rental_id = ''
    ) AS rental_id,
    SUM(
        duration IS NULL
        OR duration = ''
    ) AS duration,
    SUM(
        bike_id IS NULL
        OR bike_id = ''
    ) AS bike_id,
    SUM(
        start_date IS NULL
        OR start_date = ''
    ) AS start_date,
    SUM(
        end_date IS NULL
        OR end_date = ''
    ) AS end_date,
    SUM(
        start_station_id IS NULL
        OR start_station_id = ''
    ) AS start_station_id,
    SUM(
        start_station_name IS NULL
        OR start_station_name = ''
    ) AS start_station_name,
    SUM(
        end_station_id IS NULL
        OR end_station_id = ''
    ) AS end_station_id,
    SUM(
        end_station_name IS NULL
        OR end_station_name = ''
    ) AS end_station_name
FROM raw_journeys_old;
SELECT SUM(
        journey_number IS NULL
        OR journey_number = ''
    ) AS journey_number,
    SUM(
        start_date IS NULL
        OR start_date = ''
    ) AS start_date,
    SUM(
        end_date IS NULL
        OR end_date = ''
    ) AS end_date,
    SUM(
        start_station_number IS NULL
        OR start_station_number = ''
    ) AS start_station_number,
    SUM(
        start_station_name IS NULL
        OR start_station_name = ''
    ) AS start_station_name,
    SUM(
        end_station_number IS NULL
        OR end_station_number = ''
    ) AS end_station_number,
    SUM(
        end_station_name IS NULL
        OR end_station_name = ''
    ) AS end_station_name,
    SUM(
        bike_number IS NULL
        OR bike_number = ''
    ) AS bike_number,
    SUM(
        bike_model IS NULL
        OR bike_model = ''
    ) AS bike_model,
    SUM(
        total_duration_ms IS NULL
        OR total_duration_ms = ''
    ) AS total_duration_ms
FROM raw_journeys_new;
-- =========================================================================
-- DURATIONS
-- =========================================================================
-- Distribution and suspicious values (old are in seconds, new in ms)
SELECT 'old' as fmt,
    MIN(CAST(duration AS SIGNED)) AS min_seconds,
    MAX(CAST(duration AS SIGNED)) AS max_seconds,
    ROUND(AVG(CAST(duration AS SIGNED))) AS avg_seconds,
    SUM(CAST(duration AS SIGNED) <= 0) AS zero_or_negative,
    SUM(CAST(duration AS SIGNED) < 60) AS under_1_min,
    SUM(CAST(duration AS SIGNED) > 86400) AS over_24_hours
FROM raw_journeys_old
WHERE duration <> ''
UNION ALL
SELECT 'new (ms -> s)',
    MIN(CAST(total_duration_ms AS SIGNED) DIV 1000),
    MAX(CAST(total_duration_ms AS SIGNED) DIV 1000),
    ROUND(AVG(CAST(total_duration_ms AS SIGNED) / 1000)),
    SUM(CAST(total_duration_ms AS SIGNED) <= 0),
    SUM(CAST(total_duration_ms AS SIGNED) < 60000),
    SUM(CAST(total_duration_ms AS SIGNED) > 86400000)
FROM raw_journeys_new
WHERE total_duration_ms <> '';
-- Does stated duration match end time minus start time? Dates are just to the minute
-- so allow 2 mins slack
SELECT 'old' AS fmt,
    SUM(
        ABS(
            CAST(duration AS SIGNED) - TIMESTAMPDIFF(
                SECOND,
                STR_TO_DATE(start_date, '%d/%m/%Y %H:%i'),
                STR_TO_DATE(end_date, '%d/%m/%Y %H:%i')
            )
        ) > 120
    ) AS mismatched,
    SUM(
        STR_TO_DATE(end_date, '%d/%m/%Y %H:%i') < STR_TO_DATE(start_date, '%d/%m/%Y %H:%i')
    ) AS end_before_start
FROM raw_journeys_old
UNION ALL
SELECT 'new',
    SUM(
        ABS(
            CAST(total_duration_ms AS SIGNED) DIV 1000 - TIMESTAMPDIFF(
                SECOND,
                STR_TO_DATE(start_date, '%Y-%m-%d %H:%i'),
                STR_TO_DATE(end_date, '%Y-%m-%d %H:%i')
            )
        ) > 120
    ),
    SUM(
        STR_TO_DATE(end_date, '%Y-%m-%d %H:%i') < STR_TO_DATE(start_date, '%Y-%m-%d %H:%i')
    )
FROM raw_journeys_new;
-- Probably failed hires because it's the same dock in under two minutes
SELECT 'old' as fmt,
    SUM(
        start_station_id = end_station_id
        AND CAST(duration AS SIGNED) < 120
    ) AS same_dock_under_2_min
FROM raw_journeys_old
UNION ALL
SELECT 'new',
    SUM(
        start_station_number = end_station_number
        AND CAST(total_duration_ms AS SIGNED) < 120000
    )
FROM raw_journeys_new;
-- =========================================================================
-- STATIONS
-- Old and new formats use different ID systems so names will probably be the
-- bridge. Want to check how messy they are
-- =========================================================================
-- How many distinct stations in each format (start and end combined)
WITH old_stations AS (
    SELECT start_station_id AS station_id,
        start_station_name AS station_name
    FROM raw_journeys_old
    UNION
    SELECT end_station_id,
        end_station_name
    FROM raw_journeys_old
),
new_stations AS (
    SELECT start_station_number AS station_id,
        start_station_name AS station_name
    FROM raw_journeys_new
    UNION
    SELECT end_station_number,
        end_station_name
    FROM raw_journeys_new
)
SELECT 'old' AS fmt,
    COUNT(DISTINCT station_id) AS distinct_ids,
    COUNT(DISTINCT station_name) AS distinct_names,
    COUNT(*) AS distinct_id_name_pairs
FROM old_stations
UNION ALL
SELECT 'new',
    COUNT(DISTINCT station_id),
    COUNT(DISTINCT station_name),
    COUNT(*)
FROM new_stations;
-- For the old format, check if there are station IDs that appear with more than
-- one name
WITH old_stations AS (
    SELECT start_station_id AS station_id,
        start_station_name AS station_name
    FROM raw_journeys_old
    UNION
    SELECT end_station_id,
        end_station_name
    FROM raw_journeys_old
)
SELECT station_id,
    COUNT(*) AS n_names,
    GROUP_CONCAT(station_name SEPARATOR ' | ') AS names
FROM old_stations
GROUP BY station_id
HAVING COUNT(*) > 1
ORDER BY n_names DESC;
-- For the new format, check if there are station IDs that sppear with more than one
-- name
WITH new_stations AS (
    SELECT start_station_number AS station_id,
        start_station_name AS station_name
    FROM raw_journeys_new
    UNION
    SELECT end_station_number,
        end_station_name
    FROM raw_journeys_new
)
SELECT station_id,
    COUNT(*) AS n_names,
    GROUP_CONCAT(station_name SEPARATOR ' | ') AS names
FROM new_stations
GROUP BY station_id
HAVING COUNT(*) > 1
ORDER BY n_names DESC;
-- Check if old station names can be matched to new ones
WITH old_names AS (
    SELECT start_station_name AS station_name
    FROM raw_journeys_old
    UNION
    SELECT end_station_name
    FROM raw_journeys_old
),
new_names AS (
    SELECT start_station_name AS station_name
    FROM raw_journeys_new
    UNION
    SELECT end_station_name
    FROM raw_journeys_new
)
SELECT COUNT(*) AS old_names,
    SUM(n.station_name IS NOT NULL) AS exact_match_in_new,
    SUM(n.station_name IS NULL) AS no_match
FROM old_names o
    LEFT JOIN new_names n ON o.station_name = n.station_name;
-- If there are old names that don't match, what is different about them?
WITH old_names AS (
    SELECT start_station_name AS station_name
    FROM raw_journeys_old
    UNION
    SELECT end_station_name
    FROM raw_journeys_old
),
new_names AS (
    SELECT start_station_name AS station_name
    FROM raw_journeys_new
    UNION
    SELECT end_station_name
    FROM raw_journeys_new
)
SELECT o.station_name AS unmatched_old_name
FROM old_names o
    LEFT JOIN new_names n ON o.station_name = n.station_name
WHERE n.station_name IS NULL
ORDER BY o.station_name;
-- =========================================================================
-- BIKES
-- =========================================================================
SELECT bike_model,
    COUNT(*) AS journeys
FROM raw_journeys_new
GROUP BY bike_model
ORDER BY journeys DESC;
-- =========================================================================
-- WEATHER
-- =========================================================================
SELECT COUNT(*) AS days,
    MIN(weather_date) AS first_day,
    MAX(weather_date) AS last_day,
    MIN(CAST(temp_max_c AS DECIMAL(4, 1))) AS coolest_max,
    MAX(CAST(temp_max_c AS DECIMAL(4, 1))) AS hottest_max,
    MAX(CAST(precipitation_mm AS DECIMAL(5, 2))) AS wettest_mm,
    SUM(CAST(precipitation_mm AS DECIMAL(5, 2)) = 0) AS dry_days,
    SUM(
        temp_max_c = ''
        OR precipitation_mm = ''
    ) AS missing_values
FROM raw_weather;