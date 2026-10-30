<?php
header("Content-Type: application/json; charset=UTF-8");

$baglanti = new mysqli("localhost", "root", "", "nfc_saglik");

if ($baglanti->connect_error) {
    die(json_encode(["basari" => false, "mesaj" => "Sunucuya bağlanılamadı!"]));
}

$tc_kimlik = $_POST['tc_kimlik'] ?? '';
$diploma = $_POST['diploma_tescil'] ?? '';
$sicil = $_POST['personel_sicil'] ?? '';
$uzmanlik = $_POST['uzmanlik_tescil'] ?? ''; 
$sifre = $_POST['sifre'] ?? '';

if($tc_kimlik != '' && $diploma != '' && $sicil != '' && $sifre != '') {
    
    $sorgu = "SELECT * FROM doktorlar WHERE tc_kimlik = '$tc_kimlik' AND diploma_tescil = '$diploma' AND personel_sicil = '$sicil' AND sifre = '$sifre'";
    
    if($uzmanlik != '') {
        $sorgu .= " AND uzmanlik_tescil = '$uzmanlik'";
    } else {
        $sorgu .= " AND (uzmanlik_tescil = '' OR uzmanlik_tescil IS NULL)";
    }

    $sonuc = $baglanti->query($sorgu);

    if ($sonuc && $sonuc->num_rows > 0) {
        $doktor = $sonuc->fetch_assoc();
        echo json_encode(["basari" => true, "mesaj" => "Giriş Başarılı! Hoşgeldiniz, " . $doktor['ad_soyad']]);
    } else {
        echo json_encode(["basari" => false, "mesaj" => "Güvenlik İhlali! Bilgilerinizden biri veya birkaçı hatalı."]);
    }
} else {
    echo json_encode(["basari" => false, "mesaj" => "Lütfen zorunlu alanların hepsini doldurun."]);
}

$baglanti->close();
?>