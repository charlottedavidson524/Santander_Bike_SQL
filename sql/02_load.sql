-- =========================================================================
-- 02_load.sql
-- Loads raw CSVs into landing tables
-- Run from terminal (not SQLTools) so LOCAL INFILE works
--  mysql --local-infile=1 -u root -p < sql/02_load.sql
-- If the output is 'Loading local data is disabled', rrun:
--  SET GLOBAL local_infile=1;
-- Note: LOAD DATa can't take a variable filename or run inside a stored
-- procedure, so each file gets it's own statement
-- =========================================================================
USE bike_hire;
-- Start clean so the script can be re-run safely
TRUNCATE TABLE raw_journeys_old;
TRUNCATE TABLE raw_journeys_new;
TRUNCATE TABLE raw_weather;
-- =========================================================================
-- Old format journey files
-- Fields are only quoted when they contain commas -> OPTIONALLY ENCLOSED
-- =========================================================================
LOAD DATA LOCAL INFILE 'data/raw/332JourneyDataExtract24Aug2022-30Aug2022.csv' INTO TABLE raw_journeys_old CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 LINES (
    rental_id,
    duration,
    bike_id,
    end_date,
    end_station_id,
    end_station_name,
    start_date,
    start_station_id,
    start_station_name
)
SET source_file = '332JourneyDataExtract24Aug2022-30Aug2022.csv';
LOAD DATA LOCAL INFILE 'data/raw/333JourneyDataExtract31Aug2022-06Sep2022.csv' INTO TABLE raw_journeys_old CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 LINES (
    rental_id,
    duration,
    bike_id,
    end_date,
    end_station_id,
    end_station_name,
    start_date,
    start_station_id,
    start_station_name
)
SET source_file = '333JourneyDataExtract31Aug2022-06Sep2022.csv';
LOAD DATA LOCAL INFILE 'data/raw/334JourneyDataExtract07Sep2022-11Sep2022.csv' INTO TABLE raw_journeys_old CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 LINES (
    rental_id,
    duration,
    bike_id,
    end_date,
    end_station_id,
    end_station_name,
    start_date,
    start_station_id,
    start_station_name
)
SET source_file = '334JourneyDataExtract07Sep2022-11Sep2022.csv';
-- =========================================================================
-- New format journey files
-- =========================================================================
LOAD DATA LOCAL INFILE 'data/raw/335JourneyDataExtract12Sep2022-18Sep2022.csv' INTO TABLE raw_journeys_new CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 LINES (
    journey_number,
    start_date,
    start_station_number,
    start_station_name,
    end_date,
    end_station_number,
    end_station_name,
    bike_number,
    bike_model,
    total_duration_text,
    total_duration_ms
)
SET source_file = '335JourneyDataExtract12Sep2022-18Sep2022.csv';
LOAD DATA LOCAL INFILE 'data/raw/336JourneyDataExtract19Sep2022-25Sep2022.csv' INTO TABLE raw_journeys_new CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 LINES (
    journey_number,
    start_date,
    start_station_number,
    start_station_name,
    end_date,
    end_station_number,
    end_station_name,
    bike_number,
    bike_model,
    total_duration_text,
    total_duration_ms
)
SET source_file = '336JourneyDataExtract19Sep2022-25Sep2022.csv';
LOAD DATA LOCAL INFILE 'data/raw/337JourneyDataExtract26Sep2022-02Oct2022.csv' INTO TABLE raw_journeys_new CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 LINES (
    journey_number,
    start_date,
    start_station_number,
    start_station_name,
    end_date,
    end_station_number,
    end_station_name,
    bike_number,
    bike_model,
    total_duration_text,
    total_duration_ms
)
SET source_file = '337JourneyDataExtract26Sep2022-02Oct2022.csv';
-- =========================================================================
-- Weather table (need to skip 4 lines this time)
-- =========================================================================
LOAD DATA LOCAL INFILE 'data/raw/london_weather.csv' INTO TABLE raw_weather CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 4 LINES (
    weather_date,
    temp_max_c,
    temp_min_c,
    precipitation_mm,
    precipitation_hours
)
SET source_file = 'london_weather.csv';
-- =========================================================================
-- Checks (check line count and line endings)
-- =========================================================================
SELECT 'old' AS fmt,
    source_file,
    COUNT(*) AS rows_loaded
FROM raw_journeys_old
GROUP BY source_file
UNION ALL
SELECT 'new',
    source_file,
    COUNT(*)
FROM raw_journeys_new
GROUP BY source_file
UNION ALL
SELECT 'weather',
    source_file,
    COUNT(*)
FROM raw_weather
GROUP BY source_file;
-- Windows line endings leave hideen \r on last column
-- If it returns >0 need to strip it in cleaning step
SELECT (
        SELECT COUNT(*)
        FROM raw_journeys_old
        WHERE start_station_name LIKE '%\r'
    ) AS old_cr,
    (
        SELECT COUNT(*)
        FROM raw_journeys_new
        WHERE total_duration_ms LIKE '%\r'
    ) AS new_cr,
    (
        SELECT COUNT(*)
        FROM raw_weather
        WHERE precipitation_hours LIKE '%\r'
    ) AS weather_cr;