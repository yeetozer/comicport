# ComicPort — Eksik kitap bilgilerini gözden geçirme

Book Hub ana ekranına yazar, yayınevi ve eksik/geçersiz ISBN için sayaçlı listeler eklendi. Bu alanlar isteğe bağlıdır; kitap okumayı engellemez. Sayaç sıfırsa liste düğmesi pasiftir. Aktif kütüphanedeki Books kayıtları incelenir; arşiv veya çizgi roman kayıtları bu listelere katılmaz.

Listeden kitap detayına ve bilgi düzenleyicisine erişilir. Düzenleme sonrası liste güncel verilerden yeniden hesaplanır; alan tamamlanınca kitap o listeden çıkar. Denetim mevcut bellekteki bibliyografiyi kullanır; dosya okuma, ağ isteği veya otomatik OCR başlatılmaz.

## Doğrulama
- Başlangıç checkpoint: `checkpoint-bookhub-review-start`, temel kayıt `5312387`.
- Başlangıç ve değişiklik sonrası Mac Catalyst derlemeleri başarılı.
- Boş/boşluklu yazar ve yayınevi, geçersiz ISBN kontrol basamağı, geçerli biçimlendirilmiş ISBN ve çizgi roman ayrımı testleri geçti. Önceki model, raf, arama, sıralama ve kuyruk testleri de geçti.
- Uygulamada yalnızca test kitabı arşivden çıkarıldı. ISBN boş bırakılınca sayaç 1 oldu ve doğru kitap listelendi.
- Listeden detay ve düzenleyici açıldı; geçerli ISBN geri eklenince liste 0 kayıt ve uygun boş durum mesajı gösterdi.
- Pencere kapatma ve ana ekranda sıfır sayaç doğrulandı. Test kitabı bilgileri geri eklenerek yeniden arşivlendi.

Smoke testi geliştirme ortamından doğrudan çalıştırılan Mac Catalyst debug uygulamasında yapıldı. Gerçek iPad ve büyük gerçek kütüphane performansı bu adımda ölçülmedi.
