# YouTube Playlist Ajanı

macOS’ta YouTube oynatma listelerini seçtiğin çözünürlükte veya MP3 olarak indiren bir Terminal aracı.

## Çalıştırma

1. `YouTube-Playlist-Ajani.command` dosyasına çift tıkla. GitHub’dan ZIP olarak aldıysan ve dosya çalıştırma izni yoksa proje klasöründe `chmod +x YouTube-Playlist-Ajani.command` çalıştır.
2. Bir liste bağlantısı yapıştır veya kayıtlı listeyi seç. Ardından çözünürlüğü seç. Hedef çözünürlük bulunamazsa araç mevcut en yüksek alt çözünürlüğü dener.
3. YouTube oturum doğrulaması isterse, videoyu açabildiğin tarayıcıda YouTube’a giriş yap ve araçtaki menüden o tarayıcıyı seç. Çerezler yalnızca bu çalıştırmada kullanılır. Varsayılan seçim oturumsuz indirmedir.

İlk kullanımda eksik olan `yt-dlp`, FFmpeg ve Deno paketleri için araç kurulum onayı ister. Paket kurulumu için [Homebrew](https://brew.sh/) gerekir.

## Devam etme

Dosyalar `~/Downloads/YouTube-Oynatma-Listeleri` altında liste kimliğine ve hedef kaliteye göre kaydedilir. Aynı listeyi ve kaliteyi seçerek mevcut indirmeye devam edebilirsin. Tamamlananlar atlanır, uyumlu yarım dosyalar sürdürülür. İndirme çıktısı ilgili klasördeki `indirme.log` dosyasına yazılır.
