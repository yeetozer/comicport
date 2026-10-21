# ComicPort — Book Hub okuma filtreleri

Kütüphane ve arama sonuçlarında okuma filtreleri görünür hale getirildi. Önceki görünürlük ekran başlığına bağlıydı; profil başlığı “Books” olduğu için kütüphanede filtreler görünmüyordu. Görünürlük artık açık bir ekran seçeneğidir. Raflar ve eksik bilgi listelerine bu filtreler eklenmedi.

Books etiketleri: Tümü, Okunuyor, Okunacak, Tamamlandı, Favoriler. Diğer profillerde mevcut İngilizce etiketler korunur. Önce arama ve seçili okuma filtresi, ardından Books sıralaması uygulanır. Filtre sonucu boşsa “Seçili filtreye uyan kitap bulunamadı” mesajı gösterilir.

## Doğrulama
- Başlangıç checkpoint: `checkpoint-bookhub-filters-start`, temel kayıt `4221fbe`.
- Başlangıç ve değişiklik sonrası Mac Catalyst derlemeleri başarılı.
- Üretim filtre koduyla tüm okuma durumları, favoriler, arama+sıralama birleşimi ve profile göre etiket testleri geçti. Önceki model, raf, metadata, arama, sıralama ve kuyruk testleri geçti.
- Uygulamada Books kütüphanesinin beş Türkçe filtresi görüldü.
- Test kitabı Okunuyor filtresinde listelendi; Tamamlandı filtresi sıfır kayıt ve doğru mesaj gösterdi.
- “Manual Test Author” araması ve Okunuyor filtresi birlikte doğru kitabı gösterdi.
- Test kitabı yeniden arşivlendi; arama temizlendi ve filtre Tümü olarak bırakıldı.

Smoke testi geliştirme ortamından doğrudan çalıştırılan Mac Catalyst debug uygulamasında yapıldı. Gerçek iPad kontrolü bu adımda yapılmadı.
