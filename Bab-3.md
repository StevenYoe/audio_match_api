# BAB III
METODE PERANCANGAN

## 3.1 Metodologi Pengembangan

Penelitian ini menggunakan model Waterfall dalam kerangka Software Development Life Cycle (SDLC) sebagai metodologi pengembangan sistem AudioMatch. Model Waterfall dipilih karena lingkup dan komponen sistem AudioMatch dapat didefinisikan secara menyeluruh di awal pengembangan dimana meliputi arsitektur pipeline RAG, mekanisme Hybrid Search, sistem deteksi kendaraan, dan struktur basis data, sehingga kebutuhan untuk mengubah desain di tengah proses pengembangan dapat diminimalkan. Pargaonkar (2023) menegaskan bahwa model Waterfall sangat efektif untuk proyek dengan kebutuhan yang stabil dan terdefinisi dengan baik, di mana setiap fase dapat diselesaikan secara komprehensif sebelum melanjutkan ke fase berikutnya. Karakteristik ini relevan untuk sistem AudioMatch, di mana setiap fase pengembangan menghasilkan output yang konkret dan dapat diverifikasi sebelum menjadi input bagi fase selanjutnya.

### 3.1.1 Siklus Pengembangan SDLC Waterfall

Pengembangan AudioMatch dilaksanakan melalui enam fase sekuensial sesuai model Waterfall dalam SDLC (Yas et al., 2023). Setiap fase menghasilkan deliverable yang didokumentasikan sebelum dilanjutkan ke fase berikutnya.

**Tabel 3.1** Rencana Sprint Pengembangan AudioMatch

| Fase | Durasi | Aktivitas | Output |
|--------|--------|--------------------|--------|
| Analisis Kebutuhan | 2 minggu | Analisis proses bisnis Rendy Audio, identifikasi kebutuhan fungsional dan non-fungsional, penetapan ruang lingkup sistem | Dokumen spesifikasi kebutuhan sistem AudioMatch |
| Desain Sistem | 2 minggu | Perancangan arsitektur sistem, pipeline RAG, skema basis data, dan antarmuka API | Dokumen desain sistem, ERD, dan spesifikasi API |
| Implementasi | 2 minggu | Pengembangan backend FastAPI, integrasi VoyageAI + Gemini, implementasi Hybrid Search (BM25 + vector search), deteksi kendaraan, dan session caching Redis | Sistem AudioMatch berfungsi secara keseluruhan |
| Pengujian | 2 minggu | Black Box Testing seluruh endpoint, pengujian kualitas retrieval (NDCG@K), dan perbaikan berdasarkan hasil pengujian | Laporan hasil pengujian dan sistem yang telah divalidasi |
| Penerapan | 1 minggu | Deployment ke Vercel, containerisasi Docker untuk lingkungan lokal | Sistem AudioMatch ter-deploy dan siap digunakan |
| Pemeliharaan | Berkelanjutan | Pemantauan performa sistem, pembaruan basis pengetahuan jika diperlukan | Sistem yang terpelihara dan dokumentasi akhir |

Sumber: Diolah oleh penulis (2026)

Durasi setiap fase ditetapkan oleh peneliti berdasarkan proporsi waktu yang direkomendasikan oleh Bassil (2012) dan Pargaonkar (2023), disesuaikan dengan kompleksitas dan cakupan sistem AudioMatch.

![Gambar 3.1 Tahapan SDLC Waterfall AudioMatch](../flowchart\Gambar%203.1%20Tahapan%20SDLC%20Waterfall%20AudioMatch.png)

**Gambar 3.1** Tahapan SDLC Waterfall AudioMatch
Sumber: Diolah oleh penulis (2026)

---

## 3.2 Perancangan Sistem

### 3.2.1 Proses Bisnis Objek Penelitian

**Proses Bisnis As-Is (Sebelum Sistem)**

Proses konsultasi audio mobil sebelum adanya sistem AudioMatch berlangsung secara manual antara pelanggan dan staf toko. Pelanggan yang ingin mendapatkan rekomendasi produk atau solusi atas masalah audio harus berkomunikasi langsung dengan staf, baik melalui kunjungan tatap muka maupun melalui pesan teks. Kualitas respons yang diberikan bergantung sepenuhnya pada pengetahuan dan ketersediaan staf yang bertugas saat itu, sehingga konsistensi informasi tidak selalu terjamin antar sesi konsultasi yang berbeda. Berdasarkan wawancara dengan pemilik Rendy Audio (Februari 2026), sekitar 70% pertanyaan yang masuk bersifat berulang, namun seluruhnya tetap harus dijawab secara manual satu per satu.

![Gambar 3.2 Proses Bisnis Konsultasi dengan AudioMatch (As-Is)](../flowchart\Gambar%203.2%20Proses%20Bisnis%20Konsultasi%20dengan%20AudioMatch%20(As-Is).png)

**Gambar 3.2** Proses Bisnis Konsultasi Audio Mobil Manual (As-Is)
Sumber: Diolah oleh penulis (2026)

**Proses Bisnis To-Be (Setelah Sistem)**

