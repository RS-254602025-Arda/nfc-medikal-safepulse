import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart'; // EKLENEN HAFIZA PAKETİ

// =====================================================================
// GLOBAL AYARLAR VE DEĞİŞKENLER
// =====================================================================
const String SUNUCU_IP = "10.216.137.181";
final ValueNotifier<bool> temaYonetici = ValueNotifier<bool>(false);
final ValueNotifier<String> dilYonetici = ValueNotifier<String>(
  "Türkçe",
); // DİL YÖNETİCİSİ

Map<String, dynamic>? aktifKullanici;
String? aktifDoktorTc;

// ---------------------------------------------------------------------
// MİNİ ÇEVİRİ SÖZLÜĞÜ (Dillerin Çalışması İçin)
// ---------------------------------------------------------------------
String dilCevir(String anahtar) {
  Map<String, Map<String, String>> sozluk = {
    "Türkçe": {
      "Ana Sayfa": "Ana Sayfa",
      "Özgeçmiş": "Özgeçmiş",
      "Doktor PIN": "Doktor PIN",
      "Profil": "Profil",
      "Bileklik Aktif": "Bileklik Aktif",
      "Hizmet veya bilgi arayın...": "Hizmet veya bilgi arayın...",
      "Hasta Profili": "Hasta Profili",
      "Kan Grubu": "Kan Grubu",
      "Tıbbi Özet": "Tıbbi Özet",
      "Ayarlar": "Uygulama Ayarları",
      "Dil": "Dil Seçimi",
      "Karanlik": "Karanlık Mod (Gece Teması)",
    },
    "English": {
      "Ana Sayfa": "Home",
      "Özgeçmiş": "History",
      "Doktor PIN": "Doctor PIN",
      "Profil": "Profile",
      "Bileklik Aktif": "Band Active",
      "Hizmet veya bilgi arayın...": "Search services...",
      "Hasta Profili": "Patient Profile",
      "Kan Grubu": "Blood Type",
      "Tıbbi Özet": "Medical Summary",
      "Ayarlar": "App Settings",
      "Dil": "Language Selection",
      "Karanlik": "Dark Mode",
    },
    "Deutsch": {
      "Ana Sayfa": "Startseite",
      "Özgeçmiş": "Lebenslauf",
      "Doktor PIN": "Arzt-PIN",
      "Profil": "Profil",
      "Bileklik Aktif": "Band Aktiv",
      "Hizmet veya bilgi arayın...": "Dienste suchen...",
      "Hasta Profili": "Patientenprofil",
      "Kan Grubu": "Blutgruppe",
      "Tıbbi Özet": "Med. Zusammenfassung",
      "Ayarlar": "App-Einstellungen",
      "Dil": "Sprachauswahl",
      "Karanlik": "Dunkelmodus",
    },
    "العربية": {
      "Ana Sayfa": "الرئيسية",
      "Özgeçmiş": "تاريخ",
      "Doktor PIN": "رقم الطبيب",
      "Profil": "الملف الشخصي",
      "Bileklik Aktif": "سوار نشط",
      "Hizmet veya bilgi arayın...": "البحث عن الخدمات...",
      "Hasta Profili": "ملف المريض",
      "Kan Grubu": "فصيلة الدم",
      "Tıbbi Özet": "ملخص طبي",
      "Ayarlar": "إعدادات التطبيق",
      "Dil": "اختيار اللغة",
      "Karanlik": "الوضع الداكن",
    },
  };
  return sozluk[dilYonetici.value]?[anahtar] ?? anahtar;
}

// ---------------------------------------------------------------------

void main() async {
  // HAFIZAYI (DİL VE TEMA) BAŞLANGIÇTA YÜKLE
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  temaYonetici.value = prefs.getBool('karanlikMod') ?? false;
  dilYonetici.value = prefs.getString('dil') ?? 'Türkçe';

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Hem Tema hem de Dil değiştiğinde uygulamanın yenilenmesi için eklendi
    return ValueListenableBuilder<String>(
      valueListenable: dilYonetici,
      builder: (context, aktifDil, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: temaYonetici,
          builder: (context, karanlikMi, child) {
            return MaterialApp(
              title: 'NFC Sağlık',
              debugShowCheckedModeBanner: false,
              themeMode: karanlikMi ? ThemeMode.dark : ThemeMode.light,
              theme: ThemeData(
                brightness: Brightness.light,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                  brightness: Brightness.light,
                ),
                scaffoldBackgroundColor: const Color(0xFFF5F7FA),
                cardColor: Colors.white,
              ),
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                  brightness: Brightness.dark,
                ),
                scaffoldBackgroundColor: const Color(0xFF121212),
                cardColor: const Color(0xFF1E1E1E),
              ),
              home: const GirisSayfasi(),
            );
          },
        );
      },
    );
  }
}

// =====================================================================
// GERÇEK ŞİFRE SIFIRLAMA PENCERESİ
// =====================================================================
class SifreSifirlamaDialog extends StatefulWidget {
  const SifreSifirlamaDialog({super.key});
  @override
  State<SifreSifirlamaDialog> createState() => _SifreSifirlamaDialogState();
}

class _SifreSifirlamaDialogState extends State<SifreSifirlamaDialog> {
  int _asama = 0;
  int _kalanSaniye = 180;
  Timer? _zamanlayici;
  bool _islemYapiliyor = false;

  final TextEditingController epostaController = TextEditingController();
  final TextEditingController kodController = TextEditingController();
  final TextEditingController sifreController = TextEditingController();
  final TextEditingController sifreTekrarController = TextEditingController();

