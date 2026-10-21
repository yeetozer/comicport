# Book Hub — EPUB görselleri ve bağlantıları

8 Ekim 2026

## Tamamlanan adım
- EPUB bölümündeki yerel görseller ayrı Görseller galerisinde açılıyor. Görseller arka planda, en fazla 1200 piksele küçültülerek hazırlanıyor.
- Bağlantılar metinde işaretleniyor ve erişilebilir Bağlantılar menüsünde listeleniyor. Kitap içi bağlantı ilgili bölümü açıyor; HTTP/HTTPS bağlantısı kullanıcı eylemiyle sistem tarayıcısına iletiliyor.
- Metin normalizasyonu değişmedi; önceki UTF-16 vurguları ve arama metni korunuyor.
- Paket dışına çıkan yollar, uzak görseller ve çalıştırılabilir URL şemaları reddediliyor. Bölüm başına en fazla 256 görsel ve bağlantı hazırlanıyor.

## Doğrulama
- Başlangıç Mac derlemesi ve değişikliklerden sonraki Mac derlemeleri başarılı.
- Üretim EPUB ayrıştırıcısı ile testler: tekrar eden bağlantı etiketi, iç bağlantı, web bağlantısı, zararlı yol/şema, metinsiz görsel bölümü, eski metnin birebir korunması başarılı.
- Ayrı test kütüphanesinde iki bölümlü EPUB: görsel galerisinde kapak ve açıklama görünür; Bağlantılar menüsü ikinci bölümü açar; görsel olmayan bölümde düğme pasif.
- Doğrudan metin bağlantısının fareyle açılması otomatik UI denemesinde doğrulanmadı; menü yolu doğrulandı. Harici tarayıcı açılışı canlı test edilmedi.

## Sınırlar ve sonraki işler
- Görseller metin içine yerleştirilmiyor; yayıncı CSS düzeni uygulanmıyor. SVG ve desteklenmeyen görsel biçimleri için gösterilemiyor mesajı var.
- Fragment/dipnot bağlantıları ilgili bölüm seviyesinde çözülüyor; paragraf konumuna atlama yok.
- Bu adım EPUB geliştirmesinin ilk parçası. Okuma hedefleri, alıntı defteri ve yeni akıllı raflar henüz bu pakette uygulanmadı.
- iPad kontrolleri kullanıcının isteğiyle duraklatılmış durumda.
- Başlangıç geri dönüş etiketi: checkpoint-bookhub-epub-enhancement-start-20261008.
