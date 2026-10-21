# ComicPort — Book Hub arama paketi

Books araması başlıkla birlikte yazar, yayınevi, yayın yılı, dil ve ISBN alanlarına bakar. Birden çok kelime farklı alanlarda eşleşebilir; tüm kelimeler aranır. Türkçe karakterler ve büyük/küçük harfler toleranslıdır. ISBN tireli veya kısmi olarak aranabilir (en az üç karakter). Boşluklardan oluşan sorgu arama ekranına geçmez.

Arama seçili profilin mevcut kütüphane kayıtlarında çalışır. Arşivlenmiş kayıtlar genel kütüphane aramasına katılmaz. Çizgi romanlar için başlık araması korunur. Arama disk okumaz, OCR veya ağ isteği başlatmaz; sorgu her filtreleme için bir kez hazırlanır.

Books detayında “Okumaya devam et”, “Okumaya başla” ve “Kapak seç” metinleri kullanılır. İçerik araması bölümü kitaba uygun metin gösterir. Sonuç yoksa “Aramana uyan kitap bulunamadı” mesajı görünür. Depolama toplamı tüm kütüphaneye ait olduğu için etiket “kütüphane” olarak düzeltildi.

## Doğrulama
- Başlangıç checkpoint: `checkpoint-bookhub-search-start`, temel kayıt `5daf722`.
- Başlangıç ve değişiklik sonrası Mac Catalyst derlemeleri başarılı.
- Üretim model koduyla Türkçe karakterler, yazar/yayınevi/yıl/dil, çok kelimeli eşleşme, tireli/kısmi ISBN, boş sorgu ve çizgi roman alan ayrımı testleri geçti.
- Önceki model geçişi, metadata kuyruğu ve kapak kuyruğu testleri de geçti.
- Uygulamada test kitabı “Manual Test Author” ve “978-0-306-40615-7” sorgularıyla bulundu; olmayan sorgu sıfır sonuç verdi.
- Test kitabı testler için arşivden çıkarılıp sonunda yeniden arşivlendi.

Smoke testi geçici geliştirme imzasıyla, geliştirme ortamından doğrudan çalıştırılan Mac Catalyst uygulamasında yapıldı. Gerçek iPad ve dağıtım imzası bu paketin doğrulamasına dahil değildir.
