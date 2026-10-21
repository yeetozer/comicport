# Book Hub — okuma ve arama tutarlılığı

Kitap detayındaki yerel analiz ve depolama kontrolleri Türkçeleştirildi. EPUB dosyalarının bölüm sayısı, analiz durumu ve arama sonuçları “bölüm” olarak gösterilir. İlk bölümde kaydırılmış bir kitaptaki eylem “Okumaya devam et” olur. EPUB okuma özeti, gerçek sayfa sayısı yerine oturum süresini gösterir.

Başarım ekranında kategori, seviye, kazanılma tarihi ve bildirim metinleri Türkçedir. Kalıcı başarım kimlikleri ve eski kayıtların enum değerleri değiştirilmedi.

Kitap içi arama sonuçları, indeks sayacı, toplu indeksleme ve indeks temizleme seçili profilin kayıtlarıyla sınırlıdır. Başka profillerin indeksleri korunur. Tek kitap detayından indeksleme o kitapla sınırlı kalır. EPUB sürükle-bırak desteği ve alternatif içe aktarma ekranındaki desteklenen biçimler eşitlendi.

## Mac doğrulaması

- Her değişiklik grubu için Mac Catalyst build başarılı; compiler uyarısı veya hatası yok.
- Tüm Book Hub model, EPUB paket, metadata kuyruğu ve kapak kuyruğu kontrolleri geçti.
- Test EPUB’u son bölümden tamamlandı; %100/Tamamlandı durumu ve “İlk Kitabım” başarımı doğrulandı. EPUB bölüm geçişleri sayfa başarımlarına eklenmedi.
- Okuma özeti Türkçe süre gösterdi; EPUB indeksleme 3 bölümü tamamladı.
- “raflarının” araması 3 bölüm sonucu verdi; ikinci sonuç okuyucunun ikinci bölümünü açtı.
- Comics profilinde test EPUB adıyla arama sonuç vermedi ve Books indeks sayısı çizgi roman sayacına eklenmedi.
- iPad kontrolleri durdurulmuş olarak bırakıldı.

Kapsam: Book Hub ve EPUB akışındaki temel metinler düzeltildi; uygulamanın tüm eski ekranları için genel çeviri paketi değildir.
