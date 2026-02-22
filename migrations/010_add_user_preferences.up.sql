-- =============================================================================
-- Migration 010: Add User Preferences Table
-- Creates a table to store user preferences and settings
-- =============================================================================
-- id: 010
-- author: deepakrajoptisol-ops
-- risk: low
-- allowDestructive: false
-- labels: feature,user-preferences
-- contexts: dev,prod

-- Create user preferences table
CREATE TABLE user_preferences (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    preference_key VARCHAR(100) NOT NULL,
    preference_value TEXT,
    data_type ENUM('string', 'number', 'boolean', 'json') DEFAULT 'string',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE KEY uk_user_preference (user_id, preference_key),
    INDEX idx_user_preferences_user (user_id),
    INDEX idx_user_preferences_key (preference_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert sample preferences
INSERT INTO user_preferences (user_id, preference_key, preference_value, data_type) VALUES
(1, 'theme', 'dark', 'string'),
(1, 'notifications_enabled', 'true', 'boolean'),
(1, 'dashboard_layout', '{"widgets": ["orders", "customers"], "columns": 2}', 'json'),
(2, 'theme', 'light', 'string'),
(2, 'notifications_enabled', 'false', 'boolean'),
(3, 'language', 'en-US', 'string'),
(3, 'timezone', 'America/New_York', 'string');