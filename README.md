<div align="center">

<a href="https://www.debian.org/"><img src="https://www.debian.org/logos/openlogo-nd.svg" alt="Logo resmi Debian open-use" width="84" height="84"></a>&nbsp;&nbsp;&nbsp;&nbsp;<a href="https://github.com/NousResearch/hermes-agent"><img src="https://raw.githubusercontent.com/NousResearch/hermes-agent/main/website/static/img/favicon.svg" alt="Logo resmi Hermes Agent dari NousResearch" width="84" height="84"></a>

# Debian + Hermes Agent Railway

<p>
  <a href="https://github.com/DURIAN-ORGANISASI/debian-hermes-railway/actions/workflows/docker-build.yml"><img alt="Quality checks" src="https://img.shields.io/github/actions/workflow/status/DURIAN-ORGANISASI/debian-hermes-railway/docker-build.yml?branch=main&amp;label=quality%20checks&amp;logo=githubactions&amp;logoColor=white"></a>
  <img src="https://img.shields.io/badge/Debian-13%20Trixie-A80030?style=flat&amp;logo=debian&amp;logoColor=white" alt="Debian 13 Trixie">
  <img src="https://img.shields.io/badge/Hermes-Agent-CC8B28?style=flat&amp;logo=probot&amp;logoColor=white" alt="Hermes Agent">
  <img src="https://img.shields.io/badge/Deploy-Railway-0B0D0E?style=flat&amp;logo=railway&amp;logoColor=white" alt="Railway">
  <img src="https://img.shields.io/badge/Container-Docker-2496ED?style=flat&amp;logo=docker&amp;logoColor=white" alt="Docker">
  <a href="LICENSE"><img alt="MIT License" src="https://img.shields.io/github/license/DURIAN-ORGANISASI/debian-hermes-railway?label=license"></a>
</p>

<p><a href="README.md">🇮🇩 Bahasa Indonesia</a> · <a href="README.en.md">🇬🇧 English</a></p>

<p><strong>Hermes Agent dan terminal Debian 13 di Railway.</strong><br>
Deploy Hermes CLI, akses shell lewat browser, dan hubungkan channel Telegram/Discord dengan data konfigurasi persisten.</p>

<p>
  <a href="#fitur">Fitur</a> ·
  <a href="#arsitektur-singkat">Arsitektur</a> ·
  <a href="#1-deploy-ke-railway">Panduan deploy</a> ·
  <a href="#6-penyimpanan-dan-auto-start">Penyimpanan &amp; auto-start</a> ·
  <a href="#9-keamanan">Keamanan</a> ·
  <a href="#sumber-atribusi-dan-lisensi">Sumber &amp; lisensi</a> ·
  <a href="#kontribusi">Kontribusi</a>
</p>

</div>

---

![Ilustrasi Debian + Hermes Agent Railway](docs/hero.id.svg)

<p align="center"><sub>Ilustrasi vektor orisinal untuk dokumentasi; bukan screenshot produk resmi.</sub></p>

> [!WARNING]
> **Bukan VPS penuh.** Railway menjalankan container aplikasi, bukan server virtual dengan akses host, desktop GUI, atau jaminan systemd penuh. Terminal web berjalan sebagai root di dalam container. Pasang Railway Volume di `/opt/data` sebelum menjalankan setup Hermes pertama kali agar konfigurasi, sesi, memori, dan log tidak hilang ketika container dibuat ulang.

## Arsitektur singkat

![Diagram arsitektur Debian + Hermes Agent Railway](docs/architecture.svg)

- **Akses terminal:** Browser HTTPS → Railway → `ttyd` → Bash di container Debian 13.
- **Agent dan channel:** Hermes Gateway berjalan di container dan dapat menghubungkan bot Telegram/Discord setelah konfigurasi selesai.
- **Data persisten:** Railway Volume dipasang di `/opt/data` untuk konfigurasi dan state Hermes; tool/cache yang dapat dibuat ulang diarahkan ke luar volume.
- **Auto-start:** Entry point memulai Gateway setelah `/opt/data/config.yaml` tersedia ketika `HERMES_AUTOSTART=true`.

## Fitur

