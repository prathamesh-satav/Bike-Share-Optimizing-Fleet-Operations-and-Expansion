-- =============================================
-- 1. DATABASE SETUP
-- =============================================
-- Create the schema
DROP TABLE IF EXISTS trips;
DROP TABLE IF EXISTS weather;
DROP TABLE IF EXISTS stations;

CREATE TABLE stations (
    station_id INT PRIMARY KEY,
    station_name VARCHAR(100),
    district VARCHAR(50),
    latitude DECIMAL(10, 6),
    longitude DECIMAL(10, 6),
    capacity INT,
    deployment_date DATE
);

CREATE TABLE weather (
    date DATE PRIMARY KEY,
    temperature_f DECIMAL(5, 2),
    condition VARCHAR(50),
    ridership_factor DECIMAL(5, 2)
);

CREATE TABLE trips (
    trip_id BIGINT PRIMARY KEY,
    bike_id INT,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    start_station_id INT,
    end_station_id INT,
    user_type VARCHAR(20),
    duration_minutes INT,
    FOREIGN KEY (start_station_id) REFERENCES stations(station_id),
    FOREIGN KEY (end_station_id) REFERENCES stations(station_id)
);

-- =============================================
-- 2. DATA IMPORT (CORRECTED)
-- =============================================
-- Fixes applied:
-- 1. Changed backslashes (\) to forward slashes (/) to prevent escape character errors.
-- 2. Added explicit 'DELIMITER' keyword before the comma.

COPY stations FROM 'C:/temp/stations.csv' DELIMITER ',' CSV HEADER;

COPY weather FROM 'C:/temp/weather.csv' DELIMITER ',' CSV HEADER;

COPY trips FROM 'C:/temp/trips.csv' DELIMITER ',' CSV HEADER;

-- =============================================-- =============================================
-- 1. DATABASE SETUP
-- =============================================
-- Create the schema
DROP TABLE IF EXISTS trips;
DROP TABLE IF EXISTS weather;
DROP TABLE IF EXISTS stations;

CREATE TABLE stations (
    station_id INT PRIMARY KEY,
    station_name VARCHAR(100),
    district VARCHAR(50),
    latitude DECIMAL(10, 6),
    longitude DECIMAL(10, 6),
    capacity INT,
    deployment_date DATE
);

CREATE TABLE weather (
    date DATE PRIMARY KEY,
    temperature_f DECIMAL(5, 2),
    condition VARCHAR(50),
    ridership_factor DECIMAL(5, 2)
);

CREATE TABLE trips (
    trip_id BIGINT PRIMARY KEY,
    bike_id INT,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    start_station_id INT,
    end_station_id INT,
    user_type VARCHAR(20),
    duration_minutes INT,
    FOREIGN KEY (start_station_id) REFERENCES stations(station_id),
    FOREIGN KEY (end_station_id) REFERENCES stations(station_id)
);

-- =============================================
-- 2. DATA IMPORT (UPDATED FOR PERMISSIONS)
-- =============================================
-- INSTRUCTION: 
-- 1. Create a folder named 'Temp' directly on your C: drive (C:\Temp)
-- 2. Move your 3 CSV files into that folder.
-- This bypasses the Windows permission issues with the Desktop folder.

COPY stations FROM 'C:/Temp/stations.csv' DELIMITER ',' CSV HEADER;

COPY weather FROM 'C:/Temp/weather.csv' DELIMITER ',' CSV HEADER;

COPY trips FROM 'C:/Temp/trips.csv' DELIMITER ',' CSV HEADER;

-- =============================================
-- 3. ANALYTICAL VIEWS FOR POWER BI
-- =============================================

-- A. HOURLY STATION ACTIVITY (The "Pulse" of the network)
CREATE OR REPLACE VIEW v_hourly_station_flow AS
WITH hourly_stats AS (
    SELECT 
        DATE_TRUNC('hour', start_time) as hour_bucket,
        start_station_id as station_id,
        COUNT(*) as trips_out,
        0 as trips_in
    FROM trips
    GROUP BY 1, 2
    UNION ALL
    SELECT 
        DATE_TRUNC('hour', end_time) as hour_bucket,
        end_station_id as station_id,
        0 as trips_out,
        COUNT(*) as trips_in
    FROM trips
    GROUP BY 1, 2
)
SELECT 
    h.hour_bucket,
    h.station_id,
    s.station_name,
    s.district,
    SUM(h.trips_out) as total_out,
    SUM(h.trips_in) as total_in,
    (SUM(h.trips_in) - SUM(h.trips_out)) as net_flow
FROM hourly_stats h
JOIN stations s ON h.station_id = s.station_id
GROUP BY 1, 2, 3, 4;

