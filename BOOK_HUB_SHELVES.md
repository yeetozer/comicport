# ComicPort — Book Hub raflar

Book Hub ana ekranına yazar ve yayınevine göre raflar eklendi. Bir rafa dokunmak o gruptaki kitapları açar; karttan kitap detayına erişilir. Kitap kartlarında yazar bilgisi gösterilir.

Gruplar sadece aktif kütüphanedeki Books kayıtlarının mevcut bibliyografisinden oluşur. Boş alanlar kategori oluşturmaz. Aynı kitabın yinelenen yazarları bir kez sayılır; birden fazla yazarı varsa ilgili rafların hepsinde görünür. Gruplar kitap sayısına göre, eşitlikte ada göre sıralanır. Yatay raflar lazy olarak oluşturulur; dosya okuma, OCR veya ağ isteği başlatılmaz. Çok büyük gerçek kütüphanelerde performans ayrıca ölçülmelidir.

## Doğrulama
- Başlangıç checkpoint: `checkpoint-bookhub-shelves-start`, temel kayıt `b2d4a8a`.
- Başlangıç, raf geliştirmesi ve kapatma düğmesi düzeltmesi sonrası Mac Catalyst derlemeleri başarılı.
- Yazar/yayınevi gruplama, yinelenen yazar, boşluk temizleme, eksik metadata ve çizgi roman ayrımı testleri geçti.
- Önceki bibliyografi, ISBN, arama, metadata kuyruğu ve kapak kuyruğu testleri geçti.
- Uygulamada yazar rafı açılıp kitap detayına erişildi.
- Test kitabına “Smoke Test Press” yayınevi eklendi; yayınevi rafında doğru kitap görüldü.
- Son sürümde Kapat düğmesi denendi. Test kitabı yeniden arşivlenince ana ekran rafları ve sayılar güncellendi.

Smoke testi Mac Catalyst debug uygulamasının geliştirme ortamından doğrudan çalıştırılmasıyla yapıldı. Gerçek iPad ve dağıtım imzası doğrulaması yapılmadı.
