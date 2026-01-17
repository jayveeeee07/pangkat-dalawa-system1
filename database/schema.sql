-- ============================================
-- Pangkat Dalawa Database Schema
-- ============================================

-- Create database
CREATE DATABASE IF NOT EXISTS pangkat_dalawa 
DEFAULT CHARACTER SET utf8mb4 
DEFAULT COLLATE utf8mb4_unicode_ci;

USE pangkat_dalawa;

-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(20),
    role ENUM('admin', 'member') NOT NULL DEFAULT 'member',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    INDEX idx_username (username),
    INDEX idx_role (role),
    INDEX idx_active (is_active)
);

-- ============================================
-- EXPENSES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS expenses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    month_year VARCHAR(7) NOT NULL COMMENT 'Format: YYYY-MM',
    category VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    paid_by VARCHAR(100),
    payment_date DATE NOT NULL,
    receipt_number VARCHAR(50),
    payment_method ENUM('cash', 'bank_transfer', 'gcash', 'paymaya', 'other') DEFAULT 'cash',
    status ENUM('pending', 'paid', 'cancelled', 'reimbursed') DEFAULT 'paid',
    notes TEXT,
    created_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_month (month_year),
    INDEX idx_category (category),
    INDEX idx_status (status)
);

-- ============================================
-- PENALTIES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS penalties (
    id INT AUTO_INCREMENT PRIMARY KEY,
    month_year VARCHAR(7) NOT NULL COMMENT 'Format: YYYY-MM',
    member_id INT NOT NULL,
    penalty_type VARCHAR(50) NOT NULL,
    description TEXT,
    amount DECIMAL(10,2) NOT NULL,
    status ENUM('pending', 'paid', 'waived', 'cancelled') DEFAULT 'pending',
    due_date DATE NOT NULL,
    paid_date DATE,
    payment_method ENUM('cash', 'bank_transfer', 'gcash', 'paymaya') DEFAULT 'cash',
    reference_number VARCHAR(100),
    notes TEXT,
    created_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (member_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_month (month_year),
    INDEX idx_member (member_id),
    INDEX idx_status (status)
);

-- ============================================
-- MONTHLY CONTRIBUTIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS monthly_contributions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    month_year VARCHAR(7) NOT NULL COMMENT 'Format: YYYY-MM',
    member_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_date DATE,
    payment_method ENUM('cash', 'bank_transfer', 'gcash', 'paymaya') DEFAULT 'cash',
    reference_number VARCHAR(100),
    status ENUM('pending', 'paid', 'partial', 'overdue') DEFAULT 'pending',
    verified_by INT,
    verified_at TIMESTAMP NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (member_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (verified_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_month (month_year),
    INDEX idx_member (member_id),
    INDEX idx_status (status)
);

-- ============================================
-- AUDIT LOGS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS audit_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    username VARCHAR(50),
    action VARCHAR(100) NOT NULL,
    table_name VARCHAR(50),
    record_id INT,
    old_value JSON,
    new_value JSON,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user (user_id),
    INDEX idx_action (action),
    INDEX idx_created (created_at)
);

-- ============================================
-- SYSTEM SETTINGS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS system_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(50) UNIQUE NOT NULL,
    setting_value TEXT,
    setting_type ENUM('string', 'number', 'boolean', 'json') DEFAULT 'string',
    description TEXT,
    updated_by INT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_key (setting_key)
);

-- ============================================
-- NOTIFICATIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    type ENUM('info', 'warning', 'error', 'success') DEFAULT 'info',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user (user_id),
    INDEX idx_read (is_read),
    INDEX idx_created (created_at)
);

-- ============================================
-- BACKUP HISTORY TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS backup_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    filename VARCHAR(255) NOT NULL,
    file_size BIGINT,
    backup_type ENUM('full', 'partial') DEFAULT 'full',
    status ENUM('success', 'failed', 'pending') DEFAULT 'success',
    notes TEXT,
    created_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_created (created_at),
    INDEX idx_status (status)
);

