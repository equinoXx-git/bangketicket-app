<?php
include 'config.php';

// Handle OTP verification request
if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['email']) && isset($_POST['otp'])) {
    $email = $conn->real_escape_string($_POST['email']);
    $otp = $conn->real_escape_string($_POST['otp']);
    
    // Check if the email exists in the collectors table
    $result = $conn->query("SELECT collector_id FROM collectors WHERE email = '$email'");
    
    if ($result->num_rows > 0) {
        $collector = $result->fetch_assoc();
        $collector_id = $collector['collector_id'];

        // Check if OTP is valid, not expired, and not used
        $otpResult = $conn->query("
            SELECT * 
            FROM otp_verification 
            WHERE collector_id = '$collector_id' 
            AND otp_code = '$otp' 
            AND expiration_time > NOW() 
            AND is_used = 0
        ");
        
        if ($otpResult->num_rows > 0) {
            // OTP is valid and not used
            // Mark the OTP as used to prevent reuse
            $conn->query("UPDATE otp_verification SET is_used = 1 WHERE collector_id = '$collector_id' AND otp_code = '$otp'");
            
            // Respond with success
            echo json_encode(['success' => true, 'collector_id' => $collector_id]);
        } else {
            // Invalid, expired, or used OTP
            $usedResult = $conn->query("
                SELECT * 
                FROM otp_verification 
                WHERE collector_id = '$collector_id' 
                AND otp_code = '$otp' 
                AND is_used = 1
            ");

            if ($usedResult->num_rows > 0) {
                // OTP has already been used
                echo json_encode(['success' => false, 'message' => 'OTP has already been used.']);
            } else {
                // OTP is invalid or expired
                echo json_encode(['success' => false, 'message' => 'Invalid or expired OTP.']);
            }
        }
    } else {
        echo json_encode(['success' => false, 'message' => 'No account found with this email.']);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request.']);
}
?>