- Base image Debian 13 (Trixie) slim.
- Hermes Agent CLI dipasang pada saat Docker build menggunakan installer resmi Hermes.
- Extra messaging bersama serta extra khusus Telegram dan Discord dipasang dan diperiksa saat Docker build agar kegagalan dependency muncul di Build Logs, bukan baru saat Gateway berjalan.
- Terminal browser menggunakan ttyd dengan autentikasi username/password dan pemeriksaan Origin.
- Banner sistem otomatis menampilkan OS, kernel, arsitektur, uptime, CPU, RAM, disk, timezone, dan status Gateway.
- Git, curl, Python, pip/venv, compiler, dan pustaka build tersedia.
- Gateway dapat otomatis dimulai setelah konfigurasi Hermes tersedia.
- Default timezone Asia/Jakarta.
- Data Hermes diarahkan ke /opt/data. Tool store dan cache yang bisa dibuat ulang diarahkan di luar volume data persisten.
- Binary ttyd mendukung AMD64 dan ARM64.
- GitHub Actions menguji sintaks shell, build Docker image, dan respons HTTP terminal.

Installer memakai opsi --non-interactive dan --skip-browser supaya build tidak menunggu input serta image lebih ringan. Repo tidak mengunci vendor/model tertentu, serta tidak menyimpan token Telegram, token Discord, API key, atau password asli.

## 1. Deploy ke Railway

1. Pastikan perubahan terbaru pada branch main sudah ada di GitHub.
2. Di Railway, pilih New Project → Deploy from GitHub Repo, lalu pilih repository ini.
3. Pastikan Railway membangun dari Dockerfile di root repository. Jangan masukkan start command khusus kecuali memang diperlukan; image sudah memiliki ENTRYPOINT.
4. Buka service → Settings → Networking → Generate Domain.
5. Buat Railway Volume dan pasang mount path tepat /opt/data **sebelum melakukan setup Hermes pertama kali**. Ini penting: volume hanya menyimpan path yang dipasang. Tanpa volume di /opt/data, config, token, sesi, memori, dan log Hermes berisiko hilang saat container dibuat ulang.
6. Buka Variables dan tambahkan nilai dari kotak salin di bagian berikut.
7. Tunggu deployment selesai dan periksa Build Logs serta Deploy Logs. Buka domain, lalu login menggunakan TERMINAL_USER dan TERMINAL_PASSWORD.

## 2. Railway Variables — blok utama

Salin nilai berikut ke Railway → service → Variables. Ganti dua nilai placeholder dengan username unik dan password acak milikmu sebelum deploy.

~~~dotenv
TERMINAL_USER=GANTI_DENGAN_USERNAME_UNIK
TERMINAL_PASSWORD=GANTI_DENGAN_PASSWORD_ACAK_PANJANG_MINIMAL_24_KARAKTER
TZ=Asia/Jakarta
HERMES_HOME=/opt/data
HERMES_RUNTIME_DIR=/usr/local/share/hermes-tools
UV_CACHE_DIR=/tmp/uv-cache
HERMES_AUTOSTART=true
~~~

Aturan variabel:
- TERMINAL_USER wajib dan tidak boleh berisi titik dua (:).
- TERMINAL_PASSWORD wajib, minimal 16 karakter; disarankan 24–40 karakter atau lebih. Pakai password acak yang unik untuk setiap service.
- HERMES_HOME harus tetap /opt/data jika Volume dipasang di /opt/data.
- HERMES_RUNTIME_DIR harus berada di luar /opt/data supaya tool Python/Node/FFmpeg yang dapat diunduh ulang tidak memenuhi volume.
- UV_CACHE_DIR adalah cache sementara yang aman dibuat ulang.
- HERMES_AUTOSTART=true memungkinkan Gateway start saat container menyala setelah config Hermes dibuat. Gunakan false hanya untuk diagnosis atau jika ingin menjalankan Gateway manual.
- Jangan menambahkan PORT secara manual. Railway menyediakan PORT untuk service; image memakai 8080 hanya sebagai nilai fallback.
- Jangan memasukkan baris placeholder token atau API key ke Variables. Masukkan kredensial melalui wizard Hermes, atau atur token sebagai variabel Railway hanya jika memang sengaja memakai metode environment-variable dan sudah mengisi nilai asli yang benar.

## 3. Setup Hermes yang benar — lakukan setelah Volume /opt/data terpasang

Masuk ke terminal web Railway, lalu jalankan perintah satu per satu:

~~~bash
command -v hermes
hermes --version
hermes setup
~~~

