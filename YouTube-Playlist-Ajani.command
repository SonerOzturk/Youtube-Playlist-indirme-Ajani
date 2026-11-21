#!/bin/bash

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

finish() {
    printf '\n%s\n' "$1"
    read -r -p "Kapatmak için Enter'a bas. " unused
    exit "$2"
}

root="$HOME/Downloads/YouTube-Oynatma-Listeleri"
printf '\nYouTube Oynatma Listesi İndirici v5\n\n'

saved=()
for state in "$root"/*/*/.oynatma-listesi; do
    [[ -f "$state" ]] || continue
    saved+=("$state")
    folder="${state%/*}"
    playlist_folder="${folder%/*}"
    printf '%d) %s (%s)\n' "${#saved[@]}" "${playlist_folder##*/}" "${folder##*/}"
done
if (( ${#saved[@]} )); then
    printf '\nDevam etmek için kayıt numarasını gir veya yeni bir bağlantı yapıştır.\n'
fi
read -r -p 'YouTube bağlantısı veya kayıt numarası: ' link || exit 1

default_quality=3
saved_folder=
if [[ "$link" =~ ^[1-9][0-9]{0,5}$ ]] && (( link <= ${#saved[@]} )); then
    state="${saved[link-1]}"
    saved_folder="${state%/*}"
    {
        IFS= read -r link
        IFS= read -r default_quality
    } < "$state" || finish 'Kayıt okunamadı. Listeyi bağlantısıyla tekrar aç.' 1
fi

youtube_pattern='^https?://((www\.|m\.|music\.)?youtube\.com|youtu\.be)/[^[:space:]]+$'
list_pattern='[?&]list=([A-Za-z0-9_-]+)(&|#|$)'
if [[ ! "$link" =~ $youtube_pattern || ! "$link" =~ $list_pattern ]]; then
    finish 'Geçerli bir YouTube oynatma listesi bağlantısı veya kayıt numarası gir.' 1
fi
playlist_id="${BASH_REMATCH[1]}"

printf '\n1) 2160p (4K)\n2) 1440p\n3) 1080p\n4) 720p\n5) 480p\n6) 360p\n7) MP3 ses\n'
while true; do
    read -r -p "Kalite seç [$default_quality]: " choice || exit 1
    choice="${choice:-$default_quality}"
    [[ "$choice" =~ ^[1-7]$ ]] && break
    printf '1 ile 7 arasında bir seçenek gir.\n'
done
case "$choice" in
    1) height=2160 ;;
    2) height=1440 ;;
    3) height=1080 ;;
    4) height=720 ;;
    5) height=480 ;;
    6) height=360 ;;
    7) height= ;;
esac

if [[ -n "$height" ]]; then
    mode="${height}p"
    format=(
        -f "bv*[height<=$height]+ba/b[height<=$height]"
        -S 'height,vcodec:h264,acodec:aac'
        --format-sort-force
        --merge-output-format 'mp4/mkv'
        --remux-video 'webm>mkv'
        --print "before_dl:Hedef: ${height}p | İndirilecek: %(width)s×%(height)s | %(title)s"
    )
else
    mode=MP3
    format=(-f 'ba/b' -x --audio-format mp3 --audio-quality 0)
fi

missing=()
for dependency in yt-dlp ffmpeg deno; do
    command -v "$dependency" >/dev/null 2>&1 || missing+=("$dependency")
done
if (( ${#missing[@]} )); then
    if ! command -v brew >/dev/null 2>&1; then
        finish 'İlk kullanım için https://brew.sh üzerinden Homebrew’u kur, ardından bu dosyayı tekrar aç.' 1
    fi
    printf '\nKurulacak paketler: %s\n' "${missing[*]}"
    read -r -p 'Homebrew ile kurulsun mu? [e/H]: ' install || exit 1
    [[ "$install" == e || "$install" == E ]] || finish 'Kurulum iptal edildi.' 1
    brew install "${missing[@]}" || finish 'Kurulum tamamlanamadı. Yukarıdaki Homebrew çıktısını kontrol et.' 1
fi

destination="$root/$playlist_id/$mode"
if [[ "$choice" == "$default_quality" && "$saved_folder" == "$destination-yeniden" ]]; then
    destination="$saved_folder"
elif [[ -n "$height" && -s "$destination/.indirilenler.txt" ]]; then
    printf '\n1) Kaldığın yerden devam et\n2) Çözünürlüğü yeniden kontrol et ve ayrı klasöre indir\n'
    read -r -p 'İşlem [1]: ' action || exit 1
    case "${action:-1}" in
        1) ;;
        2) destination="$destination-yeniden" ;;
        *) finish '1 veya 2 seç.' 1 ;;
    esac
