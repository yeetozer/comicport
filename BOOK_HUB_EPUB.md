# Book Hub — EPUB ve okuma araçları

DRM koruması olmayan EPUB dosyaları içe aktarılabilir ve Books içeriği olarak kaydedilir. EPUB paketindeki başlık, yazar, yayınevi, dil, ISBN ve varsa kapak alınır. Bölüm sırası paket içindeki spine bilgisinden okunur.

Metin okuyucusunda bölüm gezintisi, 14–36 punto yazı boyutu, açık/sepya/gece temaları, bölüm yer imleri, seçili metni işaretleme, işaretleri kaldırma ve bölüm notları bulunur. Bölüm ve kaydırma konumu, tema, yazı boyutu, yer imleri ve işaretler kütüphane kaydında saklanır. Notlar mevcut not sistemiyle saklanır.

EPUB ilerlemesi bölüm ve kaydırma konumu üzerinden hesaplanır. Son bölümde “Kitabı tamamladım” ile tamamlanır. Bölüm geçişleri gerçek sayfa sayısı gibi sayfa başarımlarına eklenmez; süre ve tamamlanan kitap başarımları çalışır. Kitap içi arama EPUB metnini OCR yapmadan indeksleyebilir.

Performans: arşiv açma seri çalışır, açılmış paketler diskte en fazla 8 kayıtla önbelleğe alınır. Yalnızca geçerli bölümün metni yüklenir. Tek dosya 16 MB, toplam açılmış paket 200 MB ve 5.000 dosya sınırları uygulanır. Dış dosya yolları ve bağlantı dosyaları reddedilir; dosyanın içindeki scriptler çalıştırılmaz.

Doğrulama: Mac Catalyst derlemesi ve tüm Book Hub testleri başarılı. Otomatik testler EPUB bölüm sırası, metadata, Unicode, yol güvenliği, bozuk XML, ayar/yer imi/işaret kaydı ve ilerlemeyi kapsar. Uygulamada üç bölümlü test dosyası aktarıldı; bölüm değiştirme, yazı boyutu, temalar, yer imi, işaret ve not denenerek yeniden başlatma sonrası kayıtları doğrulandı.

Sınırlar: bu ilk EPUB okuyucusu metin odaklıdır; kitap içi görseller, yayıncı CSS düzeni, sabit sayfa düzeni, ses/video ve DRM desteklenmez. macOS metin düzenleme servisine ait sistem uyarıları görüldü; okuma ve kayıt işlemleri çalıştı. iPad kontrolleri kullanıcının isteğiyle durduruldu; iPad doğrulaması tamamlanmadı.

Paket biçimi referansı: [W3C EPUB 3.3](https://www.w3.org/TR/epub-33/).
