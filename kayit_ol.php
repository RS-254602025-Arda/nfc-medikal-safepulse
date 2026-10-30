<?php
include 'baglanti.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    
    $tc_kimlik = $_POST['tc_kimlik'] ?? '';
    $ad_soyad = $_POST['ad_soyad'] ?? '';
    $eposta = $_POST['eposta'] ?? '';
    $telefon = $_POST['telefon'] ?? '';
    $sifre = $_POST['sifre'] ?? ''; 
    $rol = $_POST['rol'] ?? 'Hasta';

    if(empty($tc_kimlik) || empty($ad_soyad) || empty($eposta) || empty($sifre)) {
        echo json_encode(["basari" => false, "mesaj" => "TC, Ad Soyad, E-posta ve Şifre zorunludur."]);
        exit;
    }

    try {
        $guvenli_sifre = password_hash($sifre, PASSWORD_DEFAULT);
        $sorgu = $db->prepare("INSERT INTO kullanicilar (tc_kimlik, ad_soyad, eposta, telefon, sifre, rol) VALUES (?, ?, ?, ?, ?, ?)");
        $sorgu->execute([$tc_kimlik, $ad_soyad, $eposta, $telefon, $guvenli_sifre, $rol]);

        echo json_encode(["basari" => true, "mesaj" => "Kayıt başarıyla oluşturuldu!"]);

    } catch(PDOException $e) {
        echo json_encode(["basari" => false, "mesaj" => "Hata: TC Kimlik veya E-posta zaten kayıtlı."]);
    }
} else {
    echo json_encode(["basari" => false, "mesaj" => "Geçersiz istek."]);
}
?>