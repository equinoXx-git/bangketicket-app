<?php
// Required for sending email
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

require 'vendor/autoload.php'; // Ensure you have PHPMailer in your project

include 'config.php';

// Function to generate OTP
function generateOTP() {
    return str_pad(rand(0, 999999), 6, '0', STR_PAD_LEFT);
}

// Handle forgot password request
if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['email'])) {
    $email = $_POST['email'];
    
    // Check if the email exists in the collector table
    $result = $conn->query("SELECT collector_id, email FROM collectors WHERE email = '$email'");
    
    if ($result->num_rows > 0) {
        $collector = $result->fetch_assoc();
        $collector_id = $collector['collector_id'];

        // Generate OTP
        $otp = generateOTP();

        // Store OTP in the database with expiration time set to NOW() + INTERVAL 3 MINUTE
        $stmt = $conn->prepare("INSERT INTO otp_verification (collector_id, otp_code, expiration_time) VALUES (?, ?, NOW() + INTERVAL 3 MINUTE)");
        $stmt->bind_param("ss", $collector_id, $otp);
        $stmt->execute();
        
        // Send email with OTP
        $mail = new PHPMailer(true);
        try {
            // Server settings
            $mail->isSMTP();
            $mail->Host = 'smtp.gmail.com'; // Your email host
            $mail->SMTPAuth = true;
            $mail->Username = 'balondodavenorman304@gmail.com'; // Your email username
            $mail->Password = 'eqiq iinl znfl ynka'; // Your email password
            $mail->SMTPSecure = 'tls';
            $mail->Port = 587;

            // SSL certificate options
            $mail->SMTPOptions = array(
                'ssl' => array(
                    'verify_peer' => true,
                    'verify_peer_name' => true,
                    'allow_self_signed' => false,
                    'cafile' => 'C:/xampp/apache/bin/curl-ca-bundle.crt',  // Path to CA bundle
                )
            );
            
            // Recipients
            $mail->setFrom('balondodavenorman304@gmail.com', 'BangkeTicket');
            $mail->addAddress($email);

            // Content
            $mail->isHTML(true);
            $mail->Subject = 'Your BangkeTicket OTP for Password Reset';
            $mail->Body = "
                <div style='font-family: Arial, sans-serif; color: #333;'>
                    <h2 style='color: #1a73e8;'>Password Reset Request</h2>
                    <p>Dear Collector,</p>
                    <p>We have received a request to reset the password for your BangkeTicket account. To proceed with the password reset, please use the OTP (One-Time Password) provided below:</p>
                    <p style='font-size: 18px; font-weight: bold; color: #1a73e8;'>$otp</p>
                    <p>This OTP is valid for <strong>3 minutes</strong>. Please enter this code in the password reset page to continue.</p>
                    <p>If you did not request a password reset, please disregard this email. Your account will remain secure.</p>
                    <p>Thank you for using BangkeTicket!</p>
                    <br>
                    <p style='color: #999;'>Best regards,</p>
                    <p><strong>BangkeTicket Support Team</strong></p>
                    <hr style='border:none; border-top:1px solid #eee;'>
                    <p style='font-size: 12px; color: #999;'>This is an automated message. Please do not reply to this email.</p>
                </div>";


            $mail->send();
            echo json_encode(['success' => true, 'message' => 'OTP has been sent to your email.']);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => "OTP could not be sent. Mailer Error: {$mail->ErrorInfo}"]);
        }
    } else {
        echo json_encode(['success' => false, 'message' => 'No account found with this email.']);
    }
}
?>
