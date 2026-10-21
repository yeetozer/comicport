# Book Hub — tamamlanan Mac geliştirme paketi

8 Ekim 2026

## Özellikler

| Alan | Sonuç |
|---|---|
| EPUB okuyucu | Bölüm görsel galerisi, erişilebilir bağlantı menüsü, Klasik/Sade/Eş aralıklı yazı tipleri; tema, punto, yer imi ve vurgular korunur. |
| Okuma hedefleri | Kitaplara özel günlük dakika ve yıllık kitap hedefi; ana ekranda ilerleme, ayrı düzenleme ekranı. |
| Alıntı defteri | EPUB vurguları ve PDF/EPUB metin notları; kitap/yazar/içerik filtresi, metin arama, not düzenleme, ilgili bölüme/sayfaya gitme ve Markdown dışa aktarma. |
| Raflar | Başlamadıklarım, 30 gündür açılmayan okumalar, bu yıl bitirdiklerim, not aldıklarım; kişisel koleksiyon oluşturma ve düzenleme. |
| Kitap bakımı | Eksik kapak/dosya, eksik yazar/yayınevi, eksik/geçersiz ISBN, aynı ISBN veya aynı başlık ve yazarla yinelenen adaylar; kitap ayrıntısından inceleme/düzeltme. |
| Başarımlar | 20 yeni hedef/yazar/koleksiyon başarımı; toplam 60 kitap başarımı ve değişmeyen 241 çizgi roman başarımı ayrı sekmelerde. |
| Kalıcılık ve yedek | Book Hub hedefleri, rafları ve tamamlanma kayıtları yerel book_hub.json dosyasında; şema 4 yedek içinde taşınır, şema 1–3 yedekler okunabilir. |

## Davranışlar

- Süre, okuyucu oturumu kapanınca güncellenir; kitap hedefi çizgi roman süresini saymaz. Süre mevcut oturum ölçümüdür, göz takibi veya etkin dikkat ölçümü değildir.
- Yıllık hedef aynı kitabı bir takvim yılında bir kez sayar. Yeni tamamlamalar tarihli kaydedilir; eski okuma günlüğündeki tarihler kullanılabilir. Tamamlanma tarihi bilinmeyen eski kitaplara tarih uydurulmaz.
- Günlük/yıllık hedef ödülleri kaydedilen kazanımlardır; hedef değiştirmek veya devre dışı bırakmak eski kazanımları geri almaz.
- Yazar başarımı tamamlanmış kitapların bilinen, boş olmayan yazarlarından hesaplanır; Türkçe harf farklılıkları aynı yazarı çoğaltmaz.
- Koleksiyon başarımı boş koleksiyonla kazanılmaz; koleksiyonun tüm kitapları tamamlanmış olmalıdır. Silinmiş/eksik kayıt kimliği koleksiyonu otomatik bitmiş saydırmaz.
- Bakım ekranı kayıtları otomatik silmez veya metadata alanlarının doğruluğunu kesin kabul etmez; inceleme adaylarını sunar.
- Alıntı defteri arşivlenen kitapların metinlerini korur; bilinmeyen/silinmiş kitap kayıtlarına ait metinleri listelemez. Çizim notlarını metne dönüştürmez.
- Yeni planlama verileri yerel kayda ve yedeğe dahildir; mevcut klasör eşitlemesinin kapsamı genişletilmedi.

## Doğrulanan kontroller

