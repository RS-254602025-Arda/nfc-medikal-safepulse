<?php
// Veritabanı Bağlantısı
$baglanti = new mysqli("localhost", "root", "", "nfc_saglik");
$baglanti->set_charset("utf8");

if ($baglanti->connect_error) {
    die("Bağlantı Hatası: " . $baglanti->connect_error);
}

// 1. Hastalar (kullanicilar tablosu) - Tüm sütunlar çekiliyor
$hastalar = $baglanti->query("SELECT * FROM kullanicilar ORDER BY kayit_tarihi DESC");

// 2. Doktorlar (doktorlar tablosu) - Tüm sütunlar çekiliyor
$doktorlar = $baglanti->query("SELECT * FROM doktorlar");

// 3. Tıbbi Profil (tibbi_profil tablosu) - Kullanıcı adıyla eşleştirilerek tüm sütunlar çekiliyor
$tibbi_profiller = $baglanti->query("
    SELECT tp.*, k.ad_soyad, k.tc_kimlik 
    FROM tibbi_profil tp 
    LEFT JOIN kullanicilar k ON tp.kullanici_id = k.id
");

// 4. Muayene Defteri (muayene_defteri tablosu) - Tüm sütunlar çekiliyor
$muayeneler = $baglanti->query("
    SELECT m.*, k.ad_soyad as hasta_adi 
    FROM muayene_defteri m 
    LEFT JOIN kullanicilar k ON m.hasta_id = k.id 
    ORDER BY m.islem_tarihi DESC
");

// 5. Tıbbi Geçmiş Kayıtları (tibbi_gecmis_kayitlari tablosu) - Tüm sütunlar çekiliyor
$tibbi_gecmis = $baglanti->query("
    SELECT tg.*, k.ad_soyad as hasta_adi 
    FROM tibbi_gecmis_kayitlari tg 
    LEFT JOIN kullanicilar k ON tg.kullanici_id = k.id 
    ORDER BY tg.olay_tarihi DESC
");

// 6. E-posta Doğrulama (eposta_dogrulama tablosu) - Tüm sütunlar çekiliyor
$onay_kodlari = $baglanti->query("SELECT * FROM eposta_dogrulama ORDER BY olusturma_tarihi DESC");

// Sayımları Al
$hasta_sayisi = $hastalar ? $hastalar->num_rows : 0;
$doktor_sayisi = $doktorlar ? $doktorlar->num_rows : 0;
$tibbi_profil_sayisi = $tibbi_profiller ? $tibbi_profiller->num_rows : 0;
$muayene_sayisi = $muayeneler ? $muayeneler->num_rows : 0;
$gecmis_sayisi = $tibbi_gecmis ? $tibbi_gecmis->num_rows : 0;
$kod_sayisi = $onay_kodlari ? $onay_kodlari->num_rows : 0;
?>

<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NFC Sağlık - Detaylı Yönetici Paneli</title>
    <!-- Bootstrap 5 CDN -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- FontAwesome CDN -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        body { background-color: #f5f7fa; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; font-size: 14px; }
        .header { background-color: #ffffff; padding: 20px 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.05); margin-bottom: 20px; display: flex; justify-content: space-between; align-items: center; }
        .header h3 { margin: 0; color: #1E88E5; font-weight: bold; font-size: 22px; }
        .badge-read-only { background-color: #757575; font-size: 11px; padding: 4px 10px; border-radius: 20px; color: white; margin-top: 5px; display: inline-block; }
        .nav-tabs .nav-link { color: #555; font-weight: 500; padding: 12px 15px; border: none; border-bottom: 3px solid transparent; font-size: 14px; }
        .nav-tabs .nav-link.active { color: #1E88E5; background: none; border-bottom: 3px solid #1E88E5; font-weight: bold; }
        .card { border: none; border-radius: 8px; box-shadow: 0 4px 15px rgba(0,0,0,0.05); margin-bottom: 30px; }
        .table { margin-bottom: 0; white-space: nowrap; }
        .table thead th { background-color: #e3f2fd; color: #1565C0; font-weight: 600; border-bottom: none; padding: 12px 15px; font-size: 13px; text-transform: uppercase; letter-spacing: 0.5px; }
        .table tbody td { padding: 12px 15px; vertical-align: middle; color: #444; border-bottom: 1px solid #f0f0f0; }
        .table tbody tr:hover { background-color: #f9fbe7; }
        .table-responsive { overflow-x: auto; }
        .btn-refresh { background-color: #1E88E5; color: white; border-radius: 6px; padding: 6px 15px; font-size: 13px; font-weight: 500; }
        .btn-refresh:hover { background-color: #1565C0; color: white; }
        .empty-state { padding: 30px; text-align: center; color: #999; font-style: italic; }
        .text-wrap { white-space: normal !important; min-width: 200px; }
    </style>
</head>
<body>

<div class="header">
    <div>
        <h3><i class="fa-solid fa-server"></i> NFC Sağlık - Veritabanı İzleme Merkezi</h3>
        <div class="badge-read-only"><i class="fa-solid fa-eye"></i> Salt Okunur (Düzenleme Kapalı)</div>
    </div>
    <button class="btn btn-refresh" onclick="location.reload();"><i class="fa-solid fa-rotate-right"></i> Yenile</button>
</div>

<div class="container-fluid px-4">
    <!-- SEKMELER -->
    <ul class="nav nav-tabs mb-4" id="panelTabs" role="tablist">
        <li class="nav-item" role="presentation">
            <button class="nav-link active" data-bs-toggle="tab" data-bs-target="#kullanicilar" type="button" role="tab"><i class="fa-solid fa-users"></i> Kullanıcılar (<?= $hasta_sayisi ?>)</button>
        </li>
        <li class="nav-item" role="presentation">
            <button class="nav-link" data-bs-toggle="tab" data-bs-target="#doktorlar" type="button" role="tab"><i class="fa-solid fa-user-doctor"></i> Doktorlar (<?= $doktor_sayisi ?>)</button>
        </li>
        <li class="nav-item" role="presentation">
            <button class="nav-link" data-bs-toggle="tab" data-bs-target="#tibbi_profil" type="button" role="tab"><i class="fa-solid fa-file-medical"></i> Tıbbi Profil (<?= $tibbi_profil_sayisi ?>)</button>
        </li>
        <li class="nav-item" role="presentation">
            <button class="nav-link" data-bs-toggle="tab" data-bs-target="#muayene_defteri" type="button" role="tab"><i class="fa-solid fa-stethoscope"></i> Muayene Defteri (<?= $muayene_sayisi ?>)</button>
        </li>
        <li class="nav-item" role="presentation">
            <button class="nav-link" data-bs-toggle="tab" data-bs-target="#tibbi_gecmis" type="button" role="tab"><i class="fa-solid fa-clock-rotate-left"></i> Tıbbi Geçmiş Kayıtları (<?= $gecmis_sayisi ?>)</button>
        </li>
        <li class="nav-item" role="presentation">
            <button class="nav-link" data-bs-toggle="tab" data-bs-target="#eposta_dogrulama" type="button" role="tab"><i class="fa-solid fa-envelope-circle-check"></i> E-Posta Doğrulama (<?= $kod_sayisi ?>)</button>
        </li>
    </ul>

    <div class="tab-content" id="panelTabsContent">
        
        <!-- 1. KULLANICILAR SEKMESİ -->
        <div class="tab-pane fade show active" id="kullanicilar" role="tabpanel">
            <div class="card">
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>id</th>
                                <th>tc_kimlik</th>
                                <th>ad_soyad</th>
                                <th>dogum_tarihi</th>
                                <th>eposta</th>
                                <th>telefon</th>
                                <th>ev_adresi</th>
                                <th>sifre</th>
                                <th>acil_kisi_ad</th>
                                <th>acil_kisi_telefon</th>
                                <th>organ_bagiscisi</th>
                                <th>kritik_uyari</th>
                                <th>nfc_uid</th>
                                <th>rol</th>
                                <th>doktor_pin</th>
                                <th>kayit_tarihi</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php if($hastalar && $hasta_sayisi > 0): while($row = $hastalar->fetch_assoc()): ?>
                            <tr>
                                <td><span class="badge bg-secondary"><?= $row['id'] ?></span></td>
                                <td><strong><?= $row['tc_kimlik'] ?? '-' ?></strong></td>
                                <td><?= $row['ad_soyad'] ?? '-' ?></td>
                                <td><?= $row['dogum_tarihi'] ?? '-' ?></td>
                                <td><?= $row['eposta'] ?? '-' ?></td>
                                <td><?= $row['telefon'] ?? '-' ?></td>
                                <td><?= $row['ev_adresi'] ?? '-' ?></td>
                                <td class="text-muted" style="font-size:10px;">[KRİPTOLU]</td>
                                <td><?= $row['acil_kisi_ad'] ?? '-' ?></td>
                                <td><?= $row['acil_kisi_telefon'] ?? '-' ?></td>
                                <td><?= (isset($row['organ_bagiscisi']) && $row['organ_bagiscisi'] == '1') ? '<span class="text-success">1 (Evet)</span>' : '<span class="text-danger">0 (Hayır)</span>' ?></td>
                                <td class="text-wrap text-danger"><?= $row['kritik_uyari'] ?? '-' ?></td>
                                <td><span class="badge bg-info text-dark"><?= $row['nfc_uid'] ?? '-' ?></span></td>
                                <td><?= $row['rol'] ?? '-' ?></td>
                                <td><span class="badge bg-dark"><?= $row['doktor_pin'] ?? '-' ?></span></td>
                                <td><?= $row['kayit_tarihi'] ?? '-' ?></td>
                            </tr>
                            <?php endwhile; else: ?>
                            <tr><td colspan="16" class="empty-state">Tabloda veri bulunmuyor.</td></tr>
                            <?php endif; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <!-- 2. DOKTORLAR SEKMESİ -->
        <div class="tab-pane fade" id="doktorlar" role="tabpanel">
            <div class="card">
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>id</th>
                                <th>ad_soyad</th>
                                <th>tc_kimlik</th>
                                <th>diploma_tescil</th>
                                <th>personel_sicil</th>
                                <th>uzmanlik_tescil</th>
                                <th>sifre</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php if($doktorlar && $doktor_sayisi > 0): while($row = $doktorlar->fetch_assoc()): ?>
                            <tr>
                                <td><span class="badge bg-secondary"><?= $row['id'] ?></span></td>
                                <td><strong><i class="fa-solid fa-user-md text-primary"></i> <?= $row['ad_soyad'] ?? '-' ?></strong></td>
                                <td><?= $row['tc_kimlik'] ?? '-' ?></td>
                                <td><?= $row['diploma_tescil'] ?? '-' ?></td>
                                <td><?= $row['personel_sicil'] ?? '-' ?></td>
                                <td><?= $row['uzmanlik_tescil'] ?? '-' ?></td>
                                <td class="text-muted" style="font-size:10px;">[KRİPTOLU]</td>
                            </tr>
                            <?php endwhile; else: ?>
                            <tr><td colspan="7" class="empty-state">Tabloda veri bulunmuyor.</td></tr>
                            <?php endif; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <!-- 3. TIBBİ PROFİL SEKMESİ -->
        <div class="tab-pane fade" id="tibbi_profil" role="tabpanel">
            <div class="card">
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>id</th>
                                <th>kullanici_id</th>
                                <th>Hasta Adı (İlişkili)</th>
                                <th>kan_grubu</th>
                                <th>boy</th>
                                <th>kilo</th>
                                <th>aktif_hamilelik_durumu</th>
                                <th>alerjiler</th>
                                <th>kronik_hastaliklar</th>
                                <th>kullanilan_ilaclar</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php if($tibbi_profiller && $tibbi_profil_sayisi > 0): while($row = $tibbi_profiller->fetch_assoc()): ?>
                            <tr>
                                <td><span class="badge bg-secondary"><?= $row['id'] ?></span></td>
                                <td><span class="badge bg-dark"><?= $row['kullanici_id'] ?></span></td>
                                <td><strong><?= $row['ad_soyad'] ?? 'Bilinmiyor' ?></strong> <small class="text-muted">(TC: <?= $row['tc_kimlik'] ?? '-' ?>)</small></td>
                                <td><span class="badge bg-danger"><?= $row['kan_grubu'] ?? '-' ?></span></td>
                                <td><?= $row['boy'] ?? '-' ?></td>
                                <td><?= $row['kilo'] ?? '-' ?></td>
                                <td><?= $row['aktif_hamilelik_durumu'] ?? '-' ?></td>
                                <td class="text-wrap text-danger"><?= $row['alerjiler'] ?? '-' ?></td>
                                <td class="text-wrap"><?= $row['kronik_hastaliklar'] ?? '-' ?></td>
                                <td class="text-wrap"><?= $row['kullanilan_ilaclar'] ?? '-' ?></td>
                            </tr>
                            <?php endwhile; else: ?>
                            <tr><td colspan="10" class="empty-state">Tabloda veri bulunmuyor.</td></tr>
                            <?php endif; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <!-- 4. MUAYENE DEFTERİ SEKMESİ -->
        <div class="tab-pane fade" id="muayene_defteri" role="tabpanel">
            <div class="card">
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>id</th>
                                <th>hasta_id</th>
                                <th>Hasta Adı (İlişkili)</th>
                                <th>doktor_tc</th>
                                <th>hastalik_tanisi</th>
                                <th>yapilan_ameliyat</th>
                                <th>verilen_ilaclar</th>
                                <th>islem_tarihi</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php if($muayeneler && $muayene_sayisi > 0): while($row = $muayeneler->fetch_assoc()): ?>
                            <tr>
                                <td><span class="badge bg-secondary"><?= $row['id'] ?></span></td>
                                <td><span class="badge bg-dark"><?= $row['hasta_id'] ?></span></td>
                                <td><strong><?= $row['hasta_adi'] ?? 'Bilinmeyen Hasta' ?></strong></td>
                                <td><?= $row['doktor_tc'] ?? '-' ?></td>
                                <td class="text-wrap"><?= $row['hastalik_tanisi'] ?? '-' ?></td>
                                <td class="text-wrap"><?= $row['yapilan_ameliyat'] ?? '-' ?></td>
                                <td class="text-wrap"><?= $row['verilen_ilaclar'] ?? '-' ?></td>
                                <td><span class="badge bg-light text-dark border"><?= $row['islem_tarihi'] ?? '-' ?></span></td>
                            </tr>
                            <?php endwhile; else: ?>
                            <tr><td colspan="8" class="empty-state">Tabloda veri bulunmuyor.</td></tr>
                            <?php endif; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <!-- 5. TIBBİ GEÇMİŞ KAYITLARI SEKMESİ -->
        <div class="tab-pane fade" id="tibbi_gecmis" role="tabpanel">
            <div class="card">
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>id</th>
                                <th>kullanici_id</th>
                                <th>Hasta Adı (İlişkili)</th>
                                <th>gecirilen_ameliyatlar</th>
                                <th>olay_tarihi</th>
                                <th>kurum_hastane</th>
                                <th>aciklama</th>
                                <th>gecmis_tanilar</th>
                                <th>hastaliklar</th>
                                <th>surekli_kull_ilac</th>
                                <th>kaydeden_doktor_id</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php if($tibbi_gecmis && $gecmis_sayisi > 0): while($row = $tibbi_gecmis->fetch_assoc()): ?>
                            <tr>
                                <td><span class="badge bg-secondary"><?= $row['id'] ?></span></td>
                                <td><span class="badge bg-dark"><?= $row['kullanici_id'] ?></span></td>
                                <td><strong><?= $row['hasta_adi'] ?? 'Bilinmeyen Hasta' ?></strong></td>
                                <td class="text-wrap"><?= $row['gecirilen_ameliyatlar'] ?? '-' ?></td>
                                <td><?= $row['olay_tarihi'] ?? '-' ?></td>
                                <td class="text-wrap"><?= $row['kurum_hastane'] ?? '-' ?></td>
                                <td class="text-wrap"><?= $row['aciklama'] ?? '-' ?></td>
                                <td class="text-wrap"><?= $row['gecmis_tanilar'] ?? '-' ?></td>
                                <td class="text-wrap"><?= $row['hastaliklar'] ?? '-' ?></td>
                                <td class="text-wrap"><?= $row['surekli_kull_ilac'] ?? '-' ?></td>
                                <td><?= $row['kaydeden_doktor_id'] ?? '-' ?></td>
                            </tr>
                            <?php endwhile; else: ?>
                            <tr><td colspan="11" class="empty-state">Tabloda veri bulunmuyor.</td></tr>
                            <?php endif; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <!-- 6. E-POSTA DOĞRULAMA SEKMESİ -->
        <div class="tab-pane fade" id="eposta_dogrulama" role="tabpanel">
            <div class="card">
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>id</th>
                                <th>eposta</th>
                                <th>dogrulama_kodu</th>
                                <th>olusturma_tarihi</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php if($onay_kodlari && $kod_sayisi > 0): while($row = $onay_kodlari->fetch_assoc()): ?>
                            <tr>
                                <td><span class="badge bg-secondary"><?= $row['id'] ?></span></td>
                                <td><strong><?= $row['eposta'] ?? '-' ?></strong></td>
                                <td><span class="badge bg-danger" style="font-size: 16px; letter-spacing: 3px;"><?= $row['dogrulama_kodu'] ?? '-' ?></span></td>
                                <td><?= $row['olusturma_tarihi'] ?? '-' ?></td>
                            </tr>
                            <?php endwhile; else: ?>
                            <tr><td colspan="4" class="empty-state">Tabloda veri bulunmuyor.</td></tr>
                            <?php endif; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

    </div>
</div>

<!-- Bootstrap JS -->
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>