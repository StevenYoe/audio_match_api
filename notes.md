# AudioMatch Database Documentation

## Simplified Database Schema (2 Tables)

Sistem telah disederhanakan dari 6 tabel menjadi **2 tabel utama** untuk memudahkan maintenance dan pengembangan.

---

## 1. Tabel `sales.master_customer_problems` (Data Masalah Pelanggan)

Tabel ini digunakan untuk mendeteksi apa masalah atau kebutuhan audio mobil si user. **Solusi sudah merge ke tabel ini** sebagai `mcp_recommended_approach`.

### Kolom Wajib:
* `mcp_problem_title` (Wajib): Judul singkat masalah (misal: "Suara Bass Kurang Bertenaga")
* `mcp_is_active` (Wajib): Pastikan diset TRUE. Data FALSE akan diabaikan oleh sistem

### Kolom Opsional:
* `mcp_description`: Penjelasan detail masalah. Akan digabung dengan title untuk embedding agar pencarian lebih akurat
* `mcp_recommended_approach`: Pendekatan solusi untuk masalah ini (misal: "Tambah subwoofer dedicated untuk frekuensi rendah, upgrade amplifier mono")
* `mcp_embedding`: **Biarkan NULL**. Ini akan diisi otomatis oleh sistem saat sync

### Contoh Data:
```
mcp_problem_title: "Bass kurang bertenaga"
mcp_description: "Suara bass terasa tipis dan tidak menggetarkan, terutama pada musik EDM dan hip-hop"
mcp_recommended_approach: "Tambah subwoofer 10-12 inch dengan amplifier dedicated. Pastikan power handling sesuai dengan kebutuhan."
mcp_is_active: TRUE
```

---

## 2. Tabel `sales.master_products` (Data Produk)

Tabel ini berisi semua produk audio yang tersedia. **Langsung terhubung ke problems** via foreign key `mp_solves_problem_id`.

### Kolom Wajib:
* `mp_name` (Wajib): Nama produk
* `mp_category` (Wajib): Kategori (Subwoofer, Head Unit, Speaker, Amplifier, dll)
* `mp_price` (Wajib): Harga produk (numeric)

### Kolom Opsional:
* `mp_brand`: Merk produk
* `mp_description`: Deskripsi detail produk
* `mp_image`: URL gambar atau emoji
* `mp_solves_problem_id`: **UUID** - Link ke `master_customer_problems.mcp_id` (produk ini menyelesaikan masalah apa)
* `mp_is_active`: Default TRUE
* `mp_embedding`: **Biarkan NULL**. Ini akan diisi otomatis oleh sistem saat sync

### Contoh Data:
```
mp_name: "Subwoofer 10 Inch Rockford Fosgate P300-10"
mp_category: "Subwoofer"
mp_brand: "Rockford Fosgate"
mp_price: 2500000
mp_description: "Powered subwoofer 10 inch dengan built-in amplifier 300W RMS"
mp_image: "🔊"
mp_solves_problem_id: "<UUID dari masalah 'Bass kurang bertenaga'>"
mp_is_active: TRUE
```

---

## Hubungan Antar Tabel

```
master_customer_problems (mcp_id)
         ↑
         | (mp_solves_problem_id FK)
         |
master_products (mp_id)
```

**Satu masalah bisa memiliki banyak produk solusi** (one-to-many relationship via direct FK).

---

## Import Data dari File (CSV/Excel)

Sistem mendukung **bulk import** dari file CSV atau Excel untuk memudahkan input data dalam jumlah besar.

### Endpoint Import:

#### 1. Import Products
```
POST /api/v1/admin/import-data/products
Content-Type: multipart/form-data
Body: file=<upload CSV/Excel>
```

**Format CSV untuk Products:**
```csv
mp_name,mp_category,mp_brand,mp_price,mp_description,mp_image,mp_solves_problem_id,mp_is_active
"Subwoofer 10 Inch Rockford Fosgate",Subwoofer,Rockford Fosgate,2500000,"Powered subwoofer 300W RMS",🔊,,TRUE
"Head Unit Pioneer DEH-S5250BT",Head Unit,Pioneer,1800000,"HU dengan Bluetooth dan USB",,TRUE
"Speaker Component 6.5 Inch Hertz",Speaker,Hertz,3200000,"Component 2-way 6.5 inch",,TRUE
```

**Kolom Wajib:** `mp_name`, `mp_category`, `mp_price`  
**Kolom Opsional:** `mp_brand`, `mp_description`, `mp_image`, `mp_solves_problem_id`, `mp_is_active`

