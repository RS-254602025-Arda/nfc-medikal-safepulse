<?php
header("Content-Type: application/json; charset=UTF-8");
$baglanti = new mysqli("localhost", "root", "", "nfc_saglik");

if ($baglanti->connect_error) {
    die(json_encode(["basari" => false, "mesaj" => "Sunucu bağlantı hatası!"]));
}

$eposta = $_POST['eposta'] ?? '';
$yeni_sifre = $_POST['yeni_sifre'] ?? '';

if($eposta != '' && $yeni_sifre != '') {
    
    // --- ŞİFRE KRİPTOLAMA (HASH) SEÇİMİ ---
    // NOT: Veritabanındaki eski şifrelerin uzunluğu 32 karakter ise md5 kullanıyorsundur.
    // Eğer şifreler $2y$ gibi işaretlerle başlıyorsa password_hash kullanıyorsundur.
    
    // SEÇENEK 1: Eğer sistemin MD5 kullanıyorsa aşağıdaki satırın başındaki // işaretlerini sil, 2. seçeneği sil.
    // $kriptolu_sifre = md5($yeni_sifre);
    
    // SEÇENEK 2: Eğer sistemin gelişmiş şifreleme kullanıyorsa bu satır kalsın.
    $kriptolu_sifre = password_hash($yeni_sifre, PASSWORD_DEFAULT);
    // --------------------------------------

    // Düz şifreyi değil, kriptolu şifreyi veritabanına yazdırıyoruz
    $sorgu = "UPDATE kullanicilar SET sifre = '$kriptolu_sifre' WHERE eposta = '$eposta'";
    
    if ($baglanti->query($sorgu) === TRUE) {
        echo json_encode(["basari" => true, "mesaj" => "Şifreniz başarıyla değiştirildi!"]);
    } else {
        echo json_encode(["basari" => false, "mesaj" => "Şifre güncellenirken veritabanında bir hata oluştu."]);
    }
} else {
    echo json_encode(["basari" => false, "mesaj" => "Eksik bilgi gönderildi."]);
}
$baglanti->close();
?>