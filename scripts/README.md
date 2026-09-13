# Docker Compose Clean Restart Scripts

Scripts untuk melakukan clean restart pada docker-compose services dengan cleanup yang komprehensif.

## 📋 Available Scripts

### 1. `docker-compose-clean-restart.sh` (Interactive)
Script utama dengan konfirmasi interaktif untuk volume pruning.

**Features:**
- ✅ Stop semua services
- ✅ Remove containers
- ✅ Clean up images
- ✅ Prune unused resources
- ✅ Interactive volume prune (optional)
- ✅ Pull latest images
- ✅ Rebuild dan start services
- ✅ Show status dan logs

**Usage:**
```bash
# Restart semua services
./scripts/docker-compose-clean-restart.sh

# Restart service tertentu
./scripts/docker-compose-clean-restart.sh backend-wms
./scripts/docker-compose-clean-restart.sh service-meta
```

**Shortcut:**
```bash
./clean-restart.sh [service-name]
```

---

### 2. `docker-compose-clean-restart-auto.sh` (Non-Interactive)
Script untuk automation/CI/CD tanpa interaksi user.

**Features:**
- ✅ Semua fitur dari script utama
- ✅ Non-interactive (skip volume prune by default)
- ✅ Safe untuk automation
- ✅ Error handling yang robust

**Usage:**
```bash
# Restart semua services (auto, skip volumes)
./scripts/docker-compose-clean-restart-auto.sh

# Restart service tertentu
./scripts/docker-compose-clean-restart-auto.sh backend-wms

# Restart dengan volume prune
./scripts/docker-compose-clean-restart-auto.sh "" false
```

**Shortcut:**
```bash
./clean-restart-auto.sh [service-name]
```

---

## 🚀 Quick Start

### Restart Semua Services
```bash
# Interactive (dengan konfirmasi)
./clean-restart.sh

# Auto (tanpa konfirmasi)
./clean-restart-auto.sh
```

### Restart Service Tertentu
```bash
# Restart backend-wms
./clean-restart.sh backend-wms

# Restart service-meta
./clean-restart.sh service-meta

# Restart backend-md
./clean-restart.sh backend-md
```

---

## 📝 What the Scripts Do

1. **Stop Services** - Stop semua running containers
2. **Remove Containers** - Hapus containers yang sudah di-stop
3. **Clean Images** - Hapus images yang terkait dengan services
4. **System Prune** - Bersihkan unused Docker resources
5. **Volume Prune** - (Optional) Hapus unused volumes
6. **Pull Images** - Download latest images dari registry
7. **Rebuild** - Build ulang images dari Dockerfile
8. **Start Services** - Start semua services dengan fresh containers
9. **Status Check** - Tampilkan status dan logs

---

## ⚠️ Important Notes

### Volume Pruning
- **Interactive script**: Akan menanyakan konfirmasi sebelum menghapus volumes
- **Auto script**: Default skip volume prune untuk keamanan data
- **Warning**: Volume prune akan menghapus semua unused volumes, termasuk data yang tidak digunakan

### Service Names
Gunakan nama service sesuai dengan yang ada di `docker-compose.yml`:
- `backend-md`
- `backend-ryo`
- `backend-wms`
- `service-meta`
- `kong`
- `kong-database`
- `prometheus`
- `grafana`

### Data Safety
- Script **TIDAK** akan menghapus volumes yang sedang digunakan
- Database data akan tetap aman jika volume masih attached
- Untuk keamanan ekstra, backup data penting sebelum menjalankan script

---

## 🔧 Troubleshooting

### Permission Denied
```bash
chmod +x scripts/docker-compose-clean-restart.sh
chmod +x scripts/docker-compose-clean-restart-auto.sh
```

### Line Ending Issues (Windows/WSL)
```bash
# Fix line endings
dos2unix scripts/docker-compose-clean-restart.sh
dos2unix scripts/docker-compose-clean-restart-auto.sh
```

### Docker Compose Not Found
```bash
# Install docker-compose
sudo apt-get update
sudo apt-get install docker-compose
```

---

## 📊 Example Output

```
==========================================
🚀 Docker Compose Clean Restart
==========================================

ℹ️  Target: All services

ℹ️  Step 1/8: Stopping services...
✅ Services stopped

ℹ️  Step 2/8: Removing containers...
✅ Containers removed

...

✅ Clean restart completed!
```

---

## 🔗 Related Scripts

- `restart-service-meta.sh` - Restart service-meta saja
- `restart-wms-backend.sh` - Restart backend-wms saja
- `kong-docker-restart.sh` - Restart Kong Gateway
- `kong-force-cleanup.sh` - Force cleanup Kong

---

**Made with ❤️ for Core Gateway Project**

