# Panduan Testing AudioMatch — Bab 4 Skripsi

Dokumen ini menjelaskan cara menjalankan dua jenis pengujian yang dirancang di Bab 3:
1. **Black Box Testing** (9 skenario, Tabel 3.9)
2. **Pengujian Kualitas Retrieval NDCG@K** (30 kueri, Tabel 3.10–3.11)

Output akhir berupa file Markdown dan JSON di folder `hasil_testing/` yang siap dimasukkan ke Bab 4.

---

## Prasyarat

### 1. Python & Virtual Environment

```bash
cd /home/graxya/Downloads/Kokoh/audio_match_api

# Buat virtual environment (hanya sekali)
python3 -m venv venv

# Aktifkan venv
source venv/bin/activate

# Install semua dependency
venv/bin/pip install -r requirements.txt
```

Cek instalasi berhasil:
```bash
venv/bin/python -c "import httpx, asyncpg, pandas, openpyxl; print('OK')"
```

### 2. File `.env`

Pastikan file `.env` ada di root project (`audio_match_api/.env`) dengan isi:

```env
DATABASE_URL=postgresql://...          # Neon PostgreSQL connection string
VOYAGE_API_KEY=pa-...                  # VoyageAI API key (untuk embedding)
GEMINI_API_KEY=AIza...                 # Google Gemini API key (untuk LLM chatbot)
UPSTASH_REDIS_REST_URL=https://...     # Upstash Redis URL
UPSTASH_REDIS_REST_TOKEN=...           # Upstash Redis token
RATE_LIMIT_ENABLED=True
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW=60
```

> Minta file `.env` dari Graxya — jangan buat sendiri karena berisi API key aktif.

### 3. Struktur File yang Harus Ada

```
audio_match_api/
├── .env                          ← wajib ada
├── venv/                         ← dibuat lewat python3 -m venv venv
├── test_bab3_blackbox.py
├── test_bab3_ndcg_generate.py
├── test_bab3_ndcg_calculate.py
└── hasil_testing/                ← dibuat otomatis saat testing
```

---

## Bagian 1 — Black Box Testing (9 Skenario)

### Langkah 1: Jalankan Server

Buka **terminal pertama** dan jalankan server:

```bash
cd /home/graxya/Downloads/Kokoh/audio_match_api
source venv/bin/activate
venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Server siap ketika muncul:
```
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000
```

Verifikasi server aktif (di terminal lain):
```bash
curl http://localhost:8000/
# → {"message": "Welcome to AudioMatch v..."}
```

### Langkah 2: Jalankan Script Black Box

Buka **terminal kedua**:

```bash
cd /home/graxya/Downloads/Kokoh/audio_match_api
source venv/bin/activate
venv/bin/python test_bab3_blackbox.py
```

**Estimasi waktu:** 3–5 menit (Test 6 mengirim 110 request concurrent untuk uji rate limit).

### Langkah 3: Cek Output

```bash
cat hasil_testing/black_box_results.md
```

Hasil yang diharapkan (target: **9/9 PASS**):

```
HASIL: 9/9 test passed
```

File output:
- `hasil_testing/black_box_results.md` — tabel hasil untuk Bab 4
- `hasil_testing/black_box_results.json` — data lengkap JSON

### Skenario yang Diuji

| No | Skenario | Endpoint | Kriteria Pass |
|----|----------|----------|---------------|
| 1 | Konsultasi umum | POST /api/v1/chat/ | HTTP 200, ada `response` dan `session_id` |
| 2 | Rekomendasi berbasis kendaraan | POST /api/v1/chat/ | HTTP 200, ada rekomendasi produk |
| 3 | Kelanjutan percakapan | POST /api/v1/chat/ | HTTP 200, `session_id` konsisten |
| 4 | Pertanyaan di luar domain | POST /api/v1/chat/ | HTTP 200, respons menyatakan di luar cakupan |
| 5 | Session baru tanpa session_id | POST /api/v1/chat/ | HTTP 200, `session_id` baru di-generate |
| 6 | Rate limiting (>100 req/60s) | POST /api/v1/chat/ | HTTP 429 setelah limit terlewati |
| 7 | Input kosong / hanya spasi | POST /api/v1/chat/ | HTTP 422 (Pydantic validation error) |
| 8 | Daftar produk | GET /api/v1/products | HTTP 200, ada daftar produk aktif |
| 9 | Konsistensi sesi lintas pesan | POST /api/v1/chat/ | HTTP 200, session_id tetap sama di 3 pesan |

### Troubleshooting Black Box

| Masalah | Solusi |
|---------|--------|
| `Connection refused` | Pastikan server berjalan di terminal pertama |
| Test 6 FAIL (tidak ada 429) | Tunggu 60 detik lalu jalankan ulang |
| Semua test FAIL dengan error LLM | VoyageAI/Gemini API quota habis — tunggu 5 menit |
| Test 7 timeout (>60 detik) | Skip Gemini rate limit — jalankan ulang saat API quota reset |

---

## Bagian 2 — Pengujian NDCG@K Kualitas Retrieval

Pengujian ini **tidak butuh server berjalan** — koneksi langsung ke database PostgreSQL.

Tiga tahap:
1. **Generate** — jalankan 30 kueri lewat Hybrid Search, simpan hasil ke Excel
2. **Anotasi** — domain expert mengisi skor relevansi di Excel (manual)
3. **Kalkulasi** — hitung NDCG dari Excel yang sudah dianotasi

---

### Fase 1: Generate Template Anotasi

```bash
cd /home/graxya/Downloads/Kokoh/audio_match_api
source venv/bin/activate
venv/bin/python test_bab3_ndcg_generate.py
```

**Estimasi waktu:** 15–25 menit

Kenapa lama? Script memanggil VoyageAI API untuk embed 30 kueri. VoyageAI free tier punya batas 3 request/menit, sehingga ada jeda otomatis antar kueri.

Progres akan tampil di terminal:
```
[K01] amplifier 4 channel 75 watt cocok untuk berapa speaker?
  → Embedding... done
  → Hybrid search: 5 results
