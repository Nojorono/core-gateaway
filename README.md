# Kong Gateway Architecture Example

Arsitektur ini menggunakan Kong sebagai API Gateway untuk mengatur routing dan autentikasi ke beberapa backend service sesuai diagram.

## Documentation

- **[Sequence Diagrams Overview](SEQUENCE_DIAGRAMS.md)** - Complete system integration diagrams
- **[Sequence Diagrams Index](SEQUENCE_DIAGRAMS_INDEX.md)** - Quick reference to all diagrams
- **[Sequence Diagrams Summary](SEQUENCE_DIAGRAMS_SUMMARY.md)** - Comprehensive summary of all diagrams
- **[Architecture Summary](ARCHITECTURE_SUMMARY.md)** - System architecture documentation

### Service-Specific Sequence Diagrams

- **[Backend-WMS Diagrams](backend-wms/WMS_SEQUENCE_DIAGRAM.md)** - Warehouse Management System flows
- **[Backend-MD Diagrams](backend-md/MD_SEQUENCE_DIAGRAM.md)** - Marketing Dashboard flows
- **[Backend-RYO Diagrams](backend-ryo/RYO_SEQUENCE_DIAGRAM.md)** - Retailer Yield Optimization flows
- **[Service-Meta Diagrams](service-meta/META_SEQUENCE_DIAGRAM.md)** - Master Data Service flows

## Struktur
- **Kong Gateway** (port 8000/8001)
- **backend-wms** - Warehouse Management System (NestJS)
- **backend-md** - Marketing Dashboard (NestJS + Drizzle)
- **backend-ryo** - Retailer Yield Optimization (Django)
- **service-meta** - Master Data Service (NestJS + Oracle)

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