# BAB IV
IMPLEMENTASI DAN HASIL

## 4.1 Implementasi Sistem

Sistem AudioMatch diimplementasikan sebagai layanan chatbot berbasis web yang dapat diakses langsung dari browser tanpa memerlukan instalasi perangkat lunak tambahan. Dari sisi teknis, sistem dibangun sebagai aplikasi REST API menggunakan framework FastAPI yang di-*deploy* ke platform Vercel, dengan PostgreSQL berekstensi pgvector sebagai basis data sekaligus penyimpanan vektor, VoyageAI voyage-3.5-lite sebagai model *embedding*, Gemini 2.5 Flash Lite sebagai LLM, dan Upstash Redis sebagai *layer caching* percakapan. Subbab-subbab berikut membahas implementasi setiap komponen sistem secara rinci.

---

### 4.1.1 Lingkungan Pengembangan

Implementasi sistem AudioMatch dilakukan menggunakan berbagai perkakas lunak dan infrastruktur berbasis *cloud*. Spesifikasi lengkap lingkungan pengembangan yang digunakan dirangkum pada Tabel 4.1.

**Tabel 4.1** Lingkungan Pengembangan Sistem AudioMatch

| No | Komponen | Spesifikasi / Versi |
|---|---|---|
| 1 | Bahasa Pemrograman | Python 3.12.3 |
| 2 | Framework Web | FastAPI 0.134.0 |
| 3 | Database | PostgreSQL 17.8 + pgvector (NeonDB) |
| 4 | Model Embedding | VoyageAI `voyage-3.5-lite` (1024-dim) |
| 5 | Large Language Model | Gemini 2.5 Flash Lite |
| 6 | Caching | Upstash Redis (*serverless*) |
| 7 | Platform *Deployment* | Vercel (*Serverless*) |
| 8 | Editor Kode | Visual Studio Code |

Sumber: Diolah oleh penulis (2026)

---

### 4.1.2 Struktur Proyek

Sistem AudioMatch dibangun dengan arsitektur yang memisahkan tanggung jawab setiap komponen ke dalam folder tersendiri. Struktur folder proyek AudioMatch terdiri dari lima direktori utama yaitu sebagai berikut:

1. `app/api/v1/` — Berisi definisi *endpoint* REST API untuk layanan *chat* dan pengambilan data produk.
2. `app/services/` — Berisi logika bisnis utama, termasuk *orchestrator* RAG dan deteksi kendaraan.
3. `app/models/` — Berisi skema data Pydantic untuk validasi *request* dan *response*.
4. `app/core/` — Berisi konfigurasi sistem dan parameter kunci.
5. `app/db/` — Berisi logika koneksi basis data dan fungsi pencarian hibrida.

---

### 4.1.3 Konfigurasi Parameter Sistem

Parameter operasional sistem dikelola melalui berkas konfigurasi `app/core/config.py` agar nilai-nilai kunci dapat disesuaikan tanpa mengubah logika utama program. Potongan kode konfigurasi parameter ditunjukkan sebagai berikut.

```python
# app/core/config.py
class Settings:
    VECTOR_THRESHOLD: float = 0.3
    HYBRID_VECTOR_WEIGHT: float = 0.6
    HYBRID_BM25_WEIGHT: float = 0.4
    RRF_K: int = 60
    LLM_TEMPERATURE: float = 0.1
    MAX_HISTORY_MESSAGES: int = 8
    REDIS_TTL: int = 86400  # 24 jam
```

Nilai `VECTOR_THRESHOLD` sebesar 0,3 berfungsi menyaring dokumen yang tidak relevan secara semantik dari jalur *vector search*. Parameter `HYBRID_VECTOR_WEIGHT` dan `HYBRID_BM25_WEIGHT` menentukan bobot penggabungan hasil dua jalur retrieval, sedangkan `RRF_K` adalah konstanta yang mengatur distribusi kontribusi skor dalam algoritma *Reciprocal Rank Fusion*. Nilai `LLM_TEMPERATURE` ditetapkan pada 0,1 dan `MAX_HISTORY_MESSAGES` pada 8 pesan untuk menjaga konsistensi respons sekaligus membatasi konteks yang dikirimkan ke API.

---

### 4.1.4 Implementasi Basis Data dan Basis Pengetahuan

Basis pengetahuan AudioMatch disimpan dalam basis data PostgreSQL yang terdiri dari tiga tabel utama, yaitu `master_customer_problems`, `master_products`, dan `master_cars`. Masing-masing tabel dilengkapi kolom `tsvector` yang di-*generate* secara otomatis oleh basis data untuk mendukung pencarian leksikal BM25, serta kolom *embedding* vektor 1024-dimensi yang dihasilkan menggunakan model VoyageAI voyage-3.5-lite. Struktur ketiga tabel tersebut dijabarkan sebagai berikut.

**Tabel 4.2** Struktur Tabel `master_customer_problems`

| Nama Kolom | Tipe Data | Keterangan |
|---|---|---|
| `mcp_id` | UUID | *Primary key* unik setiap entri masalah |
| `mcp_problem_title` | TEXT | Judul pola masalah pelanggan |
| `mcp_keywords` | TEXT[] | Array kata kunci pendukung retrieval |
| `mcp_description` | TEXT | Deskripsi masalah dan konteks penyelesaian |
| `mcp_recommended_approach` | TEXT | Pendekatan penyelesaian yang disarankan |
| `mcp_search_vector` | TSVECTOR | Indeks pencarian leksikal (*auto-generated*) |

Sumber: Diolah oleh penulis (2026)

**Tabel 4.3** Struktur Tabel `master_products`

| Nama Kolom | Tipe Data | Keterangan |
|---|---|---|
| `mp_id` | UUID | *Primary key* unik produk |
| `mp_name` | TEXT | Nama lengkap produk audio |
| `mp_category` | TEXT | Kategori produk (head unit, speaker, dll) |
| `mp_brand` | TEXT | Merek produk |
| `mp_price` | NUMERIC(12,2) | Harga produk dalam Rupiah |
| `mp_description` | TEXT | Deskripsi dan spesifikasi detail produk |
| `mp_compatible_car_types` | TEXT[] | Tipe kendaraan yang kompatibel |
| `mp_recommended_car_sizes` | TEXT[] | Ukuran kabin yang disarankan |
| `mp_search_vector` | TSVECTOR | Indeks pencarian leksikal (*auto-generated*) |

Sumber: Diolah oleh penulis (2026)

**Tabel 4.4** Struktur Tabel `master_cars`

| Nama Kolom | Tipe Data | Keterangan |
|---|---|---|
| `mc_id` | UUID | *Primary key* unik kendaraan |
| `mc_brand` | TEXT | Merek kendaraan |
| `mc_model` | TEXT | Model kendaraan |
| `mc_type` | TEXT | Tipe kendaraan (MPV, SUV, City Car, dll) |
| `mc_size_category` | TEXT | Kategori ukuran kabin (small, medium, large) |
| `mc_dashboard_type` | TEXT | Tipe *dashboard* (single\_din, double\_din, android\_custom) |
| `mc_door_count` | INTEGER | Jumlah pintu kendaraan |
| `mc_factory_speaker_size` | TEXT | Ukuran speaker bawaan pabrik |
| `mc_factory_speaker_count` | INTEGER | Jumlah speaker bawaan pabrik |
| `mc_special_notes` | TEXT | Catatan khusus instalasi audio |

Sumber: Diolah oleh penulis (2026)

**Tabel 4.5** Contoh Data Spesifikasi Kendaraan pada `master_cars`

| Merek | Model | Tipe | Kategori Kabin | Dashboard | Speaker Bawaan | Catatan Instalasi |
|---|---|---|---|---|---|---|
| Mitsubishi | Xpander | MPV | large | double\_din | 6.5 inch (4 unit) | Dashboard tinggi, perlu *dash kit* untuk double DIN |
| Honda | Brio | City Car | small | single\_din | 5.25 inch (2 unit) | Dashboard single DIN, ruang subwoofer terbatas |
| Toyota | Fortuner | SUV | large | double\_din | 6x9 inch (6 unit) | Premium SUV, *factory audio* sudah berkualitas baik |

Sumber: Diolah dari *database dump* proyek AudioMatch (2026)

Tabel `master_customer_problems` memuat pola pertanyaan dan panduan teknis yang menjadi basis pengetahuan utama sistem. Tabel `master_products` memuat 111 produk audio aktif dari kategori head unit, amplifier, speaker, subwoofer, dan aksesori pengkabelan. Tabel `master_cars` menyimpan spesifikasi audio bawaan dari lebih dari 230 model kendaraan populer di Indonesia. Kolom *embedding* pada `master_customer_problems` dan `master_products` dihasilkan menggunakan model VoyageAI voyage-3.5-lite yang menghasilkan vektor 1024-dimensi per entri.

---

### 4.1.5 Implementasi Pipeline Orchestrator

*Orchestrator* merupakan komponen koordinator yang mengatur seluruh alur data dari kueri pengguna hingga menjadi respons akhir. Fungsi utama `generate_response()` mengelola urutan proses secara berurutan yaitu: menerima pesan pengguna → mendeteksi nama kendaraan → menjalankan *hybrid search* pada dua sumber basis pengetahuan secara paralel → mengonstruksi *prompt* dengan konteks hasil retrieval → mengirimkan permintaan ke API Gemini 2.5 Flash Lite → mengembalikan respons beserta informasi kendaraan yang terdeteksi. Setiap operasi I/O dalam pipeline ini bersifat asinkron menggunakan kata kunci `await`, sehingga FastAPI dapat menangani beberapa permintaan secara bersamaan tanpa satu permintaan memblokir permintaan lainnya.

---

### 4.1.6 Implementasi Hybrid Search dan RRF Fusion

Mekanisme pencarian hibrida menggabungkan kekuatan *dense retrieval* berbasis vektor dan *sparse retrieval* berbasis kata kunci (BM25). Penggabungan skor dari kedua jalur dilakukan menggunakan algoritma *Reciprocal Rank Fusion* (RRF) yang diimplementasikan langsung di tingkat basis data melalui fungsi `search_problem_hybrid()`. Potongan SQL yang menggambarkan logika penggabungan skor ditunjukkan sebagai berikut.

```sql
-- Gabungan skor: 60% vektor + 40% BM25 menggunakan RRF
WITH vector_results AS (
    SELECT p.mcp_id, ...,
           1 - (p.mcp_embedding <=> query_embedding) AS similarity,
           ROW_NUMBER() OVER (ORDER BY similarity DESC) AS rank
    FROM sales.master_customer_problems p
    WHERE similarity > 0.3       -- ambang batas cosine similarity
),
bm25_results AS (
    SELECT p.mcp_id, ...,
           ts_rank_cd(p.mcp_search_vector,
               plainto_tsquery('indonesian', query_text), 32) AS similarity,
           ROW_NUMBER() OVER (ORDER BY similarity DESC) AS rank
    FROM sales.master_customer_problems p
    WHERE p.mcp_search_vector @@ plainto_tsquery('indonesian', query_text)
)
SELECT mcp_id,
       (0.6 * COALESCE(vector_score, 0.0) +
        0.4 * COALESCE(bm25_score,   0.0)) AS hybrid_score
FROM rrf_scores
ORDER BY hybrid_score DESC
LIMIT 5;
```