Dengan hadirnya sistem AudioMatch, pelanggan dapat memperoleh respons konsultasi secara langsung tanpa bergantung pada ketersediaan staf. Sistem mendeteksi apakah terdapat merek atau model kendaraan dalam pesan pengguna, mengambil informasi kompatibilitas produk dari basis data, lalu menjalankan Hybrid Search pada basis pengetahuan melalui kombinasi vector search dan BM25. Berdasarkan hasil retrieval, LLM menyusun respons yang akurat beserta rekomendasi produk yang relevan. Staf toko tetap terlibat untuk menangani pertanyaan di luar cakupan sistem atau kasus yang membutuhkan penilaian langsung.

![Gambar 3.3 Proses Bisnis Konsultasi dengan AudioMatch (To-Be)](../../flowchart\Gambar%203.3%20Proses%20Bisnis%20Konsultasi%20dengan%20AudioMatch%20(To-Be))

**Gambar 3.3** Proses Bisnis Konsultasi dengan AudioMatch (To-Be)
Sumber: Diolah oleh penulis (2026)

---

### 3.2.2 Pemilihan Teknologi

Setiap komponen teknologi dalam sistem AudioMatch dipilih berdasarkan pertimbangan teknis yang relevan dengan kebutuhan sistem RAG berbasis Hybrid Search dan deteksi kendaraan. Perbandingan dan justifikasi untuk setiap komponen utama dipaparkan dalam tabel-tabel berikut.

**Tabel 3.2** Framework Backend

| Komponen | FastAPI | Flask | Django |
|----------|---------|-------|--------|
| Performa asinkronus | Sangat baik (native async/await) | Terbatas | Terbatas |
| Validasi data otomatis | Ada (Pydantic) | Tidak ada bawaan | Parsial |
| Dokumentasi API otomatis | Ada (Swagger/Redoc) | Tidak ada bawaan | Tidak ada bawaan |
| Overhead | Ringan | Sangat ringan | Berat |
| **Dipilih** | **Ya** | Tidak | Tidak |

Sumber: Diolah oleh penulis (2026)

FastAPI dipilih karena mendukung operasi asinkronus secara native, yang esensial untuk menjalankan panggilan ke VoyageAI API, Gemini API, dan PostgreSQL secara bersamaan tanpa memblokir thread utama. Mykola (2024) menunjukkan bahwa FastAPI yang berbasis konstruksi asinkronus Python mampu menangani banyak koneksi secara bersamaan tanpa memblokir thread utama, sehingga penggunaan sumber daya CPU dan memori jauh lebih efisien dibandingkan server berbasis thread seperti Flask atau Django. Chen (2023) memperkuat temuan ini dengan menyatakan bahwa FastAPI menyediakan efisiensi, kemampuan asinkronus, dan arsitektur RESTful sebagai platform yang ideal untuk membangun web service yang melayani permintaan bersamaan dalam jumlah besar.

**Tabel 3.3** Database dan Penyimpanan Vektor

| Komponen | PostgreSQL + pgvector | MariaDB | MongoDB | Pinecone | ChromaDB |
|----------|-----------------------|---------|---------|----------|----------|
| Penyimpanan relasional | Ya | Ya | Tidak | Tidak | Tidak |
| Pencarian vektor bawaan | Ya (pgvector + ivfflat) | Tidak | Tidak | Ya | Ya |
| Full-text search BM25 | Ya (tsvector + GIN) | Ya (terbatas) | Ya (Atlas Search) | Tidak | Tidak |
| Transaksi ACID | Ya | Ya | Parsial | Tidak | Tidak |
| Biaya infrastruktur | Rendah (self-host) | Rendah (self-host) | Menengah | Tinggi (managed) | Rendah |
| Integrasi data relasional | Sangat baik | Baik | Tidak ada | Terbatas | Tidak ada |
| **Dipilih** | **Ya** | Tidak | Tidak | Tidak | Tidak |

Sumber: Diolah oleh penulis (2026)

PostgreSQL dengan ekstensi pgvector dipilih karena merupakan satu-satunya pilihan yang mampu menangani tiga kebutuhan sistem secara bersamaan dalam satu sistem terintegrasi, yaitu penyimpanan data relasional (produk, solusi, sesi percakapan), pencarian vektor untuk dense retrieval, dan full-text search BM25 menggunakan ‘tsvector’ dengan GIN index untuk sparse retrieval. Kemampuan ganda ini menghilangkan kebutuhan akan sistem database terpisah yang umumnya digunakan pada implementasi RAG konvensional. Lathkar (2023) menjelaskan bahwa integrasi PostgreSQL dengan ORM seperti SQLAlchemy dalam FastAPI memungkinkan pengelolaan transaksi data yang konsisten dan dapat diandalkan.

**Tabel 3.4** Model Embedding

| Komponen | VoyageAI voyage-3.5-lite | OpenAI text-embedding-3-small | Sentence-Transformers |
|----------|--------------------------|-------------------------------|------------------------|
| Dimensi vektor | 1024 | 1536 | 384–768 (variatif) |
| Kualitas retrieval | Tinggi | Sangat tinggi | Menengah |
| Biaya per token | Rendah | Menengah | Gratis (self-host) |
| Latensi API | Rendah | Menengah | Tinggi (self-host) |
| Kompatibilitas serverless | Ya | Ya | Terbatas |
| **Dipilih** | **Ya** | Tidak | Tidak |

Sumber: Diolah oleh penulis (2026)

