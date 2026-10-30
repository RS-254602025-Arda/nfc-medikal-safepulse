<?php
header("Content-Type: application/json; charset=UTF-8");
$baglanti = new mysqli("localhost", "root", "", "nfc_saglik");

if ($baglanti->connect_error) {
    die(json_encode(["basari" => false, "mesaj" => "Sunucuya bağlanılamadı!"]));
}

// 1. Doktordan gelen kodu al ve içindeki boşlukları TAMAMEN SİL. (Örn: "123 456" -> "123456")
$girilen_pin = str_replace(' ', '', $_POST['pin'] ?? '');

if($girilen_pin != '') {
    // 2. Veritabanındaki kodun da boşluklarını yoksay (REPLACE) ve öyle karşılaştır.
    // BURAYA DİKKAT: "eposta" kelimesini SELECT sorgusunun içine ekledim.
    $sorgu = "SELECT id, ad_soyad, eposta FROM kullanicilar WHERE REPLACE(doktor_pin, ' ', '') = '$girilen_pin'";
    $sonuc = $baglanti->query($sorgu);

    if ($sonuc && $sonuc->num_rows > 0) {
        $hasta = $sonuc->fetch_assoc();
        $hasta_id = $hasta['id'];
        
        // Hastanın geçmişini getir
        $gecmis_sorgu = "SELECT * FROM muayene_defteri WHERE hasta_id = '$hasta_id' ORDER BY islem_tarihi DESC";
        $gecmis_sonuc = $baglanti->query($gecmis_sorgu);
        
        $gecmis_kayitlar = [];
        if ($gecmis_sonuc && $gecmis_sonuc->num_rows > 0) {
            while($satir = $gecmis_sonuc->fetch_assoc()) {
                $gecmis_kayitlar[] = $satir;
            }
        }

        echo json_encode([
            "basari" => true, 
            "mesaj" => "Hasta dosyası açıldı.",
            "hasta_bilgisi" => $hasta,
            "gecmis_kayitlar" => $gecmis_kayitlar
        ]);
    } else {
        // Kafa karıştırmaması için hata mesajını da düzelttim
        echo json_encode(["basari" => false, "mesaj" => "Hatalı PIN! Lütfen hastanın ekranındaki kodu doğru girin."]);
    }
} else {
    echo json_encode(["basari" => false, "mesaj" => "Lütfen PIN kodunu girin."]);
}

$baglanti->close();
?>