  void _sayaciBaslat() {
    _zamanlayici = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_kalanSaniye > 0) {
        setState(() {
          _kalanSaniye--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _zamanlayici?.cancel();
    epostaController.dispose();
    kodController.dispose();
    sifreController.dispose();
    sifreTekrarController.dispose();
    super.dispose();
  }

  String _formatliSure() {
    int dk = _kalanSaniye ~/ 60;
    int sn = _kalanSaniye % 60;
    return '${dk.toString().padLeft(2, '0')}:${sn.toString().padLeft(2, '0')}';
  }

  Future<void> _kodGonder() async {
    if (epostaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen e-posta adresinizi girin.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _islemYapiliyor = true;
    });
    var url = Uri.parse(
      "http://$SUNUCU_IP/nfc_api/sifre_sifirla_kod_gonder.php",
    );
    try {
      var response = await http.post(
        url,
        body: {"eposta": epostaController.text.trim()},
      );
      var data = json.decode(response.body);
      if (data["basari"] == true) {
        setState(() {
          _asama = 1;
          _kalanSaniye = 180;
        });
        _sayaciBaslat();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["mesaj"]), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["mesaj"]), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sunucu bağlantı hatası!"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _islemYapiliyor = false;
      });
    }
  }

  Future<void> _koduDogrula() async {
    if (kodController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen e-postanıza gelen kodu girin.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _islemYapiliyor = true;
    });
    var url = Uri.parse("http://$SUNUCU_IP/nfc_api/eposta_kod_dogrula.php");
    try {
      var response = await http.post(
        url,
        body: {
          "eposta": epostaController.text.trim(),
          "kod": kodController.text.trim(),
        },
      );
      var data = json.decode(response.body);
      if (data["basari"] == true) {
        _zamanlayici?.cancel();
        setState(() {
          _asama = 2;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Kod onaylandı! Lütfen yeni şifrenizi belirleyin."),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["mesaj"]), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sunucu bağlantı hatası!"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _islemYapiliyor = false;
      });
    }
  }

  Future<void> _sifreGuncelle() async {
    if (sifreController.text.trim().isEmpty ||
        sifreTekrarController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifre alanları boş bırakılamaz.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (sifreController.text.trim() != sifreTekrarController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifreler birbiriyle eşleşmiyor!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _islemYapiliyor = true;
    });
    var url = Uri.parse("http://$SUNUCU_IP/nfc_api/sifre_guncelle.php");
    try {
      var response = await http.post(
        url,
        body: {
          "eposta": epostaController.text.trim(),
          "yeni_sifre": sifreController.text.trim(),
        },
      );
      var data = json.decode(response.body);
      if (data["basari"] == true) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["mesaj"]), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["mesaj"]), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sunucu bağlantı hatası!"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _islemYapiliyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Şifre Sıfırlama'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sisteme kayıtlı e-posta adresiniz:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: epostaController,
              readOnly: _asama > 0,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'E-Posta Adresi',
                prefixIcon: const Icon(Icons.email, color: Colors.blue),
                suffixIcon: _asama > 0
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            if (_asama == 1) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Kod Gönderildi',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatliSure(),
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: kodController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '6 Haneli Doğrulama Kodu',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  filled: true,
                  fillColor: Colors.blue.withOpacity(0.05),
                ),
              ),
            ],
            if (_asama == 2) ...[
              const SizedBox(height: 20),
              const Text(
                'Lütfen yeni şifrenizi belirleyin.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: sifreController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Yeni Şifre',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: sifreTekrarController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Yeni Şifre (Tekrar)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
          onPressed: _islemYapiliyor
              ? null
              : () {
                  if (_asama == 0) {
                    _kodGonder();
                  } else if (_asama == 1) {
                    _koduDogrula();
                  } else if (_asama == 2) {
                    _sifreGuncelle();
                  }
                },
          child: _islemYapiliyor
              ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  _asama == 2 ? 'Şifreyi Güncelle' : 'İleri',
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}

// =====================================================================
// GİRİŞ YAP SAYFASI
// =====================================================================
class GirisSayfasi extends StatefulWidget {
  const GirisSayfasi({super.key});
  @override
  State<GirisSayfasi> createState() => _GirisSayfasiState();
}

class _GirisSayfasiState extends State<GirisSayfasi> {
  bool _beniHatirla = false;
  bool _girisYapiliyor = false;

  final TextEditingController _kullaniciAdiController = TextEditingController();
  final TextEditingController _sifreController = TextEditingController();

  Future<void> girisYap() async {
    setState(() {
      _girisYapiliyor = true;
    });
    var url = Uri.parse("http://$SUNUCU_IP/nfc_api/giris_yap.php");
    try {
      var response = await http.post(
        url,
        body: {
          "kullanici_adi": _kullaniciAdiController.text.trim(),
          "sifre": _sifreController.text.trim(),
        },
      );
      var data = json.decode(response.body);
      if (data["basari"] == true) {
        aktifKullanici = data["kullanici"];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["mesaj"]), backgroundColor: Colors.green),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AnaEkran()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["mesaj"]), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sunucuya bağlanılamadı."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _girisYapiliyor = false;
      });
    }
  }

  @override
  void dispose() {
    _kullaniciAdiController.dispose();
    _sifreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.health_and_safety, size: 80, color: Colors.blue[700]),
              const SizedBox(height: 10),
              Text(
                'Giriş Yap',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _kullaniciAdiController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'TC Kimlik veya Tel No',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: Colors.blue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _sifreController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Şifreniz',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Colors.blue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Checkbox(
                    value: _beniHatirla,
                    activeColor: Colors.blue[700],
                    shape: const CircleBorder(),
                    onChanged: (v) {
                      setState(() {
                        _beniHatirla = v ?? false;
                      });
                    },
                  ),
                  const Text(
                    'Beni Hatırla',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: _girisYapiliyor ? null : girisYap,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[400]!, Colors.blue[800]!],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _girisYapiliyor
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Giriş Yap',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const SifreSifirlamaDialog(),
                  );
                },
                child: const Text(
                  'Şifrenizi mi unuttunuz?',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Hesabınız yok mu?',
                    style: TextStyle(color: Colors.grey),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const KayitOlSayfasi(),
                        ),
                      );
                    },
                    child: const Text(
                      'Kayıt Ol',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// AŞAMALI KAYIT OL SAYFASI
// =====================================================================
class KayitOlSayfasi extends StatefulWidget {
  const KayitOlSayfasi({super.key});
  @override
  State<KayitOlSayfasi> createState() => _KayitOlSayfasiState();
}

class _KayitOlSayfasiState extends State<KayitOlSayfasi> {
  int _aktifAdim = 0;
  bool _epostaKoduBekliyor = false;
  bool _telefonKoduBekliyor = false;
  bool _islemYapiliyor = false;
  int _epostaSaniye = 180;
  int _telefonSaniye = 180;
  Timer? _epostaTimer;
  Timer? _telefonTimer;
  final TextEditingController adController = TextEditingController();
  final TextEditingController soyadController = TextEditingController();
  final TextEditingController epostaController = TextEditingController();
  final TextEditingController epostaKodKontrolcu = TextEditingController();
  final TextEditingController telefonController = TextEditingController();
  final TextEditingController tcController = TextEditingController();
  final TextEditingController sifreController = TextEditingController();

  void _epostaSayacBaslat() {
    _epostaTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_epostaSaniye > 0) {
        setState(() {
          _epostaSaniye--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _telefonSayacBaslat() {
    _telefonTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_telefonSaniye > 0) {
        setState(() {
          _telefonSaniye--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _epostaTimer?.cancel();
    _telefonTimer?.cancel();
    adController.dispose();
    soyadController.dispose();
    epostaController.dispose();
    epostaKodKontrolcu.dispose();
    telefonController.dispose();
    tcController.dispose();
    sifreController.dispose();
    super.dispose();
  }

  String _formatliSure(int saniye) {
    int dk = saniye ~/ 60;
    int sn = saniye % 60;
    return '${dk.toString().padLeft(2, '0')}:${sn.toString().padLeft(2, '0')}';
  }

  Future<void> _epostaKoduGonder() async {
    if (epostaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen e-posta adresinizi girin.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _islemYapiliyor = true;
    });
    var url = Uri.parse("http://$SUNUCU_IP/nfc_api/eposta_kod_gonder.php");
    try {
      var response = await http.post(
        url,
        body: {"eposta": epostaController.text.trim()},
      );
      var data = json.decode(response.body);
      if (data["basari"] == true) {
        setState(() {
          _epostaKoduBekliyor = true;
          _epostaSaniye = 180;
        });
        _epostaSayacBaslat();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['mesaj']),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["mesaj"]), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sunucuya bağlanılamadı."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _islemYapiliyor = false;
      });
    }
  }

  Future<void> _epostaKoduDogrula() async {
    if (epostaKodKontrolcu.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen doğrulama kodunu girin.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _islemYapiliyor = true;
    });
    var url = Uri.parse("http://$SUNUCU_IP/nfc_api/eposta_kod_dogrula.php");
    try {
      var response = await http.post(
        url,
        body: {
          "eposta": epostaController.text.trim(),
          "kod": epostaKodKontrolcu.text.trim(),
        },
      );
      var data = json.decode(response.body);
      if (data["basari"] == true) {
        _epostaTimer?.cancel();
        setState(() {
          _aktifAdim++;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["mesaj"]), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["mesaj"]), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sunucuya bağlanılamadı."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _islemYapiliyor = false;
      });
    }
  }

  Future<void> veritabaninaKaydet() async {
    setState(() {
      _islemYapiliyor = true;
    });
    var url = Uri.parse("http://$SUNUCU_IP/nfc_api/kayit_ol.php");
    try {
      var response = await http.post(
        url,
        body: {
          "tc_kimlik": tcController.text.trim(),
          "ad_soyad":
              "${adController.text.trim()} ${soyadController.text.trim()}",
          "telefon": telefonController.text.trim(),
          "eposta": epostaController.text.trim(),
          "sifre": sifreController.text.trim(),
          "rol": "Hasta",
        },
      );
      var data = json.decode(response.body);
      if (data["basari"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["mesaj"]), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["mesaj"]), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sunucuya bağlanılamadı."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _islemYapiliyor = false;
      });
    }
  }

  void _ileriGit() {
    if (_aktifAdim == 0) {
      if (adController.text.isEmpty || soyadController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen ad ve soyad girin.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      setState(() {
        _aktifAdim++;
      });
      return;
    }
    if (_aktifAdim == 1) {
      if (!_epostaKoduBekliyor) {
        _epostaKoduGonder();
      } else {
        _epostaKoduDogrula();
      }
      return;
    }
    if (_aktifAdim == 2) {
      if (!_telefonKoduBekliyor) {
        setState(() {
          _telefonKoduBekliyor = true;
        });
        _telefonSayacBaslat();
      } else {
        _telefonTimer?.cancel();
        setState(() {
          _aktifAdim++;
        });
      }
      return;
    }
    if (_aktifAdim == 3) {
      veritabaninaKaydet();
    }
  }

  void _geriGit() {
    if (_aktifAdim == 1 && _epostaKoduBekliyor) {
      setState(() {
        _epostaKoduBekliyor = false;
      });
      _epostaTimer?.cancel();
      return;
    }
    if (_aktifAdim == 2 && _telefonKoduBekliyor) {
      setState(() {
        _telefonKoduBekliyor = false;
      });
      _telefonTimer?.cancel();
      return;
    }
    if (_aktifAdim > 0) {
      setState(() {
        _aktifAdim--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hesap Oluştur'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _geriGit,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: List.generate(4, (index) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 8,
                    decoration: BoxDecoration(
                      color: index <= _aktifAdim
                          ? Colors.blue[700]
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: SingleChildScrollView(child: _adimIceriginiGetir()),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: _islemYapiliyor ? null : _ileriGit,
                child: _islemYapiliyor
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _aktifAdim == 3 ? 'Kaydı Tamamla' : 'İleri',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _adimIceriginiGetir() {
    if (_aktifAdim == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sizi tanıyalım',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Lütfen kimlikte yazdığı şekliyle adınızı ve soyadınızı girin.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: adController,
            decoration: InputDecoration(
              labelText: 'Adınız',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: soyadController,
            decoration: InputDecoration(
              labelText: 'Soyadınız',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      );
    } else if (_aktifAdim == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'E-Posta Doğrulama',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Size ulaşabileceğimiz güvenli bir e-posta adresi girin.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: epostaController,
            readOnly: _epostaKoduBekliyor,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'E-Posta Adresi',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              suffixIcon: _epostaKoduBekliyor
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
            ),
          ),
          if (_epostaKoduBekliyor) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kod Gönderildi',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatliSure(_epostaSaniye),
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: epostaKodKontrolcu,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Mailinize Gelen 6 Haneli Kod',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                filled: true,
                fillColor: Colors.blue.withOpacity(0.05),
              ),
            ),
          ],
        ],
      );
    } else if (_aktifAdim == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Telefon Doğrulama',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Hesap güvenliğiniz için telefon numaranızı doğrulayın.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: telefonController,
            readOnly: _telefonKoduBekliyor,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Cep Telefonu',
              prefixText: '+90 ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              suffixIcon: _telefonKoduBekliyor
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
            ),
          ),
          if (_telefonKoduBekliyor) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SMS Onay Kodu Gönderildi',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatliSure(_telefonSaniye),
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Telefona Gelen SMS Kodu',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                filled: true,
                fillColor: Colors.blue.withOpacity(0.05),
              ),
            ),
          ],
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Son Adım',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Sisteme giriş için TC kimlik numaranızı ve bir şifre belirleyin.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: tcController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'TC Kimlik Numarası',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: sifreController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Yeni Şifre Belirleyin',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      );
    }
  }
}

