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

// Uygulamadan hastanın e-postası ve işlemi yapan doktorun TC'si gelecek
$eposta = $_POST['eposta'] ?? '';
$doktor_tc = $_POST['doktor_tc'] ?? 'Bilinmeyen Doktor';

if($eposta != '') {
    $uretilen_kod = rand(100000, 999999);
    
    // --- YENİ EKLENEN KISIM: TC ile Doktorun Adını Bulma ---
    $doktor_adi = "Yetkili Uzman"; 
    if($doktor_tc != '' && $doktor_tc != 'Bilinmeyen Doktor') {
        $dr_sorgu = $baglanti->query("SELECT ad_soyad FROM kullanicilar WHERE tc_kimlik = '$doktor_tc'");
        if($dr_sorgu && $dr_sorgu->num_rows > 0) {
            $dr_veri = $dr_sorgu->fetch_assoc();
            $doktor_adi = $dr_veri['ad_soyad'];
        }
    }
    $doktor_gosterim = "Dr. " . $doktor_adi;
    // ---------------------------------------------------------
    
    // Güvenlik: Eski kodlar silinir, sadece en son istenen kod geçerli olur
    $baglanti->query("DELETE FROM eposta_dogrulama WHERE eposta = '$eposta'");
    $sorgu = "INSERT INTO eposta_dogrulama (eposta, dogrulama_kodu) VALUES ('$eposta', '$uretilen_kod')";
    
    if($baglanti->query($sorgu) === TRUE) {
        
        $mail = new PHPMailer(true);
        try {
            $mail->isSMTP();
            $mail->Host       = 'smtp.gmail.com';
            $mail->SMTPAuth   = true;
            $mail->Username   = 'nfc.saglik26@gmail.com'; 
            $mail->Password   = 'wtztjzuhghgrfjxt';        
            $mail->SMTPSecure = PHPMailer::ENCRYPTION_SMTPS;
            $mail->Port       = 465;
            $mail->CharSet    = 'UTF-8';

            $mail->setFrom('nfc.saglik26@gmail.com', 'NFC Saglik Sistemi');
            $mail->addAddress($eposta);

            $mail->isHTML(true);
            $mail->Subject = 'NFC Saglik - Doktor Islem Onayi';
            
            // Doktora özel tasarlanmış kırmızı uyarı şablonu (TC kaldırıldı, Ad Soyad eklendi)
            $mail->Body    = "
                <div style='font-family: Arial, sans-serif; padding: 25px; text-align: center; border: 1px solid #e0e0e0; border-radius: 12px; max-width: 500px; margin: auto;'>
                    <h2 style='color: #D32F2F; margin-bottom: 10px;'>Tıbbi İşlem Onayı</h2>
                    <p style='color: #555; font-size: 15px;'><b>$doktor_gosterim</b> dosyanıza yeni bir tıbbi kayıt eklemek için yetki istiyor.</p>
                    <p style='color: #555; font-size: 15px;'>Eğer şu an doktorun yanındaysanız ve onaylıyorsanız aşağıdaki kodu doktorunuza iletiniz:</p>
                    <div style='font-size: 36px; font-weight: bold; color: #D32F2F; letter-spacing: 6px; background: #FFF5F5; padding: 15px; border-radius: 8px; display: inline-block; margin: 20px 0;'>$uretilen_kod</div>
                    <p style='color: #888; font-size: 12px;'>Bu işlem sizin bilginiz dışındaysa lütfen bu e-postayı dikkate almayınız.</p>
                </div>
            ";
            
            // SPAM önleyici düz metin (TC kaldırıldı)
            $mail->AltBody = "NFC Sağlık Sistemi - Tıbbi İşlem Onayı. $doktor_gosterim dosyanıza kayıt eklemek istiyor. İşlem Onay Kodunuz: $uretilen_kod";

            $mail->send();
            echo json_encode(["basari" => true, "mesaj" => "Onay kodu hastanın e-postasına gönderildi!"]);
        } catch (Exception $e) {
            echo json_encode(["basari" => false, "mesaj" => "Mail gönderilemedi. Hata: {$mail->ErrorInfo}"]);
        }

    } else {
        echo json_encode(["basari" => false, "mesaj" => "Kod veritabanına kaydedilemedi."]);
    }
} else {
    echo json_encode(["basari" => false, "mesaj" => "Hastanın kayıtlı e-posta adresi bulunamadı."]);
}
$baglanti->close();
?>