- Hedefler Mac arayüzünde kaydedildi; kitap oturumları sayılırken yüksek süreli çizgi roman örneği hedefe dahil edilmedi.
- EPUB vurgusu ve metin notu aynı defterde göründü; alıntı/not filtresi çalıştı. Not düzenlendi, yeniden başlatmada korundu.
- Örnek Markdown dosyası uygulamanın dışa aktarma ekranıyla kaydedildi; içeriği ve bölüm bilgileri kontrol edildi.
- Koleksiyon oluşturuldu; seçilen kitap rafında açıldı. Tamamlanınca koleksiyon ödülü ve yıllık hedef ödülü kaydedildi.
- İki farklı yazarın kitapları tamamlanınca yazar ödülü açıldı. Günlük hedef ödülü de doğrulandı.
- Yeniden başlatmada hedef, yıllık ilerleme, koleksiyon ve başarımlar korundu.
- EPUB alıntısından ilgili bölüm açıldı; Sade yazı tipi seçildi ve kaydı korundu. Eski yazı tipi alanı bulunmayan EPUB kayıtları Klasik varsayılanıyla açılır.
- Profil geçişinde BOOK HUB / COMIC PORT kimliği ve ilgili ana ekran değişti. Başarımlar 60 kitap / 241 çizgi roman olarak ayrıldı.
- Bakım örneğinde 1 eksik kapak ve 1 yinelenen aday grubu doğru bulundu.
- 1.001 kayıtla ana ekran, bakım, akıllı raflar ve koleksiyon seçim araması çalıştı; “kitap 0999” tek doğru kaydı getirdi. Bu testte 1.000 sentetik PDF kaydı aynı küçük PDF dosyasını kullanır; 1.000 ayrı büyük kitap veya uzun süreli bellek testi değildir.
- Üretim modelleri: yerel gün hesabı, yıl içi tekil kitap sayısı, arşiv/çizgi roman ayrımı, Türkçe eşleşme, boş koleksiyonun sayılmaması, Markdown metni ve kalıcılık kontrolleri geçti.
- Üretim yedek şeması ve birleştirme modeli: eski şema 1–3 açıldı; kitap kimliği eşleştirmesi ve aynı yedeğin iki kez birleştirilmesinde çoğalmama kontrolü geçti. Tam yedek dosyası canlı kütüphaneye geri yüklenmedi.
- ISBN/metadata, EPUB paket okuma, serial metadata kuyruğu ve kapak eşzamanlılık kontrolleri geçti.
- Son Debug Mac derlemesi başarılı; uygulama test günlüklerinde crash/fatal/error görülmedi. Gerçek kütüphane, analytics, başarımlar, metin notları ve okuyucu ayarı dosyalarının hash değerleri ayrı kütüphane denemeleri boyunca değişmedi.

## Kapsam sınırları

- iPad kontrolleri kullanıcının talebiyle duraklatılmıştır; yeni paket için iPad doğrulaması yapılmadı.
- EPUB görselleri bölüm galerisindedir; metin içi görsel yerleşimi, yayıncı CSS/fixed-layout, ses/video ve DRM desteği yoktur.
- İç bağlantı fragmentleri bölüm seviyesinde çözülür; dipnot/paragraf konumuna tam atlama yapılmaz. Bağlantı menüsü canlı test edildi; metinden doğrudan fare tıklaması ve harici tarayıcı açma canlı doğrulanmadı.
- App Store dağıtım/imzalama doğrulaması yapılmadı.

## Son Mac doğrulaması

- Release temiz derlemesi başarılı; derleme günlüğünde compiler hatası veya uyarısı yok.
- Release uygulaması normal kütüphaneyle açıldı; Debug test klasörü ortam değişkeni Release sürümünde etkisiz kaldı.
- Normal kütüphanede kişisel test koleksiyonu bulunmadı, hedefler başlangıçta kapalıydı ve önceki 3 kitap başarımı yeni 60’lık listede korundu. Ayrı test ödülleri gerçek kütüphaneye taşınmadı.
- Arşivdeki eski EPUB notu ve vurgusu normal kütüphanenin alıntı defterinde görüldü.
- Uygulama Book Hub ana ekranında açık bırakıldı.

Son geri dönüş etiketi: checkpoint-bookhub-final-package-verified-20261008.

Başlangıç geri dönüş etiketi: checkpoint-bookhub-final-package-start-20261008.
