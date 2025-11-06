-- Fix the point_type column size to accommodate all enum values
-- The longest enum value is "INTERMEDIATE" (11 characters)

-- Update the column to allow for longer enum values
ALTER TABLE point_gps MODIFY COLUMN point_type VARCHAR(20);

-- Verify the change
DESCRIBE point_gps;














