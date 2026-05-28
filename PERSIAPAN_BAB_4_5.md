# Audit & Finalisasi Bab 4 & 5 — AudioMatch

Berdasarkan draf Anda di `Bab-4-5.md` dan standar MIRA (Gratia), berikut adalah poin-poin yang **sudah ada** dan **yang masih perlu ditambahkan/diperbaiki** untuk menyempurnakan laporan Anda.

---

## 1. Analisis Kesenjangan (Gap Analysis)

| Komponen | Status di `Bab-4-5.md` | Tindakan Lanjutan |
|---|---|---|
| **Tabel Lingkungan Pengembangan** | ⚠️ Hanya narasi (4.1) | **Wajib dibuatkan tabel** (lihat poin 2.1 di bawah). |
| **Sub-bab per Komponen** | ❌ Belum ada | Sebaiknya 4.1 dipecah menjadi sub-bab (4.1.2–4.1.8) agar lebih terstruktur seperti MIRA. |
| **Code Snippets** | ⚠️ Baru ada Prompt | **Perlu ditambah** potongan kode untuk Hybrid Search, Redis, dan Deteksi Kendaraan. |
| **Tabel Struktur Database** | ⚠️ Hanya narasi | **Wajib dibuatkan tabel** detail kolom dan contoh data. |
| **Tampilan Antarmuka** | ✅ Lengkap (3 Gambar) | Sudah sesuai dengan revisi *Chat-Only*. |
| **Hasil Pengujian (Black Box)** | ✅ Lengkap (Tabel 4.1) | Sudah sesuai. |
| **Hasil Pengujian (NDCG)** | ✅ Lengkap (Tabel 4.2–4.5) | Sudah sesuai dengan angka nyata. |
| **Tabel Waktu Respons** | ❌ Belum ada | Disarankan menambah tabel performa latensi (opsional tapi bagus). |

---

## 2. Bahan Tambahan untuk Dimasukkan ke Laporan

### 2.1 Tabel Lingkungan Pengembangan (Gantikan narasi paragraf 1 di 4.1)

| Komponen | Spesifikasi / Versi |
|---|---|
| Bahasa Pemrograman | Python 3.12.3 |
| Framework Web | FastAPI 0.134.0 |
| Database & Vector Store | PostgreSQL 17.8 + pgvector |
| Model Embedding | VoyageAI `voyage-3.5-lite` (1024-dim) |
| Large Language Model | Gemini 1.5 Flash (Draf Anda menyebut 2.5 Flash Lite*) |
| Caching | Upstash Redis |
| Platform Deployment | Vercel (Serverless) |

> **Catatan**: Di `Bab-4-5.md` Anda menulis "Gemini 2.5 Flash Lite". Secara resmi versi yang ada saat ini adalah **1.5 Flash**. Jika itu typo, silakan diperbaiki di laporan.

### 2.2 Potongan Kode yang Perlu Disisipkan (Selain Prompt)

Untuk memenuhi standar MIRA, tambahkan sub-bab baru di bawah 4.1 dengan menyisipkan kode berikut:

**A. Implementasi Hybrid Search (Sub-bab 4.1.3)**
```sql
-- Penggabungan Vector & BM25 dengan RRF
ORDER BY (COALESCE(1.0/(60 + v.rank), 0) * 0.6 + COALESCE(1.0/(60 + b.rank), 0) * 0.4) DESC;
```

**B. Implementasi Deteksi Kendaraan (Sub-bab 4.1.4)**
```python
# Regex matching untuk 230+ model kendaraan
car_keywords = {'xpander': ('Mitsubishi', 'Xpander', 'MPV'), ...}
```

**C. Implementasi Caching Redis (Sub-bab 4.1.6)**
```python
# TTL 24 Jam untuk Session History
await redis.set(f"session:{session_id}", history, ex=86400)
```

### 2.3 Tabel Struktur Database (Sub-bab 4.1.2)

Buatlah tabel seperti ini untuk tabel `master_products`:

| Nama Kolom | Tipe Data | Keterangan |
|---|---|---|
| `mp_id` | UUID | Primary Key |
| `mp_name` | VARCHAR | Nama produk audio |
| `mp_price` | DECIMAL | Harga produk (Rupiah) |
| `mp_embedding` | VECTOR | Representasi vektor deskripsi |

---

## 3. Koreksi Data Teknis

Ada sedikit perbedaan angka antara draf Anda dan sistem, mohon dipastikan mana yang akan digunakan di laporan:
- **Jumlah Data Kendaraan**: Draf Anda menyebut "lebih dari 230", di database terdeteksi sekitar 230+. Ini sudah akurat.
- **Threshold**: Di draf Anda sudah tertulis `0,3`, ini sudah sesuai dengan konfigurasi `database_service.py`.
- **NDCG@5**: Draf Anda mencatat `0,8878`. Pastikan angka ini berasal dari file `hasil_testing/ndcg_results.json`.

---

## Daftar File yang Perlu Dikirim ke Claude (Revisi)

Karena Anda sudah memiliki draf bab yang cukup matang, Anda tinggal mengirimkan ini ke Claude untuk **"memperhalus bahasa dan melengkapi tabel"**:

1. [x] `PERSIAPAN_BAB_4_5.md` (Gunakan file audit ini sebagai panduan revisi)
2. [x] `Bab-4-5.md` (Draf awal Anda)
3. [ ] `hasil_testing/black_box_results.json` (Sebagai bukti lampiran)
4. [ ] `hasil_testing/ndcg_results.json` (Sebagai bukti lampiran)
5. [ ] Screenshot Antarmuka (Gambar 4.5, 4.6, 4.7 yang disebutkan di draf)