### Pilihan wizard yang disarankan

Nama dan urutan opsi dapat berubah menurut versi Hermes. Cocokkan berdasarkan nama/fungsi opsi, bukan hanya nomor urut.

| Prompt wizard | Pilihan yang disarankan | Alasan |
|---|---|---|
| Model/provider | Pilih provider yang API key atau login-nya benar-benar kamu miliki. Jika memakai NVIDIA NIM, gunakan NVIDIA dan pastikan kredensial NVIDIA aktif. | Model chat perlu kredensial valid. Provider model berbeda dari provider tools seperti pencarian web dan TTS. |
| Terminal backend | **Keep current (local)** | Terminal dijalankan langsung di container Railway. Tidak perlu menyiapkan Docker-in-Docker hanya untuk penggunaan normal Hermes. |
| Image generation | **Skip / configure later** jika belum membutuhkan generate gambar atau belum punya provider/key. | Fitur gambar opsional; melewatinya tidak mematikan chat Telegram/Discord. |
| Text-to-speech (TTS) | **Microsoft Edge TTS / Edge TTS** | Opsi gratis yang tidak memerlukan API key terpisah. |
| Web search | **Tavily** jika ingin mengikuti tutorial ini. Jika wizard meminta API key, isi key Tavily asli bila ada; gunakan skip/kosong hanya jika wizard mengizinkan. | Mode tanpa key dapat memiliki batasan lebih ketat. Pilih provider yang benar-benar ditampilkan wizard. |
| Shared metrics / telemetry | **No thanks** | Tidak mengaktifkan pengumpulan metrik bersama. |

Jika kamu memilih provider pencarian yang berbeda, hasil `hermes doctor` akan menampilkan provider aktif, misalnya `web search (firecrawl)`. Itu berarti Firecrawl yang aktif, bukan Tavily; bila ingin menggantinya, gunakan `hermes setup tools` atau wizard tools yang tersedia pada versi terpasang.

Jangan memasukkan placeholder seperti `YOUR_API_KEY` sebagai kredensial nyata. Selesaikan wizard sampai muncul **Setup Complete** dan kembali ke shell. Perintah `hermes doctor` mungkin menampilkan peringatan login untuk provider lain yang tidak kamu gunakan; itu tidak otomatis berarti provider/model aktif gagal.

### Setelah wizard selesai

Jalankan:

~~~bash
hermes doctor
hermes status
~~~

Pastikan nama model dan provider pada `hermes status` sesuai pilihanmu. Setelah itu, tes chat CLI biasa dengan menjalankan `hermes`; kirim pesan singkat, lalu keluar dari sesi chat sesuai petunjuk CLI.

Kemudian konfigurasi channel pesan:

~~~bash
hermes gateway setup
~~~

Pilih Telegram dan/atau Discord, masukkan token bot yang benar, dan ikuti prompt otorisasi. Bila wizard menanyakan apakah akunmu boleh berbicara dengan bot, jawab **Yes** untuk akun yang benar-benar ingin kamu izinkan.

**Penting tentang prompt Home Channel:** jika wizard bertanya apakah user ID yang ditampilkan akan dipakai sebagai *home channel*, pastikan ID tersebut memang milik platform/channel yang sedang dikonfigurasi. User ID Telegram bukan Channel ID Discord. Bila sedang konfigurasi Discord dan yang ditampilkan hanya user ID, pilih **No** kecuali kamu memang memiliki Channel ID Discord yang sesuai.

Setelah selesai, jalankan:

~~~bash
hermes doctor
hermes gateway status
hermes status
~~~

Lalu restart/redeploy service Railway satu kali agar entrypoint membaca config yang baru dibuat dan memulai Gateway otomatis. **Jangan menjalankan `hermes gateway` di terminal browser sebagai metode permanen.** Perintah itu berjalan di foreground dan dapat berhenti ketika sesi terminal ditutup. Dengan `HERMES_AUTOSTART=true`, entrypoint repo ini yang seharusnya menjalankan Gateway terpisah dari sesi `ttyd`; setelah restart kamu boleh menutup tab terminal. Jangan menjalankan Gateway kedua secara manual pada service yang sama. Jika `hermes status` menunjukkan Gateway stopped, lanjutkan ke bagian Troubleshooting di bawah.

### Pengaturan streaming dan diagnosis respons lambat