// =====================================================================
// ANA EKRAN İSKELETİ VE DİĞER SAYFALAR
// =====================================================================
class AnaEkran extends StatefulWidget {
  const AnaEkran({super.key});
  @override
  State<AnaEkran> createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> {
  int _seciliSayfa = 0;
  final List<Widget> _sayfalar = [
    const AnaSayfaIcerigi(),
    const TibbiOzgecmisSayfasi(),
    const DoktorPinSayfasi(),
    const ProfilSayfasi(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _seciliSayfa, children: _sayfalar),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _seciliSayfa,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: Theme.of(context).cardColor,
        onTap: (index) {
          setState(() {
            _seciliSayfa = index;
          });
        },
        items: [
          // BURAYA DİKKAT: Metinler artık 'dilCevir' fonksiyonundan geçerek dillere göre değişiyor
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: dilCevir('Ana Sayfa'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: dilCevir('Özgeçmiş'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.pin_outlined),
            label: dilCevir('Doktor PIN'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: dilCevir('Profil'),
          ),
        ],
      ),
    );
  }
}

Widget _maviUstKisimBasit(
  BuildContext context,
  String baslik,
  String altBaslik,
  IconData ikon,
) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: Colors.white,
          child: Icon(ikon, size: 35, color: Colors.blue[900]),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dilCevir(baslik),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                dilCevir(altBaslik),
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class AnaSayfaIcerigi extends StatefulWidget {
  const AnaSayfaIcerigi({super.key});
  @override
  State<AnaSayfaIcerigi> createState() => _AnaSayfaIcerigiState();
}

class _AnaSayfaIcerigiState extends State<AnaSayfaIcerigi> {
  String _isimSoyisim = "Giriş Yapılmadı";
  String _kullaniciId = "-";
  DateTime _dogumTarihi = DateTime(1990, 1, 1);
  String _acilKisi = "-";
  String _kritikUyari = "Yok";
  bool _organBagiscisi = false;
  String _kanGrubu = "Belirtilmedi";
  String _tibbiOzet = "Henüz tıbbi özet girilmemiş.";
  String _kronikHastalik = "";
  String _alerjiler = "";
  String _kullanilanIlaclar = "";

  @override
  void initState() {
    super.initState();
    if (aktifKullanici != null) {
      _isimSoyisim = aktifKullanici!['ad_soyad'] ?? _isimSoyisim;
      _kullaniciId = aktifKullanici!['id'].toString();
      if (aktifKullanici!['dogum_tarihi'] != null) {
        try {
          _dogumTarihi = DateTime.parse(aktifKullanici!['dogum_tarihi']);
        } catch (e) {
          print("Tarih hatası");
        }
      }
      String ad = aktifKullanici!['acil_kisi_ad'] ?? '';
      String tel = aktifKullanici!['acil_kisi_telefon'] ?? '';
      _acilKisi = ad.isNotEmpty ? "$ad - $tel" : "Belirtilmedi";
      _kritikUyari = aktifKullanici!['kritik_uyari'] ?? "Yok";
      _organBagiscisi =
          aktifKullanici!['organ_bagiscisi'] == 1 ||
          aktifKullanici!['organ_bagiscisi'] == "1";

      // ----------------------------------------------------------------------
      // TIBBİ ÖZET VERİLERİNİ BAŞLANGIÇTA OTOMATİK GETİR (KALICI YAPILDI)
      // ----------------------------------------------------------------------
      _kanGrubu = aktifKullanici!['kan_grubu'] ?? "Belirtilmedi";
      if (_kanGrubu.isEmpty) _kanGrubu = "Belirtilmedi";

      _alerjiler = aktifKullanici!['alerjiler'] ?? "";
      _kronikHastalik = aktifKullanici!['kronik_hastaliklar'] ?? "";
      _kullanilanIlaclar = aktifKullanici!['kullanilan_ilaclar'] ?? "";

      if (_alerjiler.isNotEmpty ||
          _kronikHastalik.isNotEmpty ||
          _kullanilanIlaclar.isNotEmpty) {
        _tibbiOzet =
            "• Alerjiler: ${_alerjiler.isEmpty ? 'Yok' : _alerjiler}\n• Kronik Hastalık: ${_kronikHastalik.isEmpty ? 'Yok' : _kronikHastalik}\n• Kullanılan İlaçlar: ${_kullanilanIlaclar.isEmpty ? 'Yok' : _kullanilanIlaclar}";
      }
    }
  }