-- ============================================
-- INSERT DEFAULT ADMIN USER
-- ============================================
INSERT INTO users (username, password, full_name, email, role) VALUES
('admin', '$2y$10$YourHashedPasswordHere', 'System Administrator', 'admin@pangkatdalawa.com', 'admin'),
('marjhon', '$2y$10$AnotherHashedPassword', 'Marjhon Caringal', 'marjhon@example.com', 'member');

-- ============================================
-- INSERT DEFAULT SETTINGS
-- ============================================
INSERT INTO system_settings (setting_key, setting_value, setting_type, description) VALUES
('system_name', 'Pangkat Dalawa System', 'string', 'Name of the system'),
('version', '1.0.0', 'string', 'System version'),
('maintenance_mode', 'false', 'boolean', 'System maintenance mode'),
('default_password_length', '8', 'number', 'Default password length requirement'),
('max_login_attempts', '5', 'number', 'Maximum failed login attempts'),
('session_timeout', '3600', 'number', 'Session timeout in seconds');

-- ============================================
-- SAMPLE DATA
-- ============================================
INSERT INTO expenses (month_year, category, description, amount, paid_by, payment_date, status, created_by) VALUES
('2024-01', 'Utilities', 'Electricity bill for January', 2500.00, 'Admin', '2024-01-15', 'paid', 1),
('2024-01', 'Supplies', 'Office supplies purchase', 1500.00, 'Marjhon', '2024-01-10', 'paid', 2),
('2024-01', 'Food', 'Monthly meeting snacks', 3000.00, 'Admin', '2024-01-20', 'paid', 1);

INSERT INTO penalties (month_year, member_id, penalty_type, description, amount, status, due_date, created_by) VALUES
('2024-01', 2, 'Late Payment', 'Late monthly contribution', 100.00, 'paid', '2024-01-31', 1),
('2024-01', 2, 'Absence', 'Missed monthly meeting', 200.00, 'pending', '2024-01-31', 1);

INSERT INTO monthly_contributions (month_year, member_id, amount, payment_date, status) VALUES
('2024-01', 2, 500.00, '2024-01-05', 'paid'),
('2024-01', 2, 500.00, NULL, 'pending');

-- ============================================
-- CREATE TRIGGERS
-- ============================================

-- Trigger to update user's updated_at timestamp
DELIMITER $$
CREATE TRIGGER update_user_timestamp 
BEFORE UPDATE ON users 
FOR EACH ROW 
BEGIN
    SET NEW.updated_at = CURRENT_TIMESTAMP;
END$$
DELIMITER ;

-- Trigger to log user changes
DELIMITER $$
CREATE TRIGGER log_user_changes 
AFTER UPDATE ON users 
FOR EACH ROW 
BEGIN
    IF OLD.username != NEW.username OR OLD.role != NEW.role OR OLD.is_active != NEW.is_active THEN
        INSERT INTO audit_logs (user_id, username, action, table_name, record_id, old_value, new_value)
        VALUES (
            NEW.id,
            NEW.username,
            'UPDATE',
            'users',
            NEW.id,
            JSON_OBJECT('username', OLD.username, 'role', OLD.role, 'is_active', OLD.is_active),
            JSON_OBJECT('username', NEW.username, 'role', NEW.role, 'is_active', NEW.is_active)
        );
    END IF;
END$$
DELIMITER ;

-- ============================================
-- CREATE VIEWS
-- ============================================

-- View for monthly summary
CREATE OR REPLACE VIEW monthly_summary AS
SELECT 
    m.month_year,
    COUNT(DISTINCT m.member_id) as total_members,
    SUM(m.amount) as total_contributions,
    SUM(CASE WHEN m.status = 'paid' THEN m.amount ELSE 0 END) as paid_contributions,
    SUM(CASE WHEN m.status = 'pending' THEN m.amount ELSE 0 END) as pending_contributions,
    COUNT(DISTINCT p.member_id) as members_with_penalties,
    SUM(p.amount) as total_penalties,
    SUM(e.amount) as total_expenses,
    (SUM(CASE WHEN m.status = 'paid' THEN m.amount ELSE 0 END) + 
     SUM(CASE WHEN p.status = 'paid' THEN p.amount ELSE 0 END) - 
     SUM(e.amount)) as monthly_balance
