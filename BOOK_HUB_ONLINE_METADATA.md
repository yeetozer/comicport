# Book Hub — ISBN ile bilgi ve kapak önerileri

Books detay ekranındaki “ISBN ile bilgi ve kapak bul” seçeneği, kullanıcı isteğiyle Open Library kaydını getirir. Sorguya yalnızca doğrulanmış ISBN gönderilir; kitap dosyası gönderilmez. Bilgiler önce gösterilir, eksik alanlar ayrı bir düğmeyle tamamlanır ve kapak ayrı bir seçimle uygulanır.

Mevcut dolu alanlar ve elle düzenlenen boş alanlar korunur. Çevrimiçi tamamlanan alanlar “Open Library” kaynak etiketi taşır ve yeniden yerel analizde korunur. Kapak değişimi önbellek sürümünü artırır; görüntü en fazla 1200 piksele küçültülerek kaydedilir.

Sorgular aynı ISBN için birleştirilir. Bellek önbelleği 24 kayıt ve 24 saatle sınırlıdır; istekler en az bir saniye arayla başlatılır. Zaman aşımı, geçersiz ISBN, kayıt bulunamaması ve okunamayan yanıt için Türkçe durum mesajları vardır.

## Doğrulama

- Mac Catalyst build başarılı.
- Üretim modeliyle ISBN, yanıt çözümleme, yıl/dil dönüşümü, yalnızca eksik alanları birleştirme, elle bırakılmış boş alanların korunması ve kaynak bilgisi kalıcılığı testleri geçti.
- Mac uygulamasında test EPUB’u ile gerçek ISBN sorgusu, eksik yayın yılını tamamlama, kapak yükleme ve kapağı uygulama çalıştı.
- Yeniden yerel analiz sonrası mevcut yazar/yayınevi/dil korundu; EPUB kaynak etiketi “Dosyadan”, çevrimiçi yayın yılı etiketi “Open Library” olarak doğrulandı.
- iPad kontrolleri kullanıcının isteğiyle durduruldu; bu paket için iPad sonucu verilmez.

Open Library kaydı, girilen ISBN’ye göre öneridir. Kitabın içeriğiyle otomatik eşleştirme yapılmaz; kullanıcı öneriyi inceler.

Kaynaklar: [Open Library kitap API’si](https://openlibrary.org/dev/docs/api/books), [kapak API’si](https://openlibrary.org/dev/docs/api/covers).