-- B. REBALANCING ALERTS (Advanced)
CREATE OR REPLACE VIEW v_rebalancing_alerts AS
SELECT 
    s.station_name,
    s.district,
    s.capacity,
    -- Calculate AM Rush Hour (7-9 AM) Outflows
    SUM(CASE WHEN EXTRACT(HOUR FROM t.start_time) BETWEEN 7 AND 9 THEN 1 ELSE 0 END) as am_rush_outflows,
    -- Calculate AM Rush Hour Inflows
    SUM(CASE WHEN EXTRACT(HOUR FROM t.end_time) BETWEEN 7 AND 9 THEN 1 ELSE 0 END) as am_rush_inflows,
    
    -- Risk Score: If outflows >>> inflows + capacity buffer, station risks emptying
    CASE 
        WHEN SUM(CASE WHEN EXTRACT(HOUR FROM t.start_time) BETWEEN 7 AND 9 THEN 1 ELSE 0 END) > 
             (s.capacity * 0.8 + SUM(CASE WHEN EXTRACT(HOUR FROM t.end_time) BETWEEN 7 AND 9 THEN 1 ELSE 0 END)) 
        THEN 'High Risk: Empty'
        WHEN SUM(CASE WHEN EXTRACT(HOUR FROM t.end_time) BETWEEN 7 AND 9 THEN 1 ELSE 0 END) > 
             (s.capacity * 0.9)
        THEN 'High Risk: Full'
        ELSE 'Normal'
    END as am_rush_status
FROM stations s
JOIN trips t ON s.station_id = t.start_station_id OR s.station_id = t.end_station_id
GROUP BY s.station_id, s.station_name, s.district, s.capacity;

-- C. ROUTE POPULARITY
CREATE OR REPLACE VIEW v_popular_routes AS
SELECT 
    t.start_station_id,
    s1.station_name as start_name,
    s1.latitude as start_lat,
    s1.longitude as start_lon,
    t.end_station_id,
    s2.station_name as end_name,
    s2.latitude as end_lat,
    s2.longitude as end_lon,
    COUNT(*) as trip_count,
    AVG(t.duration_minutes) as avg_duration
FROM trips t
JOIN stations s1 ON t.start_station_id = s1.station_id
JOIN stations s2 ON t.end_station_id = s2.station_id
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
HAVING COUNT(*) > 50 
ORDER BY trip_count DESC;
-- 3. ANALYTICAL VIEWS FOR POWER BI
-- =============================================

-- A. HOURLY STATION ACTIVITY (The "Pulse" of the network)
CREATE OR REPLACE VIEW v_hourly_station_flow AS
WITH hourly_stats AS (
    SELECT 
        DATE_TRUNC('hour', start_time) as hour_bucket,
        start_station_id as station_id,
        COUNT(*) as trips_out,
        0 as trips_in
    FROM trips
    GROUP BY 1, 2
    UNION ALL
    SELECT 
        DATE_TRUNC('hour', end_time) as hour_bucket,
        end_station_id as station_id,
        0 as trips_out,
        COUNT(*) as trips_in
    FROM trips
    GROUP BY 1, 2
)
SELECT 
    h.hour_bucket,
    h.station_id,
    s.station_name,
    s.district,
    SUM(h.trips_out) as total_out,
    SUM(h.trips_in) as total_in,
    (SUM(h.trips_in) - SUM(h.trips_out)) as net_flow
FROM hourly_stats h
JOIN stations s ON h.station_id = s.station_id
GROUP BY 1, 2, 3, 4;

-- B. REBALANCING ALERTS (Advanced)
CREATE OR REPLACE VIEW v_rebalancing_alerts AS
SELECT 
    s.station_name,
    s.district,
    s.capacity,
    -- Calculate AM Rush Hour (7-9 AM) Outflows
    SUM(CASE WHEN EXTRACT(HOUR FROM t.start_time) BETWEEN 7 AND 9 THEN 1 ELSE 0 END) as am_rush_outflows,
    -- Calculate AM Rush Hour Inflows
    SUM(CASE WHEN EXTRACT(HOUR FROM t.end_time) BETWEEN 7 AND 9 THEN 1 ELSE 0 END) as am_rush_inflows,
    
    -- Risk Score: If outflows >>> inflows + capacity buffer, station risks emptying
    CASE 
        WHEN SUM(CASE WHEN EXTRACT(HOUR FROM t.start_time) BETWEEN 7 AND 9 THEN 1 ELSE 0 END) > 
             (s.capacity * 0.8 + SUM(CASE WHEN EXTRACT(HOUR FROM t.end_time) BETWEEN 7 AND 9 THEN 1 ELSE 0 END)) 
        THEN 'High Risk: Empty'
        WHEN SUM(CASE WHEN EXTRACT(HOUR FROM t.end_time) BETWEEN 7 AND 9 THEN 1 ELSE 0 END) > 
             (s.capacity * 0.9)
        THEN 'High Risk: Full'
        ELSE 'Normal'
    END as am_rush_status
FROM stations s
JOIN trips t ON s.station_id = t.start_station_id OR s.station_id = t.end_station_id
GROUP BY s.station_id, s.station_name, s.district, s.capacity;

-- C. ROUTE POPULARITY
CREATE OR REPLACE VIEW v_popular_routes AS
SELECT 
    t.start_station_id,
    s1.station_name as start_name,
    s1.latitude as start_lat,
    s1.longitude as start_lon,
    t.end_station_id,
    s2.station_name as end_name,
    s2.latitude as end_lat,
    s2.longitude as end_lon,
    COUNT(*) as trip_count,
    AVG(t.duration_minutes) as avg_duration
FROM trips t
JOIN stations s1 ON t.start_station_id = s1.station_id
JOIN stations s2 ON t.end_station_id = s2.station_id
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
HAVING COUNT(*) > 50 
ORDER BY trip_count DESC;