VoyageAI voyage-3.5-lite dipilih karena menghasilkan embedding berkualitas tinggi pada dimensi 1024 dengan biaya operasional yang lebih rendah dibandingkan OpenAI, sesuai dengan keterbatasan sumber daya penelitian ini. Oro et al. (2025) dalam evaluasi komprehensif terhadap 12 model embedding menyimpulkan bahwa ukuran model tidak secara konsisten memprediksi performa retrieval dimana temuan ini mendukung pemilihan voyage-3.5-lite yang berukuran lebih kecil namun tetap menghasilkan kualitas embedding yang kompetitif untuk tugas information retrieval dan question answering pada domain spesifik.

**Tabel 3.5** Large Language Model (LLM)

| Komponen | Gemini 2.5 Flash Lite | GPT-4o Mini | Claude Haiku |
|----------|-----------------------|-------------|--------------|
| Konteks window | Sangat besar (1M token) | Besar (128K token) | Besar (200K token) |
| Kecepatan generasi | Sangat cepat | Cepat | Cepat |
| Biaya per token | Sangat rendah | Rendah | Menengah |
| Kemampuan bahasa Indonesia | Baik | Baik | Baik |
| Instruction following | Baik | Sangat baik | Sangat baik |
| **Dipilih** | **Ya** | Tidak | Tidak |

Sumber: Diolah oleh penulis (2026)

Google Gemini gemini-2.5-flash-lite dipilih karena menawarkan kecepatan generasi tinggi dengan biaya operasional sangat rendah, menjadikannya pilihan yang tepat untuk sistem chatbot yang mengutamakan latensi respons rendah. Model ini memiliki kemampuan instruction following yang memadai untuk mengikuti instruksi adaptasi gaya bahasa dalam system prompt secara konsisten. Suhu generasi ditetapkan pada 0,1 untuk menghasilkan respons yang deterministik, sedangkan batas token output ditetapkan pada 2.000 token per respons. Chang et al. (2024) menekankan bahwa evaluasi LLM yang menyeluruh harus mencakup dimensi kemampuan instruksi, kualitas generasi, dan efisiensi operasional secara bersamaan dimana ketiga dimensi tersebut menjadi dasar pertimbangan pemilihan model dalam sistem AudioMatch.

**Tabel 3.6** Layer Caching

| Komponen | Upstash Redis | Redis Self-host | In-memory Cache |
|----------|---------------|-----------------|-----------------|
| Persistensi data | Ya | Ya | Tidak |
| Kompatibilitas serverless | Sangat baik (REST API) | Tidak (TCP) | N/A |
| Biaya | Gratis (free tier) | Infrastruktur sendiri | Tidak ada |
| Manajemen koneksi | REST-based, tanpa pool | TCP, perlu pool | N/A |
| **Dipilih** | **Ya** | Tidak | Tidak |

Sumber: Diolah oleh penulis (2026)

Upstash Redis dipilih karena antarmuka REST-nya kompatibel dengan lingkungan serverless Vercel, di mana koneksi TCP persisten tidak didukung secara optimal antar invokasi fungsi. Wen et al. (2023) mencatat bahwa paradigma serverless mengharuskan aplikasi dirancang tanpa mengandalkan state yang tersimpan dalam memori proses dimana caching sesi percakapan dengan Redis memastikan kontinuitas konteks antar turn tanpa membebani database utama.

**Tabel 3.7** Platform Deployment

| Komponen | Vercel | AWS Lambda | Railway |
|----------|--------|------------|---------|
| Integrasi Python serverless | Baik | Sangat baik | Baik |
| Kemudahan deployment | Sangat mudah (git push) | Kompleks | Mudah |
| Cold start | Ada | Ada | Minimal |
| Biaya (free tier) | Ada | Ada | Ada |
| **Dipilih** | **Ya** | Tidak | Tidak |

Sumber: Diolah oleh penulis (2026)

Vercel dipilih karena menyediakan alur deployment yang sederhana berbasis git push dengan dukungan Python runtime. Wen et al. (2023) mengungkapkan bahwa paradigma serverless memungkinkan pengembang untuk berfokus pada logika aplikasi tanpa harus mengelola infrastruktur yang kompleks. Containerisasi menggunakan Docker juga disiapkan untuk lingkungan pengembangan lokal guna memastikan konsistensi dependensi antara lingkungan pengembangan dan produksi.

---

### 3.2.3 Arsitektur Sistem

Arsitektur sistem AudioMatch dirancang dalam empat lapisan yang terpisah berdasarkan tanggung jawab masing-masing komponen. Lapisan Client menangani antarmuka pengguna, lapisan API menerima dan memvalidasi permintaan menggunakan FastAPI, lapisan Services mengorkestrasi logika bisnis termasuk pipeline RAG, embedding, LLM, dan caching, serta lapisan Data menyimpan basis pengetahuan, riwayat percakapan, dan cache sesi di PostgreSQL serta Redis.

![Gambar 3.4 Arsitektur Sistem AudioMatch](../flowchart\Gambar%203.4%20Arsitektur%20Sistem%20AudioMatch.png)

**Gambar 3.4** Arsitektur Sistem AudioMatch
Sumber: Diolah oleh penulis (2026)

---

