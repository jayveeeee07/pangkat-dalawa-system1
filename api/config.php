<?php
/**
 * Database Configuration
 * 
 * This file contains database connection settings and configuration.
 * Update these values according to your environment.
 */

// Enable error reporting for debugging (disable in production)
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Database Configuration
define('DB_HOST', '127.0.0.1');      // MySQL host (use 127.0.0.1 instead of localhost)
define('DB_PORT', '3306');           // MySQL port
define('DB_NAME', 'pangkat_dalawa'); // Database name
define('DB_USER', 'pangkat_user');   // Database username
define('DB_PASS', 'password123');    // Database password

// Application Configuration
define('APP_NAME', 'Pangkat Dalawa System');
define('APP_VERSION', '1.0.0');
define('BASE_URL', 'http://127.0.0.1/pangkat-dalawa-system');

// Security Settings
define('SESSION_TIMEOUT', 3600);     // Session timeout in seconds (1 hour)
define('MAX_LOGIN_ATTEMPTS', 5);     // Maximum failed login attempts
define('PASSWORD_MIN_LENGTH', 6);    // Minimum password length

// File Upload Settings
define('MAX_FILE_SIZE', 5242880);    // 5MB max file size
define('ALLOWED_FILE_TYPES', ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx']);

// System Settings
define('DEBUG_MODE', true);          // Set to false in production
define('MAINTENANCE_MODE', false);   // Set to true for maintenance

// Create database connection
function getDatabaseConnection() {
    try {
        $dsn = "mysql:host=" . DB_HOST . ";port=" . DB_PORT . ";dbname=" . DB_NAME . ";charset=utf8mb4";
        
        $pdo = new PDO($dsn, DB_USER, DB_PASS, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
            PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4"
        ]);
        
        return $pdo;
        
    } catch (PDOException $e) {
        // Log error for debugging
        error_log("Database Connection Failed: " . $e->getMessage());
        
        // Return appropriate error message
        if (DEBUG_MODE) {
            die(json_encode([
                'success' => false,
                'message' => 'Database Connection Error: ' . $e->getMessage(),
                'error' => $e->getMessage()
            ]));
        } else {
            die(json_encode([
                'success' => false,
                'message' => 'Database connection failed. Please contact administrator.'
            ]));
        }
    }
}

// Set headers for API responses
function setHeaders() {
    header('Content-Type: application/json; charset=utf-8');
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
    header('Access-Control-Allow-Credentials: true');
    
    // Handle preflight requests
    if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
        http_response_code(200);
        exit();
    }
}

// Validate input data
function validateInput($data, $requiredFields = []) {
    $errors = [];
    
    foreach ($requiredFields as $field) {
        if (!isset($data[$field]) || empty(trim($data[$field]))) {
            $errors[] = "Field '$field' is required";
        }
    }
    
    return $errors;
}

// Sanitize input data
function sanitizeInput($data) {
    if (is_array($data)) {
        foreach ($data as $key => $value) {
            $data[$key] = sanitizeInput($value);
        }
        return $data;
    }
    
    // Remove whitespace
    $data = trim($data);
    
    // Convert special characters to HTML entities
    $data = htmlspecialchars($data, ENT_QUOTES, 'UTF-8');
    
    return $data;
}

// Generate random token
function generateToken($length = 32) {
    return bin2hex(random_bytes($length));
}

// Hash password (using bcrypt)
function hashPassword($password) {
    return password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);
}

// Verify password
function verifyPassword($password, $hash) {
    return password_verify($password, $hash);
}

// Log action to audit trail
function logAction($userId, $username, $action, $description, $ip = null, $userAgent = null) {
    try {
        $pdo = getDatabaseConnection();
        $stmt = $pdo->prepare("
            INSERT INTO audit_logs 
            (user_id, username, action, description, ip_address, user_agent) 
            VALUES (?, ?, ?, ?, ?, ?)
        ");
        
        $stmt->execute([
            $userId,
            $username,
            $action,
            $description,
            $ip ?: $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1',
            $userAgent ?: $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown'
        ]);
        
        return true;
    } catch (Exception $e) {
        error_log("Audit log error: " . $e->getMessage());
        return false;
    }
}

// Check if maintenance mode is enabled
if (MAINTENANCE_MODE && !defined('ALLOW_MAINTENANCE_ACCESS')) {
    http_response_code(503);
    die(json_encode([
        'success' => false,
        'message' => 'System is under maintenance. Please try again later.'
    ]));
}

// Set headers for all API calls
setHeaders();
?>
