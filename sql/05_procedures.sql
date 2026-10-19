-- =======================================================================
-- 05_procedures.sql
-- Run after 04. Run it from the terminal. DELIMITER needs mysql client
--  mysql -u root -p bike_hire < sql/05_procedures_events.sql
-- =======================================================================
USE bike_hire;
DROP TRIGGER IF EXISTS trg_reject_bad_journeys;
DROP PROCEDURE IF EXISTS sp_build_daily_summary;
DROP EVENT IF EXISTS ev_refresh_daily_summary;
DELIMITER $$ -- =======================================================================
-- Create a trigger to stop bad rows from getting into clean_journeys 
-- in future loads
-- =======================================================================
CREATE TRIGGER trg_reject_bad_journeys BEFORE
INSERT ON clean_journeys FOR EACH ROW BEGIN IF NEW.duration_s < 60
    OR NEW.end_time < NEW.start_time THEN SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'Rejected: journey under 60s or ends before it starts'
END IF;
END $$ 
-- =======================================================================
-- Create a stored procedure that rebuilds a one-row-per-day summary
-- JOINing daily journey counts to the weather
-- =======================================================================
CREATE PROCEDURE sp_build_daily_summary() BEGIN DROP TABLE IF EXISTS daily_summary;
CREATE TABLE daily_summary AS
SELECT d.journey_date,
    DAYNAME(d.journey_date) AS day_name,
    d.journeys,
    w.temp_max_c,
    w.precipitation_mm,
    w.is_wet_day
FROM (
        SELECT DATE(start_time) AS journey_date,
            COUNT(*) AS journeys
        FROM clean_journeys
        GROUP BY DATE(start_time)
    ) AS d
    JOIN clean_weather w ON w.weather_date = d.journey_date;
END $$ DELIMITER;

-- =======================================================================
-- Create an event. Refresh the summary every day, ready for new weekly
-- files.
-- =======================================================================
SET GLOBAL event_scheduler = ON;

CREATE EVENT ev_refresh_daily_summary
ON SCHEDULE EVERY 1 DAY 
STARTS CURRENT_DATE + INTERVAL 1 DAY + INTERVAL 6 HOUR
DO CALL sp_build_daily_summary();

-- Build the event and check
CALL sp_build_daily_summary();
SELECT COUNT(*) AS summary_days FROM daily_summary;
SHOW EVENTS;

-- Test the trigger by hand. This should fail with the 'Rejected' message
-- -- INSERT INTO clean_journeys VALUES (1, 'tst', '2022-10-01 09:00', '2022-10-01 09:00', 30, 'A', 'B', 0);