fi
browser_ids=(none)
browser_labels=('Oturumsuz indir')
support="$HOME/Library/Application Support"
for browser in Safari Firefox Chrome Edge Brave Opera Vivaldi Chromium; do
    case "$browser" in
        Safari)   id=safari;   app=Safari;          profile="$HOME/Library/Safari" ;;
        Firefox)  id=firefox;  app=Firefox;         profile="$support/Firefox/Profiles" ;;
        Chrome)   id=chrome;   app='Google Chrome'; profile="$support/Google/Chrome" ;;
        Edge)     id=edge;     app='Microsoft Edge'; profile="$support/Microsoft Edge" ;;
        Brave)    id=brave;    app='Brave Browser'; profile="$support/BraveSoftware/Brave-Browser" ;;
        Opera)    id=opera;    app=Opera;           profile="$support/com.operasoftware.Opera" ;;
        Vivaldi)  id=vivaldi;  app=Vivaldi;         profile="$support/Vivaldi" ;;
        Chromium) id=chromium; app=Chromium;        profile="$support/Chromium" ;;
    esac
    if [[ -d "$profile" || -d "/Applications/$app.app" || -d "$HOME/Applications/$app.app" ]]; then
        browser_ids+=("$id")
        browser_labels+=("$browser oturum çerezlerini bu işlem için kullan")
    fi
done

printf '\n'
for index in "${!browser_ids[@]}"; do
    printf '%d) %s\n' "$((index + 1))" "${browser_labels[index]}"
done
while true; do
    read -r -p 'YouTube oturumu [1]: ' session || exit 1
    session="${session:-1}"
    if [[ "$session" =~ ^[1-9]$ ]] && (( session <= ${#browser_ids[@]} )); then
        break
    fi
    printf 'Menüdeki seçeneklerden birini gir.\n'
done

auth=()
if (( session > 1 )); then
    auth=(--cookies-from-browser "${browser_ids[session-1]}")
fi

mkdir -p "$destination" || finish 'İndirme klasörü oluşturulamadı.' 1
lock="$destination/.indirme-kilidi"
mkdir "$lock" 2>/dev/null || finish "Liste zaten indiriliyor veya eski bir kilit var: $lock" 1
trap 'rm -f "$lock/tarama.log"; rmdir "$lock"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

printf '\nKayıt klasörü: %s\n\n' "$destination"
log="$destination/indirme.log"
playlist_url="https://www.youtube.com/playlist?list=$playlist_id"
state="$destination/.oynatma-listesi"
if [[ ! -f "$state" ]]; then
    if ! printf '%s\n%s\n' "$playlist_url" "$choice" > "$state.tmp" || ! mv "$state.tmp" "$state"; then
        finish 'Oynatma listesi kaydedilemedi.' 1
    fi
fi

for attempt in 1 2 3; do
    printf '\nListe taraması %s/3\n' "$attempt" | tee -a "$log"
    yt-dlp --ignore-config --js-runtimes "deno:$(command -v deno)" \
        --remote-components ejs:github --yes-playlist --continue --no-abort-on-error \
        --retries 5 --fragment-retries 5 --extractor-retries 3 \
        --abort-on-unavailable-fragments --retry-sleep 'http:exp=1:16' \
        --no-simulate --newline --progress --socket-timeout 30 \
        --download-archive "$destination/.indirilenler.txt" \
        -P "$destination" -o '%(playlist_index)04d - %(title).150B [%(id)s].%(ext)s' \
        "${auth[@]}" "${format[@]}" -- "$playlist_url" 2>&1 | tee -a "$log" "$lock/tarama.log"
    result=${PIPESTATUS[0]}

    if grep -Eiq '^ERROR:.*(Sign in to confirm|cookies database|could not (find|copy).*cookies|failed to decrypt)' "$lock/tarama.log"; then
        finish 'YouTube oturumu doğrulanamadı. Kullandığın tarayıcıda YouTube’a giriş yapıp videonun açıldığını kontrol et. Sonra aynı liste ve kaliteyi açıp o tarayıcıyı seç.' 1
    fi
    : > "$lock/tarama.log"

    if (( result == 0 )); then
        open "$destination"
        finish 'Liste taraması tamamlandı.' 0
    fi
    if (( result >= 128 )); then
        exit "$result"
    fi
    if (( attempt < 3 )); then
        delay=$(( attempt * 10 ))
        printf '\nKalan öğeler %s saniye sonra tekrar denenecek.\n' "$delay"
        sleep "$delay"
    fi
done
open "$destination"
finish "Üç deneme sonunda bazı öğeler indirilemedi. Ayrıntılar: $log" "$result"