---

#### 2. Import Problems
```
POST /api/v1/admin/import-data/problems
Content-Type: multipart/form-data
Body: file=<upload CSV/Excel>
```

**Format CSV untuk Problems:**
```csv
mcp_problem_title,mcp_description,mcp_recommended_approach,mcp_is_active
"Bass kurang bertenaga","Suara bass tipis tidak menggetarkan","Tambah subwoofer 10-12 inch dengan amplifier dedicated",TRUE
"Suara pecah di volume tinggi","Speaker distorsi saat volume dinaikkan","Upgrade speaker component dengan power handling lebih tinggi",TRUE
"Head Unit tidak connect Bluetooth","Bluetooth HU tidak terdeteksi","Ganti HU dengan model yang sudah support Bluetooth 5.0+",TRUE
```

**Kolom Wajib:** `mcp_problem_title`  
**Kolom Opsional:** `mcp_description`, `mcp_recommended_approach`, `mcp_is_active`

---

#### 3. Auto-Link Products to Problems (Optional Helper)
```
POST /api/v1/admin/import-data/auto-link
```
Endpoint ini akan **otomatis mencocokkan produk dengan masalah** berdasarkan keyword matching. Berguna untuk Establish relasi awal tanpa manual input `mp_solves_problem_id`.

---

## Alur Kerja Lengkap

### Step 1: Import Data
Upload file CSV/Excel untuk products dan problems:
```bash
# Import problems terlebih dahulu
curl -X POST http://localhost:8000/api/v1/admin/import-data/problems \
  -F "file=@problems.csv"

# Import products
curl -X POST http://localhost:8000/api/v1/admin/import-data/products \
  -F "file=@products.csv"

# (Opsional) Auto-link products ke problems
curl -X POST http://localhost:8000/api/v1/admin/import-data/auto-link
```

### Step 2: Generate Embeddings
Setelah data masuk, panggil sync untuk generate vector embeddings:
```bash
curl -X POST http://localhost:8000/api/v1/admin/sync-embeddings
```

**Yang terjadi saat sync:**
1. Sistem mencari problems & products yang `embedding`-nya masih NULL
2. Generate embedding menggunakan VoyageAI dari text (title + description untuk problems, name + description untuk products)
3. Simpan vector ke kolom `mcp_embedding` atau `mp_embedding`

### Step 3: Test Chatbot
Chatbot siap digunakan! User bisa tanya:
- "Bass mobil saya kurang bertenaga, solusinya apa?"
- "Speaker saya pecah kalau volume tinggi"
- "Rekomendasi subwoofer yang bagus"

---

## Update Embeddings

Jika Anda mengubah teks (title, description, approach) pada data yang sudah ada dan ingin update vector-nya:

1. **Set NULL** kolom embedding secara manual di database:
   ```sql
   UPDATE sales.master_customer_problems 
   SET mcp_embedding = NULL 
   WHERE mcp_id = '<uuid>';
   
   UPDATE sales.master_products 
   SET mp_embedding = NULL 
   WHERE mp_id = '<uuid>';
   ```

2. **Panggil sync** kembali:
   ```
   POST /api/v1/admin/sync-embeddings
   ```

---

## Stored Functions (Database)

### `sales.search_problem(embedding, threshold, limit)`
Vector similarity search untuk mencari masalah yang paling relevan.

### `sales.get_recommendations(problem_id)`
Mengambil semua produk yang terhubung ke suatu masalah via FK `mp_solves_problem_id`.

---

## Migration dari Schema Lama

Jika Anda migrate dari schema lama (6 tabel → 2 tabel), jalankan:
```bash
# Backup data dulu (opsional)
# Lalu jalankan migration
psql -d your_database -f migration.sql
```

Migration akan:
1. Tambah kolom `mcp_recommended_approach` ke problems
2. Tambah kolom `mp_solves_problem_id` ke products
3. Drop tabel `master_solutions`, `master_solution_products`, `master_knowledge_chunks`, `trx_*`
4. Update stored functions untuk schema baru

---

## Tips

1. **Import problems dulu**, baru products (agar `mp_solves_problem_id` bisa langsung di-set)
2. **Gunakan auto-link** jika tidak mau manual set problem IDs
3. **Sync embeddings** setiap kali ada data baru
4. **Test chatbot** dengan berbagai variasi pertanyaan user
5. **Plain text only** - chatbot tidak pakai markdown formatting
