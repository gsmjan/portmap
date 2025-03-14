#!/bin/bash

# Exit on error
set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

# Install required packages
echo "Installing required packages..."
apt-get update
apt-get install -y apache2 php php-mysql mysql-server

# Configure MySQL
echo "Configuring MySQL..."
mysql_secure_installation << EOF
y
your_secure_password
your_secure_password
y
y
y
y
EOF

# Create database and user
echo "Creating database and user..."
mysql -u root -p'your_secure_password' << EOF
CREATE DATABASE IF NOT EXISTS openvpn_admin;
CREATE USER IF NOT EXISTS 'openvpn_admin'@'localhost' IDENTIFIED BY 'your_secure_password';
GRANT ALL PRIVILEGES ON openvpn_admin.* TO 'openvpn_admin'@'localhost';
FLUSH PRIVILEGES;
EOF

# Create web interface files
echo "Creating web interface files..."
cat > /var/www/html/config.php << 'EOL'
<?php
// Database configuration
define('DB_HOST', 'localhost');
define('DB_NAME', 'openvpn_admin');
define('DB_USER', 'openvpn_admin');
define('DB_PASS', 'your_secure_password');

try {
    $pdo = new PDO(
        "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME,
        DB_USER,
        DB_PASS,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false
        ]
    );
} catch (PDOException $e) {
    die("Connection failed: " . $e->getMessage());
}

// Create users table if it doesn't exist
$pdo->exec("CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)");

// Create default admin user if it doesn't exist
$stmt = $pdo->prepare("SELECT id FROM users WHERE username = ?");
$stmt->execute(['admin']);
if (!$stmt->fetch()) {
    $stmt = $pdo->prepare("INSERT INTO users (username, password) VALUES (?, ?)");
    $stmt->execute(['admin', password_hash('admin123', PASSWORD_DEFAULT)]);
}
EOL

# Set proper permissions
echo "Setting proper permissions..."
chown -R www-data:www-data /var/www/html
chmod 755 /var/www/html
chmod 644 /var/www/html/config.php

# Configure Apache
echo "Configuring Apache..."
cat > /etc/apache2/sites-available/openvpn-admin.conf << 'EOL'
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html

    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL

# Enable the site
a2ensite openvpn-admin.conf
a2enmod rewrite
systemctl restart apache2

echo "Web interface setup complete!"
echo "Access the web interface at http://your-server-ip/"
echo "Default credentials:"
echo "Username: admin"
echo "Password: admin123" 