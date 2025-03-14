# OpenVPN Server Setup

A complete OpenVPN server setup with web-based client management interface.

## Features

- Secure OpenVPN server configuration
- Web-based client management interface
- User authentication system
- Automatic client certificate generation
- Real-time client status monitoring
- Secure credential storage

## Prerequisites

- Ubuntu/Debian server
- Root access
- OpenSSL
- PHP 7.4+
- MySQL/MariaDB
- Apache/Nginx

## Directory Structure

```
openvpn-server/
├── scripts/           # Server setup and management scripts
├── configs/          # OpenVPN configuration files
├── web/             # Web interface files
└── ssl/             # SSL certificates and keys
```

## Quick Start

1. Clone the repository:
```bash
git clone https://github.com/yourusername/openvpn-server.git
cd openvpn-server
```

2. Make the setup script executable:
```bash
chmod +x scripts/setup-server.sh
```

3. Run the setup script:
```bash
sudo ./scripts/setup-server.sh
```

4. Configure the web interface:
```bash
sudo ./scripts/setup-web.sh
```

5. Access the web interface:
- URL: https://your-server-ip/
- Default credentials:
  - Username: admin
  - Password: admin123

## Manual Setup

### 1. Server Setup

```bash
# Install required packages
sudo apt-get update
sudo apt-get install -y openvpn easy-rsa ufw

# Configure firewall
sudo ufw allow 1194/udp
sudo ufw allow OpenSSH
sudo ufw enable

# Enable IP forwarding
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### 2. Certificate Generation

```bash
# Generate CA certificate
cd /etc/openvpn/easy-rsa
./easyrsa init-pki
./easyrsa build-ca

# Generate server certificate
./easyrsa gen-req server nopass
./easyrsa sign-req server server

# Generate Diffie-Hellman parameters
./easyrsa gen-dh
```

### 3. Web Interface Setup

```bash
# Install web server and PHP
sudo apt-get install -y apache2 php php-mysql mysql-server

# Configure database
sudo mysql_secure_installation
mysql -u root -p
CREATE DATABASE openvpn_admin;
CREATE USER 'openvpn_admin'@'localhost' IDENTIFIED BY 'your_secure_password';
GRANT ALL PRIVILEGES ON openvpn_admin.* TO 'openvpn_admin'@'localhost';
FLUSH PRIVILEGES;
```

## Security Considerations

1. Change default credentials immediately after setup
2. Use strong passwords for all user accounts
3. Keep the server and all components updated
4. Regularly rotate certificates
5. Monitor server logs for suspicious activity

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, please open an issue in the GitHub repository or contact the maintainers. 