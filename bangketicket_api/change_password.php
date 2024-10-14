<?php
include 'config.php';

if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $collector_id = $conn->real_escape_string($_POST['collector_id']);
    $new_password = $conn->real_escape_string($_POST['new_password']);  // Do not hash the new password for testing purposes

    // Update the password in the database and set first_login to 0
    $update_query = "UPDATE collectors SET password='$new_password', first_login=0 WHERE collector_id='$collector_id'";
    
    if ($conn->query($update_query) === TRUE) {
        // Return a success message as JSON
        echo json_encode(['success' => true, 'message' => 'Password updated successfully!']);
    } else {
        // Return an error message as JSON
        echo json_encode(['success' => false, 'message' => 'Error updating password. Please try again.']);
    }
}

$conn->close();
?>
