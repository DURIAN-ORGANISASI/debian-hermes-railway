# Debian + Hermes Agent untuk Railway

Deploy **Debian 13 (Trixie) slim + Hermes Agent CLI** ke Railway. Image ini menyediakan terminal web yang dilindungi username/password, banner informasi sistem, dukungan dependency Telegram dan Discord, serta pilihan Gateway Hermes otomatis setelah konfigurasi tersedia.

> Ini adalah container Railway, bukan VPS penuh atau desktop Debian. Akses melalui terminal browser. Kontainer bisa dibuat ulang saat deploy; pasang Railway Volume untuk menyimpan konfigurasi Hermes dan data yang harus bertahan.

## Fitur

- Debian 13 `trixie-slim` sebagai base image.
- Terminal browser memakai `ttyd`, dilindungi kredensial `TERMINAL_USER` dan `TERMINAL_PASSWORD`.
- Hermes Agent CLI diinstal saat proses Docker build menggunakan installer resmi.
- Dependency adapter Telegram dan Discord disiapkan saat build; build akan gagal lebih awal jika instalasi dependency tersebut gagal.
- Banner login otomatis bergaya Fastfetch/neofetch: OS, kernel, arsitektur, uptime, CPU, RAM, disk, timezone dan status Gateway.
- Git, curl, Python 3, pip/venv, compiler dan library build.
- Gateway dapat auto-start/restart setelah `$HERMES_HOME/config.yaml` tersedia.
- Zona waktu default `Asia/Jakarta`.
- Data/config Hermes tersimpan di `HERMES_HOME` (default `/opt/data`).
- Tool runtime yang dapat diunduh ulang dan cache build tidak diarahkan ke volume persisten kecil.
- Mendukung `amd64` dan `arm64` untuk binary `ttyd`.

Installer Hermes memakai `--skip-browser` supaya image lebih ringan. Image build juga menjalankan `hermes pm install --extra telegram --extra discord`. Repo ini **tidak** menaruh API key, model, token Telegram/Discord, atau daftar user yang diizinkan secara hard-coded. Pilih provider/model dan masukkan token melalui CLI Hermes setelah deploy.

## Variabel Railway

Isi di **Railway → service → Variables**:

| Variable | Wajib? | Nilai |
|---|---|---|
| `TERMINAL_USER` | Ya | Username login terminal; tidak boleh mengandung `:` |
| `TERMINAL_PASSWORD` | Ya | Password acak unik minimal 16 karakter; disarankan 24–40 karakter |
| `TZ` | Tidak | Default `Asia/Jakarta` |
| `HERMES_HOME` | Tidak | Default `/opt/data`; konfigurasi dan state persisten |
| `HERMES_RUNTIME_DIR` | Tidak | Default `/usr/local/share/hermes-tools`; lokasi runtime tool yang dapat dibuat ulang |
| `UV_CACHE_DIR` | Tidak | Default `/tmp/uv-cache`; cache unduhan sementara |
| `HERMES_AUTOSTART` | Tidak | `true` (default) atau `false` untuk menonaktifkan auto-start Gateway |
| `PORT` | Otomatis | Disediakan Railway; jangan hard-code atau set manual kecuali ada alasan khusus |

Gunakan username/password berbeda dari layanan Debian atau Ubuntu lain. Jangan commit password, provider key, atau token channel ke GitHub. Masukkan secret melalui CLI Hermes atau mekanisme secret yang sesuai.

## Deploy ke Railway

1. Buat repository GitHub baru bernama `debian-hermes-railway`.
2. Upload isi proyek ini ke **root repository**. Pastikan `Dockerfile`, `entrypoint.sh`, `system-banner.sh` dan `start-hermes` berada di root.
3. Di Railway pilih **New Project → Deploy from GitHub Repo**, lalu pilih `debian-hermes-railway`.
4. Pastikan Railway menggunakan Dockerfile di root repository.
5. Tambahkan `TERMINAL_USER` dan `TERMINAL_PASSWORD` di Variables.
6. Tambahkan Railway Volume dengan mount path **`/opt/data` sebelum setup Hermes** agar konfigurasi awal masuk ke volume persisten.
7. Pada **Settings → Networking**, generate domain publik dan buka URL tersebut.

Railway dapat otomatis membuat ulang deployment setelah perubahan variabel atau source. Periksa Build Logs dan Deploy Logs jika start gagal.

## Setup awal Hermes

Masuk ke terminal web, login, lalu jalankan:

```bash
hermes --help
hermes setup
hermes gateway setup
```

