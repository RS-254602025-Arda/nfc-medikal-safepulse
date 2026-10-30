<?php
include 'baglanti.php';

// JSON yanıt döneceğimizi belirtelim
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    // TC Kimlik veya Telefon numarası gelebilir, ikisi için tek bir değişken kullanıyoruz
    $kullanici_adi = $_POST['kullanici_adi'] ?? ''; 
    $sifre = $_POST['sifre'] ?? '';

    if(empty($kullanici_adi) || empty($sifre)) {
        echo json_encode(["basari" => false, "mesaj" => "TC Kimlik/Telefon ve Şifre zorunludur."]);
        exit;
    }

    try {
        // Kullanıcıyı veritabanında TC kimlik numarasına VEYA telefon numarasına göre ara
        $sorgu = $db->prepare("SELECT * FROM kullanicilar WHERE tc_kimlik = ? OR telefon = ? LIMIT 1");
        $sorgu->execute([$kullanici_adi, $kullanici_adi]);
        $kullanici = $sorgu->fetch(PDO::FETCH_ASSOC);

        // Kullanıcı bulunduysa ve şifre eşleşiyorsa (şifreler hash'li kaydedilmişti)
        if ($kullanici && password_verify($sifre, $kullanici['sifre'])) {
            // Güvenlik için şifreyi JSON yanıtından çıkarıyoruz
            unset($kullanici['sifre']); 
            
            echo json_encode([
                "basari" => true, 
                "mesaj" => "Giriş başarılı!", 
                "kullanici" => $kullanici // Flutter tarafında göstermek için kullanıcının tüm bilgilerini gönderiyoruz
            ]);
        } else {
            echo json_encode(["basari" => false, "mesaj" => "Hatalı TC Kimlik/Telefon veya Şifre!"]);
        }

    } catch(PDOException $e) {
        echo json_encode(["basari" => false, "mesaj" => "Veritabanı hatası: " . $e->getMessage()]);
    }
} else {
    echo json_encode(["basari" => false, "mesaj" => "Geçersiz istek türü."]);
}
?>