FROM monthly_contributions m
LEFT JOIN penalties p ON m.month_year = p.month_year AND p.status = 'paid'
LEFT JOIN expenses e ON m.month_year = e.month_year AND e.status = 'paid'
GROUP BY m.month_year
ORDER BY m.month_year DESC;

-- View for member financial summary
CREATE OR REPLACE VIEW member_financial_summary AS
SELECT 
    u.id as member_id,
    u.username,
    u.full_name,
    COUNT(DISTINCT mc.month_year) as total_months,
    SUM(mc.amount) as total_contributions,
    SUM(CASE WHEN mc.status = 'paid' THEN mc.amount ELSE 0 END) as paid_contributions,
    COUNT(DISTINCT p.id) as total_penalties,
    SUM(p.amount) as total_penalty_amount,
    SUM(CASE WHEN p.status = 'paid' THEN p.amount ELSE 0 END) as paid_penalties
FROM users u
LEFT JOIN monthly_contributions mc ON u.id = mc.member_id
LEFT JOIN penalties p ON u.id = p.member_id
WHERE u.role = 'member'
GROUP BY u.id, u.username, u.full_name;

-- ============================================
-- CREATE STORED PROCEDURES
-- ============================================

-- Procedure to get monthly report
DELIMITER $$
CREATE PROCEDURE GetMonthlyReport(IN p_month VARCHAR(7))
BEGIN
    SELECT 
        m.month_year,
        u.full_name,
        m.amount as contribution,
        m.status as contribution_status,
        m.payment_date,
        COALESCE(SUM(p.amount), 0) as penalties,
        COUNT(p.id) as penalty_count
    FROM monthly_contributions m
    JOIN users u ON m.member_id = u.id
    LEFT JOIN penalties p ON m.member_id = p.member_id AND m.month_year = p.month_year
    WHERE m.month_year = p_month
    GROUP BY m.id, u.full_name, m.amount, m.status, m.payment_date
    ORDER BY u.full_name;
END$$
DELIMITER ;

-- Procedure to calculate monthly totals
DELIMITER $$
CREATE PROCEDURE CalculateMonthlyTotals(IN p_month VARCHAR(7))
BEGIN
    DECLARE total_contributions DECIMAL(12,2);
    DECLARE total_expenses DECIMAL(12,2);
    DECLARE total_penalties DECIMAL(12,2);
    DECLARE net_balance DECIMAL(12,2);
    
    -- Calculate contributions
    SELECT COALESCE(SUM(amount), 0) INTO total_contributions
    FROM monthly_contributions 
    WHERE month_year = p_month AND status = 'paid';
    
    -- Calculate expenses
    SELECT COALESCE(SUM(amount), 0) INTO total_expenses
    FROM expenses 
    WHERE month_year = p_month AND status = 'paid';
    
    -- Calculate penalties
    SELECT COALESCE(SUM(amount), 0) INTO total_penalties
    FROM penalties 
    WHERE month_year = p_month AND status = 'paid';
    
    -- Calculate net balance
    SET net_balance = total_contributions + total_penalties - total_expenses;
    
    -- Return results
    SELECT 
        p_month as month,
        total_contributions,
        total_expenses,
        total_penalties,
        net_balance,
        CASE 
            WHEN net_balance > 0 THEN 'Surplus'
            WHEN net_balance < 0 THEN 'Deficit'
            ELSE 'Balanced'
        END as financial_status;
END$$
DELIMITER ;

-- ============================================
-- CREATE DATABASE USER AND GRANT PRIVILEGES
-- ============================================
-- Note: Run these commands separately in MySQL client

-- CREATE USER IF NOT EXISTS 'pangkat_user'@'localhost' IDENTIFIED BY 'password123';
-- GRANT ALL PRIVILEGES ON pangkat_dalawa.* TO 'pangkat_user'@'localhost';
-- FLUSH PRIVILEGES;

-- ============================================
-- COMMENTS AND NOTES
-- ============================================
/*
IMPORTANT NOTES:
1. Default admin password needs to be hashed using password_hash() in PHP
2. Run this script in MySQL Workbench or phpMyAdmin
3. Make sure to update the admin password hash after running
4. Test all foreign key relationships
5. Regular database backups are recommended
*/
