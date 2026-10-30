<?php
// Garsonun dili Türkçe olsun diye ayar yapıyoruz
header("Content-Type: application/json; charset=UTF-8");

// Mutfakla (Veritabanı) bağlantı kuruyoruz
$baglanti = new mysqli("localhost", "root", "", "nfc_saglik");

// Mutfak kapalıysa müşteriye haber ver
if ($baglanti->connect_error) {
    die(json_encode(["basari" => false, "mesaj" => "Mutfağa (Sunucuya) ulaşılamadı!"]));
}

// Müşteriden (Flutter) gelen bilgileri (ID ve Yeni Şifre) alıyoruz
$kullanici_id = $_POST['kullanici_id'] ?? '';
$yeni_pin = $_POST['yeni_pin'] ?? '';

if ($kullanici_id != '' && $yeni_pin != '') {
    // Garson mutfaktaki deftere yeni şifreyi yazıyor
    $sorgu = "UPDATE kullanicilar SET doktor_pin = '$yeni_pin' WHERE id = '$kullanici_id'";
    
    if ($baglanti->query($sorgu) === TRUE) {
        // İşlem başarılıysa müşteriye gülücük saç :)
        echo json_encode(["basari" => true, "mesaj" => "Yeni kod başarıyla deftere yazıldı!"]);
    } else {
        // Bir sorun çıkarsa haber ver
        echo json_encode(["basari" => false, "mesaj" => "Kodu yazarken bir sorun çıktı."]);
    }
} else {
    echo json_encode(["basari" => false, "mesaj" => "Eksik bilgi verdiniz."]);
}

$baglanti->close();
?>