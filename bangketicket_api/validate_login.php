<?php
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "bangketicketdb";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Check if the POST request contains username and password
if (isset($_POST['username']) && isset($_POST['password'])) {
    
    // Retrieve the input username and password from the Flutter app
    $input_username = $_POST['username'];
    $input_password = $_POST['password'];

    // Sanitize the input to prevent SQL injection
    $input_username = mysqli_real_escape_string($conn, $input_username);
    $input_password = mysqli_real_escape_string($conn, $input_password);

    // Query to check if the username exists in the database
    $sql = "SELECT collector_id, 
                   CONCAT(lname, ', ', LEFT(fname, 1), '.') AS collectorName, 
                   password, first_login
            FROM collectors 
            WHERE username = '$input_username'";
    
    $result = $conn->query($sql);

    if ($result->num_rows > 0) {
        // Fetch collector details
        $collector = $result->fetch_assoc();

        // Check if password matches
        if ($input_password == $collector['password']) {
            // Check if this is the first login
            if ($collector['first_login'] == 1) {
                // Redirect to the change password page
                echo json_encode([
                    'success' => true,
                    'first_login' => true,  // Flag for first login
                    'collector_details' => [
                        'collector_id' => $collector['collector_id'],
                        'collectorName' => $collector['collectorName']
                    ]
                ]);
            } else {
                // Normal login, no need to change password
                echo json_encode([
                    'success' => true,
                    'first_login' => false,
                    'collector_details' => [
                        'collector_id' => $collector['collector_id'],
                        'collectorName' => $collector['collectorName']
                    ]
                ]);
            }
        } else {
            // If the password does not match
            echo json_encode(['success' => false, 'message' => 'Invalid password']);
        }
    } else {
        // If no match is found for the username
        echo json_encode(['success' => false, 'message' => 'Invalid username']);
    }
} else {
    // If username or password is not set
    echo json_encode(['success' => false, 'message' => 'Username or password missing']);
}

$conn->close();
?>