Ikuti prompt untuk memilih provider/model, mengonfigurasi token Telegram/Discord, dan pengaturan channel yang dibutuhkan. Tes chat CLI biasa terlebih dahulu untuk memisahkan masalah provider dari masalah channel.

Setelah `hermes setup` membuat `${HERMES_HOME}/config.yaml`, restart service Railway. Dengan `HERMES_AUTOSTART=true`, entrypoint akan mendeteksi file tersebut lalu menjalankan `hermes gateway run` dalam loop restart. Jika konfigurasi belum dibuat, terminal tetap bisa dipakai dan Gateway tidak dijalankan otomatis.

Untuk menjalankan Gateway secara manual untuk diagnosis:

```bash
start-hermes
```

Untuk pemeriksaan dasar:

```bash
hermes doctor
hermes gateway status
```

Lihat Railway Deploy Logs dan log Hermes di `$HERMES_HOME/logs/`.

### Telegram tidak membalas

Pastikan token bot benar, pengaturan pairing/allowed users sesuai, model/provider berhasil dipakai lewat chat CLI, dan tidak ada Gateway lain yang aktif memakai token bot yang sama.

### Discord tidak membalas

Pastikan **Message Content Intent** diaktifkan pada Discord Developer Portal, bot dapat melihat dan mengirim pesan di channel target, dan pengaturan allowed users/pairing benar. Pada server, bot biasanya perlu di-mention kecuali konfigurasi free-response telah diaktifkan.

## Penyimpanan data

Tambahkan volume sebelum menyelesaikan setup Hermes:

- **`/opt/data`** — konfigurasi, `.env` internal Hermes, sesi, memori dan log. Ini mount paling penting agar setup bertahan saat redeploy.
- **`/data`** — file umum yang dibuat melalui terminal. Folder ini tidak otomatis persisten tanpa volume tambahan.

Jika hanya menambahkan volume ke `/data`, konfigurasi Hermes di `/opt/data` masih dapat hilang saat container diganti. Jangan mengarahkan `HERMES_RUNTIME_DIR` ke `/opt/data`; runtime tool yang dapat dibuat ulang bisa menghabiskan kapasitas volume.

## Banner sistem

Banner berjalan otomatis ketika login melalui interactive Bash login shell. Skrip menggunakan `fastfetch` jika tersedia; jika tidak, skrip menampilkan informasi sistem dengan Bash. CPU/RAM yang terlihat adalah informasi container, bukan jaminan kuota paket Railway. Informasi disk mengikuti filesystem `/data`.

## Keamanan dan batasan

- Terminal web dapat diakses melalui domain publik Railway: selalu gunakan password unik dan kuat.
- Shell berjalan sebagai `root` di dalam container.
- Ini bukan desktop GUI Debian penuh dan bukan lingkungan VPS berbasis systemd.
- Gateway berjalan selama service Railway dan resource yang diperlukan tersedia.
- Jangan simpan token, API key atau password asli di repository.
- Build membutuhkan akses jaringan ke installer Hermes, package index dan release `ttyd`; jika sumber upstream bermasalah, build dapat gagal.

## Troubleshooting

**Build gagal saat instalasi Hermes atau dependency Telegram/Discord** — periksa Build Logs. Installer dan dependency diunduh saat build, sehingga koneksi internet dan ketersediaan upstream diperlukan.

**Muncul `No space left on device`** — pastikan `HERMES_RUNTIME_DIR=/usr/local/share/hermes-tools`, bukan `/opt/data`. Cache yang dapat dibuat ulang diarahkan keluar volume persisten.

**Gateway tidak auto-start** — selesaikan `hermes setup` dan `hermes gateway setup`, pastikan `$HERMES_HOME/config.yaml` ada, lalu restart service. Pastikan `HERMES_AUTOSTART=true`.

**Config hilang setelah redeploy** — tambahkan volume `/opt/data` lalu selesaikan ulang setup jika konfigurasi lama sudah tidak ada.

**Banner tidak terlihat** — buka sesi terminal baru dan pastikan shell adalah interactive Bash login shell.

## Struktur file

```text
.
├── Dockerfile
├── entrypoint.sh
├── system-banner.sh
├── start-hermes
├── .dockerignore
├── .gitignore
├── .env.example
├── .github/
│   └── workflows/
│       └── docker-build.yml
├── LICENSE
└── README.md
```

## Referensi

- [Panduan instalasi resmi Hermes](https://hermes-agent.nousresearch.com/docs/getting-started/installation/)
- [Panduan messaging/Gateway Hermes](https://hermes-agent.nousresearch.com/docs/user-guide/messaging/)
- [Repositori upstream Hermes Agent](https://github.com/NousResearch/hermes-agent)
