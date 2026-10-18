-- =========================================================================
-- 01_schema_raw.sql
-- This creates the database and raw landing tables 
-- Every data column is TEXT so nothing is silently converted or rejected
-- on import; typing happens later in 04_clean.sql
-- =========================================================================
CREATE DATABASE IF NOT EXISTS bike_hire CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE bike_hire;
-- ------------------------------------------------------------------------
-- Old format journey files (before September 2022)
-- Header: Rental Id, Duration, Bike Id, End Date, EndStation Id, 
--         EndStation Name, Start Date, StartStation Id, StartStation Name
-- ------------------------------------------------------------------------
DROP TABLE IF EXISTS raw_journeys_old;
CREATE TABLE raw_journeys_old (
    load_id INT AUTO_INCREMENT PRIMARY KEY,
    -- row tracker, added by me
    rental_id TEXT,
    duration TEXT,
    -- seconds
    bike_id TEXT,
    end_date TEXT,
    end_station_id TEXT,
    -- dd/mm/yyyy hh:mm
    end_station_name TEXT,
    start_date TEXT,
    start_station_id TEXT,
    start_station_name TEXT,
    source_file VARCHAR(255),
    -- which CSV the row came from
    loaded_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
-- -------------------------------------------------------------------------
-- New format journey files (after september 2022)
-- Header: Number, Start date, Start station number, Start station,
--         End date, End station number, End station, Bike number,
--         Bike model, Total duration, Total duration (ms)
-- -------------------------------------------------------------------------
DROP TABLE IF EXISTS raw_journeys_new;
CREATE TABLE raw_journeys_new (
    load_id INT AUTO_INCREMENT PRIMARY KEY,
    journey_number TEXT,
    start_date TEXT,
    -- yyyy-mm-dd hh:mm
    start_station_number TEXT,
    -- Different ID system from old format
    start_station_name TEXT,
    end_date TEXT,
    end_station_number TEXT,
    end_station_name TEXT,
    bike_number TEXT,
    bike_model TEXT,
    -- e.g. Classic
    total_duration_text TEXT,
    total_duration_ms TEXT,
    source_file VARCHAR(255),
    loaded_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
-- -------------------------------------------------------------------------
-- Daily weather (Open-Meteo)
-- Header: time, temperature_2m_max (Celsius), temperature_2m_min,
--         precipitation_sum (mm), precipitaion_hours (h)
-- -------------------------------------------------------------------------
DROP TABLE IF EXISTS raw_weather;
CREATE TABLE raw_weather (
    load_id INT AUTO_INCREMENT PRIMARY KEY,
    weather_date TEXT,
    temp_max_c TEXT,
    temp_min_c TEXT,
    precipitation_mm TEXT,
    precipitation_hours TEXT,
    source_file VARCHAR(255),
    loaded_at DATETIME DEFAULT CURRENT_TIMESTAMP
);