Streaming menentukan apakah jawaban ditampilkan bertahap; streaming **tidak** mempercepat model/provider yang lambat mengirim token pertama. Jika ingin Telegram menampilkan jawaban secara bertahap, periksa dan atur nilai berikut:

~~~bash
hermes config set streaming.enabled true
hermes config set display.platforms.telegram.streaming true
hermes config get streaming.enabled
hermes config get display.platforms.telegram.streaming
hermes config get display.platforms.discord.streaming
~~~

Nilai true, true, false berarti streaming global aktif, streaming Telegram aktif, dan Discord tetap mengirim jawaban utuh. Jika ingin streaming juga di Discord, ubah pengaturan Discord secara eksplisit. Setelah mengubah konfigurasi yang dibaca oleh Gateway, restart service Railway agar Gateway memuat konfigurasi baru.

Jika Telegram terus menampilkan indikator mengetik atau log memperlihatkan pesan **waiting for stream response (..., first_chunk)**, periksa dulu model yang dipilih. Untuk menguji respons model dari terminal dengan satu permintaan:

~~~bash
hermes -c "Balas hanya: OK"
~~~

Atau jalankan perintah hermes, lalu ketik Balas hanya: OK pada prompt chat yang muncul. **Jangan** mengetik perintah hermes diikuti Balas hanya: OK sebagai argumen biasa; CLI dapat menganggap kata pertama sebagai nama subcommand.

- Jika tes CLI juga lambat, masalah lebih mungkin berada pada model/provider atau tingkat reasoning. Coba model lain yang terbukti merespons lebih cepat lewat perintah hermes model, atau turunkan tingkat reasoning jika model mendukung pengaturannya.
- Jika tes CLI cepat tetapi Telegram lambat, periksa model aktif lewat hermes status dan log Gateway. Pastikan Gateway memakai konfigurasi model yang sama dan periksa error/timeout.
- Pengaturan reasoning opsional untuk model yang mendukungnya:

~~~bash
hermes config set agent.reasoning_effort low
hermes config get agent.reasoning_effort
~~~

Nilai low dapat mengurangi waktu berpikir pada model yang menghormati parameter tersebut, dengan kemungkinan trade-off pada kedalaman jawaban. Pengaturan ini bukan jaminan latensi dan tidak menggantikan pengujian model. Jangan mengganti model default dalam tutorial secara paksa; pilih model yang paling sesuai dengan kebutuhan dan hasil tesmu.

## 4. Telegram — dari nol sampai tes pesan

1. Buka Telegram dan chat dengan @BotFather.
2. Kirim /newbot, ikuti instruksi untuk nama dan username bot, lalu simpan token yang diberikan secara rahasia.
3. Cari user ID numerik akun Telegram milikmu, misalnya melalui @userinfobot.
4. Dari terminal Railway, jalankan hermes gateway setup. Pilih Telegram, masukkan token dari BotFather, dan masukkan user ID jika wizard memintanya.
5. Jika setup menawarkan pairing atau allowlist, selesaikan langkah otorisasi. Gateway secara default dapat menolak pengguna yang belum diizinkan.
6. Restart service Railway, buka chat pribadi dengan bot dan kirim /start, lalu kirim pesan biasa.

Jika mendapat kode pairing, setujui dari terminal menggunakan kode yang tampil pada Telegram:

~~~bash
hermes pairing list
hermes pairing approve telegram KODE_PAIRING_DARI_BOT
~~~

Jangan menyalin teks placeholder KODE_PAIRING_DARI_BOT secara literal; ganti dengan kode nyata. Jangan jalankan dua Gateway aktif menggunakan token Telegram yang sama karena dapat menyebabkan polling bertabrakan.

## 5. Discord — dari Developer Portal sampai tes pesan

Ikuti semua langkah ini; bot yang sudah online tetap bisa mengabaikan pesan jika akses pengguna atau intent belum benar.

