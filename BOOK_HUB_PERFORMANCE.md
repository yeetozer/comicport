# Book Hub — performans ve Mac kontrolü

## Uygulanan prensipler

Kütüphanenin diskten yüklenmesi ilk ekran sonrası arka planda yapılır. Ana sayfadaki okuma ve yeni eklenen rafları sınırlı sayıda kayıt gösterir; kitap rafı LazyVGrid kullanır. Yazar sıralamasında karşılaştırma anahtarları kayıt başına bir defa hazırlanır. Arama kitap dosyalarını açmaz.

Metadata işleri seri yürütülür; bekleyen işler 8, metadata bellek önbelleği 32 kayıtla sınırlıdır. Aynı analiz ve kapak istekleri birleştirilir. Kapak çözümleme aynı anda en fazla 2 iş yapar; NSCache Mac üzerinde 360 kayıt/256 MB maliyet sınırı kullanır ve bellek uyarısında temizlenir. Bu sınırlar tüm uygulamanın toplam RAM sınırı değildir.

EPUB kapağı artık tam çözünürlüklü UIImage oluşturmak yerine ImageIO ile en fazla 1200 piksele küçültülür. Çevrimiçi kapak seçimi de aynı hazırlama işlevini kullanır. Kitap başarımları, kullanılmayan çizgi roman seri hesaplamasını çalıştırmaz.

## Ölçüm

Üretim Models.swift kodu, optimize edilmiş Swift derlemesiyle 3 tekrar ölçüldü. Aşağıdaki son ölçüm Mac derlemesi bittikten sonra alındı. Değerler bu Mac'teki ortanca süredir; açılış veya ekran kare süresi değildir.

| İşlem | 1.000 kayıt | 10.000 kayıt |
| --- | ---: | ---: |
| JSON çözümleme | 11,9 ms | 118,5 ms |
| Çok sözcüklü arama | 7,7 ms | 75,3 ms |
| Türkçe yazar araması | 7,3 ms | 75,5 ms |
| Yazara göre sıralama | 19,7 ms | 151,5 ms |
| Yazar ve yayınevi rafları | 3,3 ms | 46,4 ms |
| Sınırlı okuma kuyruğu | 0,3 ms | 2,7 ms |

10.000 kayıt yalnızca veri işlemleriyle ölçüldü; bu büyüklükte ekran performansı doğrulanmış değildir. Son ölçümde 10.000 kaydın yazar sıralamasındaki en yavaş tekrar 310,1 ms idi. Bu süreler 10.000 kayıt için gelecekte arka plan hesaplaması gereksinimine işaret eder. Önceki ölçümde 1.000 kayıtta arama 26,6 ms, sıralama 42,6 ms sürdü; sonuçlar sistem yüküne göre değişir.

## Native Mac testi

Geliştirme sürümünde COMICPORT_TEST_LIBRARY ortam değişkeniyle ayrı kayıt klasörü seçilebilir. Release sürümünde bu seçim derlenmez. Ayrı LibraryStore; gerçek kütüphanenin kayıt, kaynak klasörü, senkronizasyon ve aktif profil ayarlarını yüklemez.

1.000 sentetik kitap, 1.000 ayrı kapak dosya yolu ve ortak dört sayfalık test PDF'i kullanıldı. Kapaklar aynı sentetik 240×360 görselin kopyalarıdır; 1.000 farklı büyük kitap dosyası testi yapılmadı. Ana ekran, rafın sonuna kaydırma, tek kayıt araması, Türkçe yazar araması (200 sonuç), birleşik favori filtresi (100 sonuç) ve yazar sıralaması çalıştı. Boşta tek ölçümde RSS yaklaşık 106 MB ve CPU %0 idi; uzun süreli profil veya tepe bellek ölçümü değildir.

4.000×6.000 kapaklı ek test EPUB'u içe aktarıldı; kaydedilen kapak 800×1.200 olarak doğrulandı. PDF okuyucusunda tek sayfa düzeni, ileri/geri tuşları ve Escape ile çıkış çalıştı.

Test öncesi/sonrası dosya özetleri karşılaştırıldı: gerçek kütüphane, okuma istatistikleri, başarımlar, notlar ve okuyucu ayarları değişmedi. Genel Book Hub model, EPUB paket, metadata ve kapak kuyruğu testleri geçti. iPad kontrolleri durdurulmuş olarak bırakıldı.

Tekrar ölçüm: `python3 Tests/run-bookhub-performance.py`. Bu komut sentetik kayıtlarla çalışır; gerçek kütüphaneyi okumaz.
