# Debian 13 Trixie + Hermes Agent untuk Railway

Repository ini menjalankan terminal web yang dilindungi password dan Hermes Agent CLI di Railway. Image ini bukan VPS penuh atau desktop GUI. Gunakan Railway Volume untuk menyimpan konfigurasi Hermes dan riwayat yang perlu bertahan setelah redeploy.

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

Masuk ke terminal web dan jalankan satu per satu:

~~~bash
command -v hermes
hermes --version
hermes setup
~~~

Dalam wizard setup:
1. Pilih provider/model yang benar-benar memiliki API key atau akses akun aktif.
2. Masukkan API key melalui prompt Hermes; jangan tempel secret ke README, issue, atau terminal command yang tersimpan di riwayat.
3. Selesaikan wizard hingga kembali ke shell.

Kemudian jalankan:

~~~bash
hermes gateway setup
~~~

Di wizard Gateway, pilih Telegram dan/atau Discord yang ingin digunakan, lalu ikuti prompt token dan izin pengguna. Gunakan ID numerik akun pengguna bila diminta. Jangan gunakan nama tampilan/nickname sebagai pengganti user ID. Setelah selesai, jalankan pemeriksaan:

~~~bash
hermes doctor
hermes gateway status
~~~

Pastikan setup berhasil sebelum menguji bot. Coba chat Hermes secara normal di CLI terlebih dahulu untuk memastikan model dan provider bekerja. Setelah wizard membuat konfigurasi di /opt/data, restart service Railway satu kali. Karena container awalnya mungkin menyala sebelum konfigurasi ada, restart memastikan entrypoint membaca konfigurasi dan memulai Gateway otomatis. Dengan HERMES_AUTOSTART=true, jangan jalankan Gateway kedua secara manual pada service yang sama.

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

1. Buka https://discord.com/developers/applications dan buat application.
2. Buka tab Bot, buat bot bila diminta, lalu salin token bot. Perlakukan token ini seperti password.
3. Pada pengaturan Bot, aktifkan **Message Content Intent** (wajib agar Discord dapat mengirim teks pesan ke Gateway). Karena panduan ini memakai allowlist berupa user ID numerik, **Server Members Intent** tidak biasanya diperlukan; aktifkan juga intent itu hanya jika kamu memilih allowlist berbasis username atau role.
4. Buka OAuth2 → URL Generator. Pilih scope bot dan applications.commands. Pilih permission minimum yang diperlukan, setidaknya View Channels, Send Messages, Read Message History, serta Attach Files/Embed Links bila dibutuhkan. Gunakan URL yang dibuat untuk mengundang bot ke server.
5. Aktifkan Developer Mode pada Discord client. Salin user ID numerik milikmu bila diperlukan untuk allowlist.
6. Dari terminal Railway, jalankan hermes gateway setup. Pilih Discord, masukkan token bot dan izinkan user ID milikmu bila diminta.
7. Restart service Railway setelah wizard selesai.
8. Tes terlebih dahulu lewat DM ke bot. Di channel server, perilaku default biasanya mensyaratkan @mention bot kecuali channel free-response sudah dikonfigurasi.

Pastikan bot memiliki izin melihat channel yang diuji dan mengirim pesan ke sana. Menambahkan bot ke server saja tidak otomatis memberi akses ke setiap channel. Gunakan pairing atau allowlist user yang tepat; jangan aktifkan allow-all untuk bot publik.

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

**Build gagal pada installer Hermes atau dependency Telegram/Discord**  
Periksa Build Logs. Build membutuhkan akses jaringan ke installer Hermes, repository paket OS, package index, dan release ttyd. CI membantu menemukan regresi build, tetapi kegagalan upstream sementara tetap bisa terjadi. Jalankan ulang deployment setelah penyebab upstream atau network pulih.

**Terminal menolak login atau service restart terus**  
Pastikan TERMINAL_USER dan TERMINAL_PASSWORD ada di Variables; password minimal 16 karakter. Lihat Deploy Logs untuk pesan validasi variable.

**hermes: command not found**  
Pastikan build image baru benar-benar selesai dan periksa hasil command -v hermes. Jangan menjalankan installer manual berulang kali di setiap startup; instalasi CLI dipanggang ke image saat build.

**Bot online tetapi tidak membalas**  
Jalankan hermes doctor dan hermes gateway status. Periksa Deploy Logs dan log di /opt/data/logs. Pastikan chat CLI biasa berhasil, token tidak kedaluwarsa, user ID benar, dan pairing/allowlist sudah mengizinkan akunmu.

**Telegram tidak merespons**  
Pastikan token dari BotFather benar, user sudah diizinkan, dan tidak ada Gateway lain yang menjalankan token yang sama.

**Discord tidak merespons**  
Pastikan Message Content Intent aktif, token benar, bot sudah diundang ke server, bot punya akses channel, dan user diizinkan. Untuk pesan server biasa, coba @mention bot; DM adalah tes awal yang lebih sederhana.

**Gateway belum otomatis hidup**  
Pastikan file konfigurasi dibuat oleh wizard, HERMES_AUTOSTART=true, Volume /opt/data terpasang, lalu restart service.

**Konfigurasi hilang setelah redeploy**  
Pasang Volume di /opt/data dan ulangi setup jika konfigurasi lama sudah hilang. Menambahkan Volume hanya di /data tidak melindungi konfigurasi Hermes.

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
