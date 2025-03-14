#!/bin/bash

# Exit on error
set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

# Function to display usage
show_usage() {
    echo "Usage: $0 [command] [options]"
    echo "Commands:"
    echo "  create <client-name> <username> <password>  - Create a new client"
    echo "  list                                      - List all clients"
    echo "  revoke <client-name>                      - Revoke a client's access"
    echo "  status                                    - Show server status"
    echo "  help                                      - Show this help message"
    exit 1
}

# Function to create a new client
create_client() {
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo "Error: Missing parameters"
        show_usage
    fi

    CLIENT_NAME=$1
    USERNAME=$2
    PASSWORD=$3

    echo "Creating client: $CLIENT_NAME"
    
    # Generate client certificate
    /etc/openvpn/generate-client.sh "$CLIENT_NAME"
    
    # Create credentials file
    mkdir -p /etc/openvpn/credentials
    echo "$USERNAME:$PASSWORD" > "/etc/openvpn/credentials/$CLIENT_NAME"
    
    echo "Client created successfully!"
    echo "Configuration file: /etc/openvpn/client-configs/$CLIENT_NAME.ovpn"
}

# Function to list all clients
list_clients() {
    echo "List of OpenVPN clients:"
    echo "------------------------"
    for config in /etc/openvpn/client-configs/*.ovpn; do
        if [ -f "$config" ]; then
            client_name=$(basename "$config" .ovpn)
            echo "- $client_name"
        fi
    done
}

# Function to revoke a client
revoke_client() {
    if [ -z "$1" ]; then
        echo "Error: Missing client name"
        show_usage
    fi

    CLIENT_NAME=$1
    
    echo "Revoking client: $CLIENT_NAME"
    
    # Remove client certificate and key
    rm -f "/etc/openvpn/certs/$CLIENT_NAME.crt"
    rm -f "/etc/openvpn/certs/$CLIENT_NAME.key"
    rm -f "/etc/openvpn/certs/$CLIENT_NAME.csr"
    
    # Remove client configuration
    rm -f "/etc/openvpn/client-configs/$CLIENT_NAME.ovpn"
    
    # Remove credentials
    rm -f "/etc/openvpn/credentials/$CLIENT_NAME"
    
    echo "Client revoked successfully!"
}

# Function to show server status
show_status() {
    echo "OpenVPN Server Status:"
    echo "---------------------"
    systemctl status openvpn@server | cat
    echo
    echo "Connected Clients:"
    echo "-----------------"
    cat /var/log/openvpn/openvpn-status.log
}

# Main script
case "$1" in
    "create")
        create_client "$2" "$3" "$4"
        ;;
    "list")
        list_clients
        ;;
    "revoke")
        revoke_client "$2"
        ;;
    "status")
        show_status
        ;;
    "help"|"")
        show_usage
        ;;
    *)
        echo "Unknown command: $1"
        show_usage
        ;;
esac 