[K02] berapa watt amplifier yang dibutuhkan untuk subwoofer 12 inch?
  ...
✅ Selesai! Template: hasil_testing/ndcg_annotation_template.xlsx
```

**Output:** `hasil_testing/ndcg_annotation_template.xlsx`

---

### Fase 2: Anotasi oleh Domain Expert

Buka file `hasil_testing/ndcg_annotation_template.xlsx`.

Struktur kolom:

| query_id | kategori | query_text | rank_1 | rank_2 | rank_3 | rank_4 | rank_5 | rel_1 | rel_2 | rel_3 | rel_4 | rel_5 |
|----------|----------|------------|--------|--------|--------|--------|--------|-------|-------|-------|-------|-------|
| K01 | Kompatibilitas Komponen | amplifier 4 channel... | Masalah A | Masalah B | ... | ... | ... | **?** | **?** | **?** | **?** | **?** |

**Kolom yang harus diisi:** `rel_1` hingga `rel_5` (kolom berwarna kuning)

**Skala penilaian:**

| Nilai | Arti |
|-------|------|
| `0` | Tidak relevan — hasil retrieval tidak berhubungan dengan kueri |
| `1` | Relevan — hasil berhubungan dengan kueri tapi tidak spesifik |
| `2` | Sangat relevan — hasil persis menjawab kueri |

**Contoh pengisian:**
- Kueri: `"amplifier 4 channel 75 watt cocok untuk berapa speaker?"`
  - rank_1: "Cara menghubungkan speaker ke amplifier 4 channel" → `rel_1 = 2`
  - rank_2: "Kerusakan amplifier karena beban speaker berlebih" → `rel_2 = 1`
  - rank_3: "Cara memasang head unit aftermarket" → `rel_3 = 0`

**Total baris:** 30 kueri × 5 kolom rel = 150 nilai yang perlu diisi.

> Setelah selesai, **simpan file tanpa mengganti nama** — tetap `ndcg_annotation_template.xlsx`.

---

### Fase 3: Hitung NDCG

Setelah file Excel sudah diisi lengkap:

```bash
cd /home/graxya/Downloads/Kokoh/audio_match_api
source venv/bin/activate
venv/bin/python test_bab3_ndcg_calculate.py
```

**Estimasi waktu:** < 5 detik (hanya membaca Excel dan menghitung).

Output:
- `hasil_testing/ndcg_results.md` — tabel untuk Bab 4
- `hasil_testing/ndcg_results.json` — data lengkap per kueri dan per kategori

### Target Skor (sesuai Bab 3 Tabel 3.11)

| Metrik | Target | Keterangan |
|--------|--------|------------|
| NDCG@3 | ≥ 0.75 | Kualitas top-3 hasil retrieval |
| NDCG@5 | ≥ 0.70 | Kualitas top-5 hasil retrieval |
| Precision@3 | ≥ 0.70 | % hasil relevan di top-3 |
| Precision@5 | ≥ 0.65 | % hasil relevan di top-5 |

---

## Ringkasan Perintah

```bash
# Setup (sekali saja)
python3 -m venv venv
source venv/bin/activate
venv/bin/pip install -r requirements.txt

# ── Black Box Testing ──────────────────────────────────────────────────────
# Terminal 1: jalankan server
venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000

# Terminal 2: jalankan test
venv/bin/python test_bab3_blackbox.py
# → hasil_testing/black_box_results.md   ✓

# ── NDCG Testing ───────────────────────────────────────────────────────────
# Fase 1: generate template (15-25 menit, tidak perlu server)
venv/bin/python test_bab3_ndcg_generate.py
# → hasil_testing/ndcg_annotation_template.xlsx

# Fase 2: buka Excel, isi kolom rel_1 s/d rel_5 (manual)
#         gunakan skala 0=tidak relevan, 1=relevan, 2=sangat relevan

# Fase 3: hitung NDCG
venv/bin/python test_bab3_ndcg_calculate.py
# → hasil_testing/ndcg_results.md        ✓
# → hasil_testing/ndcg_results.json      ✓
```

---

## File Output untuk Bab 4

| File | Isi | Digunakan di |
|------|-----|--------------|
| `hasil_testing/black_box_results.md` | Tabel 9 skenario black box + status PASS/FAIL | Bab 4 — Black Box Testing |
| `hasil_testing/black_box_results.json` | Data lengkap JSON | Lampiran |
| `hasil_testing/ndcg_annotation_template.xlsx` | 30 kueri + hasil retrieval + anotasi relevansi | Lampiran |
| `hasil_testing/ndcg_results.md` | Tabel NDCG@3, NDCG@5, Precision@3, Precision@5 | Bab 4 — Pengujian NDCG |
| `hasil_testing/ndcg_results.json` | Data lengkap per kueri + per kategori | Lampiran |

---

## Catatan Penting

- **Jangan jalankan black box test dan NDCG test secara bersamaan** — keduanya menggunakan VoyageAI API yang punya rate limit ketat (3 req/menit untuk free tier).
- **Tunggu minimal 5 menit** antara dua kali menjalankan `test_bab3_ndcg_generate.py` jika gagal di tengah jalan — quota VoyageAI perlu reset.
- **Server tidak perlu running** untuk NDCG test (langsung ke database).
- **Server wajib running** untuk Black Box test.
- Semua output file aman dijalankan ulang — file lama akan ditimpa dengan hasil baru.