### 3.2.4 Basis Pengetahuan

Basis pengetahuan AudioMatch merupakan fondasi dari seluruh pipeline RAG. Bagian ini menjelaskan sumber data yang digunakan, proses konversinya menjadi format yang siap digunakan, serta struktur data hasil konversi yang disimpan di dalam sistem.

#### 3.2.4.1 Sumber Data dan Dokumen

Basis pengetahuan AudioMatch dikurasi secara manual dari tiga sumber utama. Pertama, dokumen spesifikasi produk dan panduan instalasi komponen audio mobil yang tersedia secara publik, meliputi lembar spesifikasi amplifier, speaker, subwoofer, head unit, dan panduan pengkabelan dari berbagai merek yang dijual di Rendy Audio. Kedua, materi konsultasi yang diperoleh melalui wawancara dengan pemilik Rendy Audio pada Februari 2026, mencakup pertanyaan-pertanyaan umum pelanggan beserta jawaban yang diverifikasi secara teknis. Ketiga, data kendaraan berupa informasi spesifikasi audio bawaan dari berbagai model mobil populer di Indonesia, meliputi tipe dashboard, ukuran speaker bawaan, kapasitas kabin, dan catatan instalasi khusus.

Setiap dokumen diverifikasi kesesuaian teknisnya oleh pemilik Rendy Audio sebelum diproses lebih lanjut. Proses kurasi ini penting untuk memastikan bahwa basis pengetahuan hanya berisi informasi yang akurat dan relevan dengan domain audio mobil, sehingga meminimalkan risiko halusinasi pada respons chatbot.

#### 3.2.4.2 Proses Konversi dan Pembuatan Indeks

Dokumen sumber diproses melalui dua tahap sebelum dapat digunakan dalam pipeline RAG. Tahap pertama adalah chunking, yaitu pemecahan dokumen sumber menjadi unit teks yang disebut knowledge chunk. Setiap chunk dirancang cukup granular untuk mendukung retrieval semantik yang presisi, namun cukup komprehensif agar konteks yang diambil tetap bermakna bagi generator. Setiap chunk dianotasi dengan metadata berupa intent dan kategori topiknya.

Tahap kedua adalah indexing, yang terdiri dari dua proses paralel. Proses pertama adalah pembuatan embedding vektor untuk setiap chunk menggunakan VoyageAI voyage-3.5-lite, menghasilkan representasi vektor 1024 dimensi yang disimpan sebagai kolom bertipe `vector(1024)` dengan ivfflat index di PostgreSQL. Proses kedua adalah pembuatan indeks full-text search (FTS) menggunakan mekanisme `tsvector` PostgreSQL dengan konfigurasi bahasa Indonesia, yang disimpan sebagai kolom `tsvector` dengan GIN index untuk mendukung pencarian BM25 secara efisien.

#### 3.2.4.3 Struktur Data pada Chatbot

Data yang telah diproses disimpan dalam tiga tabel utama. Tabel `master_customer_problems` menyimpan basis masalah terstruktur, di mana setiap entri mewakili satu kategori masalah atau pertanyaan umum pelanggan. Setiap entri dilengkapi dengan daftar kata kunci (`mcp_keywords`), narasi pendekatan solusi (`mcp_recommended_approach`), embedding vektor 1024 dimensi (`mcp_embedding`), dan kolom `mcp_search_vector` bertipe `tsvector` yang di-generate otomatis untuk mendukung BM25 full-text search. Produk rekomendasi yang menyelesaikan suatu masalah ditautkan melalui kolom `mp_solves_problem_id` pada tabel `master_products`, sehingga pipeline dapat langsung mengambil rekomendasi produk berdasarkan masalah yang teridentifikasi menggunakan fungsi `get_recommendations()`.

Tabel `master_products` menyimpan katalog produk audio mobil yang dijual di Rendy Audio. Setiap produk memiliki kolom embedding vektor (`mp_embedding`) dan kolom `mp_search_vector` untuk mendukung Hybrid Search langsung pada katalog produk. Kolom `mp_compatible_car_types` dan `mp_recommended_car_sizes` memungkinkan filtering produk berdasarkan kompatibilitas kendaraan yang terdeteksi. Sumber data produk berasal dari kombinasi informasi yang diperoleh langsung dari Rendy Audio (nama produk, tipe, merek, harga), ditambah deskripsi dari website resmi merek dan bantuan AI untuk melengkapi detail teknis yang belum tersedia secara langsung.

Tabel `master_cars` menyimpan data spesifikasi audio bawaan kendaraan, meliputi merek, model, tipe, kategori ukuran kabin, tipe dashboard, ukuran speaker bawaan, dan catatan instalasi khusus. Data kendaraan dikumpulkan dengan bantuan AI berdasarkan spesifikasi teknis kendaraan populer di Indonesia, kemudian diverifikasi kesesuaiannya oleh pemilik Rendy Audio. Tabel ini digunakan oleh fungsi `search_car()` untuk mencocokkan referensi kendaraan dalam pesan pengguna, dan hasilnya diteruskan ke `get_products_for_car()` untuk mengambil produk yang kompatibel.

---

### 3.2.5 Pipeline RAG dan Hybrid Search

