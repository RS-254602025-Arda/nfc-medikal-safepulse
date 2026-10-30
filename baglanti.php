<?php
$host = "localhost";
$veritabani_adi = "nfc_saglik";
$kullanici_adi = "saglik_nfc_api";
$sifre = "Emirhisar.160320"; 

try {
    $db = new PDO("mysql:host=$host;dbname=$veritabani_adi;charset=utf8", $kullanici_adi, $sifre);
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    echo "Bağlantı hatası: " . $e->getMessage();
    die();
}
?>