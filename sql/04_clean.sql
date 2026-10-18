-- =========================================================================
-- 04_clean.sql
-- Run the whole file from the terminal (because temporary tables last one
-- session)
--  mysql -u root -p bike_hire < sql/04_clean.sql
-- =========================================================================
USE bike_hire;
DROP TABLE IF EXISTS clean_journeys;
DROP TABLE IF EXISTS clean_weather;
-- =========================================================================
-- Convert the weather from text to prroper types
-- =========================================================================
CREATE TABLE clean_weather AS
SELECT STR_TO_DATE(weather_date, '%Y-%m-%d') AS weather_date,
    CAST(temp_max_c AS DECIMAL(4, 1)) AS temp_max_c,
    CAST(precipitation_mm AS DECIMAL(5, 2)) AS precipitation_mm,
    CAST(precipitation_mm AS DECIMAL(5, 2)) >= 1 AS is_wet_day
FROM raw_weather;
-- =========================================================================
-- Stage both formats of data into a temporary table so cleaning steps below
-- can be done against one consistent shape.
--  old: dd/mm/yyyy, duration in seconds
--  new: yyyy-mm-dd, duration in milliseconds
-- =========================================================================
CREATE TEMPORARY TABLE tmp_journeys AS
SELECT 'old' AS source_format,
    CAST(rental_id AS UNSIGNED) AS journey_id,
    STR_TO_DATE(start_date, '%d/%m/%Y %H:%i') AS start_time,
    STR_TO_DATE(end_date, '%d/%m/%Y %H:%i') AS end_time,
    CAST(duration AS SIGNED) AS duration_s,
    start_station_name AS start_station,
    end_station_name AS end_station
FROM raw_journeys_old
UNION ALL
SELECT 'new',
    CAST(journey_number AS UNSIGNED),
    STR_TO_DATE(start_date, '%Y-%m-%d %H:%i'),
    STR_TO_DATE(end_date, '%Y-%m-%d %H:%i'),
    CAST(total_duration_ms AS SIGNED) DIV 1000,
    start_station_name,
    end_station_name
FROM raw_journeys_new;
-- =========================================================================
-- Create the final clean table
--  Tidy station names using regex
--  Drop journeys under 60s (old data doesn't count them)
--  Over 24 hour tips and same dock trips lasting less than 2 minutes flagged
--  but not deleted
-- =========================================================================
CREATE TABLE clean_journeys AS
SELECT journey_id,
    source_format,
    start_time,
    end_time,
    duration_s,
    CAST(
        TRIM(
            REGEXP_REPLACE(
                REGEXP_REPLACE(start_station, '[[:space:]]+,', ','),
                '[[:space:]]+',
                ' '
            )
        ) AS CHAR(255)
    ) AS start_station,
    CAST(
        TRIM(
            REGEXP_REPLACE(
                REGEXP_REPLACE(end_station, '[[:space:]]+,', ','),
                '[[:space:]]+',
                ' '
            )
        ) AS CHAR(255)
    ) AS end_station,
    (
        duration_s > 86400
        OR (
            start_station = end_station
            AND duration_s < 120
        )
    ) AS is_suspect
FROM tmp_journeys
WHERE duration_s >= 60;
ALTER TABLE clean_journeys
ADD PRIMARY KEY (journey_id),
    ADD INDEX (start_time),
    ADD INDEX (start_station);
-- =========================================================================
-- Check that raw rows are equal to clean rows added to excluded rows
-- =========================================================================
SELECT COUNT(*) AS raw_rows,
    SUM(duration_s < 60) AS excluded_under_60s,
    (
        SELECT COUNT(*)
        FROM clean_journeys
    ) AS clean_rows,
    (
        SELECT SUM(is_suspect)
        FROM clean_journeys
    ) AS flagged_suspect
FROM tmp_journeys;