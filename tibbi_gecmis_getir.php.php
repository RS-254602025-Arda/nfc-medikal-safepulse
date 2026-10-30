<?php
include 'baglanti.php';
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $kullanici_id = $_POST['kullanici_id'] ?? '';

    if(empty($kullanici_id)) {
        echo json_encode(["basari" => false, "mesaj" => "Kullanıcı ID eksik."]);
        exit;
    }

    try {
        $sorgu = $db->prepare("SELECT * FROM tibbi_gecmis_kayitlari WHERE kullanici_id = ? ORDER BY id DESC");
        $sorgu->execute([$kullanici_id]);
        $kayitlar = $sorgu->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode([
            "basari" => true,
            "gecmis_kayitlari" => $kayitlar
        ]);
    } catch(PDOException $e) {
        echo json_encode(["basari" => false, "mesaj" => "Hata: " . $e->getMessage()]);
    }
} else {
    echo json_encode(["basari" => false, "mesaj" => "Geçersiz istek."]);
}
?>