# Book Hub — Okuma akışı

## Değişiklikler
- Ana sayfaya “Okunacak kitapların” rafı eklendi. En eski eklenenlerden başlayarak en fazla 8 kitap gösterilir; “Tümünü gör” tam Okunacak listesini açar.
- Arşivlenen, kütüphaneden kaldırılan ve Books profiline ait olmayan kayıtlar bu rafta gösterilmez.
- Kitap detayındaki durum, favori, puan ve arşiv kontrolleri Türkçeleştirildi.
- Kayıt dosyasındaki mevcut İngilizce durum değerleri korundu; eski kütüphane kayıtlarıyla uyumluluk devam eder.

## Doğrulama
- Başlangıç checkpoint: `checkpoint-bookhub-reading-flow-start` (`51144b0`).
- Başlangıç ve değişiklik sonrası Mac Catalyst derlemeleri başarılı.
- Model ve kapak/metadata kuyruk testleri başarılı. Yeni kontroller: raf sırası ve 8 kitap sınırı, sıfır/negatif sınır, dışlanacak kayıtlar, Türkçe durum etiketleri ve eski kayıt değerleri.
- Çalışan Mac Catalyst geliştirme uygulamasında test kitabı arşivden geri alındı, “Okunacak” seçildi, ana sayfa rafında göründü ve “Tümünü gör” üzerinden doğru liste açıldı.
- Durum değişiminde %50 ilerleme ve 2/4 sayfa bilgisi korundu. Test sonunda kitap tekrar “Okunuyor” durumuna ve arşive alındı.
- Çalışma günlüğünde hata çıktısı görülmedi.

Bu doğrulama yerel Mac Catalyst geliştirme derlemesiyle yapıldı; iPad ve dağıtım imzası bu paketin test kapsamına dahil değildir.