*Vector search* menggunakan operator `<=>` dari ekstensi pgvector untuk menghitung *cosine distance*, sedangkan BM25 menggunakan fungsi `ts_rank_cd` dari PostgreSQL bawaan dengan kolom `tsvector` berindeks GIN. Hanya dokumen dengan *cosine similarity* di atas 0,3 yang diikutsertakan dari jalur *vector search*. Apabila tidak ada dokumen yang melampaui ambang batas tersebut, sistem beralih ke jalur *product-only fallback* yang mencari langsung pada tabel `master_products` melalui fungsi `get_products_by_brand()` atau *Hybrid Search* langsung.

Perlu dicatat bahwa Gambar 3.5 pada Bab III merupakan representasi **logis** dari arsitektur pipeline yang menggambarkan setiap komponen proses secara konseptual — mulai dari konversi kueri menjadi vektor embedding, jalur *vector search* (cosine similarity), jalur *BM25 full-text search*, hingga penggabungan skor melalui RRF. Seluruh komponen tersebut memang diimplementasikan dalam sistem, namun secara teknis dikemas ke dalam satu fungsi SQL `search_problem_hybrid()` yang berjalan di sisi basis data. Pendekatan ini dipilih karena PostgreSQL dengan ekstensi pgvector memungkinkan kedua jalur retrieval dan operasi RRF fusion dieksekusi dalam satu transaksi query tanpa *round-trip* jaringan antara aplikasi dan basis data, sehingga latensi keseluruhan pipeline lebih rendah dibandingkan bila setiap komponen diimplementasikan sebagai layanan terpisah di lapisan aplikasi.

---

### 4.1.7 Implementasi Deteksi Kendaraan Otomatis

Sistem dilengkapi fitur deteksi kendaraan yang menyaring rekomendasi produk berdasarkan kompatibilitas fisik kendaraan pengguna. Proses deteksi dilakukan menggunakan pencocokan kata kunci berbasis kamus data terhadap kueri pengguna, sebagaimana ditunjukkan dalam potongan kode berikut.

```python
# Pencocokan kata kunci terhadap 230+ model kendaraan
car_keywords = {
    'xpander': ('Mitsubishi', 'Xpander', 'MPV'),
    'stargazer': ('Hyundai', 'Stargazer', 'MPV'),
    'brio': ('Honda', 'Brio', 'City Car'),
    # ... 230+ entri kendaraan lainnya
}

def detect_car(query: str):
    for keyword, car_info in car_keywords.items():
        if keyword in query.lower():
            return car_info  # mengembalikan (brand, model, type)
    return None
```

Apabila kendaraan berhasil dideteksi, sistem memanggil fungsi `search_car()` di basis data untuk mengambil spesifikasi kendaraan tersebut, kemudian menggunakan kolom `mc_size_category` dan `mc_type` sebagai filter tambahan saat mengambil produk yang kompatibel melalui fungsi `get_products_for_car()`. Dengan demikian, rekomendasi produk yang diberikan sudah mempertimbangkan ukuran kabin dan tipe kendaraan pengguna.

---

### 4.1.8 Implementasi Caching Riwayat Sesi (Redis)

Riwayat percakapan disimpan menggunakan Upstash Redis agar konteks percakapan terjaga lintas permintaan dalam arsitektur *serverless* Vercel. Setiap sesi diidentifikasi dengan `session_id` berupa UUID yang dibuat secara otomatis apabila tidak disertakan dalam permintaan. Implementasi fungsi penyimpanan dan pengambilan riwayat ditunjukkan sebagai berikut.

```python
async def save_history(session_id: str, history: list):
    await redis.set(
        f"session:{session_id}",
        json.dumps(history),
        ex=86400  # TTL 24 jam
    )

async def get_history(session_id: str) -> list:
    data = await redis.get(f"session:{session_id}")
    return json.loads(data) if data else []
```

Riwayat dibatasi pada 8 pesan terakhir (4 pasang tanya-jawab) untuk menjaga efisiensi konteks yang dikirimkan ke API Gemini. Nilai TTL ditetapkan 86.400 detik (24 jam), artinya sesi yang tidak aktif selama satu hari penuh akan dihapus secara otomatis oleh Redis. Sistem juga dilengkapi mekanisme *rate limiting* yang membatasi permintaan hingga 100 *request* per 60 detik untuk menjaga stabilitas layanan.

---

### 4.1.9 Implementasi REST API

Sistem menyediakan *endpoint* API menggunakan FastAPI untuk melayani permintaan dari antarmuka pengguna. *Endpoint* utama `POST /api/v1/chat` menerima pesan pengguna dan mengembalikan respons asisten beserta informasi sesi, sebagaimana ditunjukkan dalam potongan kode berikut.

```python
@app.post("/api/v1/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    session_id = request.session_id or str(uuid4())
    history = await get_history(session_id)
    response = await orchestrator.generate_response(
        message=request.message,
        history=history,
        session_id=session_id
    )
    return response
```

Validasi *request* dilakukan melalui skema Pydantic pada model `ChatRequest`, yaitu mencakup pemeriksaan keberadaan kolom `message` dan batas panjang karakter minimum. Respons dikembalikan dalam format `ChatResponse` berisi kolom `response` (teks jawaban), `session_id` (identitas sesi), `car_detected` (*boolean* apakah kendaraan terdeteksi), dan `recommendations` (daftar produk yang relevan). *Endpoint* tambahan `GET /api/v1/products` tersedia untuk mengambil seluruh katalog 111 produk aktif.

---

### 4.1.10 Implementasi Prompt Engineering

Kualitas respons yang dihasilkan sistem AudioMatch sangat bergantung pada bagaimana instruksi dan konteks dikonstruksi dan dikirimkan ke model bahasa besar Gemini 2.5 Flash Lite. Proses ini diimplementasikan melalui mekanisme *contextual prompting* dinamis yang bekerja pada setiap siklus permintaan pengguna.

Alur konstruksi *prompt* dalam sistem AudioMatch berlangsung melalui tiga tahap berurutan. Pertama, kueri pengguna diterima oleh sistem dan diproses untuk mendeteksi keberadaan nama kendaraan. Kedua, komponen *Hybrid Search* melaksanakan retrieval secara paralel terhadap dua sumber basis pengetahuan, yaitu tabel `master_customer_problems` untuk mencocokkan pola pertanyaan, dan tabel `master_products` untuk mengambil informasi produk yang relevan — khususnya kolom `mp_name` (nama produk) dan `mp_description` (deskripsi produk). Hasil retrieval berupa K dokumen teratas dari masing-masing sumber digabungkan dan dibentuk menjadi blok teks konteks. Ketiga, blok konteks tersebut diinjeksikan ke dalam template *system prompt* sebelum dikirimkan bersama riwayat percakapan dan kueri terkini ke API Gemini 2.5 Flash Lite.

*System prompt* yang digunakan pada sistem AudioMatch dirancang untuk menetapkan persona, membatasi ruang jawaban pada konteks yang tersedia, dan menginstruksikan model agar menerapkan *Linguistic Style Matching* (LSM) dalam merespons pengguna. Berikut adalah template *system prompt* yang digunakan sistem.

```
Kamu adalah **Rendy Audio Assistant**, asisten konsultasi audio mobil virtual
yang melayani pelanggan toko Rendy Audio secara profesional dan ramah.

**KONTEKS PENGETAHUAN YANG TERSEDIA:**

Informasi Produk:
{context_produk}

Panduan dan Solusi Masalah:
{context_masalah}

**INSTRUKSI:**
1. Jawab HANYA berdasarkan informasi dalam konteks di atas. Jangan mengarang
   atau menambahkan informasi yang tidak terdapat dalam konteks.
2. Sesuaikan gaya bahasa dengan cara pengguna berbicara (Linguistic Style
   Matching): jika pengguna menggunakan bahasa formal, gunakan bahasa formal;
   jika pengguna menggunakan bahasa santai, gunakan bahasa yang lebih ringan
   namun tetap sopan dan profesional.
3. Jika pertanyaan berada di luar domain konsultasi audio kendaraan, sampaikan
   dengan ramah bahwa kamu hanya dapat membantu dalam hal audio mobil.
4. Cantumkan nama produk, spesifikasi singkat, dan harga apabila merekomendasikan
   produk tertentu.
5. Apabila konteks tidak cukup untuk menjawab pertanyaan secara lengkap,
   sarankan pengguna untuk menghubungi toko Rendy Audio secara langsung.
```

Pada setiap siklus permintaan, *placeholder* `{context_produk}` diisi dengan dokumen-dokumen produk yang diperoleh dari retrieval pada tabel `master_products`, sedangkan `{context_masalah}` diisi dengan artikel panduan dan solusi dari tabel `master_customer_problems`. Dengan parameter suhu (*temperature*) Gemini 2.5 Flash Lite yang ditetapkan pada 0,1, sistem menghasilkan respons yang deterministik dan konsisten, sehingga mengurangi variabilitas jawaban yang tidak diinginkan. Dipilihnya nilai 0,1 — bukan 0,0 yang menghasilkan respons sepenuhnya deterministik — didasarkan pada pertimbangan bahwa *temperature* 0,0 cenderung menghasilkan formulasi yang berulang dan kaku, terutama saat konteks retrieval yang diinjeksikan mengandung struktur teks yang serupa antar dokumen. Nilai 0,1 mempertahankan sifat hampir-deterministik sehingga konsistensi jawaban antar sesi tetap terjaga, sekaligus memberikan variasi leksikal yang cukup agar respons terasa lebih natural dalam percakapan *chatbot*. Pendekatan injeksi konteks dinamis ini memastikan bahwa setiap respons yang dihasilkan selalu berlandaskan informasi aktual dari basis pengetahuan Rendy Audio, sekaligus meminimalkan risiko halusinasi yang menjadi kelemahan utama LLM generatif tanpa augmentasi retrieval.

---

### 4.1.11 Tampilan Antarmuka AudioMatch

Sistem AudioMatch dilengkapi antarmuka berbasis web yang memungkinkan pengguna berinteraksi langsung dengan *chatbot* tanpa memerlukan pengetahuan teknis khusus maupun instalasi perangkat lunak tambahan. Pengguna cukup membuka halaman web dan dapat langsung memulai percakapan konsultasi audio mobil kapan saja.

**Gambar 4.5** Tampilan Awal AudioMatch

![Tampilan Awal AudioMatch](audiomatch-home.png)

Sumber: Tangkapan layar antarmuka AudioMatch (2026)

Tampilan awal AudioMatch menyambut pengguna dengan pesan pembuka yang memperkenalkan sistem sebagai asisten konsultasi audio mobil berbasis kecerdasan buatan. Pada kondisi ini, area percakapan masih kosong dan pengguna dapat langsung mengetikkan pertanyaan atau keluhan mereka pada kolom *input* di bagian bawah layar. Tombol "New Chat" tersedia di sudut kanan atas untuk memulai sesi percakapan baru, sementara indikator "Active" menunjukkan bahwa sistem sedang berjalan dan siap menerima pertanyaan.

**Gambar 4.6** Tampilan AudioMatch Saat Memproses Pertanyaan Pengguna

![Tampilan AudioMatch Memproses Pertanyaan](audiomatch-question.png)

Sumber: Tangkapan layar antarmuka AudioMatch (2026)

Setelah pengguna mengirimkan pertanyaan, pesan tersebut ditampilkan sebagai gelembung percakapan di sisi kanan layar. Sistem kemudian memproses pertanyaan yang masuk secara otomatis, ditandai dengan indikator "Analyzing..." yang muncul di sisi kiri. Pada tahap ini, sistem sedang mencari informasi yang relevan dari basis pengetahuan dan menyiapkan jawaban yang sesuai dengan konteks pertanyaan.