1. Buka https://discord.com/developers/applications, buat application, masuk tab **Bot**, lalu salin token bot secara rahasia.
2. Pada **Bot → Privileged Gateway Intents**, aktifkan **Message Content Intent** dan simpan. Hermes memerlukan intent ini untuk membaca isi pesan. Aktifkan **Server Members Intent** juga bila menggunakan allowlist berbasis username atau role; jika muncul `PrivilegedIntentsRequired`, periksa kedua intent tersebut.
3. Pada **OAuth2 → URL Generator**, centang scope `bot` dan `applications.commands`. Berikan permission seperlunya, minimal View Channels, Send Messages, dan Read Message History. Buka URL yang dihasilkan untuk mengundang bot ke server yang benar.
4. Aktifkan **Developer Mode** di Discord (User Settings → Advanced). Gunakan **Copy User ID** untuk memperoleh user ID Discord numerik milikmu. Jangan memasukkan username/nickname sebagai pengganti ID numerik jika wizard meminta ID.
5. Dari terminal Railway, jalankan `hermes gateway setup`, pilih Discord, masukkan token yang benar, dan bila ditanya **“Allow yourself (...) to talk to the bot?”**, jawab **Yes** untuk akun Discord milikmu.
6. Pastikan konfigurasi akses mengizinkan user-mu. Untuk pemakaian privat, izinkan ID numerik milikmu melalui wizard. Jika muncul `No Discord access policy configured` atau `User not allowed`, lihat langkah diagnosis pada bagian Troubleshooting; jangan mengaktifkan akses semua pengguna untuk bot publik.
7. Pastikan bot sudah diundang dan memiliki izin melihat channel yang diuji. Tes pertama lewat DM: buka profil bot, klik Message, lalu kirim pesan biasa.

### Aturan balasan Discord

- **DM:** secara default Hermes merespons pesan langsung tanpa perlu mention.
- **Channel server:** secara default Hermes hanya merespons ketika kamu menyebut `@DURIAN HERMES` (atau nama bot yang kamu pilih). Pesan biasa tanpa mention akan diabaikan.
- Bot yang diundang ke server belum tentu memiliki izin untuk melihat setiap channel. Periksa pengaturan permission channel dan role bot.
- Token bot dan user ID adalah dua hal berbeda. Token mengautentikasi bot; `DISCORD_ALLOWED_USERS` mengizinkan akun pengguna untuk berinteraksi dengannya.

Jika Telegram sudah berfungsi tetapi Discord tidak, jangan ubah provider/model atau konfigurasi Telegram. Fokus periksa Discord token, intents, allowlist, izin channel, dan aturan mention.

## 6. Penyimpanan dan auto-start

- /opt/data — lokasi persisten yang direkomendasikan untuk konfigurasi, file .env internal Hermes, sesi, memori, dan log.
- /data — direktori kerja terminal untuk file umum. File di sini tidak dijamin persisten kecuali dibuatkan Volume tambahan.
- /usr/local/share/hermes-tools — runtime tools yang dapat dibuat ulang. Biarkan terpisah dari /opt/data.
- /tmp/uv-cache — cache download sementara; boleh hilang saat container dibuat ulang.

Gateway dimulai otomatis hanya ketika HERMES_AUTOSTART=true dan file konfigurasi Hermes sudah tersedia saat container mulai. Bila menyelesaikan wizard ketika service sedang berjalan, restart service setelah setup. Untuk diagnosis saat auto-start dinonaktifkan, jalankan start-hermes dari satu terminal saja, dan jangan menyalakan Gateway manual jika loop auto-start sudah aktif.

## 7. Variabel opsional untuk token channel

Cara yang direkomendasikan untuk instalasi pertama adalah hermes gateway setup seperti langkah di atas. Jika sengaja memilih menyimpan token sebagai Railway Variables, masukkan nilai asli (jangan kosong dan jangan memakai placeholder) untuk channel yang dipakai:

~~~dotenv
TELEGRAM_BOT_TOKEN=ISI_TOKEN_ASLI_DARI_BOTFATHER
TELEGRAM_ALLOWED_USERS=ID_TELEGRAM_NUMERIK_MILIKMU
DISCORD_BOT_TOKEN=ISI_TOKEN_ASLI_DARI_DISCORD_DEVELOPER_PORTAL
DISCORD_ALLOWED_USERS=ID_USER_DISCORD_NUMERIK_MILIKMU
~~~

Tambahkan hanya baris channel yang benar-benar digunakan. Variabel token yang ditetapkan di Railway dapat mengungguli nilai dari file .env Hermes. Jadi jangan menetapkan token lama atau placeholder di Railway jika sudah mengisi token yang benar melalui wizard. Jangan commit token ke GitHub.

## 8. Troubleshooting

