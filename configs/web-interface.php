<?php
session_start();
require_once 'config.php';

// Check if user is logged in
if (!isset($_SESSION['user_id'])) {
    header('Location: login.php');
    exit();
}

// Handle client generation
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['generate_client'])) {
    $client_name = sanitize_input($_POST['client_name']);
    $username = sanitize_input($_POST['username']);
    $password = $_POST['password'];
    
    // Generate client certificate
    exec("/etc/openvpn/generate-client.sh $client_name");
    
    // Create user credentials file
    $credentials = "$username:$password";
    file_put_contents("/etc/openvpn/credentials/$client_name", $credentials);
    
    // Get client config
    $config = file_get_contents("/etc/openvpn/client-configs/$client_name.ovpn");
    
    // Send config to user
    header('Content-Type: application/x-openvpn-profile');
    header('Content-Disposition: attachment; filename="' . $client_name . '.ovpn"');
    echo $config;
    exit();
}

// Get list of existing clients
$clients = glob("/etc/openvpn/client-configs/*.ovpn");
$client_list = array_map(function($file) {
    return basename($file, '.ovpn');
}, $clients);

function sanitize_input($data) {
    $data = trim($data);
    $data = stripslashes($data);
    $data = htmlspecialchars($data);
    return $data;
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>OpenVPN Client Manager</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        body {
            font-family: 'Inter', sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            background-color: #f8fafc;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            padding: 2rem;
            border-radius: 10px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
            color: #1e293b;
            margin-bottom: 2rem;
        }
        .form-group {
            margin-bottom: 1.5rem;
        }
        label {
            display: block;
            margin-bottom: 0.5rem;
            color: #475569;
        }
        input {
            width: 100%;
            padding: 0.75rem;
            border: 1px solid #e2e8f0;
            border-radius: 5px;
            font-size: 1rem;
        }
        button {
            background-color: #2563eb;
            color: white;
            padding: 0.75rem 1.5rem;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 1rem;
            transition: background-color 0.3s;
        }
        button:hover {
            background-color: #1d4ed8;
        }
        .client-list {
            margin-top: 2rem;
        }
        .client-list h2 {
            color: #1e293b;
            margin-bottom: 1rem;
        }
        ul {
            list-style: none;
            padding: 0;
        }
        li {
            padding: 0.75rem;
            border: 1px solid #e2e8f0;
            border-radius: 5px;
            margin-bottom: 0.5rem;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .delete-btn {
            background-color: #ef4444;
        }
        .delete-btn:hover {
            background-color: #dc2626;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>OpenVPN Client Manager</h1>
        
        <form method="POST" action="">
            <div class="form-group">
                <label for="client_name">Client Name</label>
                <input type="text" id="client_name" name="client_name" required>
            </div>
            
            <div class="form-group">
                <label for="username">Username</label>
                <input type="text" id="username" name="username" required>
            </div>
            
            <div class="form-group">
                <label for="password">Password</label>
                <input type="password" id="password" name="password" required>
            </div>
            
            <button type="submit" name="generate_client">Generate Client Config</button>
        </form>
        
        <div class="client-list">
            <h2>Existing Clients</h2>
            <ul>
                <?php foreach ($client_list as $client): ?>
                <li>
                    <span><?php echo htmlspecialchars($client); ?></span>
                    <form method="POST" action="" style="display: inline;">
                        <input type="hidden" name="delete_client" value="<?php echo $client; ?>">
                        <button type="submit" class="delete-btn">Delete</button>
                    </form>
                </li>
                <?php endforeach; ?>
            </ul>
        </div>
    </div>
</body>
</html> 