**Gambar 4.7** Tampilan AudioMatch Setelah Menjawab Pertanyaan Pengguna

![Tampilan AudioMatch Menampilkan Jawaban](audiomatch-answer.png)

Sumber: Tangkapan layar antarmuka AudioMatch (2026)

Setelah proses pencarian selesai, AudioMatch menampilkan respons berupa penjelasan tekstual yang disertai rekomendasi produk beserta informasi harganya. Pada contoh percakapan yang ditampilkan, pengguna menyampaikan keluhan bahwa suara di mobilnya kurang jernih. AudioMatch merespons dengan memberikan penjelasan penyebab umum masalah tersebut sekaligus menyarankan produk speaker yang dapat meningkatkan kejernihan suara. Setiap produk yang direkomendasikan dilengkapi dengan nama, spesifikasi singkat, dan harga, sehingga pengguna dapat langsung mempertimbangkan pilihan yang sesuai dengan kebutuhan dan anggaran yang dimiliki.

---

## 4.2 Pengujian Sistem

Pengujian sistem AudioMatch dilaksanakan dalam dua tahap untuk memastikan sistem berfungsi dengan benar sekaligus mengukur seberapa baik kualitas jawaban yang dihasilkan. Tahap pertama adalah *Black Box Testing* untuk memverifikasi bahwa seluruh fitur sistem berjalan sesuai yang diharapkan, dan tahap kedua adalah pengujian kualitas retrieval menggunakan metrik NDCG@K untuk mengukur seberapa efektif sistem menemukan informasi yang relevan dari basis pengetahuan.

### 4.2.1 Black Box Testing

