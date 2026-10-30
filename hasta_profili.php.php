<?php
include 'baglanti.php';
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $kullanici_id = $_POST['kullanici_id'] ?? '';
    $ad_soyad = $_POST['ad_soyad'] ?? '';
    $dogum_tarihi = $_POST['dogum_tarihi'] ?? null;
    if($dogum_tarihi == '') $dogum_tarihi = null;
    
    $acil_durum_metni = $_POST['acil_durum_metni'] ?? '';
    $acil_kisi_ad = '';
    $acil_kisi_telefon = '';

    // "İsim - Telefon" formatını tire işaretine göre ayırıyoruz
    if (!empty($acil_durum_metni) && strpos($acil_durum_metni, '-') !== false) {
        $parcalar = explode('-', $acil_durum_metni);
        $acil_kisi_ad = trim($parcalar[0]);
        $acil_kisi_telefon = trim($parcalar[1]);
    } else {
        $acil_kisi_ad = trim($acil_durum_metni);
        $acil_kisi_telefon = "";
    }

    $kritik_uyari = $_POST['kritik_uyari'] ?? '';
    $organ_bagiscisi = isset($_POST['organ_bagiscisi']) ? (int)$_POST['organ_bagiscisi'] : 0;

    if(empty($kullanici_id)) {
        echo json_encode(["basari" => false, "mesaj" => "Kullanıcı ID zorunludur."]);
        exit;
    }

    try {
        $sorgu = $db->prepare("UPDATE kullanicilar SET ad_soyad = ?, dogum_tarihi = ?, acil_kisi_ad = ?, acil_kisi_telefon = ?, kritik_uyari = ?, organ_bagiscisi = ? WHERE id = ?");
        $sonuc = $sorgu->execute([$ad_soyad, $dogum_tarihi, $acil_kisi_ad, $acil_kisi_telefon, $kritik_uyari, $organ_bagiscisi, $kullanici_id]);

        if ($sonuc) {
            echo json_encode(["basari" => true, "mesaj" => "Hasta profili başarıyla güncellendi!"]);
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