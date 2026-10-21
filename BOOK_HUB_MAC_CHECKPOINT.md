# Book Hub — doğrulanan Mac geliştirme paketi

Tarih: 8 Ekim 2026. Temel sürüm: Stage 21.0.1 Profile Switch Fix üzerine aynı ComicPort projesinde geliştirme. iPad kontrolleri kullanıcı isteğiyle durduruldu.

## Geliştirme planının durumu

| Paket | Mac durumu |
| --- | --- |
| Books seçildiğinde sol üst Book Hub kimliği | Tamamlandı |
| Sıcak ahşap/kütüphane renkleri ve Books dashboard | Tamamlandı |
| Books veri modeli, eski kayıtlara uyumlu geçiş | Tamamlandı |
| Yazar/yayınevi/ISBN/dil/yıl/özet ve kaynak bilgisi | Tamamlandı |
| Kitap bilgisi düzenleme ve kapak seçimi | Tamamlandı |
| Türkçe karakterleri destekleyen bibliyografik arama | Tamamlandı |
| Yazar/yayınevi rafları, sıralama ve eksik bilgi listeleri | Tamamlandı |
| Okuma filtreleri, sınırlandırılmış okuma kuyruğu ve ilerleme metinleri | Tamamlandı |
| Yerel EPUB aktarımı ve metin okuyucusu | Tamamlandı; kapsam sınırları aşağıda |
| EPUB bölüm, tema, yazı boyutu, yer imi, işaret ve not kaydı | Tamamlandı |
| Kitap içi arama ve EPUB bölümüne gitme | Tamamlandı; seçili profil kapsamıyla |
| Kullanıcı isteğiyle ISBN’den bilgi ve kapak önerisi | Tamamlandı |
| 40 Book Hub başarımı; kitap/çizgi roman ayrı sekmeleri | Tamamlandı |
| Performans sınırları ve 1.000 kayıtlı native Mac testi | Tamamlandı |
| Son temiz Mac Catalyst Release build ve uygulama açılışı | Başarılı |
| iPad/device/simülatör testleri | Durduruldu; doğrulanmış sayılmaz |

## Son doğrulama

Mac Catalyst Debug paket derlemeleri ve son Release `clean build` başarılıdır. Son temiz derlemede compiler hatası veya uyarısı bulunmadı. Release sürümünde geliştirme test klasörü seçimi devre dışı kaldı; normal kütüphane açıldı. Son Release açılış kaydında uygulama hatası/crash kaydı görülmedi.

Model kontrolleri eski kütüphane kayıtları, bibliyografik alanlar, ISBN, arama, sıralama, filtre, okuma kuyruğu, başarımların ayrılması, EPUB konumu/ayarları ve metadata birleştirmesini kapsar. EPUB paket kontrolleri bölüm sırası, Unicode, metadata, bozuk XML ve dışarı çıkan yolları kapsar. Metadata ve kapak kuyruklarının sınırları, yinelenen istekler ve önbellek yenilenmesi doğrulandı.

Native Mac testlerinde EPUB import/okuma, ayar ve notların yeniden başlatma sonrası korunması, bölüm metni arama, açık tamamlama eylemi ve ISBN/kapak önerileri çalıştı. PDF okuyucusunda sayfa düzeni, ileri/geri tuşları ve Escape ile çıkış doğrulandı. Başarım ekranında 40 kitap başarımı ile mevcut 241 çizgi roman başarımı ayrı gösterildi; mevcut 6 çizgi roman kilidi korundu.

1.000 sentetik kitapla ayrı kütüphane açıldı; rafın sonuna kaydırma, arama, sıralama ve birleşik filtreler çalıştı. Gerçek kayıtların dosya özetleri test öncesi/sonrası aynı kaldı. Büyük EPUB kapağı 4.000×6.000’den 800×1.200’e küçültüldü. Ölçüm ayrıntıları BOOK_HUB_PERFORMANCE.md içindedir.

Normal kütüphanedeki iki smoke test kitabı arşivde saklanır. Bu testlerle kazanılan kitap başarımları korunmuştur; kazanılmış başarımlar arşivleme ile geri alınmaz. 1.000 kayıt ve büyük kapak testi ayrı geliştirme klasöründedir.

## Sınırlar

EPUB okuyucusu bu sürümde metin odaklıdır. Kitap içi görseller, yayıncı CSS düzeni, sabit sayfa düzeni, ses/video ve DRM desteklenmez. EPUB bölümleri gerçek sayfa olarak başarımlara sayılmaz; süre, seri ve tamamlanan kitap başarımları kullanılabilir.

10.000 kayıt yalnızca veri işlemlerinde ölçüldü; bu büyüklükte ekran veya uzun süreli tepe bellek performansı doğrulanmadı. Çevrimiçi metadata ISBN’ye dayalı öneridir; içerikle otomatik doğrulanmış eşleşme değildir. macOS metin servislerine ait uyarılar önceki not testlerinde görüldü; kayıt/okuma çalıştı.

Bu doğrulama yerel Mac uygulaması içindir. App Store dağıtım imzası, noter onayı ve iPad desteği için tamamlanmış bir dağıtım doğrulaması değildir.

Git geri dönüş etiketi: `checkpoint-bookhub-mac-verified-20261008`.
