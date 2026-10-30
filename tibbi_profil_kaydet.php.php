<?php
include 'baglanti.php';
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $kullanici_id = $_POST['kullanici_id'] ?? '';
    $kan_grubu = $_POST['kan_grubu'] ?? '';
    $kronik_hastaliklar = $_POST['kronik_hastaliklar'] ?? '';
    $alerjiler = $_POST['alerjiler'] ?? '';
    $kullanilan_ilaclar = $_POST['kullanilan_ilaclar'] ?? '';

    if(empty($kullanici_id)) {
        echo json_encode(["basari" => false, "mesaj" => "Kullanıcı ID eksik."]);
        exit;
    }

    try {
        $kontrol = $db->prepare("SELECT id FROM tibbi_profil WHERE kullanici_id = ?");
        $kontrol->execute([$kullanici_id]);
        
        if($kontrol->rowCount() > 0) {
            $sorgu = $db->prepare("UPDATE tibbi_profil SET kan_grubu = ?, kronik_hastaliklar = ?, alerjiler = ?, kullanilan_ilaclar = ? WHERE kullanici_id = ?");
            $sonuc = $sorgu->execute([$kan_grubu, $kronik_hastaliklar, $alerjiler, $kullanilan_ilaclar, $kullanici_id]);
        } else {
            $sorgu = $db->prepare("INSERT INTO tibbi_profil (kullanici_id, kan_grubu, kronik_hastaliklar, alerjiler, kullanilan_ilaclar) VALUES (?, ?, ?, ?, ?)");
            $sonuc = $sorgu->execute([$kullanici_id, $kan_grubu, $kronik_hastaliklar, $alerjiler, $kullanilan_ilaclar]);
        }

        if ($sonuc) {
            echo json_encode(["basari" => true, "mesaj" => "Tıbbi profil başarıyla güncellendi!"]);
        } else {
            echo json_encode(["basari" => false, "mesaj" => "Kayıt işlemi başarısız."]);
        }
    } catch(PDOException $e) {
        echo json_encode(["basari" => false, "mesaj" => "Hata: " . $e->getMessage()]);
    }
} else {
    echo json_encode(["basari" => false, "mesaj" => "Geçersiz istek."]);
}
?>