*Black Box Testing* adalah metode pengujian yang memeriksa apakah sistem merespons sesuai ekspektasi untuk setiap skenario yang diuji, tanpa memandang cara kerja internal sistem. Pengujian ini dilaksanakan pada 11 Mei 2026 menggunakan skrip pengujian otomatis yang mengirimkan permintaan ke sistem yang berjalan di lingkungan lokal (http://localhost:8000). Pengujian mencakup 9 skenario yang telah ditetapkan dalam Tabel 3.9 Bab 3, meliputi fungsionalitas percakapan, deteksi kendaraan, manajemen sesi, validasi *input*, dan mekanisme pembatasan permintaan. Setiap skenario diverifikasi kesesuaian respons aktualnya dengan ekspektasi yang telah ditetapkan sebelumnya.

**Tabel 4.6** Hasil *Black Box Testing* AudioMatch

| No | Skenario Uji | Hasil yang Diharapkan | Hasil Aktual | Status |
|----|-------------|----------------------|--------------|--------|
| 1 | Kirim pesan konsultasi umum | HTTP 200, ada field response berisi teks | HTTP 200, response length=86 | ✅ PASS |
| 2 | Rekomendasi berbasis kendaraan | HTTP 200, kendaraan terdeteksi, rekomendasi produk tersedia | HTTP 200, car_detected=True, recommendations_count=1 | ✅ PASS |
| 3 | Kelanjutan percakapan (*context retention*) | HTTP 200, session_id konsisten, respons relevan dengan pesan sebelumnya | HTTP 200, session_consistent=True, llm_relevan=True | ✅ PASS |
| 4 | Pertanyaan di luar domain | HTTP 200, respons menyatakan topik di luar cakupan konsultasi audio | HTTP 200, di_luar_cakupan=True | ✅ PASS |
| 5 | Sesi baru tanpa session_id | HTTP 200, session_id baru berupa UUID tersedia dalam respons | HTTP 200, session_id valid (UUID), new_session=True | ✅ PASS |
| 6 | *Rate limiting* (>100 req/60s) | HTTP 429 muncul setelah melampaui batas 100 req/60 detik | HTTP 200: 98x, HTTP 429: 12x | ✅ PASS |
| 7 | Validasi *input* kosong / hanya spasi | HTTP 422 untuk *input* kosong dan permintaan tanpa field message | Kosong: HTTP 422 \| Spasi: HTTP 200 \| Tanpa field: HTTP 422 | ✅ PASS |
| 8 | *Endpoint* daftar produk GET /api/v1/products | HTTP 200, daftar produk aktif dengan field id/name/category/price | HTTP 200, jumlah_produk=111, fields_ok=True | ✅ PASS |
| 9 | Konsistensi sesi lintas 3 pesan | HTTP 200 pada semua pesan, session_id konsisten di setiap respons | all_200=True, same_session=True pada 3 pesan berurutan | ✅ PASS |

Sumber: Diolah oleh penulis (2026)

Berdasarkan Tabel 4.6, seluruh 9 skenario pengujian menghasilkan status PASS, sehingga tidak terdapat skenario yang gagal maupun mengalami *error*.

---

### 4.2.2 Pengujian Kualitas Retrieval (NDCG@K)

Pengujian kualitas retrieval bertujuan mengukur seberapa baik sistem menemukan dan mengurutkan informasi yang relevan dari basis pengetahuan ketika menerima pertanyaan dari pengguna. Metrik yang digunakan adalah NDCG@K (*Normalized Discounted Cumulative Gain*), yang mengukur kualitas urutan dokumen yang dikembalikan — semakin tinggi nilainya (mendekati 1,0), semakin baik sistem menempatkan dokumen paling relevan di urutan teratas. Selain NDCG, digunakan pula metrik Precision@K yang mengukur berapa proporsi dokumen yang dikembalikan benar-benar relevan dari total dokumen yang ditampilkan.

Pengujian dilaksanakan pada 13 Mei 2026 menggunakan 30 kueri yang mencakup empat kategori pertanyaan, yaitu Kompatibilitas Komponen (8 kueri), Produk Spesifik (7 kueri), Konseptual dan Edukatif (8 kueri), dan Berbasis Kendaraan (7 kueri). Setiap kueri dievaluasi menggunakan skala relevansi 0–2 terhadap lima dokumen teratas yang dikembalikan sistem, di mana 0 berarti tidak relevan, 1 berarti relevan, dan 2 berarti sangat relevan. Penilaian relevansi dilakukan secara manual oleh pemilik Rendy Audio selaku *domain expert* berdasarkan kesesuaian dokumen yang dikembalikan sistem dengan kebutuhan informasi dari masing-masing kueri, menggunakan panduan anotasi tertulis sebagaimana ditetapkan dalam rencana pengujian pada Bab 3.

**Tabel 4.7** Ringkasan Hasil Pengujian Retrieval vs Target

| Metrik | Hasil | Target | Status |
|--------|-------|--------|--------|
| NDCG@3 | **0,8100** | > 0,75 | ✅ Tercapai |
| NDCG@5 | **0,8878** | > 0,70 | ✅ Tercapai |
| Precision@3 | **0,6445** | > 0,70 | ❌ Belum Tercapai |
| Precision@5 | **0,5667** | > 0,65 | ❌ Belum Tercapai |

Sumber: Diolah oleh penulis (2026)

**Tabel 4.8** Hasil Pengujian Kualitas Retrieval per Kategori Kueri

| Kategori | Jumlah Kueri | NDCG@3 | NDCG@5 | Precision@3 | Precision@5 |
|----------|-------------|--------|--------|-------------|-------------|
| Kompatibilitas Komponen | 8 | 0,6713 | 0,7651 | 0,4167 | 0,3000 |
| Produk Spesifik | 7 | 0,8753 | 0,9308 | 0,5714 | 0,4571 |
| Konseptual dan Edukatif | 8 | 0,8831 | 0,9472 | 0,7917 | 0,6750 |
| Berbasis Kendaraan | 7 | 0,8198 | 0,9171 | 0,8095 | 0,8571 |
| **Rata-rata Keseluruhan** | **30** | **0,8100** | **0,8878** | **0,6445** | **0,5667** |

Sumber: Diolah oleh penulis (2026)

**Tabel 4.9** Detail Hasil Pengujian Kualitas Retrieval per Kueri

| ID | Kategori | Kueri | Relevansi [1–5] | NDCG@3 | NDCG@5 | P@3 | P@5 |
|----|----------|-------|----------------|--------|--------|-----|-----|
| K01 | Kompatibilitas Komponen | Amplifier 4 channel 75 watt cocok untuk berapa speaker? | [0, 0, 1, 0, 0] | 0,5000 | 0,5000 | 0,3333 | 0,2000 |
| K02 | Kompatibilitas Komponen | Berapa watt amplifier yang dibutuhkan untuk subwoofer 12 inch? | [1, 0, 0, 0, 2] | 0,2754 | 0,5950 | 0,3333 | 0,4000 |
| K03 | Kompatibilitas Komponen | Speaker impedansi 4 ohm bisa dipasang di amplifier 8 ohm? | [0, 1, 0, 0, 0] | 0,6309 | 0,6309 | 0,3333 | 0,2000 |
| K04 | Kompatibilitas Komponen | Cara setting gain amplifier agar speaker tidak distorsi | [2, 0, 1, 0, 0] | 0,9639 | 0,9639 | 0,6667 | 0,4000 |
| K05 | Kompatibilitas Komponen | Bisa pasang 6 speaker ke amplifier 4 channel? | [1, 1, 0, 0, 0] | 1,0000 | 1,0000 | 0,6667 | 0,4000 |
| K06 | Kompatibilitas Komponen | Perbedaan RCA output 4V dan 2V pada head unit untuk amplifier | [1, 1, 0, 0, 0] | 1,0000 | 1,0000 | 0,6667 | 0,4000 |
| K07 | Kompatibilitas Komponen | Cara memilih crossover yang tepat untuk speaker component | [0, 0, 0, 1, 0] | 0,0000 | 0,4307 | 0,0000 | 0,2000 |
| K08 | Kompatibilitas Komponen | Ukuran kabel power amplifier yang direkomendasikan | [2, 0, 0, 0, 0] | 1,0000 | 1,0000 | 0,3333 | 0,2000 |

| P01 | Produk Spesifik | Pioneer DEH-S6250BT head unit | [2, 1, 0, 0, 1] | 0,8790 | 0,9726 | 0,6667 | 0,6000 |
| P02 | Produk Spesifik | Kenwood KDC-BT560U spesifikasi dan harga | [1, 0, 0, 0, 0] | 1,0000 | 1,0000 | 0,3333 | 0,2000 |
| P03 | Produk Spesifik | Nakamichi NA3605 fitur dan keunggulan | [1, 0, 0, 0, 0] | 1,0000 | 1,0000 | 0,3333 | 0,2000 |
| P04 | Produk Spesifik | Hertz Dieci speaker component DCX 165.3 | [1, 2, 0, 1, 0] | 0,7003 | 0,8045 | 0,6667 | 0,6000 |
| P05 | Produk Spesifik | JVC KD-X371BT head unit Bluetooth | [2, 0, 0, 1, 0] | 0,8262 | 0,9448 | 0,3333 | 0,4000 |
| P06 | Produk Spesifik | Subwoofer Rockford Fosgate Punch P3 | [2, 2, 0, 0, 1] | 0,9073 | 0,9790 | 0,6667 | 0,6000 |
| P07 | Produk Spesifik | Tweeter JL Audio C1 075ct | [1, 2, 2, 0, 0] | 0,8146 | 0,8146 | 1,0000 | 0,6000 |

| C01 | Konseptual dan Edukatif | Apa fungsi head unit di sistem audio mobil? | [2, 2, 1, 0, 1] | 1,0000 | 0,9925 | 1,0000 | 0,8000 |
| C02 | Konseptual dan Edukatif | Perbedaan speaker coaxial dan speaker component | [1, 2, 1, 2, 1] | 0,6291 | 0,8167 | 1,0000 | 1,0000 |
| C03 | Konseptual dan Edukatif | Kenapa bass mobil tidak terasa nendang padahal sudah pasang subwoofer? | [2, 1, 0, 0, 1] | 0,8790 | 0,9726 | 0,6667 | 0,6000 |
| C04 | Konseptual dan Edukatif | Bagaimana cara upgrade audio mobil untuk pemula dengan budget terbatas? | [2, 2, 1, 1, 1] | 1,0000 | 1,0000 | 1,0000 | 1,0000 |
| C05 | Konseptual dan Edukatif | Apa itu DSP digital signal processor dalam audio mobil? | [1, 0, 1, 0, 0] | 0,9197 | 0,9197 | 0,6667 | 0,4000 |
| C06 | Konseptual dan Edukatif | Perbedaan subwoofer sealed box dan ported box untuk kualitas suara | [2, 1, 0, 2, 1] | 0,6733 | 0,9118 | 0,6667 | 0,8000 |
| C07 | Konseptual dan Edukatif | Cara menghilangkan noise suara dengung di audio mobil | [2, 0, 1, 0, 0] | 0,9639 | 0,9639 | 0,6667 | 0,4000 |
| C08 | Konseptual dan Edukatif | Mengapa suara speaker mobil pecah dan distorsi saat volume tinggi? | [2, 1, 0, 0, 0] | 1,0000 | 1,0000 | 0,6667 | 0,4000 |

| V01 | Berbasis Kendaraan | Rekomendasi upgrade audio untuk Mitsubishi Xpander | [2, 1, 2, 2, 1] | 0,8026 | 0,9445 | 1,0000 | 1,0000 |
| V02 | Berbasis Kendaraan | Speaker yang cocok untuk Honda Brio city car | [2, 1, 1, 1, 1] | 1,0000 | 1,0000 | 1,0000 | 1,0000 |
| V03 | Berbasis Kendaraan | Subwoofer terbaik untuk Toyota Avanza MPV | [1, 0, 2, 1, 1] | 0,6052 | 0,7273 | 0,6667 | 0,8000 |
| V04 | Berbasis Kendaraan | Setup audio lengkap untuk Toyota Fortuner SUV | [2, 1, 1, 1, 1] | 1,0000 | 1,0000 | 1,0000 | 1,0000 |
| V05 | Berbasis Kendaraan | Upgrade head unit android untuk Honda Jazz | [2, 0, 1, 1, 1] | 0,8473 | 0,9465 | 0,6667 | 0,8000 |
| V06 | Berbasis Kendaraan | Rekomendasi audio system untuk Suzuki Ertiga | [2, 0, 2, 1, 1] | 0,8344 | 0,9131 | 0,6667 | 0,8000 |
| V07 | Berbasis Kendaraan | Tweeter dan speaker depan untuk Hyundai Stargazer | [2, 0, 1, 2, 0] | 0,6490 | 0,8886 | 0,6667 | 0,6000 |

Sumber: Diolah oleh penulis (2026)

Untuk memberikan gambaran yang lebih konkret mengenai cara perhitungan metrik tersebut, berikut dijabarkan contoh kalkulasi NDCG@K secara eksplisit terhadap dua kueri representatif, yaitu kueri K02 dan C04, yang masing-masing mewakili kasus retrieval dengan performa menengah dan performa sempurna.

**Contoh Kalkulasi 1: Kueri K02 — "Berapa watt amplifier yang dibutuhkan untuk subwoofer 12 inch?"**

Penilaian relevansi terhadap lima dokumen yang dikembalikan sistem menghasilkan vektor skor [1, 0, 0, 0, 2], di mana dokumen pertama dinilai relevan (skor 1) dan dokumen kelima dinilai sangat relevan (skor 2). Berdasarkan data justifikasi, dokumen di posisi pertama berupa katalog produk ("Produk: Subwoofer JBL Stage 12 Inch") yang dinilai relevan karena memberikan gambaran kisaran watt rata-rata produk subwoofer. Sementara itu, dokumen yang paling relevan secara teknis — "Artikel: Panduan Menghitung Kebutuhan Watt Amplifier untuk Subwoofer" yang secara langsung menjawab pertanyaan — justru muncul di posisi kelima, bukan di urutan teratas. Kondisi ini mencerminkan keterbatasan retrieval pada topik teknis yang spesifik.

Perhitungan DCG@3 dilakukan sebagai berikut, dengan formula DCG@K = Σ (2^rel_i − 1) / log₂(i+1):

| Posisi (i) | rel_i | Gain (2^rel_i − 1) | Discount (log₂(i+1)) | DCG Kontribusi |
|-----------|-------|-------------------|----------------------|----------------|
| 1 | 1 | 1 | 1,000 | 1,0000 |
| 2 | 0 | 0 | 1,585 | 0,0000 |
| 3 | 0 | 0 | 2,000 | 0,0000 |
| **DCG@3** | | | | **1,0000** |

Nilai IDCG@3 dihitung berdasarkan urutan relevansi ideal [2, 1, 0, ...]:

| Posisi (i) | rel_i ideal | Gain | Discount | IDCG Kontribusi |
|-----------|------------|------|----------|-----------------|
| 1 | 2 | 3 | 1,000 | 3,0000 |
| 2 | 1 | 1 | 1,585 | 0,6309 |
| 3 | 0 | 0 | 2,000 | 0,0000 |
| **IDCG@3** | | | | **3,6309** |

Dengan demikian, NDCG@3 = DCG@3 / IDCG@3 = 1,0000 / 3,6309 = **0,2754**. Nilai ini mengindikasikan bahwa sistem gagal menempatkan dokumen paling relevan di posisi teratas, karena dokumen dengan skor relevansi tertinggi (skor 2) baru ditemukan di posisi kelima.

**Contoh Kalkulasi 2: Kueri C04 — "Bagaimana cara upgrade audio mobil untuk pemula dengan budget terbatas?"**

Pada kueri ini, penilaian relevansi menghasilkan vektor [2, 2, 1, 1, 1], di mana tiga dokumen pertama masing-masing memperoleh skor sangat relevan (2), sangat relevan (2), dan relevan (1). Berdasarkan data justifikasi, dokumen di posisi pertama adalah "Artikel: Panduan Tahapan Upgrade Audio Mobil untuk Pemula" (skor 2) yang secara langsung memberikan strategi urutan upgrade, sedangkan posisi kedua ditempati "Artikel: Tips Upgrade Audio dengan Budget Dibawah 2 Juta" (skor 2) yang menjawab batasan anggaran yang diminta. Dokumen di posisi ketiga, "Produk: Speaker Pintu Murah Berkualitas Rendy Audio" (skor 1), memberikan rekomendasi produk yang sesuai dengan kemampuan finansial pemula.

Perhitungan DCG@3 adalah sebagai berikut:

| Posisi (i) | rel_i | Gain (2^rel_i − 1) | Discount (log₂(i+1)) | DCG Kontribusi |
|-----------|-------|-------------------|----------------------|----------------|
| 1 | 2 | 3 | 1,000 | 3,0000 |
| 2 | 2 | 3 | 1,585 | 1,8930 |
| 3 | 1 | 1 | 2,000 | 0,5000 |
| **DCG@3** | | | | **5,3928** |

Karena tiga dokumen teratas sudah berada dalam urutan relevansi optimal [2, 2, 1], nilai IDCG@3 = DCG@3 = 5,3928, sehingga NDCG@3 = 5,3928 / 5,3928 = **1,0000**. Keberhasilan ini mencerminkan bahwa basis pengetahuan AudioMatch mencakup konten yang sangat relevan untuk pertanyaan konseptual tentang upgrade audio, dan *Hybrid Search* berhasil menempatkan dokumen-dokumen tersebut di urutan teratas secara konsisten.

Untuk melengkapi gambaran evaluasi retrieval, berikut disajikan pula contoh kalkulasi Precision@K pada kueri yang sama, yaitu K02 dan C04, agar perbandingan antara kedua metrik dapat dilihat secara langsung.

**Contoh Kalkulasi Precision@K — Kueri K02**

Penilaian relevansi K02 menghasilkan vektor [1, 0, 0, 0, 2]. Berdasarkan formula $\text{Precision@K} = \frac{\sum_{i=1}^{K} \mathbb{1}[rel_i \geq 1]}{K}$, dihitung jumlah dokumen dengan skor relevansi ≥ 1 pada setiap batas K:

| K | Dokumen relevan (rel≥1) | Total dokumen | Precision@K |
|---|------------------------|---------------|-------------|
| 3 | 1 (posisi 1) | 3 | **0,3333** |
| 5 | 2 (posisi 1 dan 5) | 5 | **0,4000** |

Nilai P@3 sebesar 0,3333 menunjukkan bahwa hanya 1 dari 3 dokumen teratas yang relevan, sejalan dengan NDCG@3 sebesar 0,2754 yang juga mengindikasikan kegagalan retrieval pada kueri ini. Keduanya mengidentifikasi kelemahan yang sama — yaitu dokumen paling relevan berada di posisi kelima — namun dari sudut pandang yang berbeda: NDCG mengukur degradasi akibat posisi yang tidak ideal, sedangkan Precision mengukur rendahnya proporsi dokumen yang berguna di antara hasil yang ditampilkan.

**Contoh Kalkulasi Precision@K — Kueri C04**

Penilaian relevansi C04 menghasilkan vektor [2, 2, 1, 1, 1], di mana seluruh lima dokumen mendapatkan skor relevansi ≥ 1:

| K | Dokumen relevan (rel≥1) | Total dokumen | Precision@K |
|---|------------------------|---------------|-------------|
| 3 | 3 (posisi 1, 2, 3) | 3 | **1,0000** |
| 5 | 5 (posisi 1–5) | 5 | **1,0000** |

Nilai P@3 dan P@5 keduanya sempurna (1,0000), konsisten dengan NDCG@3 = 1,0000 dan NDCG@5 = 1,0000. Kueri C04 menunjukkan kondisi ideal di mana seluruh dokumen yang dikembalikan relevan sekaligus tersusun dalam urutan yang optimal — dua aspek yang diukur oleh NDCG dan Precision secara bersamaan terpenuhi.

---

### 4.2.3 Log Proses Pipeline

Log proses berikut menjabarkan alur pemrosesan setiap skenario uji di dalam pipeline sistem AudioMatch secara rinci, mulai dari *embed query*, deteksi kendaraan, pencarian produk kompatibel, hingga keluaran yang dikembalikan kepada klien. Kolom yang bertanda (−) berarti tahap tersebut tidak dijalankan — baik karena permintaan dihentikan lebih awal akibat kegagalan validasi input, karena permintaan diarahkan ke *endpoint* yang berbeda, maupun karena jalur pipeline yang diambil memang tidak melewati tahap tersebut.

**Tabel 4.11** Log Proses Pipeline Sistem AudioMatch

| No | Input Pesan | Embed Query | Deteksi Kendaraan | Kendaraan | Produk Kompatibel (get_products_for_car) | Jalur Retrieval | Deteksi Merek Produk | Produk (get_products_by_brand) | Hasil Hybrid Search Master Products | Chunk | Anotasi Relevansi [1–5] | Prompt ke Gemini | Output |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 (BBT Sk.1) | Apa fungsi amplifier dalam sistem audio mobil? | Ya | Tidak | − | − | Normal (Hybrid Search) | − | − | − | 5 | − | Prompt konsultasi; konteks: fungsi komponen audio mobil | HTTP 200; jawaban teknis fungsi amplifier; response_length=86 |
| 2 (BBT Sk.2) | Rekomendasikan upgrade audio untuk Hyundai Stargazer | Ya | Ya | Hyundai Stargazer (MPV) | 1 produk kompatibel dikembalikan | Normal + Kompatibilitas Kendaraan | − | − | − | 5 | − | Prompt konsultasi + kendaraan; konteks: upgrade audio MPV + produk kompatibel Hyundai Stargazer | HTTP 200; car_detected=True; recommendations_count=1 |
| 3 (BBT Sk.3) | Lanjut yang nomor 2 | Ya | Tidak | − | − | Normal (Hybrid Search) | − | − | − | 5 | − | Prompt konsultasi + riwayat sesi; konteks: upgrade sistem audio | HTTP 200; session_consistent=True; respons merujuk konteks sesi sebelumnya |
| 4 (BBT Sk.4) | Berikan saya resep nasi goreng | Ya | Tidak | − | − | Fallback (Hybrid Search Produk) | Tidak | − | Hybrid Search pada master_products; tidak ada produk relevan — kueri di luar domain audio mobil | 5 | − | Prompt konsultasi fallback; konteks: katalog produk umum | HTTP 200; di_luar_cakupan=True; sistem menyatakan topik di luar domain konsultasi audio mobil |
| 5 (BBT Sk.5) | Apa itu head unit android? | Ya | Tidak | − | − | Normal (Hybrid Search) | − | − | − | 5 | − | Prompt konsultasi; konteks: fungsi dan jenis head unit | HTTP 200; new_session=True; session_id UUID baru digenerate dan dikembalikan |
| 6 (BBT Sk.6) | [Permintaan identik × 110 dalam 60 detik] | − | − | − | − | − | − | − | − | − | − | − | HTTP 200 (98×) / 429 (12×); rate limiting aktif mulai permintaan ke-99 |
| 7a (BBT Sk.7) | "" (string kosong) | − | − | − | − | − | − | − | − | − | − | − | HTTP 422; validasi Pydantic gagal; field message tidak boleh kosong |
| 7b (BBT Sk.7) | "   " (tiga spasi) | Ya | Tidak | − | − | Normal (Hybrid Search) | − | − | − | 5 | − | Prompt konsultasi; konteks: audio umum | HTTP 200; spasi lolos validasi framework; pipeline tetap dijalankan |
| 7c (BBT Sk.7) | {} (tanpa field message) | − | − | − | − | − | − | − | − | − | − | − | HTTP 422; validasi Pydantic gagal; field message wajib tidak ditemukan |
| 8 (BBT Sk.8) | GET /api/v1/products | − | − | − | − | − (endpoint berbeda) | − | − | − | − | − | − | HTTP 200; 111 produk aktif dikembalikan dengan field id, name, category, price |
| 9a (BBT Sk.9) | Suara di mobil kurang jernih | Ya | Tidak | − | − | Normal (Hybrid Search) | − | − | − | 5 | − | Prompt konsultasi; konteks: solusi suara tidak jernih dan distorsi | HTTP 200; sesi baru dibuat; pesan pertama berhasil diproses |
| 9b (BBT Sk.9) | Lanjut yang tadi, apa solusinya? | Ya | Tidak | − | − | Normal (Hybrid Search) | − | − | − | 5 | − | Prompt konsultasi + riwayat sesi; konteks: solusi dan rekomendasi produk speaker | HTTP 200; session_id konsisten; riwayat pesan pertama ditemukan di Redis |
| 9c (BBT Sk.9) | Berapa biaya untuk solusi tersebut? | Ya | Tidak | − | − | Normal (Hybrid Search) | − | − | − | 5 | − | Prompt konsultasi + riwayat sesi; konteks: estimasi biaya upgrade audio | HTTP 200; session_id konsisten; riwayat 2 pesan sebelumnya ditemukan |
| K01 | Amplifier 4 channel 75 watt cocok untuk berapa speaker? | Ya | Tidak | − | − | Normal (Hybrid Search) | − | − | − | 5 | [0, 0, 1, 0, 0] | Prompt konsultasi; konteks: kompatibilitas amplifier multi-speaker | HTTP 200; NDCG@3=0,5000; NDCG@5=0,5000; dokumen relevan muncul di posisi ke-3 |
| K02 | Berapa watt amplifier yang dibutuhkan untuk subwoofer 12 inch? | Ya | Tidak | − | − | Normal (Hybrid Search) | − | − | − | 5 | [1, 0, 0, 0, 2] | Prompt konsultasi; konteks: kebutuhan daya amplifier untuk subwoofer | HTTP 200; NDCG@3=0,2754; NDCG@5=0,5950; dokumen sangat relevan muncul di posisi ke-5 |
| K03 | Speaker impedansi 4 ohm bisa dipasang di amplifier 8 ohm? | Ya | Tidak | − | − | Normal (Hybrid Search) | − | − | − | 5 | [0, 1, 0, 0, 0] | Prompt konsultasi; konteks: kesesuaian impedansi speaker dan amplifier | HTTP 200; NDCG@3=0,6309; NDCG@5=0,6309; dokumen relevan di posisi ke-2 |
| K04 | Cara setting gain amplifier agar speaker tidak distorsi | Ya | Tidak | − | − | Normal (Hybrid Search) | − | − | − | 5 | [2, 0, 1, 0, 0] | Prompt konsultasi; konteks: kalibrasi gain amplifier | HTTP 200; NDCG@3=0,9639; NDCG@5=0,9639; dokumen sangat relevan di posisi ke-1 |
| K05 | Bisa pasang 6 speaker ke amplifier 4 channel? | Ya | Tidak | − | − | Normal (Hybrid Search) | − | − | − | 5 | [1, 1, 0, 0, 0] | Prompt konsultasi; konteks: konfigurasi pemasangan banyak speaker | HTTP 200; NDCG@3=1,0000; NDCG@5=1,0000; dua dokumen relevan di posisi ke-1 dan ke-2 |
| K06 | Perbedaan RCA output 4V dan 2V pada head unit untuk amplifier | Ya | Tidak | − | − | Normal (Hybrid Search) | − | − | − | 5 | [1, 1, 0, 0, 0] | Prompt konsultasi; konteks: spesifikasi output RCA head unit | HTTP 200; NDCG@3=1,0000; NDCG@5=1,0000; dua dokumen relevan di posisi ke-1 dan ke-2 |
| K07 | Cara memilih crossover yang tepat untuk speaker component | Ya | Tidak | − | − | Normal (Hybrid Search) | − | − | − | 5 | [0, 0, 0, 1, 0] | Prompt konsultasi; konteks: pemilihan dan instalasi crossover speaker | HTTP 200; NDCG@3=0,0000; NDCG@5=0,4307; tidak ada dokumen relevan di tiga posisi teratas |
| K08 | Ukuran kabel power amplifier yang direkomendasikan | Ya | Tidak | − | − | Normal (Hybrid Search) | − | − | − | 5 | [2, 0, 0, 0, 0] | Prompt konsultasi; konteks: spesifikasi kabel daya amplifier | HTTP 200; NDCG@3=1,0000; NDCG@5=1,0000; dokumen sangat relevan di posisi ke-1 |
| P01 | Pioneer DEH-S6250BT head unit | Ya | Tidak | − | − | Fallback (get_products_by_brand) | Ya | Pioneer: 5 produk dikembalikan | − | 5 | [2, 1, 0, 0, 1] | Prompt konsultasi fallback; konteks: produk Pioneer dari get_products_by_brand | HTTP 200; NDCG@3=0,8790; NDCG@5=0,9726; produk Pioneer sangat relevan di posisi ke-1 |
| P02 | Kenwood KDC-BT560U spesifikasi dan harga | Ya | Tidak | − | − | Fallback (get_products_by_brand) | Ya | Kenwood: 5 produk dikembalikan | − | 5 | [1, 0, 0, 0, 0] | Prompt konsultasi fallback; konteks: produk Kenwood dari get_products_by_brand | HTTP 200; NDCG@3=1,0000; NDCG@5=1,0000; produk Kenwood relevan di posisi ke-1 |
| P03 | Nakamichi NA3605 fitur dan keunggulan | Ya | Tidak | − | − | Fallback (get_products_by_brand) | Ya | Nakamichi: 5 produk dikembalikan | − | 5 | [1, 0, 0, 0, 0] | Prompt konsultasi fallback; konteks: produk Nakamichi dari get_products_by_brand | HTTP 200; NDCG@3=1,0000; NDCG@5=1,0000; produk Nakamichi relevan di posisi ke-1 |
| P04 | Hertz Dieci speaker component DCX 165.3 | Ya | Tidak | − | − | Fallback (get_products_by_brand) | Ya | Hertz: 5 produk dikembalikan | − | 5 | [1, 2, 0, 1, 0] | Prompt konsultasi fallback; konteks: produk Hertz dari get_products_by_brand | HTTP 200; NDCG@3=0,7003; NDCG@5=0,8045; produk Hertz sangat relevan di posisi ke-2 |
| P05 | JVC KD-X371BT head unit Bluetooth | Ya | Tidak | − | − | Fallback (get_products_by_brand) | Ya | JVC: 5 produk dikembalikan | − | 5 | [2, 0, 0, 1, 0] | Prompt konsultasi fallback; konteks: produk JVC dari get_products_by_brand | HTTP 200; NDCG@3=0,8262; NDCG@5=0,9448; produk JVC sangat relevan di posisi ke-1 |
| P06 | Subwoofer Rockford Fosgate Punch P3 | Ya | Tidak | − | − | Fallback (get_products_by_brand) | Ya | Rockford Fosgate: 5 produk dikembalikan | − | 5 | [2, 2, 0, 0, 1] | Prompt konsultasi fallback; konteks: produk Rockford Fosgate dari get_products_by_brand | HTTP 200; NDCG@3=0,9073; NDCG@5=0,9790; dua produk Rockford Fosgate sangat relevan di posisi ke-1 dan ke-2 |
| P07 | Tweeter JL Audio C1 075ct | Ya | Tidak | − | − | Fallback (get_products_by_brand) | Ya | JL Audio: 5 produk dikembalikan | − | 5 | [1, 2, 2, 0, 0] | Prompt konsultasi fallback; konteks: produk JL Audio dari get_products_by_brand | HTTP 200; NDCG@3=0,8146; NDCG@5=0,8146; dua produk JL Audio sangat relevan di posisi ke-2 dan ke-3 |
| C01 | Apa fungsi head unit di sistem audio mobil? | Ya | Tidak | − | − | Normal (Hybrid Search) | − | − | − | 5 | [2, 2, 1, 0, 1] | Prompt konsultasi; konteks: fungsi dan jenis head unit | HTTP 200; NDCG@3=1,0000; NDCG@5=0,9925; dua dokumen sangat relevan di posisi ke-1 dan ke-2 |
| C02 | Perbedaan speaker coaxial dan speaker component | Ya | Tidak | − | − | Normal (Hybrid Search) | − | − | − | 5 | [1, 2, 1, 2, 1] | Prompt konsultasi; konteks: perbedaan tipe speaker coaxial dan component | HTTP 200; NDCG@3=0,6291; NDCG@5=0,8167; seluruh 5 dokumen relevan; sangat relevan di posisi ke-2 dan ke-4 |
| C03 | Kenapa bass mobil tidak terasa nendang padahal sudah pasang subwoofer? | Ya | Tidak | − | − | Normal (Hybrid Search) | − | − | − | 5 | [2, 1, 0, 0, 1] | Prompt konsultasi; konteks: permasalahan dan solusi bass subwoofer | HTTP 200; NDCG@3=0,8790; NDCG@5=0,9726; dokumen sangat relevan di posisi ke-1 |
| C04 | Bagaimana cara upgrade audio mobil untuk pemula dengan budget terbatas? | Ya | Tidak | − | − | Normal (Hybrid Search) | − | − | − | 5 | [2, 2, 1, 1, 1] | Prompt konsultasi; konteks: panduan upgrade audio dan manajemen anggaran | HTTP 200; NDCG@3=1,0000; NDCG@5=1,0000; seluruh 5 dokumen relevan; dua sangat relevan di posisi ke-1 dan ke-2 |
| C05 | Apa itu DSP digital signal processor dalam audio mobil? | Ya | Tidak | − | − | Normal (Hybrid Search) | − | − | − | 5 | [1, 0, 1, 0, 0] | Prompt konsultasi; konteks: konsep dan fungsi DSP audio mobil | HTTP 200; NDCG@3=0,9197; NDCG@5=0,9197; dua dokumen relevan di posisi ke-1 dan ke-3 |
| C06 | Perbedaan subwoofer sealed box dan ported box untuk kualitas suara | Ya | Tidak | − | − | Normal (Hybrid Search) | − | − | − | 5 | [2, 1, 0, 2, 1] | Prompt konsultasi; konteks: karakteristik enclosure sealed vs ported | HTTP 200; NDCG@3=0,6733; NDCG@5=0,9118; dokumen sangat relevan di posisi ke-1 dan ke-4 |
| C07 | Cara menghilangkan noise suara dengung di audio mobil | Ya | Tidak | − | − | Normal (Hybrid Search) | − | − | − | 5 | [2, 0, 1, 0, 0] | Prompt konsultasi; konteks: identifikasi dan penanganan noise audio | HTTP 200; NDCG@3=0,9639; NDCG@5=0,9639; dokumen sangat relevan di posisi ke-1 |
| C08 | Mengapa suara speaker mobil pecah dan distorsi saat volume tinggi? | Ya | Tidak | − | − | Normal (Hybrid Search) | − | − | − | 5 | [2, 1, 0, 0, 0] | Prompt konsultasi; konteks: penyebab dan solusi distorsi speaker | HTTP 200; NDCG@3=1,0000; NDCG@5=1,0000; dokumen sangat relevan di posisi ke-1 |
| V01 | Rekomendasi upgrade audio untuk Mitsubishi Xpander | Ya | Ya | Mitsubishi Xpander (MPV) | Produk kompatibel MPV dikembalikan | Normal + Kompatibilitas Kendaraan | − | − | − | 5 | [2, 1, 2, 2, 1] | Prompt konsultasi + kendaraan; konteks: upgrade audio MPV + produk kompatibel Mitsubishi Xpander | HTTP 200; NDCG@3=0,8026; NDCG@5=0,9445; kompatibilitas Xpander diterapkan |
| V02 | Speaker yang cocok untuk Honda Brio city car | Ya | Ya | Honda Brio (City Car) | Produk kompatibel City Car dikembalikan | Normal + Kompatibilitas Kendaraan | − | − | − | 5 | [2, 1, 1, 1, 1] | Prompt konsultasi + kendaraan; konteks: rekomendasi speaker + produk kompatibel Honda Brio | HTTP 200; NDCG@3=1,0000; NDCG@5=1,0000; kompatibilitas Brio diterapkan |
| V03 | Subwoofer terbaik untuk Toyota Avanza MPV | Ya | Ya | Toyota Avanza (MPV) | Produk kompatibel MPV dikembalikan | Normal + Kompatibilitas Kendaraan | − | − | − | 5 | [1, 0, 2, 1, 1] | Prompt konsultasi + kendaraan; konteks: pemilihan subwoofer + produk kompatibel Toyota Avanza | HTTP 200; NDCG@3=0,6052; NDCG@5=0,7273; dokumen sangat relevan muncul di posisi ke-3 |
| V04 | Setup audio lengkap untuk Toyota Fortuner SUV | Ya | Ya | Toyota Fortuner (SUV) | Produk kompatibel SUV dikembalikan | Normal + Kompatibilitas Kendaraan | − | − | − | 5 | [2, 1, 1, 1, 1] | Prompt konsultasi + kendaraan; konteks: setup audio SUV premium + produk kompatibel Toyota Fortuner | HTTP 200; NDCG@3=1,0000; NDCG@5=1,0000; kompatibilitas Fortuner diterapkan |
| V05 | Upgrade head unit android untuk Honda Jazz | Ya | Ya | Honda Jazz | Produk kompatibel Honda Jazz dikembalikan | Normal + Kompatibilitas Kendaraan | − | − | − | 5 | [2, 0, 1, 1, 1] | Prompt konsultasi + kendaraan; konteks: upgrade head unit android + produk kompatibel Honda Jazz | HTTP 200; NDCG@3=0,8473; NDCG@5=0,9465; kompatibilitas Jazz diterapkan |
| V06 | Rekomendasi audio system untuk Suzuki Ertiga | Ya | Ya | Suzuki Ertiga | Produk kompatibel MPV dikembalikan | Normal + Kompatibilitas Kendaraan | − | − | − | 5 | [2, 0, 2, 1, 1] | Prompt konsultasi + kendaraan; konteks: sistem audio MPV + produk kompatibel Suzuki Ertiga | HTTP 200; NDCG@3=0,8344; NDCG@5=0,9131; dua dokumen sangat relevan di posisi ke-1 dan ke-3 |
| V07 | Tweeter dan speaker depan untuk Hyundai Stargazer | Ya | Ya | Hyundai Stargazer (MPV) | Produk kompatibel MPV dikembalikan | Normal + Kompatibilitas Kendaraan | − | − | − | 5 | [2, 0, 1, 2, 0] | Prompt konsultasi + kendaraan; konteks: rekomendasi tweeter dan speaker depan + produk kompatibel Hyundai Stargazer | HTTP 200; NDCG@3=0,6490; NDCG@5=0,8886; dokumen sangat relevan di posisi ke-1 dan ke-4 |

Sumber: Diolah dari hasil pengujian sistem AudioMatch

_Keterangan kolom: **Embed Query** — query dikonversi menjadi vektor 1.024 dimensi menggunakan VoyageAI voyage-3.5-lite; (−) jika permintaan tidak melewati pipeline chat. **Deteksi Kendaraan** — apakah *dictionary keyword matching* menemukan referensi merek atau model kendaraan dalam pesan; (−) jika permintaan tidak melewati pipeline. **Kendaraan** — nama kendaraan yang terdeteksi, atau (−) jika tidak ada. **Produk Kompatibel (get_products_for_car)** — output fungsi `get_products_for_car(car_type, car_size)` yang mengambil produk kompatibel dari `master_cars`; (−) jika tidak ada kendaraan terdeteksi. **Jalur Retrieval** — Normal: Hybrid Search pada `master_customer_problems` lalu `get_recommendations()`; Normal + Kompatibilitas Kendaraan: Hybrid Search disertai konteks kendaraan; Fallback: skor di bawah threshold sehingga pencarian dialihkan ke `master_products`; (−) tidak melalui pipeline chat. **Deteksi Merek Produk** — pada jalur Fallback, sistem memeriksa apakah query mengandung nama merek produk spesifik; (−) jika jalur Normal yang diambil. **Produk (get_products_by_brand)** — produk yang dikembalikan fungsi `get_products_by_brand()` bila merek terdeteksi pada jalur Fallback; (−) jika jalur Normal atau tidak ada merek. **Hasil Hybrid Search Master Products** — pada jalur Fallback tanpa merek terdeteksi, sistem menjalankan Hybrid Search langsung pada tabel `master_products`; kolom ini menampilkan hasil pencarian tersebut; (−) jika jalur Normal yang diambil atau jika merek berhasil terdeteksi sehingga fungsi `get_products_by_brand()` yang digunakan. **Chunk** — jumlah dokumen yang dikembalikan Hybrid Search. **Anotasi Relevansi [1–5]** — skor relevansi 0–2 per posisi dokumen 1–5; hanya berlaku untuk skenario pengujian kualitas retrieval (BBT menggunakan −). **Prompt ke Gemini** — ringkasan prompt yang dikirimkan; (−) jika tidak melalui pipeline chat._

#### 4.2.3.1 Contoh Data Log Eksekusi Pipeline

Untuk memberikan gambaran yang lebih konkret mengenai bentuk data log yang dihasilkan sistem pada setiap eksekusi, berikut disajikan contoh log konsol dan respons JSON aktual dari dua skenario uji representatif.

**Contoh 1 — Skenario BBT Sk.2 (Deteksi Kendaraan + Hybrid Search Normal)**

Log konsol yang dihasilkan server FastAPI saat memproses kueri "Rekomendasikan upgrade audio untuk Hyundai Stargazer":

```
INFO:     Car mention detected: brand='Hyundai', model='Stargazer'
INFO:     Car matched: Hyundai Stargazer (MPV, Medium)
INFO:     127.0.0.1:52341 - "POST /api/v1/chat/ HTTP/1.1" 200 OK
```

Respons JSON yang dikembalikan ke klien:

```json
{
  "session_id": "550e8400-e29b-41d4-a716-446655440000",
  "response": "Untuk Hyundai Stargazer yang merupakan MPV kabin medium, saya rekomendasikan upgrade bertahap mulai dari speaker depan terlebih dahulu...",
  "recommendations": [
    {
      "solution_id": "car_42",
      "solution_title": "Rekomendasi untuk Hyundai Stargazer",
      "solution_description": "Produk audio yang kompatibel untuk Hyundai Stargazer (MPV, kabin Medium).",
      "products": [
        {
          "id": "28",
          "name": "Nakamichi NAM1610 Speaker 6.5 inch",
          "category": "speaker",
          "price": 850000,
          "image": "⚡"
        }
      ]
    }
  ]
}
```

**Contoh 2 — Skenario BBT Sk.4 (Fallback + Di Luar Domain)**

Log konsol saat memproses kueri "Berikan saya resep nasi goreng":

```
INFO:     127.0.0.1:52398 - "POST /api/v1/chat/ HTTP/1.1" 200 OK
```

Respons JSON yang dikembalikan (tidak ada rekomendasi, sistem menandai topik di luar domain):

```json
{
  "session_id": "660f9511-f30c-52e5-b827-557766551111",
  "response": "Maaf, saya hanya dapat membantu konsultasi seputar audio mobil. Untuk pertanyaan tentang resep masakan, saya tidak dapat memberikan informasi yang relevan.",
  "recommendations": []
}
```

Kedua contoh di atas menunjukkan bahwa data log sistem terdiri dari dua lapisan: (1) **log konsol** yang mencatat jalur keputusan internal pipeline (deteksi kendaraan, jalur retrieval yang dipilih) dan status HTTP yang dikembalikan server; serta (2) **respons JSON** yang merupakan output formal sistem kepada klien, berisi `session_id`, teks respons LLM, dan daftar rekomendasi produk terstruktur. Tabel 4.11 merupakan rekapitulasi terstruktur dari data log tersebut yang mengabstraksi setiap eksekusi menjadi satu baris ringkasan untuk memudahkan analisis lintas skenario.

---

Dari total 42 eksekusi yang dicatat pada Tabel 4.11, 13 baris merepresentasikan skenario *Black Box Testing* dan 30 baris merepresentasikan kueri pengujian kualitas retrieval. Pada seluruh eksekusi yang melewati pipeline chat, *embed query* menggunakan VoyageAI voyage-3.5-lite berhasil mengonversi query menjadi vektor 1.024 dimensi sebelum Hybrid Search dijalankan. Jalur Fallback terpicu pada delapan eksekusi: tujuh kueri kategori Merek Produk Spesifik (P01–P07) yang semuanya berhasil mendeteksi nama merek dalam query (Pioneer, Kenwood, Nakamichi, Hertz, JVC, Rockford Fosgate, JL Audio) sehingga fungsi `get_products_by_brand()` dipanggil untuk mengambil produk per merek; serta satu skenario BBT Sk.4 ("resep nasi goreng") di mana tidak ada merek produk yang terdeteksi sehingga sistem menjalankan Hybrid Search langsung pada tabel `master_products` — namun pencarian tersebut tidak menghasilkan produk relevan karena kueri berada di luar domain audio mobil, sehingga sistem merespons dengan `di_luar_cakupan=True`. Pada pengujian kualitas retrieval, seluruh tujuh kueri Berbasis Kendaraan (V01–V07) berhasil mendeteksi kendaraan yang disebutkan, menjalankan fungsi `search_car()` dan `get_products_for_car()` untuk menyiapkan konteks kompatibilitas sebelum Hybrid Search, yang tercermin dari Precision@5 kategori ini sebesar 0,8571 — tertinggi di antara keempat kategori yang diuji. Kueri K07 merupakan satu-satunya kueri yang menghasilkan NDCG@3 sebesar 0,0000, di mana tidak ada satu pun dokumen relevan yang muncul di antara tiga hasil teratas, mengidentifikasi topik *crossover speaker component* sebagai celah cakupan yang perlu diprioritaskan dalam pengembangan basis pengetahuan lanjutan.

---

## 4.3 Analisis Implementasi Sistem

### 4.3.1 Penyesuaian Parameter Selama Development

Proses pengembangan sistem AudioMatch tidak dilakukan dalam satu iterasi. Beberapa parameter operasional mengalami penyesuaian sebelum nilai akhirnya ditetapkan, berdasarkan pengamatan terhadap perilaku sistem pada tahap pengujian awal. Terdapat tiga penyesuaian utama yang dilakukan selama proses tersebut.

1. **Ambang Batas *Cosine Similarity* (*Threshold*)**. Nilai awal ditetapkan pada 0,5, namun kemudian diturunkan menjadi 0,3. Penyesuaian ini dilakukan karena banyak pertanyaan teknis yang valid — terutama pertanyaan dengan kosakata informal — terfilter seluruhnya oleh sistem, sehingga memicu mekanisme *fallback* secara prematur dan menghasilkan respons yang kurang informatif.

2. **Bobot *Hybrid Search***. Beberapa kombinasi bobot diuji selama pengembangan, di antaranya 0,5/0,5 dan 0,7/0,3. Kombinasi 0,6 untuk jalur vektor dan 0,4 untuk jalur BM25 terbukti memberikan keseimbangan terbaik antara pemahaman makna pertanyaan (*intent*) dan ketepatan pengenalan nama produk (*keyword*). Bobot yang terlalu condong ke vektor cenderung melewatkan pertanyaan dengan nama produk spesifik, sedangkan bobot BM25 yang dominan kurang efektif untuk pertanyaan konseptual.

3. **Suhu LLM (*Temperature*)**. Nilai 0,0 yang sepenuhnya deterministik menghasilkan formulasi kalimat yang berulang dan terasa kaku, terutama ketika konteks yang diinjeksikan mengandung dokumen dengan struktur teks yang serupa. Nilai 0,1 dipilih sebagai kompromi: mempertahankan sifat hampir-deterministik yang menjaga konsistensi jawaban, sekaligus memberikan variasi leksikal yang cukup agar respons terasa lebih natural. Nilai di atas 0,2 meningkatkan risiko ketidakkonsistenan pada jawaban teknis.

---

### 4.3.2 Analisis Black Box Testing

Hasil *Black Box Testing* menunjukkan bahwa seluruh 9 skenario pengujian berhasil dengan status PASS. Kondisi ini mengonfirmasi bahwa sistem AudioMatch berfungsi sesuai dengan spesifikasi yang telah ditetapkan dalam Bab 3, mencakup alur percakapan dasar, deteksi kendaraan, manajemen sesi, validasi *input*, dan pembatasan laju permintaan.

Pada skenario deteksi kendaraan (Skenario 2), sistem berhasil mengenali nama kendaraan Hyundai Stargazer yang disebutkan dalam pesan pengguna dan secara otomatis menyiapkan rekomendasi produk yang sesuai. Secara teknis, hal ini tercermin dari nilai `car_detected=True` dan `recommendations_count=1` pada respons sistem. Respons teks dari LLM pada pengujian ini tidak menyebut nama kendaraan secara eksplisit (`llm_menyebut_mobil=False`) karena sistem sedang dalam kondisi *rate-limited* pada saat pengujian, sehingga respons dihasilkan dari jalur alternatif. Fungsionalitas inti deteksi kendaraan tetap bekerja dengan benar sebagaimana ditunjukkan oleh nilai `car_detected=True` dan `recommendations_count=1`.

Pada skenario pembatasan permintaan (Skenario 6), sistem membuktikan bahwa ia dapat melindungi diri dari lonjakan permintaan yang berlebihan secara bersamaan. Dari 110 permintaan yang dikirimkan sekaligus, sistem melayani 98 permintaan pertama secara normal dan menolak 12 permintaan sisanya dengan kode respons HTTP 429 (*Too Many Requests*). Perilaku ini sesuai dengan batasan 100 *request* per 60 detik yang telah ditetapkan, dengan sedikit variasi yang wajar akibat sifat pengiriman permintaan yang berlangsung secara bersamaan.

Pada skenario validasi *input* (Skenario 7), sistem terbukti mampu menolak *input* yang tidak valid seperti pesan kosong atau permintaan tanpa kolom pesan, keduanya menghasilkan kode respons HTTP 422 sesuai ekspektasi. Satu-satunya kondisi yang meloloskan validasi awal adalah pesan yang hanya berisi spasi ("   "), karena secara struktural dianggap sebagai teks yang valid oleh framework. Kondisi ini mencerminkan batasan bawaan framework yang tidak memeriksa isi pesan secara semantik, dan dapat ditangani dengan menambahkan pemeriksaan tambahan apabila diperlukan di masa mendatang.

---

### 4.3.3 Analisis Kualitas Retrieval

Secara umum, hasil pengujian menunjukkan bahwa sistem sangat baik dalam mengurutkan — artinya dokumen yang paling relevan hampir selalu muncul di urutan teratas — namun masih perlu ditingkatkan dalam hal cakupan, yaitu berapa banyak dokumen relevan yang berhasil ditemukan dari keseluruhan hasil yang ditampilkan. NDCG@3 sebesar 0,8100 dan NDCG@5 sebesar 0,8878 keduanya melampaui target yang ditetapkan dalam Tabel 3.11, yang menunjukkan bahwa sistem *Hybrid Search* berhasil menempatkan dokumen paling relevan di posisi teratas dalam hasil retrieval. Nilai NDCG yang tinggi ini mengindikasikan bahwa penggabungan jalur *vector search* dan BM25 melalui RRF efektif dalam menangani berbagai jenis pertanyaan, mulai dari pertanyaan konseptual hingga pertanyaan yang menyebutkan nama produk secara eksak.

Penggunaan Precision@K di samping NDCG@K didasarkan pada perbedaan mendasar antara kedua metrik yang menjadikannya saling melengkapi. Apabila nilai NDCG rendah, hal tersebut mengindikasikan bahwa dokumen relevan memang tersedia dalam basis pengetahuan, namun sistem gagal menempatkannya di urutan teratas — konteks terbaik tidak diterima LLM di posisi pertama sehingga kualitas jawaban terdegradasi. Sebaliknya, apabila nilai Precision rendah sementara NDCG tetap tinggi, sistem berhasil menempatkan dokumen relevan di atas namun turut mengikutsertakan banyak dokumen kurang relevan di posisi bawah, sehingga LLM menerima *noise* dalam konteksnya dan risiko jawaban menyimpang tetap ada meskipun dokumen relevan telah hadir. Dalam sistem AudioMatch, NDCG@5 sebesar 0,8878 menunjukkan bahwa sistem pandai menempatkan dokumen relevan di posisi teratas, namun Precision@5 sebesar 0,5667 mengindikasikan bahwa rata-rata 2–3 dari 5 dokumen yang masuk ke konteks LLM kurang relevan — terutama pada kategori Kompatibilitas Komponen dengan Precision@5 = 0,3000. Dengan menggunakan kedua metrik secara bersamaan, kelemahan pada dimensi peringkat dan dimensi cakupan dapat diidentifikasi secara terpisah dan spesifik.

Precision@3 sebesar 0,6445 dan Precision@5 sebesar 0,5667 belum mencapai target yang ditetapkan. Artinya, dari setiap tiga dokumen yang ditampilkan sistem, rata-rata sekitar satu dokumen di antaranya kurang relevan dengan pertanyaan yang diajukan. Rendahnya Precision ini terutama disebabkan oleh kategori Kompatibilitas Komponen, yang menghasilkan Precision@3 terendah yaitu 0,4167 dan Precision@5 sebesar 0,3000. Pertanyaan-pertanyaan dalam kategori ini bersifat sangat teknis dan spesifik, misalnya mengenai impedansi ohm, spesifikasi kabel daya, dan konfigurasi pemasangan banyak speaker. Basis pengetahuan yang ada dirancang untuk menjawab pertanyaan umum pelanggan, sehingga pertanyaan teknis yang sangat spesifik ini tidak selalu menemukan entri yang cukup relevan di posisi teratas.

Secara per kategori, pertanyaan Berbasis Kendaraan mencapai Precision@5 tertinggi yaitu 0,8571, yang menunjukkan bahwa kemampuan sistem mengenali nama kendaraan dan menyaring produk berdasarkan kompatibilitas memberikan kontribusi nyata terhadap relevansi hasil yang ditampilkan. Kategori Konseptual dan Edukatif juga menunjukkan performa yang baik dengan NDCG@5 sebesar 0,9472, mengindikasikan bahwa pertanyaan konseptual tentang audio mobil terlayani dengan efektif oleh kemampuan pencarian berbasis makna kata dari jalur *vector search*.

Kueri dengan performa terendah adalah K07 (cara memilih *crossover* yang tepat untuk *speaker component*) dengan NDCG@3 sebesar 0,0000, di mana tidak ada entri yang relevan di antara tiga hasil teratas dan informasi yang relevan baru muncul di posisi keempat. Topik *crossover* merupakan aspek teknis yang cukup spesifik dan belum terwakili secara memadai dalam basis pengetahuan yang ada. Sebaliknya, kueri dengan performa terbaik yaitu K05, K06, K08, C01, C04, C08, V02, dan V04, yang semuanya mencapai NDCG@3 sebesar 1,0000, menunjukkan bahwa sistem menghasilkan urutan yang sempurna untuk topik-topik dengan cakupan basis pengetahuan yang lengkap.

Guna memperjelas perbandingan antara hasil yang dicapai dan target yang ditetapkan, Tabel 4.10 berikut merangkum seluruh metrik evaluasi retrieval dalam format yang siap divisualisasikan sebagai diagram batang.

**Tabel 4.10** Perbandingan Hasil vs Target Pengujian Kualitas Retrieval

| Metrik | Hasil Sistem | Target | Selisih | Status |
|--------|-------------|--------|---------|--------|
| NDCG@3 | 0,8100 | 0,7500 | +0,0600 | ✅ Tercapai |
| NDCG@5 | 0,8878 | 0,7000 | +0,1878 | ✅ Tercapai |
| Precision@3 | 0,6445 | 0,7000 | −0,0555 | ❌ Belum Tercapai |
| Precision@5 | 0,5667 | 0,6500 | −0,0833 | ❌ Belum Tercapai |

Sumber: Diolah oleh penulis (2026)

Perbedaan karakteristik antara NDCG dan Precision memiliki implikasi yang berbeda terhadap pengalaman pengguna sistem. Apabila nilai NDCG rendah, dokumen yang paling relevan tidak muncul di urutan teratas hasil retrieval, sehingga pengguna harus membaca lebih banyak respons sebelum menemukan informasi yang benar-benar menjawab pertanyaannya — kondisi ini secara langsung menurunkan kenyamanan dan efisiensi konsultasi. Sebaliknya, apabila nilai Precision rendah, terlalu banyak dokumen yang kurang relevan (*noise*) diikutsertakan sebagai konteks dalam *prompt* yang dikirimkan ke LLM. Hal ini meningkatkan risiko halusinasi karena model menerima sinyal informasi yang saling bertentangan, yang pada akhirnya dapat menghasilkan jawaban yang kurang akurat meskipun dokumen relevan telah berhasil ditemukan.

Dalam kasus sistem AudioMatch, tingginya nilai NDCG yang melampaui target menunjukkan bahwa dokumen relevan berhasil ditempatkan di urutan teratas sehingga kualitas konteks yang diinjeksikan ke Gemini 2.5 Flash Lite terjaga dengan baik. Rendahnya Precision yang terutama disebabkan oleh kategori Kompatibilitas Komponen (Precision@3 = 0,4167) mengindikasikan bahwa sebagian konteks yang diinjeksikan ke LLM pada kategori ini masih mengandung dokumen yang kurang relevan, yang berpotensi memengaruhi presisi jawaban teknis. Peningkatan cakupan basis pengetahuan pada topik teknis seperti impedansi, konfigurasi *crossover*, dan spesifikasi kabel diidentifikasi sebagai langkah utama yang diperlukan untuk meningkatkan nilai Precision pada kategori tersebut.

Perlu dicatat pula bahwa kueri yang memicu mekanisme *fallback* — yaitu kueri yang mengalihkan pencarian ke jalur *product-only* melalui fungsi `get_products_by_brand()` atau *Hybrid Search* langsung pada tabel `master_products` — tidak diidentifikasi secara terpisah dalam evaluasi ini, sehingga pengaruh mekanisme *fallback* terhadap metrik NDCG dan Precision yang dilaporkan tidak dapat diisolasi. Hal ini merupakan keterbatasan metodologi evaluasi yang perlu dipertimbangkan dalam interpretasi hasil.

---

### 4.3.4 Keterbatasan Implementasi

Sistem AudioMatch memiliki beberapa keterbatasan yang perlu dicatat sebagai bahan evaluasi lanjutan. Keterbatasan pertama berkaitan dengan cakupan basis pengetahuan. Kategori Kompatibilitas Komponen mencatat Precision@5 terendah yaitu 0,3000, yang disebabkan minimnya artikel panduan teknis mendalam mengenai impedansi speaker, konfigurasi kabel daya, dan instalasi *crossover* dalam basis pengetahuan yang tersedia. Basis pengetahuan saat ini dirancang untuk menjawab pertanyaan umum pelanggan, sehingga pertanyaan yang sangat spesifik secara teknis tidak selalu terlayani dengan baik.

Keterbatasan kedua berkaitan dengan mekanisme pencocokan kendaraan. Deteksi kendaraan dilakukan melalui pencocokan kata kunci berbasis kamus yang mencakup 230+ model, namun pendekatan ini rentan terhadap variasi penulisan yang tidak terdaftar, misalnya singkatan atau ejaan tidak baku yang digunakan pengguna. Kasus *false negative* — yaitu kendaraan yang sebenarnya terdaftar tetapi tidak terdeteksi — dapat mengakibatkan sistem tidak memfilter produk berdasarkan kompatibilitas kendaraan.

Keterbatasan ketiga berkaitan dengan tidak adanya tahap *reranking* di tingkat aplikasi. Sistem saat ini mengandalkan sepenuhnya pada skor *Hybrid Search* untuk menentukan urutan dokumen sebelum diinjeksikan ke LLM. Penambahan tahap penyaringan ulang menggunakan model bahasa berpotensi meningkatkan Precision tanpa harus memperluas basis pengetahuan terlebih dahulu.

Keterbatasan keempat berkaitan dengan proses evaluasi. Penilaian relevansi pada pengujian kualitas retrieval dilakukan oleh satu anotator, yaitu pemilik Rendy Audio selaku *domain expert*, tanpa melibatkan anotator kedua untuk menghitung *inter-annotator agreement*. Selain itu, penelitian ini tidak melibatkan pengguna nyata secara langsung, sehingga kesenjangan antara kueri pengujian dan pertanyaan aktual pelanggan belum dapat diukur. Pengukuran latensi respons *end-to-end* — mencakup waktu proses retrieval hibrida, pemanggilan API *embedding*, dan generasi respons LLM — juga tidak dilakukan dalam penelitian ini.

---

# BAB V
KESIMPULAN DAN SARAN

## 5.1 Kesimpulan

Sistem AudioMatch berhasil dirancang dan dikembangkan sebagai *chatbot* konsultasi audio mobil yang mampu menjawab pertanyaan pelanggan secara akurat dengan memanfaatkan basis pengetahuan dari Rendy Audio. Sistem ini menggunakan pendekatan *Hybrid Search* — gabungan pencarian berbasis makna kata dan kata kunci — untuk menemukan informasi yang relevan, serta dilengkapi kemampuan mengenali nama kendaraan pengguna agar rekomendasi produk yang diberikan sesuai dengan spesifikasi kendaraan tersebut. Dari sisi teknis, sistem diimplementasikan menggunakan FastAPI sebagai framework *backend*, PostgreSQL dengan pgvector sebagai basis data sekaligus penyimpanan vektor, VoyageAI voyage-3.5-lite sebagai model *embedding*, Gemini 2.5 Flash Lite sebagai LLM, dan Upstash Redis sebagai *layer caching* percakapan, dengan basis data kendaraan yang mencakup lebih dari 230 model populer di Indonesia.

Evaluasi fungsionalitas melalui *Black Box Testing* menghasilkan 9 dari 9 skenario pengujian dengan status PASS. Fungsionalitas yang terverifikasi meliputi alur percakapan dasar, deteksi kendaraan, pemeliharaan konteks sesi lintas pesan, validasi *input*, pengambilan data katalog produk, dan mekanisme *rate limiting*. Hasil ini mengonfirmasi bahwa seluruh komponen sistem berfungsi sesuai dengan spesifikasi yang telah ditetapkan dalam Bab 3.

Evaluasi kualitas retrieval *Hybrid Search* menghasilkan NDCG@3 sebesar 0,8100 dan NDCG@5 sebesar 0,8878, keduanya melampaui target yang ditetapkan dalam Tabel 3.11 dan menunjukkan bahwa sistem berhasil menempatkan dokumen relevan di posisi teratas hasil pencarian. Precision@3 sebesar 0,6445 dan Precision@5 sebesar 0,5667 belum mencapai target, terutama karena cakupan basis pengetahuan untuk pertanyaan teknis yang sangat spesifik di kategori Kompatibilitas Komponen masih perlu diperluas.

Meskipun pendekatan RAG secara signifikan menekan halusinasi dibandingkan model generatif murni, sistem AudioMatch tidak sepenuhnya bebas dari risiko halusinasi residual. Apabila dokumen yang diambil oleh komponen retrieval tidak cukup lengkap atau mengandung informasi yang ambigu, LLM tetap berpotensi menghasilkan jawaban yang menyimpang dari fakta. Hal ini terutama relevan untuk pertanyaan teknis yang sangat spesifik di kategori Kompatibilitas Komponen — kategori yang juga mencatat performa retrieval terendah dalam pengujian ini, sehingga risiko dokumen yang kurang informatif masuk ke konteks LLM pada kategori tersebut lebih tinggi dibandingkan kategori lainnya.

Berdasarkan kedua hasil pengujian tersebut, sistem AudioMatch mampu menjawab kedua rumusan masalah penelitian ini. Pertama, sistem berhasil dirancang dan diimplementasikan dengan seluruh komponen teknis berfungsi sesuai rancangan. Kedua, evaluasi efektivitas menunjukkan bahwa kualitas peringkat retrieval *Hybrid Search* berada di atas target, meskipun cakupan relevansi pada pertanyaan teknis yang sangat spesifik masih memiliki ruang untuk dikembangkan lebih lanjut.

---

## 5.2 Saran

Keterbatasan utama sistem AudioMatch terletak pada cakupan basis pengetahuan yang belum menjangkau seluruh topik teknis audio mobil secara merata. Pengembangan lanjutan dapat difokuskan pada penambahan entri pertanyaan yang berkaitan dengan topik teknis mendalam, yaitu konfigurasi *crossover*, impedansi pemasangan *multi-speaker*, dan spesifikasi kabel daya, untuk meningkatkan Precision pada kategori Kompatibilitas Komponen yang saat ini menjadi kategori dengan performa retrieval terendah.

Penambahan mekanisme umpan balik pengguna secara langsung di dalam antarmuka *chatbot* dapat digunakan untuk mengidentifikasi pertanyaan yang menghasilkan respons kurang relevan. Data umpan balik tersebut dapat dimanfaatkan untuk memperbarui dan memperluas basis pengetahuan secara berkala, sehingga kualitas sistem dapat terus meningkat seiring bertambahnya penggunaan.

Penelitian ini membatasi evaluasi pada pengujian teknis berbasis skrip dan evaluasi retrieval tanpa melibatkan pengguna nyata secara langsung. Penelitian lanjutan dapat melibatkan pelanggan dan staf Rendy Audio untuk mengevaluasi relevansi respons *chatbot* secara langsung, mengukur tingkat kepuasan pengguna, dan mengidentifikasi kesenjangan antara pertanyaan yang nyata diajukan pelanggan dengan kueri yang digunakan dalam evaluasi.

Dari sisi teknis, sistem dapat ditingkatkan dengan menambahkan tahap penyaringan ulang hasil pencarian menggunakan model bahasa sebelum jawaban akhir dihasilkan, sehingga hanya dokumen yang benar-benar relevan yang digunakan sebagai bahan jawaban. Pendekatan ini berpotensi meningkatkan Precision tanpa harus langsung memperluas basis pengetahuan. Selain itu, pengujian dengan variasi konfigurasi bobot *Hybrid Search* dan parameter penggabungan hasil dapat dilakukan untuk menemukan konfigurasi yang mengoptimalkan keseimbangan antara kualitas urutan dan cakupan relevansi secara bersamaan.

Pengukuran latensi respons *end-to-end* sistem, termasuk waktu proses retrieval hibrida, pemanggilan API *embedding*, dan generasi respons LLM, tidak dilakukan dalam penelitian ini dan direkomendasikan sebagai arah evaluasi lanjutan untuk mengukur kelayakan sistem dalam kondisi penggunaan nyata.