Pipeline RAG AudioMatch mengalirkan setiap pertanyaan pengguna melalui serangkaian tahap yang terurut. Sistem pertama-tama memeriksa apakah terdapat konteks kendaraan dalam pesan pengguna, jika ada pipeline akan mengambil data kompatibilitas kendaraan dari database sebelum menjalankan Hybrid Search. Hybrid Search menggabungkan jalur vector search dan jalur BM25 full-text search yang berjalan secara paralel, kemudian hasilnya digabungkan menggunakan algoritma Reciprocal Rank Fusion (RRF). Gambar 3.5 berikut mengilustrasikan alur umum chatbot AudioMatch secara keseluruhan.

**Gambar 3.5** Pipeline RAG dengan Hybrid Search AudioMatch

![Gambar 3.5 Pipeline RAG dengan Hybrid Search AudioMatch](../flowchart\Gambar%203.5%20Pipeline%20RAG%20dengan%20Hybrid%20Search%20AudioMatch.png)

Sumber: Diolah oleh penulis (2026)

Apabila skor hybrid tertinggi dari seluruh dokumen yang dikembalikan tidak melampaui ambang batas yang ditetapkan, sistem tidak mengulang proses Hybrid Search yang sama melainkan beralih ke jalur product-only fallback. Perbedaan mendasar antara jalur normal dan jalur fallback ini terletak pada titik masuk retrieval-nya. Pada jalur normal, query pengguna terlebih dahulu dicocokkan dengan tabel master_customer_problems untuk mengidentifikasi kategori masalah yang relevan, kemudian dari masalah yang teridentifikasi sistem mengambil rekomendasi produk melalui fungsi get_recommendations() berdasarkan relasi mp_solves_problem_id. Pada jalur fallback, tahap problem matching dilewati sepenuhnya karena tidak ada masalah yang cukup relevan ditemukan di basis pengetahuan. Sistem langsung menjalankan pencarian produk pada tabel master_products menggunakan query pengguna secara langsung melalui fungsi get_products_by_brand() apabila terdeteksi nama merek spesifik, atau melalui Hybrid Search langsung pada katalog produk apabila query bersifat konseptual. Dengan demikian, pengguna tetap menerima rekomendasi produk yang relevan meskipun konteks masalah teknisnya tidak ditemukan di basis pengetahuan, sekaligus menghindari respons kosong yang dapat menurunkan pengalaman pengguna.

#### 3.2.5.1 Mekanisme Hybrid Search dengan RRF

Hybrid Search pada AudioMatch beroperasi melalui dua jalur retrieval yang berjalan secara paralel dan digabungkan melalui strategi fusion berbasis prioritas. Jalur pertama adalah dense retrieval, di mana query pengguna diubah menjadi vektor embedding 1024 dimensi menggunakan VoyageAI voyage-3.5-lite, kemudian dicari kemiripannya dengan embedding yang tersimpan di `master_customer_problems` menggunakan metrik cosine similarity dari pgvector. Hanya dokumen dengan skor kemiripan cosine di atas ambang batas 0,3 yang dipertimbangkan.

Jalur kedua adalah sparse retrieval menggunakan BM25 full-text search melalui fungsi `ts_rank_cd` PostgreSQL. Query dikonversi menjadi `tsquery` dengan konfigurasi bahasa Indonesia, kemudian dicocokkan dengan kolom `tsvector` pada tabel `master_customer_problems` menggunakan GIN index. Pendekatan leksikal ini efektif untuk pertanyaan yang menyebutkan nama merek atau kode model produk secara eksak.

Penggabungan hasil kedua jalur dilakukan menggunakan algoritma Reciprocal Rank Fusion (RRF) dengan konstanta $k = 60$. Setiap dokumen pada masing-masing jalur diberi skor RRF berdasarkan posisi ranking-nya: 

RRF_vector (d)=1/(60+ rank_vector (d) )

dan

RRF_BM25 (d)=1/(60 + rank_BM25 (d))

Skor hybrid akhir dihitung sebagai kombinasi tertimbang:

hybrid_score=0,6×RRF_vector+0,4×RRF_BM25

Bobot yang lebih besar pada jalur vector search (0,6) mencerminkan pentingnya pemahaman semantik untuk pertanyaan konsultasi teknis yang beragam.

#### 3.2.5.2 Justifikasi Hybrid Search untuk Domain Audio Mobil

Domain audio mobil menghadirkan dua jenis pertanyaan yang membutuhkan pendekatan retrieval berbeda. Pertanyaan konseptual seperti "subwoofer yang cocok untuk musik rock itu yang seperti apa?" membutuhkan pemahaman semantik yang ditangani dengan baik oleh dense retrieval. Sedangkan pertanyaan spesifik seperti "apakah Pioneer TS-W311S4 cocok dipasang dengan amplifier ini?" memuat nama produk eksak yang membutuhkan pencocokan leksikal presisi. Shuster et al. (2021) menunjukkan bahwa sistem retrieval yang kuat merupakan prasyarat utama untuk menekan halusinasi dalam model generatif dimana temuan ini memperkuat pentingnya mekanisme Hybrid Search yang dapat mengambil dokumen paling relevan dari berbagai jenis pertanyaan pengguna.

#### 3.2.5.3 Deteksi Kendaraan dan Kompatibilitas Produk

