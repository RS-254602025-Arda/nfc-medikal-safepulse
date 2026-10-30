<?php
header("Content-Type: application/json; charset=UTF-8");

require 'PHPMailer/src/Exception.php';
require 'PHPMailer/src/PHPMailer.php';
require 'PHPMailer/src/SMTP.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

$baglanti = new mysqli("localhost", "root", "", "nfc_saglik");

if ($baglanti->connect_error) {
    die(json_encode(["basari" => false, "mesaj" => "Sunucu bağlantı hatası!"]));
}

$eposta =$_POST['eposta'] ?? '';

if($eposta != '') {
    // 1. Önce bu e-posta adresi sistemde kayıtlı mı kontrol et
    $kontrol =$baglanti->query("SELECT * FROM kullanicilar WHERE eposta = '$eposta'");
    
    if($kontrol &&$kontrol->num_rows > 0) {
        $uretilen_kod = rand(100000, 999999);$baglanti->query("DELETE FROM eposta_dogrulama WHERE eposta = '$eposta'");
        $sorgu = "INSERT INTO eposta_dogrulama (eposta, dogrulama_kodu) VALUES ('$eposta', '$uretilen_kod')";
        
        if($baglanti->query($sorgu) === TRUE) {$mail = new PHPMailer(true);
            try {
                $mail->isSMTP();
                $mail->Host       = 'smtp.gmail.com';$mail->SMTPAuth   = true;
                $mail->Username   = 'nfc.saglik26@gmail.com'; 
                $mail->Password   = 'wtztjzuhghgrfjxt';$mail->SMTPSecure = PHPMailer::ENCRYPTION_SMTPS;
                $mail->Port       = 465;
                $mail->CharSet    = 'UTF-8';

                $mail->setFrom('nfc.saglik26@gmail.com', 'NFC Saglik Sistemi');
                $mail->addAddress($eposta);

                $mail->isHTML(true);
                $mail->Subject = 'NFC Saglik - Sifre Sifirlama Kodu';$mail->Body = "
                    <div style='font-family: Arial, sans-serif; padding: 25px; text-align: center; border: 1px solid #e0e0e0; border-radius: 12px; max-width: 500px; margin: auto;'>
                        <h2 style='color: #1565C0; margin-bottom: 10px;'>Şifre Sıfırlama Talebi</h2>
                        <p style='color: #555; font-size: 15px;'>Hesabınızın şifresini sıfırlamak için güvenlik kodunuz aşağıdadır:</p>
                        <div style='font-size: 36px; font-weight: bold; color: #1E88E5; letter-spacing: 6px; background: #F5F7FA; padding: 15px; border-radius: 8px; display: inline-block; margin: 20px 0;'>$uretilen_kod</div>
                        <p style='color: #888; font-size: 12px;'>Bu talebi siz yapmadıysanız, lütfen bu e-postayı dikkate almayın ve şifrenizi değiştirmeyin.</p>
                    </div>
                ";
                
                $mail->AltBody = "NFC Sağlık Sistemi - Şifre Sıfırlama Kodunuz: $uretilen_kod";

                $mail->send();
                echo json_encode(["basari" => true, "mesaj" => "Sıfırlama kodu e-postanıza gönderildi!"]);
            } catch (Exception $e) {
                echo json_encode(["basari" => false, "mesaj" => "Mail gönderilemedi."]);
            }
        } else {
            echo json_encode(["basari" => false, "mesaj" => "Kod veritabanına işlenemedi."]);
        }
    } else {
        echo json_encode(["basari" => false, "mesaj" => "Bu e-posta adresiyle kayıtlı bir hesap bulunamadı!"]);
    }
} else {
    echo json_encode(["basari" => false, "mesaj" => "Lütfen geçerli bir e-posta adresi girin."]);
}
$baglanti->close();
?>