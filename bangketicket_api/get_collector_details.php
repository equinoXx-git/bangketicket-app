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

// Retrieve the collector ID from the request
$collectorID = $_GET['collectorID'];

// Sanitize the input
$collectorID = mysqli_real_escape_string($conn, $collectorID);

// Query to fetch collector's name
$sql = "SELECT collectorName FROM collector_list WHERE collectorID = '$collectorID'";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
    // Fetch the collector details
    $row = $result->fetch_assoc();
    $collectorFullName = $row['collectorName'];  // Fetch the collector's full name
    echo json_encode([
        'success' => true,
        'collector_full_name' => $collectorFullName,
    ]);
} else {
    // If no match is found, return an error
    echo json_encode([
        'success' => false,
        'message' => 'Collector not found'
    ]);
}

$conn->close();
?>
