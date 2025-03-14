#!/bin/bash

# Update system
apt-get update
apt-get upgrade -y

# Install OpenVPN and required packages
apt-get install -y openvpn easy-rsa ufw

# Create directory for certificates
mkdir -p /etc/openvpn/certs
cd /etc/openvpn/certs

# Generate CA key and certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ca.key -out ca.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=OpenVPN-CA"

# Generate server key and certificate
openssl req -newkey rsa:2048 -nodes -keyout server.key \
    -out server.csr \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=OpenVPN-Server"

# Sign server certificate
openssl x509 -req -days 365 -in server.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -out server.crt

# Generate Diffie-Hellman parameters
openssl dhparam -out dh2048.pem 2048

# Generate TLS auth key
openvpn --genkey --secret ta.key

# Create server configuration
cat > /etc/openvpn/server.conf << 'EOL'
port 1194
proto udp
dev tun
ca /etc/openvpn/certs/ca.crt
cert /etc/openvpn/certs/server.crt
key /etc/openvpn/certs/server.key
dh /etc/openvpn/certs/dh2048.pem
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist /var/log/openvpn/ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
keepalive 10 120
cipher AES-256-CBC
auth SHA256
comp-lzo
user nobody
group nogroup
persist-key
persist-tun
status /var/log/openvpn/openvpn-status.log
verb 3
tls-auth /etc/openvpn/certs/ta.key 0
key-direction 0
EOL

# Create log directory
mkdir -p /var/log/openvpn

# Enable IP forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# Configure firewall
ufw allow 1194/udp
ufw allow OpenSSH
echo "y" | ufw enable

# Create client certificate generation script
cat > /etc/openvpn/generate-client.sh << 'EOL'
#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <client-name>"
    exit 1
fi

CLIENT_NAME=$1
cd /etc/openvpn/certs

# Generate client key and certificate
openssl req -newkey rsa:2048 -nodes -keyout ${CLIENT_NAME}.key \
    -out ${CLIENT_NAME}.csr \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=${CLIENT_NAME}"

# Sign client certificate
openssl x509 -req -days 365 -in ${CLIENT_NAME}.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -out ${CLIENT_NAME}.crt

# Create client configuration
cat > /etc/openvpn/client-configs/${CLIENT_NAME}.ovpn << EOF
client
proto udp
remote $(curl -s ifconfig.me) 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
auth-user-pass
comp-lzo
verb 3
cipher AES-256-CBC
auth SHA256
key-direction 1
<ca>
$(cat ca.crt)
</ca>
<cert>
$(cat ${CLIENT_NAME}.crt)
</cert>
<key>
$(cat ${CLIENT_NAME}.key)
</key>
<tls-auth>
$(cat ta.key)
</tls-auth>
EOF

echo "Client configuration generated: /etc/openvpn/client-configs/${CLIENT_NAME}.ovpn"
EOL

# Make client generation script executable
chmod +x /etc/openvpn/generate-client.sh

# Create client configs directory
mkdir -p /etc/openvpn/client-configs

# Start OpenVPN service
systemctl enable openvpn@server
systemctl start openvpn@server

echo "OpenVPN server setup complete!"
echo "To generate a client configuration, run: /etc/openvpn/generate-client.sh <client-name>" 