  Future<void> _hastaProfiliniVeritabaninaKaydet(String acilDurumMetni) async {
    if (aktifKullanici == null) return;
    var url = Uri.parse("http://$SUNUCU_IP/nfc_api/hasta_profili.php");
    String formattedDate =
        "${_dogumTarihi.year}-${_dogumTarihi.month.toString().padLeft(2, '0')}-${_dogumTarihi.day.toString().padLeft(2, '0')}";
    try {
      var response = await http.post(
        url,
        body: {
          "kullanici_id": _kullaniciId,
          "ad_soyad": _isimSoyisim,
          "dogum_tarihi": formattedDate,
          "acil_durum_metni": acilDurumMetni,
          "kritik_uyari": _kritikUyari,
          "organ_bagiscisi": _organBagiscisi ? "1" : "0",
        },
      );
      var data = json.decode(response.body);
      if (data["basari"] == true) {
        aktifKullanici!['ad_soyad'] = _isimSoyisim;
        aktifKullanici!['dogum_tarihi'] = formattedDate;
        aktifKullanici!['kritik_uyari'] = _kritikUyari;
        aktifKullanici!['organ_bagiscisi'] = _organBagiscisi ? 1 : 0;
        if (acilDurumMetni.contains('-')) {
          var parcalar = acilDurumMetni.split('-');
          aktifKullanici!['acil_kisi_ad'] = parcalar[0].trim();
          aktifKullanici!['acil_kisi_telefon'] = parcalar[1].trim();
        } else {
          aktifKullanici!['acil_kisi_ad'] = acilDurumMetni.trim();
          aktifKullanici!['acil_kisi_telefon'] = "";
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data["mesaj"]),
          backgroundColor: data["basari"] ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {}
  }

  Future<void> _tibbiProfiliVeritabaninaKaydet() async {
    if (aktifKullanici == null) return;
    var url = Uri.parse("http://$SUNUCU_IP/nfc_api/tibbi_profil_kaydet.php");
    try {
      var response = await http.post(
        url,
        body: {
          "kullanici_id": _kullaniciId,
          "kan_grubu": _kanGrubu,
          "kronik_hastaliklar": _kronikHastalik,
          "alerjiler": _alerjiler,
          "kullanilan_ilaclar": _kullanilanIlaclar,
        },
      );
      var data = json.decode(response.body);

      // HAFIZADA TUTMASI İÇİN AKTİF KULLANICIYA YAZILIYOR
      if (data["basari"] == true) {
        aktifKullanici!['kan_grubu'] = _kanGrubu;
        aktifKullanici!['alerjiler'] = _alerjiler;
        aktifKullanici!['kronik_hastaliklar'] = _kronikHastalik;
        aktifKullanici!['kullanilan_ilaclar'] = _kullanilanIlaclar;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data["mesaj"]),
          backgroundColor: data["basari"] ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {}
  }

  void _hastaProfiliDuzenlePenceresi() {
    String geciciIsim = _isimSoyisim;
    DateTime geciciTarih = _dogumTarihi;
    String geciciAcilKisi = _acilKisi == "Belirtilmedi" ? "" : _acilKisi;
    String geciciKritikUyari = _kritikUyari;
    bool geciciBagisci = _organBagiscisi;
    TextEditingController isimKontrolcu = TextEditingController(
      text: geciciIsim,
    );
    TextEditingController acilKontrolcu = TextEditingController(
      text: geciciAcilKisi,
    );
    TextEditingController uyariKontrolcu = TextEditingController(
      text: geciciKritikUyari,
    );
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPencereState) {
            return AlertDialog(
              title: const Text('Hasta Profilini Düzenle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: isimKontrolcu,
                      decoration: const InputDecoration(
                        labelText: 'İsim Soyisim',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    InkWell(
                      onTap: () async {
                        DateTime? secilenTarih = await showDatePicker(
                          context: context,
                          initialDate: geciciTarih,
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (secilenTarih != null) {
                          setPencereState(() {
                            geciciTarih = secilenTarih;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Doğum: ${geciciTarih.day}/${geciciTarih.month}/${geciciTarih.year}',
                            ),
                            const Icon(
                              Icons.calendar_month,
                              color: Colors.blueAccent,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: acilKontrolcu,
                      decoration: const InputDecoration(
                        labelText: 'Acil Durum (İsim - Tel)',
                        hintText: 'Örn: Ahmet Yılmaz - 05554443322',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: uyariKontrolcu,
                      decoration: const InputDecoration(
                        labelText: 'Kritik Uyarı (Kronik vb.)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Organ Bağışçısıyım'),
                        Switch(
                          value: geciciBagisci,
                          activeColor: Colors.blueAccent,
                          onChanged: (yeniDeger) {
                            setPencereState(() {
                              geciciBagisci = yeniDeger;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isimSoyisim = isimKontrolcu.text;
                      _dogumTarihi = geciciTarih;
                      _acilKisi = acilKontrolcu.text;
                      _kritikUyari = uyariKontrolcu.text;
                      _organBagiscisi = geciciBagisci;
                    });
                    _hastaProfiliniVeritabaninaKaydet(acilKontrolcu.text);
                    Navigator.pop(context);
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _kanGrubuSecmePenceresi() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Kan Grubunuzu Seçin'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _kanGrubuSecenekTusu('A Rh+'),
                _kanGrubuSecenekTusu('A Rh-'),
                _kanGrubuSecenekTusu('B Rh+'),
                _kanGrubuSecenekTusu('B Rh-'),
                _kanGrubuSecenekTusu('AB Rh+'),
                _kanGrubuSecenekTusu('AB Rh-'),
                _kanGrubuSecenekTusu('0 Rh+'),
                _kanGrubuSecenekTusu('0 Rh-'),
              ],
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------------------------
  // KAN GRUBU UYARI VE KİLİT SİSTEMİ (YENİ)
  // ----------------------------------------------------------------------
  void _kanGrubuKilitSistemi() {
    if (_kanGrubu != "Belirtilmedi" && _kanGrubu.isNotEmpty) {
      // KAN GRUBU ZATEN SEÇİLMİŞ - DEĞİŞTİRMESİ YASAK!
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock, color: Colors.red),
              SizedBox(width: 10),
              Text('İşlem Kilitli', style: TextStyle(color: Colors.red)),
            ],
          ),
          content: const Text(
            'Kan grubu genetik olarak değişmeyen bir veridir. Daha önce kan grubunuzu belirlediğiniz için tekrar değiştiremezsiniz.\n\nEğer yanlış girdiğinizi düşünüyorsanız lütfen hasta destek ekibiyle iletişime geçin.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
    } else {
      // KAN GRUBU İLK DEFA SEÇİLECEK - HAYATİ UYARI!
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange),
              SizedBox(width: 10),
              Text('Hayati Uyarı'),
            ],
          ),
          content: const Text(
            'Kan grubunuzu sadece BİR KEZ seçebilirsiniz ve bir daha değiştiremezsiniz. Yanlış kan grubu seçimi acil müdahalelerde hayati risk taşır.\n\nKan grubunuzdan kesin olarak eminseniz onaylayın.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                _kanGrubuSecmePenceresi();
              },
              child: const Text(
                'Eminim, Seçime Geç',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _kanGrubuSecenekTusu(String grupAdi) {
    return ListTile(
      title: Text(grupAdi, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.touch_app, size: 20, color: Colors.blueAccent),
      onTap: () {
        setState(() {
          _kanGrubu = grupAdi;
        });
        _tibbiProfiliVeritabaninaKaydet();
        Navigator.pop(context);
      },
    );
  }

  void _tibbiOzetDuzenlePenceresi() {
    TextEditingController alerjiKontrolcu = TextEditingController(
      text: _alerjiler,
    );
    TextEditingController kronikKontrolcu = TextEditingController(
      text: _kronikHastalik,
    );
    TextEditingController ilacKontrolcu = TextEditingController(
      text: _kullanilanIlaclar,
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tıbbi Özeti Düzenle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: alerjiKontrolcu,
                decoration: const InputDecoration(labelText: 'Alerjiler'),
              ),
              TextField(
                controller: kronikKontrolcu,
                decoration: const InputDecoration(
                  labelText: 'Kronik Hastalıklar',
                ),
              ),
              TextField(
                controller: ilacKontrolcu,
                decoration: const InputDecoration(
                  labelText: 'Kullanılan İlaçlar',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _alerjiler = alerjiKontrolcu.text;
                  _kronikHastalik = kronikKontrolcu.text;
                  _kullanilanIlaclar = ilacKontrolcu.text;
                  _tibbiOzet =
                      "• Alerjiler: ${_alerjiler.isEmpty ? 'Yok' : _alerjiler}\n• Kronik Hastalık: ${_kronikHastalik.isEmpty ? 'Yok' : _kronikHastalik}\n• Kullanılan İlaçlar: ${_kullanilanIlaclar.isEmpty ? 'Yok' : _kullanilanIlaclar}";
                });
                _tibbiProfiliVeritabaninaKaydet();
                Navigator.pop(context);
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _maviUstKisim(
            context,
            'Merhaba, ${_isimSoyisim.split(' ')[0]}!',
            dilCevir('Bileklik Aktif'),
            Icons.nfc,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DijitalKimlikSayfasi(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 15,
              right: 15,
              top: 10,
              bottom: 5,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: dilCevir('Hizmet veya bilgi arayın...'),
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.blueAccent,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                _tiklanabilirBilgiKarti(
                  baslik: dilCevir('Hasta Profili'),
                  icerik:
                      '$_isimSoyisim\nDoğum Tarihi: ${_dogumTarihi.day}/${_dogumTarihi.month}/${_dogumTarihi.year}\nKullanıcı ID: $_kullaniciId\nAcil Durum: $_acilKisi\nOrgan Bağışçısı: ${_organBagiscisi ? 'Evet' : 'Hayır'}\nKritik Uyarı: $_kritikUyari',
                  ikon: Icons.assignment_ind,
                  tiklandiginda: _hastaProfiliDuzenlePenceresi,
                ),
                const SizedBox(height: 15),
                // BURAYA DİKKAT: Kan grubu tıklandığında artık direkt açılmıyor, UYARI fonksiyonuna gidiyor
                _tiklanabilirKanGrubuKarti(
                  mevcutKanGrubu: _kanGrubu,
                  tiklandiginda: _kanGrubuKilitSistemi,
                ),
                const SizedBox(height: 15),
                _tiklanabilirBilgiKarti(
                  baslik: dilCevir('Tıbbi Özet'),
                  icerik: _tibbiOzet,
                  ikon: Icons.medical_information,
                  tiklandiginda: _tibbiOzetDuzenlePenceresi,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _maviUstKisim(
    BuildContext context,
    String baslik,
    String altBaslik,
    IconData ikon,
    VoidCallback profilTiklama,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: profilTiklama,
            child: CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Colors.blue[900]),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  baslik,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(ikon, size: 18, color: Colors.white70),
                    const SizedBox(width: 5),
                    Text(
                      altBaslik,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tiklanabilirBilgiKarti({
    required String baslik,
    required String icerik,
    required IconData ikon,
    required VoidCallback tiklandiginda,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: tiklandiginda,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(ikon, color: Colors.blueAccent, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          baslik,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.edit, size: 18, color: Colors.grey[400]),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 5),
                Text(
                  icerik,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tiklanabilirKanGrubuKarti({
    required String mevcutKanGrubu,
    required VoidCallback tiklandiginda,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: tiklandiginda,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dilCevir('Kan Grubu'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Icon(Icons.edit, size: 18, color: Colors.grey[400]),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.water_drop,
                      color: Colors.redAccent,
                      size: 50,
                    ),
                    const SizedBox(width: 15),
                    Text(
                      mevcutKanGrubu,
                      style: const TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DijitalKimlikSayfasi extends StatefulWidget {
  const DijitalKimlikSayfasi({super.key});
  @override
  State<DijitalKimlikSayfasi> createState() => _DijitalKimlikSayfasiState();
}

class _DijitalKimlikSayfasiState extends State<DijitalKimlikSayfasi> {
  bool _tcEslesmeYapildi = false;
  bool _yukleniyor = false;
  @override
  void initState() {
    super.initState();
    if (aktifKullanici != null &&
        aktifKullanici!['nfc_uid'] != null &&
        aktifKullanici!['nfc_uid'].toString().isNotEmpty) {
      _tcEslesmeYapildi = true;
    }
  }

  void _sistemeBaglan() async {
    if (aktifKullanici == null) return;
    setState(() {
      _yukleniyor = true;
    });
    String sahteNfcUid =
        "04:${Random().nextInt(99)}:${Random().nextInt(99)}:1F:2B:3C";
    var url = Uri.parse("http://$SUNUCU_IP/nfc_api/nfc_kaydet.php");
    try {
      var response = await http.post(
        url,
        body: {
          "kullanici_id": aktifKullanici!['id'].toString(),
          "nfc_uid": sahteNfcUid,
        },
      );
      var data = json.decode(response.body);
      if (data["basari"] == true) {
        aktifKullanici!['nfc_uid'] = sahteNfcUid;
        setState(() {
          _tcEslesmeYapildi = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["mesaj"]), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
    } finally {
      setState(() {
        _yukleniyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dijital Kimlik Kartı'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 80, color: Colors.blueAccent),
              ),
              const SizedBox(height: 20),
              Text(
                aktifKullanici?['ad_soyad'] ?? 'Bilinmeyen Kullanıcı',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Kullanıcı ID: ${aktifKullanici?['id'] ?? '-'}',
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 30),
              Icon(
                Icons.qr_code_2,
                size: 150,
                color: _tcEslesmeYapildi
                    ? Colors.green
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 10),
              const Text(
                'Sağlık kuruluşlarında bu kodu okutarak hızlı işlem yapabilirsiniz.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              if (_yukleniyor)
                const CircularProgressIndicator()
              else if (_tcEslesmeYapildi)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_user, color: Colors.green),
                      const SizedBox(width: 10),
                      Text(
                        'TC Kimlik Eşleştirildi\n(NFC: ${aktifKullanici!['nfc_uid']})',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _sistemeBaglan,
                  icon: const Icon(Icons.link, color: Colors.white),
                  label: const Text(
                    'TC Kimlik ile Eşleştir',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class TibbiOzgecmisSayfasi extends StatefulWidget {
  const TibbiOzgecmisSayfasi({super.key});
  @override
  State<TibbiOzgecmisSayfasi> createState() => _TibbiOzgecmisSayfasiState();
}

class _TibbiOzgecmisSayfasiState extends State<TibbiOzgecmisSayfasi> {
  bool _verilerKilitli = true;
  bool _yukleniyor = true;
  List<dynamic> _gecmisVerileri = [];
  @override
  void initState() {
    super.initState();
    _tibbiGecmisVerileriniGetir();
  }

  Future<void> _tibbiGecmisVerileriniGetir() async {
    if (aktifKullanici == null) return;
    var url = Uri.parse("http://$SUNUCU_IP/nfc_api/tibbi_gecmis_getir.php");
    try {
      var response = await http.post(
        url,
        body: {"kullanici_id": aktifKullanici!['id'].toString()},
      );
      var data = json.decode(response.body);
      if (data["basari"] == true) {
        setState(() {
          _gecmisVerileri = data["gecmis_kayitlari"];
          _yukleniyor = false;
        });
      } else {
        setState(() {
          _yukleniyor = false;
        });
      }
    } catch (e) {
      setState(() {
        _yukleniyor = false;
      });
    }
  }

  void _kilitDurumunuDegistir() {
    setState(() {
      _verilerKilitli = !_verilerKilitli;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _maviUstKisimBasit(
            context,
            'Tıbbi Özgeçmiş',
            'Sadece sağlık personeli güncelleyebilir',
            Icons.history,
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: _verilerKilitli
                ? _kilitliEkraniGoster()
                : _acikVerileriGoster(),
          ),
        ],
      ),
    );
  }

  Widget _kilitliEkraniGoster() {
    return GestureDetector(
      onTap: _kilitDurumunuDegistir,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.lock,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Hassas Veriler Kilitli',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tıbbi özgeçmişinizi görüntülemek için dokunun.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _acikVerileriGoster() {
    return Column(
      children: [
        GestureDetector(
          onTap: _kilitDurumunuDegistir,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_open, color: Colors.blueAccent, size: 20),
                SizedBox(width: 8),
                Text(
                  'Açık (Kilitlemek için dokun)',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        _yukleniyor
            ? const Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              )
            : _gecmisVerileri.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  "Henüz hastanede işlenmiş bir tıbbi geçmiş kaydı bulunmuyor.",
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _gecmisVerileri.length,
                itemBuilder: (context, index) {
                  var kayit = _gecmisVerileri[index];
                  return Column(
                    children: [
                      if (kayit['gecirilen_ameliyatlar'] != null &&
                          kayit['gecirilen_ameliyatlar'].toString().isNotEmpty)
                        _kilitliGecmisKarti(
                          'Geçirilen Ameliyatlar',
                          '• ${kayit['gecirilen_ameliyatlar']}\nTarih: ${kayit['olay_tarihi'] ?? '-'}\nKurum: ${kayit['kurum_hastane'] ?? '-'}',
                          Icons.local_hospital,
                        ),
                      if (kayit['surekli_kull_ilac'] != null &&
                          kayit['surekli_kull_ilac'].toString().isNotEmpty) ...[
                        const SizedBox(height: 15),
                        _kilitliGecmisKarti(
                          'Sürekli Kullanılan İlaçlar',
                          '• ${kayit['surekli_kull_ilac']}\nDoz: ${kayit['aciklama'] ?? '-'}',
                          Icons.medication,
                        ),
                      ],
                      if ((kayit['gecmis_tanilar'] != null &&
                              kayit['gecmis_tanilar'].toString().isNotEmpty) ||
                          (kayit['hastaliklar'] != null &&
                              kayit['hastaliklar'].toString().isNotEmpty)) ...[
                        const SizedBox(height: 15),
                        _kilitliGecmisKarti(
                          'Geçmiş Tanılar ve Hastalıklar',
                          '• ${kayit['gecmis_tanilar'] ?? kayit['hastaliklar']}\nTarih: ${kayit['olay_tarihi'] ?? '-'}',
                          Icons.coronavirus,
                        ),
                      ],
                      const SizedBox(height: 15),
                    ],
                  );
                },
              ),
      ],
    );
  }

  Widget _kilitliGecmisKarti(String baslik, String icerik, IconData ikon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(ikon, color: Colors.blueAccent, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    baslik,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.lock_outline, size: 18, color: Colors.grey),
            ],
          ),
          const Divider(),
          const SizedBox(height: 5),
          Text(
            icerik,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class DoktorPinSayfasi extends StatefulWidget {
  const DoktorPinSayfasi({super.key});
  @override
  State<DoktorPinSayfasi> createState() => _DoktorPinSayfasiState();
}

class _DoktorPinSayfasiState extends State<DoktorPinSayfasi> {
  String _guncelPin = "482 915";
  bool _yukleniyor = false;
  Future<void> _yeniPinUret() async {
    if (aktifKullanici == null) return;
    setState(() {
      _yukleniyor = true;
    });
    String yeniPin =
        "${(Random().nextInt(900000) + 100000).toString().substring(0, 3)} ${(Random().nextInt(900000) + 100000).toString().substring(3, 6)}";
    var url = Uri.parse("http://$SUNUCU_IP/nfc_api/pin_guncelle.php");
    try {
      var response = await http.post(
        url,
        body: {
          "kullanici_id": aktifKullanici!['id'].toString(),
          "yeni_pin": yeniPin,
        },
      );
      var data = json.decode(response.body);
      if (data["basari"] == true) {
        setState(() {
          _guncelPin = yeniPin;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["mesaj"]), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
    } finally {
      setState(() {
        _yukleniyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _maviUstKisimBasit(
          context,
          'Doktor PIN',
          'Geçici Erişim Şifresi',
          Icons.security,
        ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.lock_clock,
                  size: 60,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 20),
                Text(
                  'Sağlık personeline aşağıdaki PIN kodunu vererek bilgilerinize ulaşmasını sağlayabilirsiniz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  _guncelPin,
                  style: TextStyle(
                    fontSize: 45,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 5,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _yukleniyor ? null : _yeniPinUret,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _yukleniyor
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Yeni PIN Oluştur',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DoktorGirisSayfasi(),
                      ),
                    );
                  },
                  icon: Icon(Icons.medical_services, color: Colors.blue[900]),
                  label: Text(
                    'Doktor Girişi',
                    style: TextStyle(
                      color: Colors.blue[900],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ProfilSayfasi extends StatelessWidget {
  const ProfilSayfasi({super.key});
  void _cikisYapOnayi(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Çıkış Yap'),
          content: const Text(
            'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hayır, İptal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                aktifKullanici = null;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const GirisSayfasi()),
                  (route) => false,
                );
              },
              child: const Text(
                'Evet, Çıkış Yap',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _maviUstKisimBasit(
            context,
            dilCevir('Profil'),
            'Hesap Ayarları',
            Icons.settings,
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _profilSecenegi(
                    context,
                    'Kişisel Bilgiler',
                    Icons.person_outline,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const KisiselBilgilerSayfasi(),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  _profilSecenegi(
                    context,
                    'Bileklik Kimliği',
                    Icons.nfc,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NfcAyarlariSayfasi(),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  _profilSecenegi(
                    context,
                    'Güvenlik ve Bildirimler',
                    Icons.notifications_none,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BildirimlerSayfasi(),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  _profilSecenegi(
                    context,
                    dilCevir('Ayarlar'),
                    Icons.settings_outlined,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AyarlarSayfasi(),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  _profilSecenegi(
                    context,
                    'Çıkış Yap',
                    Icons.exit_to_app,
                    () => _cikisYapOnayi(context),
                    kirmiziMi: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profilSecenegi(
    BuildContext context,
    String baslik,
    IconData ikon,
    VoidCallback basildiginda, {
    bool kirmiziMi = false,
  }) {
    return ListTile(
      leading: Icon(ikon, color: kirmiziMi ? Colors.red : Colors.blueAccent),
      title: Text(
        baslik,
        style: TextStyle(
          fontSize: 16,
          color: kirmiziMi
              ? Colors.red
              : Theme.of(context).textTheme.bodyLarge?.color,
          fontWeight: kirmiziMi ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: basildiginda,
    );
  }
}

class KisiselBilgilerSayfasi extends StatefulWidget {
  const KisiselBilgilerSayfasi({super.key});
  @override
  State<KisiselBilgilerSayfasi> createState() => _KisiselBilgilerSayfasiState();
}

class _KisiselBilgilerSayfasiState extends State<KisiselBilgilerSayfasi> {
  final TextEditingController epostaController = TextEditingController(
    text: aktifKullanici?['eposta'] ?? '',
  );
  final TextEditingController telefonController = TextEditingController(
    text: aktifKullanici?['telefon'] ?? '',
  );
  final TextEditingController evAdresiController = TextEditingController(
    text: aktifKullanici?['ev_adresi'] ?? '',
  );
  bool _guncelleniyor = false;
  Future<void> _bilgileriGuncelle() async {
    if (aktifKullanici == null) return;
    setState(() {
      _guncelleniyor = true;
    });
    var url = Uri.parse("http://$SUNUCU_IP/nfc_api/profil_guncelle.php");
    try {
      var response = await http.post(
        url,
        body: {
          "kullanici_id": aktifKullanici!['id'].toString(),
          "eposta": epostaController.text.trim(),
          "telefon": telefonController.text.trim(),
          "ev_adresi": evAdresiController.text.trim(),
        },
      );
      var data = json.decode(response.body);
      if (data["basari"] == true) {
        aktifKullanici!['eposta'] = epostaController.text.trim();
        aktifKullanici!['telefon'] = telefonController.text.trim();
        aktifKullanici!['ev_adresi'] = evAdresiController.text.trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["mesaj"]), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
    } finally {
      setState(() {
        _guncelleniyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kişisel Bilgiler'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              TextField(
                controller: epostaController,
                decoration: const InputDecoration(
                  labelText: 'E-Posta Adresi',
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: telefonController,
                decoration: const InputDecoration(
                  labelText: 'Telefon Numarası',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: evAdresiController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Ev Adresi',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guncelleniyor ? null : _bilgileriGuncelle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: _guncelleniyor
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Bilgilerimi Güncelle',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NfcAyarlariSayfasi extends StatefulWidget {
  const NfcAyarlariSayfasi({super.key});
  @override
  State<NfcAyarlariSayfasi> createState() => _NfcAyarlariSayfasiState();
}

class _NfcAyarlariSayfasiState extends State<NfcAyarlariSayfasi> {
  bool _kayipModu = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bileklik Kimliği'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[900],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.nfc, size: 80, color: Colors.white),
                  const SizedBox(height: 10),
                  const Text(
                    'Pasif Sağlık Çipi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'UID: ${aktifKullanici?['nfc_uid'] ?? 'Eşleştirilmedi'}',
                      style: const TextStyle(
                        color: Colors.white,
                        letterSpacing: 2,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.history, color: Colors.blue),
                    title: const Text('Son Okutulma'),
                    subtitle: const Text(
                      '12 Ekim 2026 - 14:45\nDenizli Devlet Hastanesi',
                    ),
                    trailing: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text(
                      'Kayıp/Çalıntı Modu',
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: const Text(
                      'Açıldığında bilekliğiniz okutulursa tüm hassas veriler kilitlenir.',
                    ),
                    secondary: const Icon(
                      Icons.warning_amber,
                      color: Colors.red,
                    ),
                    value: _kayipModu,
                    activeColor: Colors.red,
                    onChanged: (v) {
                      setState(() {
                        _kayipModu = v;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BildirimlerSayfasi extends StatefulWidget {
  const BildirimlerSayfasi({super.key});
  @override
  State<BildirimlerSayfasi> createState() => _BildirimlerSayfasiState();
}

class _BildirimlerSayfasiState extends State<BildirimlerSayfasi> {
  bool _okunmaBildirimi = true;
  bool _veriGuncelleme = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Güvenlik ve Bildirimler'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Bileklik Okutulduğunda Bildir'),
                subtitle: const Text(
                  'Bilekliğiniz okutulduğunda anında bildirim gelir.',
                ),
                value: _okunmaBildirimi,
                onChanged: (v) {
                  setState(() {
                    _okunmaBildirimi = v;
                  });
                },
                activeColor: Colors.blueAccent,
                secondary: const Icon(Icons.cell_wifi),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Sağlık Verisi Güncellendiğinde'),
                subtitle: const Text('Dosyanıza veri işlendiğinde bildir.'),
                value: _veriGuncelleme,
                onChanged: (v) {
                  setState(() {
                    _veriGuncelleme = v;
                  });
                },
                activeColor: Colors.blueAccent,
                secondary: const Icon(Icons.update),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AyarlarSayfasi extends StatefulWidget {
  const AyarlarSayfasi({super.key});
  @override
  State<AyarlarSayfasi> createState() => _AyarlarSayfasiState();
}

class _AyarlarSayfasiState extends State<AyarlarSayfasi> {
  void _dilSecimiGoster() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(dilCevir('Dil')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dilRadyosu('Türkçe', context),
              _dilRadyosu('English', context),
              _dilRadyosu('Deutsch', context),
              _dilRadyosu('العربية', context),
            ],
          ),
        );
      },
    );
  }

  // DİL SEÇİLDİĞİNDE HAFIZAYA KAYDEDER
  Widget _dilRadyosu(String dil, BuildContext context) {
    return RadioListTile(
      title: Text(dil),
      value: dil,
      groupValue: dilYonetici.value,
      activeColor: Colors.blueAccent,
      onChanged: (v) async {
        dilYonetici.value = v.toString();
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('dil', v.toString());
        if (mounted) Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(dilCevir('Ayarlar')),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text(dilCevir('Karanlik')),
                secondary: const Icon(Icons.dark_mode),
                value: temaYonetici.value,
                activeColor: Colors.blueAccent,
                // TEMA DEĞİŞTİĞİNDE HAFIZAYA KAYDEDER
                onChanged: (v) async {
                  temaYonetici.value = v;
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  prefs.setBool('karanlikMod', v);
                },
              ),
              const Divider(height: 1),
              ValueListenableBuilder<String>(
                valueListenable: dilYonetici,
                builder: (context, aktifDil, child) {
                  return ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(dilCevir('Dil')),
                    trailing: Text(
                      aktifDil,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    onTap: _dilSecimiGoster,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DoktorGirisSayfasi extends StatefulWidget {
  const DoktorGirisSayfasi({super.key});
  @override
  State<DoktorGirisSayfasi> createState() => _DoktorGirisSayfasiState();
}

class _DoktorGirisSayfasiState extends State<DoktorGirisSayfasi> {
  final TextEditingController tcKontrolcu = TextEditingController();
  final TextEditingController diplomaTescilKontrolcu = TextEditingController();
  final TextEditingController personelSicilKontrolcu = TextEditingController();
  final TextEditingController uzmanlikTescilKontrolcu = TextEditingController();
  final TextEditingController sifreKontrolcu = TextEditingController();
  bool _yukleniyor = false;
  Future<void> _doktorDogrula() async {
    setState(() {
      _yukleniyor = true;
    });
    var url = Uri.parse("http://$SUNUCU_IP/nfc_api/doktor_giris.php");
    try {
      var response = await http.post(
        url,
        body: {
          "tc_kimlik": tcKontrolcu.text.trim(),
          "diploma_tescil": diplomaTescilKontrolcu.text.trim(),
          "personel_sicil": personelSicilKontrolcu.text.trim(),
          "uzmanlik_tescil": uzmanlikTescilKontrolcu.text.trim(),
          "sifre": sifreKontrolcu.text.trim(),
        },
      );
      var data = json.decode(response.body);
      if (data["basari"] == true) {
        aktifDoktorTc = tcKontrolcu.text.trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["mesaj"]), backgroundColor: Colors.green),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HastaPinSorgulamaSayfasi(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["mesaj"]), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
    } finally {
      setState(() {
        _yukleniyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doktor Paneli Girişi'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: const Text(
                    '"Beni Türk Hekimlerine Emanet Ediniz."',
                    style: TextStyle(
                      fontSize: 24,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w300,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  alignment: Alignment.center,
                  child: Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Mustafa_Kemal_Atat%C3%BCrk%27s_signature.svg/512px-Mustafa_Kemal_Atat%C3%BCrk%27s_signature.svg.png',
                    height: 60,
                    color: Colors.black,
                    errorBuilder: (context, error, stackTrace) => const Text(
                      'K. Atatürk',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Icon(Icons.admin_panel_settings, size: 60, color: Colors.blue[900]),
            const SizedBox(height: 10),
            const Text(
              'Lütfen Doktor Kimliğinizi Doğrulayın',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: tcKontrolcu,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'TC Kimlik Numarası',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: diplomaTescilKontrolcu,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Diploma Tescil Numarası',
                prefixIcon: const Icon(Icons.school),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: personelSicilKontrolcu,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Personel Sicil Numarası',
                prefixIcon: const Icon(Icons.badge),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: uzmanlikTescilKontrolcu,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Uzmanlık Tescil Kaydı Numarası',
                hintText: 'Varsa yazınız, yoksa boş kalabilir.',
                helperText: 'Sadece uzman hekimlerimiz içindir.',
                prefixIcon: const Icon(Icons.star),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: sifreKontrolcu,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Doktor Şifresi',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _yukleniyor ? null : _doktorDogrula,
                child: _yukleniyor
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Yetkiyi Doğrula ve Giriş Yap',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class HastaPinSorgulamaSayfasi extends StatefulWidget {
  const HastaPinSorgulamaSayfasi({super.key});
  @override
  State<HastaPinSorgulamaSayfasi> createState() =>
      _HastaPinSorgulamaSayfasiState();
}

class _HastaPinSorgulamaSayfasiState extends State<HastaPinSorgulamaSayfasi> {
  final TextEditingController pinKontrolcu = TextEditingController();
  bool _sorgulaniyor = false;
  Future<void> _pinSorgula() async {
    if (pinKontrolcu.text.isEmpty) return;
    setState(() {
      _sorgulaniyor = true;
    });
    var url = Uri.parse("http://$SUNUCU_IP/nfc_api/hasta_pin_kontrol.php");
    try {
      var response = await http.post(
        url,
        body: {"pin": pinKontrolcu.text.trim()},
      );
      var data = json.decode(response.body);
      if (data["basari"] == true) {
        var hastaBilgisi = data["hasta_bilgisi"];
        var gecmisKayitlar = data["gecmis_kayitlar"];
        _izinKoduGonder(hastaBilgisi, gecmisKayitlar);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["mesaj"]), backgroundColor: Colors.red),
        );
        setState(() {
          _sorgulaniyor = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sunucu bağlantı hatası!"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _sorgulaniyor = false;
      });
    }
  }

  Future<void> _izinKoduGonder(
    Map<String, dynamic> hastaBilgisi,
    List<dynamic> gecmisKayitlar,
  ) async {
    String hastaEposta = hastaBilgisi['eposta'] ?? '';
    if (hastaEposta.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hastanın sisteme kayıtlı bir e-postası bulunmuyor!'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _sorgulaniyor = false;
      });
      return;
    }
    var url = Uri.parse(
      "http://$SUNUCU_IP/nfc_api/doktor_izin_kodu_gonder.php",
    );
    try {
      var response = await http.post(
        url,
        body: {
          "eposta": hastaEposta,
          "doktor_tc": aktifDoktorTc ?? 'Bilinmeyen',
        },
      );
      var data = json.decode(response.body);
      if (data["basari"] == true) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HastaMailOnaySayfasi(
              eposta: hastaEposta,
              hastaBilgisi: hastaBilgisi,
              gecmisKayitlar: gecmisKayitlar,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["mesaj"]), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sunucu bağlantı hatası!"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _sorgulaniyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasta PIN Sorgulama'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.health_and_safety, size: 80, color: Colors.green[700]),
            const SizedBox(height: 20),
            const Text(
              'Hastanızın Ekranındaki PIN Kodunu Giriniz',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: pinKontrolcu,
              keyboardType: TextInputType.text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 5),
              decoration: InputDecoration(
                hintText: 'Örn: 123 456',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _sorgulaniyor ? null : _pinSorgula,
                child: _sorgulaniyor
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Sorgula ve Hastadan İzin İste',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HastaMailOnaySayfasi extends StatefulWidget {
  final String eposta;
  final Map<String, dynamic> hastaBilgisi;
  final List<dynamic> gecmisKayitlar;
  const HastaMailOnaySayfasi({
    super.key,
    required this.eposta,
    required this.hastaBilgisi,
    required this.gecmisKayitlar,
  });
  @override
  State<HastaMailOnaySayfasi> createState() => _HastaMailOnaySayfasiState();
}

class _HastaMailOnaySayfasiState extends State<HastaMailOnaySayfasi> {
  final TextEditingController onayKoduKontrolcu = TextEditingController();
  bool _dogrulaniyor = false;
  String _epostaMaskele(String email) {
    if (!email.contains('@')) return email;
    List<String> parcalar = email.split('@');
    String isim = parcalar[0];
    String uzanti = parcalar[1];
    if (isim.length <= 3) return "${isim[0]}***@$uzanti";
    return "${isim.substring(0, 2)}***${isim.substring(isim.length - 1)}@$uzanti";
  }

  Future<void> _koduDogrula() async {
    if (onayKoduKontrolcu.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen 6 haneli kodu eksiksiz girin.")),
      );
      return;
    }
    setState(() {
      _dogrulaniyor = true;
    });
    var url = Uri.parse(
      "http://$SUNUCU_IP/nfc_api/doktor_izin_kodu_dogrula.php",
    );
    try {
      var res = await http.post(
        url,
        body: {"eposta": widget.eposta, "kod": onayKoduKontrolcu.text.trim()},
      );
      if (res.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "API dosyası bulunamadı! Lütfen PHP dosya adını kontrol edin.",
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _dogrulaniyor = false;
        });
        return;
      }
      var data = json.decode(res.body);
      if (data["basari"] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DoktorHastaDosyasiSayfasi(
              hastaBilgisi: widget.hastaBilgisi,
              gecmisKayitlar: widget.gecmisKayitlar,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Hatalı Kod! Lütfen hastadan aldığınız kodu tekrar kontrol edin.",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Sunucuya ulaşılamadı. Lütfen bağlantınızı kontrol edin.",
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _dogrulaniyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KVKK E-Posta Doğrulama'),
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.security, size: 80, color: Colors.red[800]),
              const SizedBox(height: 20),
              Text(
                "Hastanın (${_epostaMaskele(widget.eposta)}) E-Posta Adresine Onay Kodu Gönderildi.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "KVKK gereği; hastanın dosyasını görüntüleyebilmek ve işlem yapabilmek için hastanızın e-postasına gönderilen 6 haneli güvenlik kodunu aşağıya girmelisiniz.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: onayKoduKontrolcu,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 30,
                  letterSpacing: 10,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: '000000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  filled: true,
                  fillColor: Colors.red.withOpacity(0.05),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[800],
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _dogrulaniyor ? null : _koduDogrula,
                  child: _dogrulaniyor
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Kodu Doğrula ve Dosyayı Aç',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DoktorHastaDosyasiSayfasi extends StatefulWidget {
  final Map<String, dynamic> hastaBilgisi;
  final List<dynamic> gecmisKayitlar;
  const DoktorHastaDosyasiSayfasi({
    super.key,
    required this.hastaBilgisi,
    required this.gecmisKayitlar,
  });
  @override
  State<DoktorHastaDosyasiSayfasi> createState() =>
      _DoktorHastaDosyasiSayfasiState();
}

class _DoktorHastaDosyasiSayfasiState extends State<DoktorHastaDosyasiSayfasi> {
  final TextEditingController taniKontrolcu = TextEditingController();
  final TextEditingController ameliyatKontrolcu = TextEditingController();
  final TextEditingController ilacKontrolcu = TextEditingController();
  bool _kaydediliyor = false;
  Future<void> _yeniMuayeneKaydet() async {
    setState(() {
      _kaydediliyor = true;
    });
    var url = Uri.parse("http://$SUNUCU_IP/nfc_api/muayene_kaydet.php");
    try {
      var response = await http.post(
        url,
        body: {
          "hasta_id": widget.hastaBilgisi['id'].toString(),
          "doktor_tc": aktifDoktorTc ?? 'Bilinmeyen',
          "hastalik_tanisi": taniKontrolcu.text.trim(),
          "yapilan_ameliyat": ameliyatKontrolcu.text.trim(),
          "verilen_ilaclar": ilacKontrolcu.text.trim(),
        },
      );
      var data = json.decode(response.body);
      if (data["basari"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["mesaj"]), backgroundColor: Colors.green),
        );
        taniKontrolcu.clear();
        ameliyatKontrolcu.clear();
        ilacKontrolcu.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["mesaj"]), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sunucu bağlantı hatası!"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _kaydediliyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.hastaBilgisi['ad_soyad']} Dosyası'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Geçmiş Muayene ve İşlem Kayıtları",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            widget.gecmisKayitlar.isEmpty
                ? const Text(
                    "Bu hastanın sistemde geçmiş kayıtlı işlemi bulunmuyor.",
                    style: TextStyle(color: Colors.grey),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.gecmisKayitlar.length,
                    itemBuilder: (context, index) {
                      var kayit = widget.gecmisKayitlar[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const Icon(
                            Icons.history,
                            color: Colors.teal,
                          ),
                          title: Text(
                            "Tarih: ${kayit['islem_tarihi']}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "Tanı: ${kayit['hastalik_tanisi'] ?? 'Yok'}\nAmeliyat: ${kayit['yapilan_ameliyat'] ?? 'Yok'}\nİlaçlar: ${kayit['verilen_ilaclar'] ?? 'Yok'}",
                          ),
                        ),
                      );
                    },
                  ),
            const Divider(height: 40, thickness: 2),
            const Text(
              "Yeni İşlem / Muayene Ekle",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const Text(
              "KVKK onayı alınmıştır. Bilgiler kaydedildiğinde hastaya anlık mail iletilecektir.",
              style: TextStyle(fontSize: 12, color: Colors.green),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: taniKontrolcu,
              decoration: const InputDecoration(
                labelText: 'Hastalık Tanısı / Şikayet',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: ameliyatKontrolcu,
              decoration: const InputDecoration(
                labelText: 'Yapılan Ameliyat / Müdahale (Yoksa boş bırakın)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: ilacKontrolcu,
              decoration: const InputDecoration(
                labelText: 'Reçete Edilen İlaçlar',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[700],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: _kaydediliyor ? null : _yeniMuayeneKaydet,
                icon: _kaydediliyor
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save, color: Colors.white),
                label: Text(
                  _kaydediliyor
                      ? 'Kaydediliyor...'
                      : 'Hastanın Dosyasına Kaydet ve Bildir',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