Sebelum memasuki Hybrid Search, sistem memeriksa apakah terdapat referensi merek atau model kendaraan dalam pesan pengguna menggunakan dictionary keyword matching terhadap lebih dari 230 model kendaraan populer di Indonesia. Apabila kendaraan terdeteksi, sistem menjalankan fungsi `search_car(brand, model)` untuk mencocokkan kendaraan dengan data di `master_cars`, kemudian `get_products_for_car(car_type, car_size)` untuk mengambil produk yang kompatibel beserta skor kompatibilitasnya. Konteks kendaraan ini disertakan dalam input ke Hybrid Search sehingga hasil retrieval dan rekomendasi produk yang dihasilkan lebih relevan dengan spesifikasi kendaraan pengguna.

![Gambar 3.6 Alur Pipeline](../flowchart\Gambar%203.6%20Alur%20Pipeline.png)

**Gambar 3.6** Alur Pipeline
Sumber: Diolah oleh penulis (2026)

---

### 3.2.6 Basis Data

Basis data AudioMatch menggunakan PostgreSQL dengan skema `sales` sebagai namespace untuk seluruh tabel. Terdapat tiga tabel master yang menyimpan seluruh data domain system, yaitu `master_products` untuk katalog produk audio mobil, `master_customer_problems` untuk basis masalah dan pertanyaan umum pelanggan, dan `master_cars` untuk spesifikasi kendaraan. Relasi antara masalah dan produk direpresentasikan melalui kolom `mp_solves_problem_id` pada tabel `master_products` yang merujuk ke `master_customer_problems`. Riwayat percakapan dan manajemen sesi tidak disimpan di PostgreSQL, melainkan sepenuhnya dikelola di layer Upstash Redis sebagaimana dijelaskan pada subbab 3.2.7.

![Gambar 3.7 Entity Relationship Diagram (ERD) AudioMatch](../flowchart\Gambar%203.7%20Entity%20Relationship%20Diagram%20(ERD)%20AudioMatch.png)

**Gambar 3.7** Entity Relationship Diagram (ERD) AudioMatch
Sumber: Diolah oleh penulis (2026)

**Tabel 3.8** Indeks Database AudioMatch

| Tabel | Nama Indeks | Kolom | Tipe | Fungsi |
|-------|-------------|-------|------|--------|
| master_products | idx_products_active | mp_is_active | B-tree | Filter produk aktif |
| master_products | idx_products_category | mp_category | B-tree | Filter produk per kategori |
| master_products | idx_products_fts_name_desc | mp_search_vector | GIN | BM25 full-text search produk |
| master_products | idx_products_problem_fk | mp_solves_problem_id | B-tree | Join produk ke masalah (`get_recommendations`) |
| master_customer_problems | idx_problems_active | mcp_is_active | B-tree | Filter masalah aktif |
| master_customer_problems | idx_problems_embedding | mcp_embedding | ivfflat (cosine) | Vector search masalah |
| master_customer_problems | idx_problems_fts_title_desc | mcp_search_vector | GIN | BM25 full-text search masalah |
| master_cars | idx_cars_active | mc_is_active | B-tree | Filter kendaraan aktif |
| master_cars | idx_cars_brand | mc_brand | B-tree | Pencarian merek kendaraan (`search_car`) |
| master_cars | idx_cars_brand_model | mc_brand, mc_model | B-tree (composite) | Pencarian merek + model sekaligus |
| master_cars | idx_cars_model | mc_model | B-tree | Pencarian model kendaraan |
| master_cars | idx_cars_type | mc_type | B-tree | Filter tipe kendaraan (`get_products_for_car`) |

Sumber: Diolah oleh penulis (2026)

---

### 3.2.7 Implementasi Caching

Sistem AudioMatch mengimplementasikan Upstash Redis sebagai layer caching dengan namespace session:{session_id} yang menyimpan riwayat percakapan pengguna dalam format JSON. Setiap entri sesi menyimpan satu string JSON dengan struktur sebagai berikut:

{
  "history": [
    {
      "role": "user",
      "content": "rekomendasi audio mobil xpander"
    },
    {
      "role": "assistant",
      "content": "Tentu, untuk Mitsubishi Xpander..."
    }
  ]
}

Key sesi menggunakan format session:{session_id} dengan nilai TTL 86.400 detik (24 jam). Array history menyimpan seluruh riwayat percakapan secara berurutan dalam format peran user dan assistant, dibatasi maksimal 8 pesan terakhir untuk menjaga ukuran konteks yang dikirimkan ke Gemini API tetap efisien. Setiap kali pesan baru dikirimkan, sistem memuat riwayat dari Redis, menambahkan pesan baru ke dalam array, lalu menyimpan kembali keseluruhan objek JSON ke Redis dengan TTL yang diperbarui. Caching riwayat percakapan di Redis memastikan bahwa setiap permintaan baru ke Gemini API dapat menyertakan konteks percakapan sebelumnya tanpa harus mengambil ulang dari database utama, sekaligus mempertahankan state percakapan antar invokasi fungsi yang bersifat stateless pada lingkungan serverless Vercel (Wen et al. 2023).

---

## 3.3 Pengujian

Sub-bab ini memaparkan rencana pengujian sistem AudioMatch yang mencakup dua area, yaitu pengujian fungsionalitas melalui metode Black Box Testing, pengujian kualitas retrieval menggunakan metrik NDCG@K.

