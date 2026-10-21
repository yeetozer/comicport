# ComicPort — Book Hub kitap bilgileri paketi

8 Ekim 2026

## Değişiklikler
- Books detayında yazar, yayınevi, yıl, ISBN ve dil; bilgilerin kaynağı görünür.
- Books için ayrı kitap bilgisi düzenleyicisi: başlık, yazarlar, yayınevi, yıl, ISBN, dil ve özet.
- ISBN-10/13 kontrol basamağı doğrulanır; biçimlendirilmiş geçerli ISBN sadeleştirilerek saklanır. Boş ISBN kabul edilir, hatalı ISBN kaydedilemez.
- Elle girilen dil ve ISBN yeniden yerel analiz sırasında korunur.
- Kaydedilenler listesi seçili profile göre süzülür. Arşiv satırından detay ve geri yükleme erişilebilir.
- Kapak istekleri ortak kuyrukta birleşir; aynı anda en fazla iki görsel çözülür. Mevcut bellek sınırları ve kapak sürümü anahtarı korunur.

## Doğrulama
- Başlangıç checkpoint: `checkpoint-bookhub-bibliography-start` (`23f0d9b`).
- Değişikliklerden önce Mac Catalyst clean build başarılı.
- Kitap düzenleyicisi, arşiv erişimi ve kapak kuyruğu sonrası Catalyst derlemeleri başarılı.
- Model testleri: ISBN, eski kayıt geçişi, bibliyografi/dil round-trip, okuma ilerlemesi, 1000 kayıt çözümleme.
- Metadata kuyruğu: seri çalışma, kapasite, yinelenen istek birleşimi, önbellek ve dosya değişikliği.
- Kapak kuyruğu: 16 istek/8 anahtar yalnızca 8 çözümleme; eşzamanlı iş sayısı en fazla 2; önbellek tekrarı; yeni sürümde yeniden çözümleme.
- Uygulamada test PDF üzerinde geçersiz ISBN kaydetmeyi engelledi; `978-0-306-40615-7` değeri `9780306406157` olarak saklandı. Dil `tr` olarak kaydedildi.
- Yeniden analiz ve uygulamayı yeniden açma sonrası ISBN/dil/elle girilen yazar korundu.
- Test PDF arşivden geri yüklendi, okuyucu açıldı, sayfa değişimi ve oturumdan çıkış denendi; ardından yeniden arşivlendi.

## Sınırlar
Bu paket PDF/çizgi roman dosyalarının mevcut yerel altyapısını kullanır. EPUB desteği veya çevrimiçi metadata sağlayıcısı eklenmedi. Kapak testinde görsel çözümleme sahte yükle değiştirilirken üretimdeki kuyruk kodu aynen derlendi. Gerçek iPad testi yapılmadı. Kapak için bekleyen iş sayısına ayrı bir üst sınır eklenmedi; çalışan çözümlemeler iki işçiyle sınırlıdır.

Başlangıç incelemesinde macOS üzerinden açılan geçici imzalı debug uygulamasının dosya açma aşamasında beklediği örneklemeyle görüldü. Aynı anda macOS Belgeler klasörü erişim kontrolü kayıtları oluştu; erişim tamamlanınca ana ekran açıldı. Bu, erişim kontrolü gecikmesine işaret eder; başlangıç görevleri için denenen değişiklikler ve geçici izler son pakete alınmadı. Son smoke testi geliştirme ortamından doğrudan çalıştırılan uygulamayla yapıldı. Dağıtım imzası ve Finder üzerinden kararlı açılış ayrıca doğrulanmalıdır.
