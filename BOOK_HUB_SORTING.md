# ComicPort — Book Hub sıralama

Books koleksiyonlarına başlık, ilk yazar, yayın yılı (yeni önce) ve son eklenen tarihine göre sıralama menüsü eklendi. Varsayılan seçeneği gelen liste sırasını korur. Yazar ve yıl bilgisi eksik kayıtlar sona gider; eşit değerlerde başlık, sonra kayıt kimliği tutarlı sıralama sağlar. Seçim cihazda saklanır ve yeniden açılışta korunur. Menü yalnızca Books profilinde görünür ve uygulanır.

Sıralama dosya okumaz veya analiz başlatmaz. Karşılaştırma anahtarları kitap başına bir kez hazırlanır. Koleksiyon aynı ekran çiziminde sayım/boş durum/grid için tekrar sıralanmaz.

## Doğrulama
- Başlangıç checkpoint: `checkpoint-bookhub-sort-start`; temel kayıt `03df57d`.
- Başlangıç ve değişiklik sonrası Mac Catalyst derlemeleri başarılı.
- Üretim modeliyle üç kayıt üzerinde başlık, yazar, yıl ve tarih sıralaması; eksik bilgiler, boş liste, varsayılan sıra ve giriş sırasından bağımsız sonuç testleri geçti.
- Önceki bibliyografi, arama, raf ve kuyruk testleri geçti.
- Uygulamada Books menüsü açıldı, Yazar seçildi, uygulama yeniden açılınca seçim korundu. Sonunda Varsayılan seçeneğine dönüldü.

Uygulama kontrolü boş Books kütüphanesinde yapıldı; çok kitaplı sıralama otomatik model testinde doğrulandı. Smoke testi Mac Catalyst debug uygulamasının geliştirme ortamından doğrudan çalıştırılmasıyla yapıldı. Gerçek iPad ve büyük gerçek kütüphane performansı ayrıca doğrulanmalıdır.
