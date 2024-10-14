<?php
include 'config.php'; // Ensure this path is correct

if (isset($_POST['vendorID']) && isset($_POST['date']) && isset($_POST['amount']) && isset($_POST['collector_id'])) {
    // Sanitize and validate input values
    $vendorID = $conn->real_escape_string($_POST['vendorID']);
    $date = $conn->real_escape_string($_POST['date']);
    $amount = intval($_POST['amount']); // Ensure amount is treated as an integer
    $collector_id = $conn->real_escape_string($_POST['collector_id']); // Sanitize collector_id

    // Extract the current date in the format YYYYMMDD
    $currentDate = date('Ymd'); // Example: 20241006

    // Check for the last transaction on the same date (starting with current date YYYYMMDD)
    $query = "SELECT transactionID FROM vendor_transaction WHERE transactionID LIKE '$currentDate-%' ORDER BY transactionID DESC LIMIT 1";
    $result = $conn->query($query);

    if ($result && $result->num_rows > 0) {
        $lastTransactionID = $result->fetch_assoc()['transactionID'];
        
        // Extract the numeric part (after the last '-') and increment it
        $numericPart = intval(substr($lastTransactionID, 9)) + 1; // Start increment from position 9 (YYYYMMDD-XXX)
        $transactionID = $currentDate . '-' . str_pad($numericPart, 3, '0', STR_PAD_LEFT); // Format as "YYYYMMDD-XXX"
    } else {
        // No previous transactions for today, start from "YYYYMMDD-001"
        $transactionID = $currentDate . '-001';
    }

    // Insert data into the vendor_transaction table
    $query = "INSERT INTO vendor_transaction (transactionID, vendorID, date, amount, collector_id) VALUES ('$transactionID', '$vendorID', '$date', $amount, '$collector_id')";

    if ($conn->query($query) === TRUE) {
        echo json_encode(['status' => 'success', 'message' => 'Transaction inserted successfully', 'transactionID' => $transactionID]);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Error inserting transaction: ' . $conn->error]);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Invalid input data']);
}

$conn->close();
?>
