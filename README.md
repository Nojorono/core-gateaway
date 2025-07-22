# Kong Gateway Architecture Example

Arsitektur ini menggunakan Kong sebagai API Gateway untuk mengatur routing dan autentikasi ke beberapa backend service sesuai diagram.

## Struktur
- **Kong Gateway** (port 8000/8001)
- **Postgres** (untuk database Kong)
- **wms-backend** (contoh backend)
- **sofia-backend** (contoh backend)
- **md-backend** (contoh backend)

## Cara Menjalankan

1. **Jalankan semua service dengan Docker Compose**
   ```bash
   docker-compose up -d
   ```

2. **Setup Kong (daftarkan service & route)**
   Jalankan skrip berikut setelah semua container berjalan:
   ```bash
   bash kong-setup.sh
   ```

3. **Akses API Gateway**
   - WMS: `http://localhost:8000/wms-backend-api`
   - Sofia: `http://localhost:8000/sofia-backend-api`
   - MD: `http://localhost:8000/md-backend-api`

4. **(Opsional) Tambah Plugin Auth**
   - Edit `kong-setup.sh` untuk mengaktifkan plugin JWT atau lainnya sesuai kebutuhan.

## Catatan
- Untuk backend service, digunakan image `kennethreitz/httpbin` sebagai contoh. Ganti dengan backend Anda jika perlu.
- Untuk manajemen Kong lebih mudah, bisa gunakan [Konga UI](https://pantsel.github.io/konga/).

---

Jika butuh bantuan lebih lanjut, silakan hubungi! 🇮🇩 