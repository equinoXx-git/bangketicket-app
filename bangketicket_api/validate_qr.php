<?php
include 'config.php';

if (isset($_GET['vendorID'])) {
    // Retrieve and sanitize the vendorID
    $vendorID = $conn->real_escape_string($_GET['vendorID']);

    // Ensure that vendorID is in the correct format (e.g., BTV-001)
    if (preg_match('/^BTV-\d+$/', $vendorID)) {
        // Fetch the vendor record based on the full vendorID
        $query = "SELECT * FROM vendor_list WHERE vendorID = '$vendorID'";
        $result = $conn->query($query);

        // Check if the result contains any rows
        if ($result !== false && $result->num_rows > 0) {
            echo json_encode(['status' => 'valid']);
        } else {
            echo json_encode(['status' => 'invalid', 'message' => 'Vendor ID not found']);
        }
    } else {
        echo json_encode(['status' => 'invalid', 'message' => 'Invalid Vendor ID format']);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Vendor ID not provided']);
}

$conn->close();
?>
