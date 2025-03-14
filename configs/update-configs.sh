#!/bin/bash

# Function to update a client config
update_client_config() {
    local client=$1
    local config_file="${client}.ovpn"
    
    # Create temporary file
    cp "${config_file}" "${config_file}.tmp"
    
    # Replace CA certificate
    sed -i "/<ca>/r certs/ca.crt" "${config_file}.tmp"
    sed -i "/# Copy the contents of certs\/ca.crt here/d" "${config_file}.tmp"
    
    # Replace client certificate
    sed -i "/<cert>/r certs/${client}.crt" "${config_file}.tmp"
    sed -i "/# Copy the contents of certs\/${client}.crt here/d" "${config_file}.tmp"
    
    # Replace client key
    sed -i "/<key>/r certs/${client}.key" "${config_file}.tmp"
    sed -i "/# Copy the contents of certs\/${client}.key here/d" "${config_file}.tmp"
    
    # Replace TLS auth key
    sed -i "/<tls-auth>/r certs/ta.key" "${config_file}.tmp"
    sed -i "/# Copy the contents of certs\/ta.key here/d" "${config_file}.tmp"
    
    # Move temporary file back
    mv "${config_file}.tmp" "${config_file}"
}

# Update all client configs
for client in windows linux macos; do
    update_client_config "$client"
done

echo "Client configurations updated with real certificates!" 