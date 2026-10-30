<?php
header("Content-Type: application/json; charset=UTF-8");
$baglanti = new mysqli("localhost", "root", "", "nfc_saglik");

$eposta = $_POST['eposta'] ?? '';
$girilen_kod = $_POST['kod'] ?? '';

if($eposta != '' && $girilen_kod != '') {
    $sorgu = "SELECT * FROM eposta_dogrulama WHERE eposta = '$eposta' AND dogrulama_kodu = '$girilen_kod'";
    $sonuc = $baglanti->query($sorgu);
    
    if ($sonuc && $sonuc->num_rows > 0) {
        $baglanti->query("DELETE FROM eposta_dogrulama WHERE eposta = '$eposta'");
        echo json_encode(["basari" => true, "mesaj" => "E-Posta başarıyla doğrulandı!"]);
    } else {
        echo json_encode(["basari" => false, "mesaj" => "Hatalı doğrulama kodu girdiniz."]);
    }
} else {
    echo json_encode(["basari" => false, "mesaj" => "Lütfen kodu girin."]);
}
?>