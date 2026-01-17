<?php
/**
 * Authentication API
 * 
 * Handles user login, registration, and authentication
 */

require_once 'config.php';

// Get request method
$method = $_SERVER['REQUEST_METHOD'];

// Handle preflight requests
if ($method == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Get request data
$input = json_decode(file_get_contents('php://input'), true);
$action = $input['action'] ?? $_GET['action'] ?? '';

try {
    $pdo = getDatabaseConnection();
    
    switch ($method) {
        case 'POST':
            handlePostRequest($pdo, $action, $input);
            break;
            
        case 'GET':
            handleGetRequest($pdo, $action);
            break;
            
        default:
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error: ' . $e->getMessage()
    ]);
}

/**
 * Handle POST requests
 */
function handlePostRequest($pdo, $action, $data) {
    switch ($action) {
        case 'login':
            handleLogin($pdo, $data);
            break;
            
        case 'register':
            handleRegister($pdo, $data);
            break;
            
        case 'logout':
            handleLogout();
            break;
            
        case 'validate':
            validateSession($pdo, $data);
            break;
            
        default:
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Invalid action']);
    }
}

/**
 * Handle GET requests
 */
function handleGetRequest($pdo, $action) {
    switch ($action) {
        case 'check':
            checkAuthStatus();
            break;
            
        case 'users':
            getUsers($pdo);
            break;
            
        default:
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Invalid action']);
    }
}

/**
 * Handle user login
 */
function handleLogin($pdo, $data) {
    // Validate input
    $errors = validateInput($data, ['username', 'password']);
    if (!empty($errors)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => implode(', ', $errors)]);
        return;
    }
    
    $username = sanitizeInput($data['username']);
    $password = $data['password'];
    
    try {
        // Check if user exists and is active
        $stmt = $pdo->prepare("
            SELECT id, username, password, full_name, role, is_active, last_login 
            FROM users 
            WHERE username = ? AND is_active = 1
        ");
        $stmt->execute([$username]);
        $user = $stmt->fetch();
        
        if (!$user) {
            echo json_encode([
                'success' => false,
                'message' => 'Invalid username or password'
            ]);
            return;
        }
        
        // Verify password
        if (!verifyPassword($password, $user['password'])) {
            echo json_encode([
                'success' => false,
                'message' => 'Invalid username or password'
            ]);
            return;
        }
        
        // Update last login
        $updateStmt = $pdo->prepare("UPDATE users SET last_login = NOW() WHERE id = ?");
        $updateStmt->execute([$user['id']]);
        
        // Log the action
        logAction(
            $user['id'],
            $user['username'],
            'login',
            'User logged in successfully',
            $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1',
            $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown'
        );
        
        // Return user data (excluding password)
        unset($user['password']);
        
        echo json_encode([
            'success' => true,
            'message' => 'Login successful',
            'user' => $user,
            'token' => generateToken()
        ]);
        
    } catch (Exception $e) {
        error_log("Login error: " . $e->getMessage());
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Login failed. Please try again.'
        ]);
    }
}

/**
 * Handle user registration
 */
function handleRegister($pdo, $data) {
    // Validate input
    $errors = validateInput($data, ['username', 'password', 'full_name']);
    if (!empty($errors)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => implode(', ', $errors)]);
        return;
    }
    
    $username = sanitizeInput($data['username']);
    $password = $data['password'];
    $fullName = sanitizeInput($data['full_name']);
    $email = isset($data['email']) ? sanitizeInput($data['email']) : null;
    $phone = isset($data['phone']) ? sanitizeInput($data['phone']) : null;
    
    // Validate password length
    if (strlen($password) < PASSWORD_MIN_LENGTH) {
        echo json_encode([
            'success' => false,
            'message' => 'Password must be at least ' . PASSWORD_MIN_LENGTH . ' characters'
        ]);
        return;
    }
    
    // Prevent registering as admin
    if (strtolower($username) === 'admin') {
        echo json_encode([
            'success' => false,
            'message' => 'Cannot register as admin'
        ]);
        return;
    }
    
    try {
        // Check if username already exists
        $checkStmt = $pdo->prepare("SELECT id FROM users WHERE username = ?");
        $checkStmt->execute([$username]);
        
        if ($checkStmt->rowCount() > 0) {
            echo json_encode([
                'success' => false,
                'message' => 'Username already exists'
            ]);
            return;
        }
        
        // Hash password
        $hashedPassword = hashPassword($password);
        
        // Insert new user
        $stmt = $pdo->prepare("
            INSERT INTO users (username, password, full_name, email, phone, role) 
            VALUES (?, ?, ?, ?, ?, 'member')
        ");
        
        $stmt->execute([$username, $hashedPassword, $fullName, $email, $phone]);
        $userId = $pdo->lastInsertId();
        
        // Log the action
        logAction(
            $userId,
            $username,
            'register',
            'New user registered: ' . $fullName,
            $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1',
            $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown'
        );
        
        echo json_encode([
            'success' => true,
            'message' => 'Registration successful! You can now login.',
            'user_id' => $userId
        ]);
        
    } catch (Exception $e) {
        error_log("Registration error: " . $e->getMessage());
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Registration failed. Please try again.'
        ]);
    }
}

/**
 * Handle user logout
 */
function handleLogout() {
    // Get user from request
    $data = json_decode(file_get_contents('php://input'), true);
    $userId = $data['user_id'] ?? null;
    $username = $data['username'] ?? null;
    
    if ($userId && $username) {
        // Log the action
        logAction(
            $userId,
            $username,
            'logout',
            'User logged out',
            $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1',
            $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown'
        );
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Logged out successfully'
    ]);
}

/**
 * Validate user session
 */
function validateSession($pdo, $data) {
    $userId = $data['user_id'] ?? null;
    $username = $data['username'] ?? null;
    
    if (!$userId || !$username) {
        echo json_encode(['success' => false, 'message' => 'Session invalid']);
        return;
    }
    
    try {
        $stmt = $pdo->prepare("
            SELECT id, username, full_name, role, is_active 
            FROM users 
            WHERE id = ? AND username = ? AND is_active = 1
        ");
        $stmt->execute([$userId, $username]);
        $user = $stmt->fetch();
        
        if ($user) {
            unset($user['password']);
            echo json_encode([
                'success' => true,
                'user' => $user
            ]);
        } else {
            echo json_encode(['success' => false, 'message' => 'Session expired']);
        }
        
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Session validation failed']);
    }
}

/**
 * Check authentication status
 */
function checkAuthStatus() {
    echo json_encode([
        'success' => true,
        'authenticated' => false,
        'timestamp' => date('Y-m-d H:i:s')
    ]);
}

/**
 * Get all users (admin only)
 */
function getUsers($pdo) {
    try {
        $stmt = $pdo->query("
            SELECT id, username, full_name, email, phone, role, 
                   created_at, last_login, is_active 
            FROM users 
            ORDER BY created_at DESC
        ");
        $users = $stmt->fetchAll();
        
        echo json_encode([
            'success' => true,
            'users' => $users,
            'count' => count($users)
        ]);
        
    } catch (Exception $e) {
        error_log("Get users error: " . $e->getMessage());
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Failed to fetch users'
        ]);
    }
}
?>