**Model lambat / Telegram terus mengetik sebelum jawaban muncul**  
Jika muncul pesan seperti **waiting for stream response (150s, first_chunk)**, Gateway belum menerima chunk jawaban pertama tepat waktu. Ini berbeda dari sekadar animasi mengetik. Tes model dengan perintah satu-shot berikut atau jalankan Hermes interaktif lalu ketik pesan pada prompt chat:

~~~bash
hermes -c "Balas hanya: OK"
~~~

Jangan mengetik perintah Hermes diikuti Balas hanya: OK sebagai argumen biasa, sebab itu dapat dibaca sebagai nama subcommand. Jika CLI dan Telegram sama-sama lambat, coba model yang lebih cepat melalui hermes model; jika model mendukung reasoning control, uji pengaturan agent.reasoning_effort ke low. Jika CLI cepat tetapi Telegram lambat, periksa model aktif, konfigurasi Gateway, dan log berikut:

~~~bash
hermes status
hermes gateway status
grep -Ei 'first_chunk|no chunks|timeout|stream|nvidia|telegram|error|exception' /opt/data/logs/*.log | tail -n 100
~~~

Jangan menganggap streaming.enabled=true akan memperbaiki waktu token pertama. Streaming mengubah cara jawaban ditampilkan; kecepatan awal tetap bergantung pada model/provider, reasoning, jaringan, dan Gateway.

**Atur streaming Telegram**  
Untuk jawaban progresif, gunakan:

~~~bash
hermes config set streaming.enabled true
hermes config set display.platforms.telegram.streaming true
hermes config get streaming.enabled
hermes config get display.platforms.telegram.streaming
hermes config get display.platforms.discord.streaming
~~~

Streaming global harus aktif agar opsi streaming per-platform bekerja. Nilai true / true / false berarti global aktif, Telegram streaming, Discord jawaban utuh. Setelah perubahan, restart service Railway. Perubahan ini tidak otomatis membuat model lebih cepat.

**Gateway mati saat terminal ditutup / Gateway berstatus stopped**  
Jangan mengandalkan perintah hermes gateway yang dijalankan di shell interaktif karena perintah itu berjalan di foreground. Pastikan HERMES_AUTOSTART=true, file /opt/data/config.yaml sudah ada, dan Railway Volume terpasang pada /opt/data. Setelah wizard selesai, lakukan Redeploy service dari commit terbaru, lalu buka Deploy Logs dan cari pesan **Hermes config found; starting Gateway supervisor.** serta **Starting Hermes Gateway...**. Tutup tab terminal dan tes bot lagi. Bila log menyebut Gateway sedang berjalan manual, itu hanya menjelaskan proses tersebut tidak dipasang sebagai system service; di container ini, entrypoint Railway seharusnya yang mengelola auto-start. Jangan menjalankan Gateway ganda dengan token yang sama.

**Bot online tetapi tidak membalas di Discord**  
Periksa berurutan: (1) **Message Content Intent** aktif di Developer Portal; (2) user ID numerik milikmu diizinkan; (3) bot punya View Channel, Send Messages, dan Read Message History; (4) untuk channel server, kirim pesan dengan mention bot; (5) coba DM sebagai tes awal.

**Log menampilkan No Discord access policy configured atau User not allowed**  
Discord dapat tersambung tetapi menolak pesan masuk jika tidak ada kebijakan akses yang mengizinkan user. Jalankan ulang hermes gateway setup untuk memperbaiki otorisasi melalui wizard, atau periksa DISCORD_ALLOWED_USERS di /opt/data/.env jika mengelola variabel secara manual. Isinya harus berupa user ID Discord numerik yang benar. Jangan menimpa file .env secara keseluruhan, karena file itu juga dapat berisi kredensial provider dan bot.

**Log menampilkan PrivilegedIntentsRequired atau bot langsung offline**  
Buka Developer Portal → Application → Bot → Privileged Gateway Intents. Aktifkan **Message Content Intent**; aktifkan juga **Server Members Intent** bila menggunakan username/role allowlist atau bila error meminta intent tersebut. Simpan pengaturan, kemudian restart service Railway.

**Bot tidak membalas pesan biasa di channel server**  
Coba sebut bot secara eksplisit, misalnya @DURIAN HERMES halo. Ini perilaku default. DM tidak memerlukan mention.

**Telegram tidak merespons sama sekali**  
Pastikan token BotFather benar, akun telah diizinkan/pairing selesai, dan tidak ada Gateway lain yang menggunakan token Telegram yang sama. Periksa juga hermes gateway status dan log Gateway.

**hermes doctor menunjukkan provider lain tidak login**  
Peringatan provider yang tidak dipilih tidak otomatis berarti model utama gagal. Periksa nilai Model/Provider di hermes status dan bagian API Connectivity pada hermes doctor.

**hermes: command not found atau build gagal**  
Periksa Build Logs, pastikan deployment memakai commit terbaru, dan jalankan command -v hermes dari terminal. Installer serta adapter Telegram/Discord dipasang saat image dibuat; jangan instal ulang pada setiap startup.

**Terminal menolak login atau service restart terus**  
Pastikan TERMINAL_USER dan TERMINAL_PASSWORD ada di Variables; password minimal 16 karakter, disarankan 24 karakter atau lebih. Periksa Deploy Logs untuk pesan validasi.

**Konfigurasi hilang setelah redeploy**  
Pasang Railway Volume di /opt/data sebelum menjalankan wizard pertama kali. Volume yang hanya dipasang di /data tidak melindungi konfigurasi Hermes.

## 9. Keamanan

- Terminal publik menjalankan shell root di dalam container. Password yang kuat wajib.
- Jangan commit password terminal, API key, atau token bot ke repository.
- Jangan membagikan token bot pada chat atau screenshot; rotasi/revoke token jika terlanjur bocor.
- Hindari mengaktifkan akses semua pengguna pada bot yang punya akses ke tools atau terminal.
- Resource, waktu aktif, dan filesystem tetap mengikuti batas serta kebijakan Railway.

## Referensi resmi

- Instalasi Hermes: https://hermes-agent.nousresearch.com/docs/getting-started/installation
- Messaging Gateway: https://hermes-agent.nousresearch.com/docs/user-guide/messaging
- Telegram setup: https://hermes-agent.nousresearch.com/docs/user-guide/messaging/telegram
- Discord setup: https://hermes-agent.nousresearch.com/docs/user-guide/messaging/discord
- Environment variables: https://hermes-agent.nousresearch.com/docs/reference/environment-variables
- Upstream Hermes: https://github.com/NousResearch/hermes-agent


## Struktur repository

```text
debian-hermes-railway/
├── Dockerfile
├── entrypoint.sh
├── start-hermes
├── system-banner.sh
├── .env.example
├── LICENSE
├── README.md
├── README.en.md
├── CONTRIBUTING.md
├── SECURITY.md
├── docs/
│   ├── hero.id.svg
│   ├── hero.en.svg
│   ├── architecture.svg
│   ├── architecture.en.svg
│   └── SOURCES.md
└── .github/
    └── workflows/
        └── docker-build.yml
```

## Sumber, atribusi, dan lisensi

Daftar komponen upstream, logo, ilustrasi, serta batas lisensi dijelaskan dalam [`docs/SOURCES.md`](docs/SOURCES.md).

- **Repository ini:** materi proyek yang tercakup mengikuti [MIT License](LICENSE).
- **Debian:** logo yang ditampilkan adalah logo resmi *open-use*. Hak cipta dan ketentuannya mengikuti upstream Debian; penggunaannya tidak menandakan dukungan resmi Debian.
- **Hermes Agent:** proyek upstream dikelola oleh [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent), dengan lisensi upstream tersendiri.
- **ttyd, Railway, Docker dan paket Debian:** komponen, layanan, merek, dan lisensinya tetap tunduk pada ketentuan pemilik masing-masing.
- Ilustrasi `docs/hero.*.svg` dan `docs/architecture*.svg` dibuat khusus untuk dokumentasi repository ini, bukan screenshot resmi atau jaminan kondisi deployment aktif.

## Kontribusi

Issues dan Pull Requests dipersilakan. Baca [`CONTRIBUTING.md`](CONTRIBUTING.md) sebelum mengajukan perubahan. Jangan unggah token Telegram/Discord, API key, password, file konfigurasi sensitif, atau log yang mengandung rahasia.

## Kebijakan keamanan

Untuk melaporkan potensi kerentanan, ikuti [`SECURITY.md`](SECURITY.md). Hindari memublikasikan token bot, kredensial Railway, domain privat, atau isi konfigurasi sensitif. Jika token terlanjur terekspos, cabut dan buat token baru dari portal penyedia terkait.