### 3.3.1 Rencana Pengujian Fungsionalitas (Black Box Testing)

Pengujian fungsionalitas dilakukan dengan metode Black Box Testing untuk memverifikasi bahwa seluruh fitur sistem berjalan sesuai fungsinya tanpa mempertimbangkan implementasi internal. Pengujian ini berfokus pada validasi input-output setiap endpoint dan alur percakapan utama, termasuk skenario khusus yang melibatkan deteksi kendaraan.

Gambar 3.8 berikut mengilustrasikan salah satu skenario pengujian konkret, yaitu skenario rekomendasi audio untuk kendaraan Hyundai Stargazer dengan dua opsi anggaran (high-end dan mid-range), yang mencakup alur deteksi kendaraan, Hybrid Search, dan generasi respons dua opsi oleh LLM.

![Gambar 3.8 Flowchart Skenario Uji Rekomendasi Audio Stargazer 2 Opsi](../flowchart\Gambar%203.8%20Flowchart%20Skenario%20Uji%20Rekomendasi%20Audio%20Stargazer%202%20Opsi.png)

**Gambar 3.8** Flowchart Skenario Uji: Rekomendasi Audio Stargazer 2 Opsi
Sumber: Diolah oleh penulis (2026)

**Tabel 3.9** Rencana Pengujian Black Box Testing AudioMatch

| No | Fitur yang Diuji | Skenario Uji | Langkah-langkah | Hasil yang Diharapkan |
|----|-----------------|--------------|-----------------|----------------------|
| 1 | Kirim pesan konsultasi umum | Pengguna mengirim pertanyaan baru tentang produk audio tanpa menyebut kendaraan | 1. POST /api/v1/chat dengan session_id baru dan pesan pertanyaan produk; 2. Periksa respons yang diterima | Sistem mengembalikan respons berisi jawaban teknis dan rekomendasi produk yang relevan; status HTTP 200 |
| 2 | Rekomendasi berbasis kendaraan | Pengguna menyebut merek dan model kendaraan dalam pertanyaan | 1. POST /api/v1/chat dengan pesan yang menyebutkan nama kendaraan (mis. "Hyundai Stargazer"); 2. Periksa apakah sistem mengenali kendaraan dan memberikan produk kompatibel | Sistem mengidentifikasi kendaraan, mengambil spesifikasi dari master_cars, dan mengembalikan rekomendasi produk yang kompatibel dengan kendaraan tersebut |
| 3 | Kelanjutan percakapan (context retention) | Pengguna mengirim pertanyaan lanjutan yang merujuk pesan sebelumnya | 1. Kirim pesan awal, simpan session_id; 2. Kirim pesan referensial ("lanjut yang nomor 2") menggunakan session_id sama | Sistem mengenali konteks percakapan sebelumnya dan menjawab pertanyaan lanjutan dengan konteks yang tepat |
| 4 | Pertanyaan di luar cakupan domain | Pengguna mengirim pertanyaan tentang topik non-audio-mobil | 1. POST /api/v1/chat dengan pesan tidak relevan (mis. resep masakan) | Sistem mengembalikan respons yang menyatakan topik di luar cakupan konsultasi audio mobil |
| 5 | Session baru tanpa session_id | Sistem membuat sesi baru secara otomatis | 1. POST /api/v1/chat tanpa menyertakan session_id | Sistem menghasilkan session_id baru, menyimpannya di Redis, dan mengembalikan respons beserta session_id tersebut |
| 6 | Rate limiting | Pengguna mengirim permintaan melebihi batas 100 req/60 detik | 1. Kirim lebih dari 100 permintaan dalam 60 detik dari IP yang sama | Sistem mengembalikan status HTTP 429 setelah melampaui batas |
| 7 | Validasi input kosong | Pengguna mengirim pesan kosong atau hanya spasi | 1. POST /api/v1/chat dengan field message berisi string kosong | Sistem mengembalikan status HTTP 422 dengan pesan error yang jelas |
| 8 | Endpoint daftar produk | Administrator mengakses daftar produk aktif | 1. GET /api/v1/products | Sistem mengembalikan daftar produk aktif dengan status HTTP 200 |
| 9 | Konsistensi sesi lintas pesan | Riwayat percakapan tersimpan dan dapat digunakan kembali | 1. Kirim 3 pesan berurutan dengan session_id sama; 2. Verifikasi riwayat di Redis | Riwayat berisi pesan-pesan percakapan yang benar; TTL sesi diperbarui setiap pesan baru dikirim |

Sumber: Diolah oleh penulis (2026)

---

### 3.3.2 Rencana Pengujian Kualitas Retrieval (NDCG@K)

Pengujian dilakukan menggunakan 30 kueri uji yang dikelompokkan berdasarkan jenis pertanyaan sebagai berikut:

**Tabel 3.10** Distribusi Kueri Uji Pengujian Kualitas Retrieval

