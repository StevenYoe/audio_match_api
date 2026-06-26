# Panduan Import Data

Panduan untuk import data **Produk**, **Masalah Pelanggan**, dan **Model Mobil** ke dalam sistem.

Semua endpoint menerima file **CSV** atau **Excel** (`.xlsx` / `.xls`) lewat form-field bernama `file`. Template CSV tersedia di folder ini:

| Data | Endpoint | Template |
|---|---|---|
| Produk | `POST /api/v1/admin/import-data/products` | `template_products.csv` |
| Masalah Pelanggan | `POST /api/v1/admin/import-data/problems` | `template_problems.csv` |
| Model Mobil | `POST /api/v1/admin/import-data/cars` | `template_cars.csv` |

## Cara Import

Lewat Swagger UI (`http://localhost:8000/docs`) pilih endpoint, klik **Try it out**, upload file, **Execute**.

Atau lewat `curl`:

```bash
curl -X POST http://localhost:8000/api/v1/admin/import-data/products \
  -F "file=@templates/template_products.csv"

curl -X POST http://localhost:8000/api/v1/admin/import-data/problems \
  -F "file=@templates/template_problems.csv"

curl -X POST http://localhost:8000/api/v1/admin/import-data/cars \
  -F "file=@templates/template_cars.csv"
```

Respons sukses:

```json
{ "message": "Successfully imported 3 products", "inserted_count": 3, "total_rows": 3 }
```

## Aturan Umum

- Nama kolom **case-insensitive** dan spasi di awal/akhir diabaikan.
- Kolom alias didukung (mis. `name` → `mp_name`, `brand` → `mc_brand`). Lihat tabel kolom di bawah.
- Baris yang kolom **wajib**-nya kosong akan dilewati (tidak diimport).
- Kolom boolean (`*_is_active`) menerima `TRUE/FALSE`, `1/0`, `yes/no`. Default `TRUE` bila kolom tidak ada.

## 1. Produk (`/products`)

| Kolom | Wajib | Alias | Keterangan |
|---|---|---|---|
| `mp_name` | ✅ | `name` | Nama produk |
| `mp_category` | ✅ | `category` | mis. Subwoofer, Head Unit, Speaker, Amplifier |
| `mp_price` | ✅ | `price` | Angka (numeric) |
| `mp_brand` | | `brand` | Merek |
| `mp_description` | | `description` | Deskripsi |
| `mp_image` | | `image` | URL gambar |
| `mp_solves_problem_id` | | `problem_id` | UUID masalah yang dipecahkan |
| `mp_is_active` | | `active` | Default `TRUE` |

## 2. Masalah Pelanggan (`/problems`)

| Kolom | Wajib | Alias | Keterangan |
|---|---|---|---|
| `mcp_problem_title` | ✅ | `title`, `problem_title` | Judul masalah |
| `mcp_description` | | `description` | Deskripsi masalah |
| `mcp_recommended_approach` | | `solution`, `recommended_approach` | Pendekatan solusi |
| `mcp_is_active` | | `active`, `is_active` | Default `TRUE` |

## 3. Model Mobil (`/cars`)

| Kolom | Wajib | Alias | Keterangan |
|---|---|---|---|
| `mc_brand` | ✅ | `brand` | mis. Toyota |
| `mc_model` | ✅ | `model` | mis. Avanza |
| `mc_size_category` | ✅ | `size`, `size_category` | `small` / `medium` / `large` |
| `mc_type` | | `type` | MPV, SUV, City Car, Sedan, Hatchback, Pickup |
| `mc_dashboard_type` | | `dashboard_type` | `single_din` / `double_din` / `android_custom` (default `double_din`) |
| `mc_door_count` | | `doors`, `door_count` | Integer (default 4) |
| `mc_cabin_volume` | | `cabin_volume` | Teks bebas |
| `mc_subwoofer_space` | | `subwoofer_space` | `spacious` / `moderate` / `limited` / `underseat_only` |
| `mc_factory_speaker_size` | | `factory_speaker_size` | mis. `6.5 inch` |
| `mc_factory_speaker_count` | | `factory_speaker_count` | Integer (default 2) |
| `mc_special_notes` | | `notes`, `special_notes` | Catatan instalasi |
| `mc_is_active` | | `active`, `is_active` | Default `TRUE` |

## Setelah Import: Sinkronisasi Embedding

Produk dan masalah butuh embedding untuk hybrid search. Setelah import, jalankan berulang sampai `status: "complete"`:

```bash
curl -X POST "http://localhost:8000/api/v1/admin/sync-embeddings?batch_size=20"
```

Model mobil **tidak** butuh embedding (pencarian via brand/model langsung), jadi langkah ini tidak berlaku untuk `/cars`.
