-- ============================================================================
-- Illinois Crime Analytics Database Schema
-- Author: Rakesh Budige
-- Date: January 2025
-- Database: PostgreSQL 14+
-- Purpose: Store and analyze Illinois crime data from ISP I-UCR
-- ============================================================================

-- Drop tables if they exist (for clean rebuild)
DROP TABLE IF EXISTS crime_forecasts CASCADE;
DROP TABLE IF EXISTS crime_incidents CASCADE;
DROP TABLE IF EXISTS counties CASCADE;

-- ============================================================================
-- TABLE: counties
-- Purpose: Dimension table for Illinois counties
-- ============================================================================
CREATE TABLE counties (
    county_id SERIAL PRIMARY KEY,
    county_name VARCHAR(100) NOT NULL UNIQUE,
    population INTEGER NOT NULL CHECK (population > 0),
    region VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index for faster lookups
CREATE INDEX idx_counties_name ON counties(county_name);

COMMENT ON TABLE counties IS 'Illinois counties with population data';
COMMENT ON COLUMN counties.region IS 'Geographic region (Chicagoland, Downstate, etc.)';

-- ============================================================================
-- TABLE: crime_incidents
-- Purpose: Fact table for crime incidents
-- ============================================================================
CREATE TABLE crime_incidents (
    incident_id SERIAL PRIMARY KEY,
    county_id INTEGER NOT NULL REFERENCES counties(county_id),
    incident_date DATE NOT NULL,
    crime_type VARCHAR(100) NOT NULL,
    incident_count INTEGER NOT NULL CHECK (incident_count >= 0),
    cleared_count INTEGER CHECK (cleared_count >= 0),
    clearance_flag BOOLEAN GENERATED ALWAYS AS (cleared_count > 0) STORED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for query optimization
CREATE INDEX idx_crime_date ON crime_incidents(incident_date);
CREATE INDEX idx_crime_county ON crime_incidents(county_id);
CREATE INDEX idx_crime_type ON crime_incidents(crime_type);
CREATE INDEX idx_crime_composite ON crime_incidents(county_id, incident_date, crime_type);

COMMENT ON TABLE crime_incidents IS 'Crime incident records from Illinois State Police I-UCR';
COMMENT ON COLUMN crime_incidents.clearance_flag IS 'Automatically set to TRUE if any crimes cleared';

-- ============================================================================
-- TABLE: crime_forecasts
-- Purpose: Store ARIMA model predictions
-- ============================================================================
CREATE TABLE crime_forecasts (
    forecast_id SERIAL PRIMARY KEY,
    county_id INTEGER NOT NULL REFERENCES counties(county_id),
    forecast_date DATE NOT NULL,
    crime_type VARCHAR(100) NOT NULL,
    predicted_count DECIMAL(10,2) NOT NULL,
    confidence_low DECIMAL(10,2),
    confidence_high DECIMAL(10,2),
    model_version VARCHAR(50) DEFAULT 'ARIMA(2,1,2)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_forecast_county_date ON crime_forecasts(county_id, forecast_date);

COMMENT ON TABLE crime_forecasts IS 'ARIMA time-series forecasts for crime incidents';
COMMENT ON COLUMN crime_forecasts.model_version IS 'ARIMA parameters used for this forecast';

-- ============================================================================
-- GRANT PERMISSIONS (adjust as needed for your environment)
-- ============================================================================
-- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO data_analyst;

-- ============================================================================
-- SAMPLE DATA INSERT (for testing)
-- ============================================================================

-- Insert sample counties
INSERT INTO counties (county_name, population, region) VALUES
    ('Cook', 5173363, 'Chicagoland'),
    ('DuPage', 932877, 'Chicagoland'),
    ('Lake', 714342, 'Chicagoland'),
    ('Sangamon', 196778, 'Downstate');

COMMENT ON SCHEMA public IS 'Illinois Crime Analytics Database - Production Ready';