| Kategori Kueri | Jumlah Kueri | Keterangan |
|----------------|-------------|-----------|
| Kompatibilitas komponen (amplifier ↔ speaker) | 8 | Pertanyaan teknis tentang kecocokan spesifikasi antar produk |
| Rekomendasi produk spesifik (menyebut merek/kode) | 7 | Pertanyaan dengan menyebut merek atau kode model tertentu |
| Konseptual dan edukatif | 8 | Pertanyaan tentang konsep umum audio mobil |
| Rekomendasi berbasis kendaraan | 7 | Pertanyaan yang menyebutkan merek/model kendaraan |
| **Total** | **30** | |

Untuk setiap kueri uji, disiapkan ground truth berupa daftar dokumen relevan yang diannotasi secara manual oleh pemilik Rendy Audio sebagai domain expert, dengan tingkat relevansi berskala 0–2 (0 = tidak relevan, 1 = relevan, 2 = sangat relevan). Setiap kueri kemudian dijalankan melalui pipeline Hybrid Search AudioMatch dan dihasilkan ranked list dokumen. DCG@K dan NDCG@K dihitung menggunakan formula:

DCG@K=∑_(i=1)^K▒(2^(rel_i )-1)/log_2⁡〖(i+1)〗   ,NDCG@K=(DCG@K)/(IDCG@K)

**Tabel 3.11** Rencana Pengujian Kualitas Retrieval Hybrid Search

| No | Metrik | Deskripsi Pengujian | Cara Pengukuran | Target Skor |
|----|--------|---------------------|-----------------|-------------|
| 1 | NDCG@3 | Kualitas ranking 3 dokumen teratas hasil Hybrid Search | Hitung DCG@3 berdasarkan relevansi dokumen pada posisi 1–3, bagi dengan IDCG@3 | > 0,75 |
| 2 | NDCG@5 | Kualitas ranking 5 dokumen teratas hasil Hybrid Search | Hitung DCG@5 berdasarkan relevansi dokumen pada posisi 1–5, bagi dengan IDCG@5 | > 0,70 |
| 3 | Precision@3 | Proporsi dokumen relevan di antara 3 dokumen teratas | Hitung jumlah dokumen relevan (rel ≥ 1) di posisi 1–3 dibagi 3 | > 0,70 |
| 4 | Precision@5 | Proporsi dokumen relevan di antara 5 dokumen teratas | Hitung jumlah dokumen relevan (rel ≥ 1) di posisi 1–5 dibagi 5 | > 0,65 |

Sumber: Diolah oleh penulis (2026)

Target skor kualitas retrieval ditetapkan berdasarkan dua pertimbangan yang saling melengkapi. Untuk metrik NDCG, target NDCG@3 > 0,75 dan NDCG@5 > 0,70 mengacu pada rentang performa yang dilaporkan pada sistem Hybrid Search dengan basis pengetahuan domain-spesifik yang dikurasi, di mana penelitian terdahulu melaporkan NDCG mencapai 0,847 pada kondisi basis pengetahuan in-domain yang terkurasi penuh (Sultania et al., 2024). Mengingat kondisi basis pengetahuan AudioMatch yang serupa dimana dikurasi secara manual oleh domain expert dan bersifat in-domain, target yang ditetapkan berada pada posisi konservatif di bawah angka tersebut, berbeda jauh dari kondisi evaluasi zero-shot pada BEIR benchmark yang hanya melaporkan rata-rata NDCG@10 sebesar 0,43–0,53 (Thakur et al., 2021). Untuk metrik Precision, target Precision@3 > 0,70 dan Precision@5 > 0,65 ditetapkan dengan dua pertimbangan tambahan. Pertama, secara matematis Precision@K merupakan metrik yang lebih permisif dibandingkan NDCG@K karena tidak memperhitungkan posisi ranking dokumen dalam hasil retrieval (Manning et al., 2009), sehingga target Precision yang ditetapkan konsisten berada di bawah target NDCG yang lebih ketat. Kedua, tidak ada threshold universal yang mendefinisikan skor Precision yang baik karena performa bervariasi signifikan bergantung pada karakteristik corpus dan tingkat kurasi basis pengetahuan, di mana skor yang sama dapat bermakna berbeda antara corpus umum dan sistem retrieval dengan basis pengetahuan yang dikurasi dengan jawaban terverifikasi Manning et al. (2009). Dengan demikian, target Precision pada rentang 0,65–0,70 merupakan ekspektasi yang terukur dan dapat dipertanggungjawabkan mengingat basis pengetahuan AudioMatch dikurasi langsung oleh pemilik Rendy Audio sebagai domain expert.

Pelaksanaan pengujian kualitas retrieval dilakukan dalam empat langkah. Pertama, disiapkan 30 kueri uji beserta anotasi relevansi dokumen yang telah diverifikasi oleh pemilik Rendy Audio. Kedua, setiap kueri dijalankan melalui pipeline Hybrid Search AudioMatch dan dicatat ranked list dokumen yang dikembalikan beserta skor hybrid-nya. Ketiga, dihitung nilai DCG@K dan NDCG@K serta Precision@K untuk setiap kueri menggunakan anotasi relevansi sebagai ground truth. Keempat, dihitung rata-rata skor NDCG@3, NDCG@5, Precision@3, dan Precision@5 di seluruh 30 kueri dan dibandingkan dengan target yang ditetapkan untuk mengevaluasi apakah konfigurasi Hybrid Search (bobot RRF 0,6/0,4, threshold cosine 0,3) menghasilkan kualitas retrieval yang memadai.