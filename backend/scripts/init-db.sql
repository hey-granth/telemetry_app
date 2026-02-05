-- Initialize database extensions and configuration
-- This script runs automatically when PostgreSQL container starts

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable pg_trgm for text search (optional)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Set timezone
SET timezone = 'UTC';

-- Grant permissions (if needed)
-- GRANT ALL PRIVILEGES ON DATABASE telemetry_db TO telemetry;
