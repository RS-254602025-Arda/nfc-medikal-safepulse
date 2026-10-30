<?php
include 'baglanti.php';
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $kullanici_id = $_POST['kullanici_id'] ?? '';
    $yeni_eposta = $_POST['eposta'] ?? '';
    $yeni_telefon = $_POST['telefon'] ?? '';
    $yeni_ev_adresi = $_POST['ev_adresi'] ?? ''; // EV ADRESİ BURADA

    if(empty($kullanici_id) || empty($yeni_eposta) || empty($yeni_telefon)) {
        echo json_encode(["basari" => false, "mesaj" => "E-posta ve Telefon alanları zorunludur."]);
        exit;
    }

    try {
        $sorgu = $db->prepare("UPDATE kullanicilar SET eposta = ?, telefon = ?, ev_adresi = ? WHERE id = ?");
        $sonuc = $sorgu->execute([$yeni_eposta, $yeni_telefon, $yeni_ev_adresi, $kullanici_id]);

        if ($sonuc) {
            echo json_encode(["basari" => true, "mesaj" => "Bilgileriniz başarıyla güncellendi!"]);
        } else {
            echo json_encode(["basari" => false, "mesaj" => "Güncelleme başarısız."]);
        }
    } catch(PDOException $e) {
        echo json_encode(["basari" => false, "mesaj" => "Hata: " . $e->getMessage()]);
    }
} else {
    echo json_encode(["basari" => false, "mesaj" => "Geçersiz istek."]);
}
?>