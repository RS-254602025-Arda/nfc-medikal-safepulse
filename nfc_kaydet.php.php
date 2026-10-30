<?php
include 'baglanti.php';
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $kullanici_id = $_POST['kullanici_id'] ?? '';
    $nfc_uid = $_POST['nfc_uid'] ?? '';

    if(empty($kullanici_id) || empty($nfc_uid)) {
        echo json_encode(["basari" => false, "mesaj" => "Kullanıcı ID ve NFC UID zorunludur."]);
        exit;
    }

    try {
        $sorgu = $db->prepare("UPDATE kullanicilar SET nfc_uid = ? WHERE id = ?");
        $sonuc = $sorgu->execute([$nfc_uid, $kullanici_id]);

        if ($sonuc) {
            echo json_encode(["basari" => true, "mesaj" => "TC Kimlik ve Bileklik başarıyla eşleştirildi!"]);
        } else {
            echo json_encode(["basari" => false, "mesaj" => "Eşleştirme başarısız oldu."]);
        }
    } catch(PDOException $e) {
        echo json_encode(["basari" => false, "mesaj" => "Hata: " . $e->getMessage()]);
    }
} else {
    echo json_encode(["basari" => false, "mesaj" => "Geçersiz istek."]);
}
?>