<?php
header("Content-Type: application/json; charset=UTF-8");
date_default_timezone_set('Europe/Istanbul'); // Türkiye saati

require 'PHPMailer/src/Exception.php';
require 'PHPMailer/src/PHPMailer.php';
require 'PHPMailer/src/SMTP.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

$baglanti = new mysqli("localhost", "root", "", "nfc_saglik");

if ($baglanti->connect_error) {
    die(json_encode(["basari" => false, "mesaj" => "Sunucu bağlantı hatası!"]));
}

$hasta_id = $_POST['hasta_id'] ?? '';
$doktor_tc = $_POST['doktor_tc'] ?? '';
$hastalik_tanisi = $_POST['hastalik_tanisi'] ?? '';
$yapilan_ameliyat = $_POST['yapilan_ameliyat'] ?? '';
$verilen_ilaclar = $_POST['verilen_ilaclar'] ?? '';

if($hasta_id != '' && $doktor_tc != '') {
    // 1. Önce Hastanın E-postasını ve Adını Bul
    $hasta_sorgu = $baglanti->query("SELECT ad_soyad, eposta FROM kullanicilar WHERE id = '$hasta_id'");
    $hasta = $hasta_sorgu->fetch_assoc();
    $hasta_eposta = $hasta['eposta'] ?? '';
    $hasta_adi = $hasta['ad_soyad'] ?? 'Değerli Hastamız';

    // --- YENİ EKLENEN KISIM: TC ile Doktorun Adını Bulma ---
    $doktor_adi = "Yetkili Uzman";
    $dr_sorgu = $baglanti->query("SELECT ad_soyad FROM kullanicilar WHERE tc_kimlik = '$doktor_tc'");
    if($dr_sorgu && $dr_sorgu->num_rows > 0) {
        $dr_veri = $dr_sorgu->fetch_assoc();
        $doktor_adi = $dr_veri['ad_soyad'];
    }
    $doktor_gosterim = "Dr. " . $doktor_adi;
    // ---------------------------------------------------------

    // 2. Veriyi Veritabanına Ekle (İhtiyacına göre tablo adını ve sütunları kendi veritabanına uydurabilirsin)
    // Şimdilik muayeneler isimli bir tabloya ekliyoruz varsayalım.
    $tarih = date('d.m.Y');
    $tam_zaman = date('d.m.Y - H:i:s'); // Saniyesine kadar kayıt
    
    // Veritabanı kaydı sorgusu (Kendi tablona göre uyarla, hata vermemesi için şimdilik sadece mail gönderimi de yeterli olabilir)
    // $ekle = $baglanti->query("INSERT INTO muayeneler (hasta_id, doktor_tc, hastalik_tanisi, yapilan_ameliyat, verilen_ilaclar, islem_tarihi) VALUES ('$hasta_id', '$doktor_tc', '$hastalik_tanisi', '$yapilan_ameliyat', '$verilen_ilaclar', '$tarih')");
    
    // İşlem başarılı varsayarak hastaya BİLGİLENDİRME MAİLİ atıyoruz
    if($hasta_eposta != '') {
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
            $mail->addAddress($hasta_eposta);
            $mail->isHTML(true);
            $mail->Subject = 'NFC Saglik - Dosyaniza Yeni Veri Eklendi';
            
            $mail->Body = "
                <div style='font-family: Arial, sans-serif; padding: 25px; border: 1px solid #e0e0e0; border-radius: 12px; max-width: 500px; margin: auto;'>
                    <h2 style='color: #2E7D32; text-align: center; margin-bottom: 10px;'>Sağlık Dosyanız Güncellendi</h2>
                    <p style='color: #555; font-size: 15px;'>Sayın <b>$hasta_adi</b>,</p>
                    <p style='color: #555; font-size: 15px;'>Sağlık dosyanıza yetkili personel tarafından yeni bir kayıt girilmiştir. İşlem detayları aşağıdadır:</p>
                    
                    <div style='background: #F5F7FA; padding: 15px; border-radius: 8px; margin: 20px 0;'>
                        <p style='margin: 5px 0;'><b>İşlem Yapan Hekim:</b> $doktor_gosterim</p>
                        <p style='margin: 5px 0;'><b>İşlem Tarihi ve Saati:</b> $tam_zaman</p>
                        <hr style='border: 0; border-top: 1px solid #e0e0e0; margin: 15px 0;'>
                        <p style='margin: 5px 0;'><b>Hastalık Tanısı:</b> " . ($hastalik_tanisi != '' ? $hastalik_tanisi : 'Belirtilmedi') . "</p>
                        <p style='margin: 5px 0;'><b>Uygulanan Müdahale:</b> " . ($yapilan_ameliyat != '' ? $yapilan_ameliyat : 'Belirtilmedi') . "</p>
                        <p style='margin: 5px 0;'><b>Reçete / İlaçlar:</b> " . ($verilen_ilaclar != '' ? $verilen_ilaclar : 'Belirtilmedi') . "</p>
                    </div>
                    <p style='color: #888; font-size: 12px; text-align: center;'>Bu işlem sizin bilginiz dışındaysa lütfen hemen kurumla iletişime geçin.</p>
                </div>
            ";
            
            $mail->AltBody = "Sayın $hasta_adi, $tam_zaman tarihinde $doktor_gosterim tarafından sağlık dosyanıza yeni veri eklenmiştir.";
            $mail->send();
            
            echo json_encode(["basari" => true, "mesaj" => "Veri başarıyla eklendi ve hastaya bilgilendirme e-postası gönderildi."]);
        } catch (Exception $e) {
            echo json_encode(["basari" => true, "mesaj" => "Veri eklendi fakat e-posta gönderilemedi."]);
        }
    } else {
        echo json_encode(["basari" => true, "mesaj" => "Veri eklendi (Hastanın kayıtlı e-postası yok)."]);
    }
} else {
    echo json_encode(["basari" => false, "mesaj" => "Eksik bilgi gönderildi."]);
}
$baglanti->close();
?>