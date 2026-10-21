# Book Hub — İlerleme etiketleri

Kitap detayında sayfa sayısı, okuma ilerlemesi ve son okuma başlığı Türkçeleştirildi. Örnek gösterim: “4 sayfa”, “%50 okundu · sayfa 2/4”, “Son okuma: …”. Göreli süre biçimi sistem yerel ayarlarını kullanmaya devam eder.

Başlangıç checkpoint: `checkpoint-bookhub-progress-labels-start` (`56e114a`). Başlangıç ve değişiklik sonrası Mac Catalyst derlemeleri başarılı. Çalışan geliştirme uygulamasında arşivdeki test kitabının detay ekranı açılarak üç etiket de doğrulandı; %50 ve 2/4 değerleri korundu. Çalışma günlüğü boş. Kütüphane verilerine değişiklik yapılmadı.

Bu paket yalnızca görünür metinleri değiştirir. Mac Catalyst geliştirme derlemesi doğrulandı; iPad testi yapılmadı.
