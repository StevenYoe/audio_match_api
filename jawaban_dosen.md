# Jawaban atas Masukan Dosen Pembimbing

Dokumen ini berisi jawaban langsung untuk disampaikan ke dosen, bukan untuk dimasukkan ke laporan.

---

## Pertanyaan 1 — "WITH vector_results AS (...) ini apa istilahnya?"

**Jawaban:**
Konstruksi SQL tersebut bernama **CTE (Common Table Expression)** atau dalam bahasa Indonesia disebut *Ekspresi Tabel Umum*. CTE didefinisikan menggunakan klausa `WITH` di awal query, dan setiap blok bernama di dalamnya (seperti `vector_results`, `bm25_results`) berlaku seperti tabel sementara yang hanya hidup selama eksekusi query tersebut.

Contoh sederhananya:
```sql
WITH nama_cte AS (
    SELECT ... FROM tabel
)
SELECT * FROM nama_cte;
```

Pada fungsi `search_problem_hybrid()`, terdapat **empat CTE berantai**: `vector_results` → `bm25_results` → `all_candidates` → `rrf_scores`.

---

## Pertanyaan 2 — "vector_results dan bm25_results kapan dipakainya? Di bawahnya tidak ada yang memanggil keduanya"

**Jawaban:**
Potongan query yang ditampilkan di laporan sebelumnya **tidak lengkap/terpotong**. CTE `all_candidates` dan `rrf_scores` yang seharusnya ada di antaranya tidak ditampilkan, sehingga terlihat seolah-olah `vector_results` dan `bm25_results` tidak pernah digunakan.

Struktur lengkap query yang sebenarnya memiliki 4 CTE:

| CTE | Fungsi | Memanggil |
|-----|--------|-----------|
| `vector_results` | Dense retrieval (cosine similarity) | — |
| `bm25_results` | Sparse retrieval (BM25 / ts_rank_cd) | — |
| `all_candidates` | Gabungkan kandidat dari kedua jalur (UNION) | `vector_results`, `bm25_results` |
| `rrf_scores` | Hitung skor RRF tiap kandidat | `all_candidates`, `vector_results`, `bm25_results` |

Bagian yang hilang dari snippet laporan adalah `all_candidates` dan `rrf_scores`. Di sinilah `vector_results` dan `bm25_results` dipanggil. Dalam kode aktual (file `migrations/004_hybrid_search.sql`, baris 129–151):

```sql
all_candidates AS (
    SELECT mcp_id FROM vector_results
    UNION
    SELECT mcp_id FROM bm25_results
),
rrf_scores AS (
    SELECT c.mcp_id, ...
    FROM all_candidates c
    LEFT JOIN vector_results v ON c.mcp_id = v.mcp_id
    LEFT JOIN bm25_results  b  ON c.mcp_id = b.mcp_id
)
```

**Perbaikan di laporan:** Snippet SQL di Bab IV Sub-bab 4.1.6 telah diperbarui untuk menampilkan keempat CTE secara lengkap beserta komentar yang menjelaskan peran masing-masing.

---

## Pertanyaan 3 — "Apakah query tersebut ada logika fallback ke get_products_by_brand() atau Hybrid Search langsung?"

**Jawaban:**
**Tidak.** Logika *fallback* tersebut **tidak ada di dalam query SQL**. Penjelasan rincinya:

- **Yang ada di SQL:** Ambang batas cosine similarity 0,3 diterapkan sebagai filter `WHERE` di dalam CTE `vector_results`. Jika tidak ada dokumen yang melampaui ambang batas, CTE tersebut mengembalikan baris kosong, sehingga `all_candidates` hanya berisi hasil BM25. Jika BM25 juga kosong, fungsi SQL mengembalikan *empty result set*.

- **Yang ada di Python (lapisan aplikasi):** File `app/api/v1/endpoints/chat.py` memeriksa apakah hasil dari `search_problem_hybrid()` kosong (`if not recommendations:`). Jika iya, kode Python secara eksplisit memanggil `get_products_by_brand()` (jika ada nama merek di query) atau `search_product_hybrid()` (jika query bersifat konseptual). Inilah logika *fallback* yang dimaksud.

Jadi, kalimat di laporan yang menyebut "sistem beralih ke jalur *product-only fallback*" adalah deskripsi perilaku sistem secara keseluruhan, bukan deskripsi isi query SQL-nya. **Perbaikan di laporan** pada Sub-bab 4.1.6 sudah ditambahkan klarifikasi bahwa *fallback routing* ini terjadi di lapisan aplikasi Python, bukan di dalam fungsi SQL.

---

## Pertanyaan 4 — "Apakah semua proses di Gambar 3.5 sudah terwakilkan di query tersebut?"

**Jawaban:**
**Tidak semuanya.** Gambar 3.5 menggambarkan empat proses utama pipeline:

| No | Proses di Gambar 3.5 | Diimplementasikan di... | Ada di SQL? |
|----|----------------------|-------------------------|-------------|
| 1 | Konversi kueri → vektor *embedding* (VoyageAI) | Python — `EmbeddingService` memanggil API VoyageAI | **Tidak** |
| 2 | Jalur *vector search* (cosine similarity, pgvector) | SQL — CTE `vector_results` | **Ya** |
| 3 | Jalur BM25 *full-text search* (ts_rank_cd) | SQL — CTE `bm25_results` | **Ya** |
| 4 | Penggabungan skor via RRF | SQL — CTE `all_candidates` + `rrf_scores` | **Ya** |

Proses nomor 1 (konversi *embedding*) dilakukan di Python sebelum memanggil fungsi SQL. Hasilnya berupa vektor 1024 dimensi yang dikirim sebagai parameter `query_embedding` ke fungsi `search_problem_hybrid()`. Fungsi SQL hanya menerima vektor yang sudah jadi — ia tidak tahu cara memanggil API VoyageAI.

Dengan kata lain: **query SQL merepresentasikan proses (2), (3), dan (4)**. Proses (1) ada di sistem, tetapi ada di lapisan Python, bukan di SQL. Hal ini sudah dijelaskan di laporan pada paragraf tentang Gambar 3.5, namun penjelasannya telah diperjelas di Bab IV Sub-bab 4.1.6 agar lebih eksplisit.

---

---

## Glosarium Teknis — Nama Resmi dari Hal-hal yang Sudah Kamu Pakai

Bagian ini bukan untuk dosen, tapi untuk kamu sendiri. Semuanya sudah ada di sistemmu — ini hanya nama formalnya.

---

### SQL & Database

#### CTE — *Common Table Expression*
Nama resmi untuk blok `WITH nama AS (SELECT ...)`. Fungsinya seperti membuat "tabel sementara" yang hanya hidup selama satu query berjalan. Alternatifnya adalah subquery langsung di dalam `FROM (...)`, tapi CTE lebih mudah dibaca karena diberi nama. Kalau CTE merujuk ke dirinya sendiri, itu disebut *recursive CTE* — punya kamu tidak recursive, jadi disebut *non-recursive CTE*.

#### Window Function
Nama resmi untuk `ROW_NUMBER() OVER (ORDER BY ...)`. Disebut "window" karena ia menghitung nilai untuk setiap baris tapi tetap bisa "melihat" baris-baris lain di sekitarnya (tidak seperti `GROUP BY` yang menciutkan baris). Selain `ROW_NUMBER()`, family ini termasuk `RANK()`, `DENSE_RANK()`, `LAG()`, `LEAD()`. Kamu pakai ini untuk memberi nomor urut ranking di dalam `vector_results` dan `bm25_results`.

#### COALESCE
Fungsi SQL yang mengembalikan argumen pertama yang nilainya bukan NULL. `COALESCE(vector_score, 0.0)` artinya: "pakai nilai `vector_score`, tapi kalau NULL, pakai 0.0 sebagai gantinya." Kamu butuh ini karena dokumen yang hanya muncul di BM25 tidak punya `vector_score` (NULL), dan NULL × apapun = NULL, yang akan merusak perhitungan skor hybrid.

#### LEFT JOIN vs INNER JOIN
`INNER JOIN` hanya mengambil baris yang ada di **kedua** tabel. `LEFT JOIN` mengambil semua baris dari tabel kiri, dan kalau tidak ada pasangannya di tabel kanan, kolom dari kanan diisi NULL. Di CTE `rrf_scores`, kamu pakai `LEFT JOIN` ke `vector_results` dan `bm25_results` karena ada dokumen yang muncul hanya di salah satu jalur — dokumen yang hanya ditemukan BM25 tidak ada di `vector_results`, dan `LEFT JOIN` memastikan mereka tetap masuk dengan `vector_score = NULL` (yang kemudian di-handle oleh `COALESCE`).

#### UNION
Menggabungkan hasil dua `SELECT` menjadi satu daftar baris, dan secara otomatis menghapus duplikat. Di CTE `all_candidates` kamu pakai `UNION` (bukan `UNION ALL`) karena dokumen yang muncul di kedua jalur hanya boleh masuk satu kali ke daftar kandidat.

#### GIN Index — *Generalized Inverted Index*
Tipe indeks di PostgreSQL yang cocok untuk data yang "satu baris punya banyak nilai" — seperti `tsvector` yang merepresentasikan banyak kata sekaligus, atau array. Cara kerjanya mirip indeks buku: daripada cari kata per halaman, ia punya daftar "kata ini ada di halaman mana saja". Itulah kenapa pencarian `@@` (apakah tsvector mengandung tsquery) sangat cepat. Kamu pakai ini di kolom `mcp_search_vector` dan `mp_search_vector`.

#### ivfflat Index
Singkatan dari *Inverted File with Flat Quantization* — tipe indeks untuk pencarian vektor di pgvector. Berbeda dengan indeks B-tree yang mencari nilai eksak, ivfflat mencari vektor yang **paling mirip** secara approximate (tidak 100% akurat tapi sangat cepat). Ia membagi ruang vektor ke dalam beberapa "cluster" dan saat query masuk, hanya mencari di cluster yang paling dekat. Kamu pakai ini di kolom `mcp_embedding` untuk mempercepat pencarian cosine similarity.

#### tsvector & tsquery
`tsvector` adalah representasi teks yang sudah diproses: kata-kata dipecah, distop-word, di-stem (bentuk dasar). Contoh: kalimat `"suara bass kurang keras"` menjadi `tsvector` berisi token seperti `'bass' 'keras' 'kur' 'suar'`. `tsquery` adalah query pencariannya, misal `plainto_tsquery('indonesian', 'bass kurang')` menghasilkan `'bass' & 'kur'`. Operator `@@` mengecek apakah `tsvector` cocok dengan `tsquery`.

#### ts_rank_cd
Fungsi PostgreSQL untuk menghitung **skor relevansi** teks terhadap suatu query, berdasarkan frekuensi dan distribusi kemunculan kata dalam dokumen. Ini adalah implementasi praktis dari konsep **BM25** (lihat di bawah) yang ada di PostgreSQL secara built-in. Angka `32` yang kamu tulis adalah normalisasi option (membagi skor berdasarkan panjang dokumen).

#### Operator `<=>` (pgvector)
Operator dari ekstensi pgvector untuk menghitung **cosine distance** antara dua vektor. Perhatikan: ini distance (jarak), bukan similarity (kemiripan). Range-nya 0–2, di mana 0 = identik dan 2 = berlawanan. Itulah kenapa kamu tulis `1 - (p.mcp_embedding <=> query_embedding)` — mengubah distance menjadi similarity dengan range 0–1.

---

### Information Retrieval (IR)

#### Dense Retrieval vs Sparse Retrieval
Dua pendekatan mencari dokumen:
- **Dense retrieval**: merepresentasikan teks sebagai **vektor angka** (embedding) menggunakan model neural. Bisa "mengerti makna" — query "mobil berisik" bisa menemukan dokumen "kebisingan kabin kendaraan" meski tidak ada kata yang sama.
- **Sparse retrieval**: merepresentasikan teks sebagai **daftar kata** (seperti BM25/TF-IDF). Hanya cocok kalau kata-katanya sama atau mirip. Lebih cepat dan bagus untuk query yang menyebut nama spesifik seperti merek produk.

Sistemmu pakai keduanya karena pertanyaan pelanggan bisa conceptual ("suara bass tidak nendang") atau spesifik ("Pioneer TS-W311S4").

#### BM25 — *Best Match 25*
Algoritma ranking dokumen yang sudah menjadi standar di information retrieval sejak 1994. Intinya menghitung seberapa relevan dokumen terhadap query berdasarkan: (1) frekuensi kata query muncul di dokumen, (2) seberapa jarang kata itu di seluruh koleksi (kata langka = lebih informatif), (3) panjang dokumen (dokumen panjang dinormalisasi). Fungsi `ts_rank_cd` di PostgreSQL adalah implementasi BM25-style built-in yang sudah terintegrasi dengan `tsvector`.

#### Embedding / Vector Embedding
Representasi teks (atau data lain) sebagai **array angka desimal** berdimensi tinggi. Model VoyageAI voyage-3.5-lite mengubah kalimat apapun menjadi array 1024 angka. Angka-angka ini bukan sembarangan — teks yang bermakna mirip akan menghasilkan vektor yang secara matematis "dekat" di ruang 1024 dimensi itu. Di database disimpan sebagai tipe `vector(1024)` dari ekstensi pgvector.

#### Cosine Similarity vs Cosine Distance
Dua cara mengukur "kesamaan arah" dua vektor:
- **Cosine similarity**: range -1 sampai 1, di mana 1 = identik dan -1 = berlawanan
- **Cosine distance**: `1 - cosine_similarity`, range 0 sampai 2, di mana 0 = identik

Operator `<=>` di pgvector menghitung **cosine distance**. Untuk membandingkan dengan threshold 0.3 (similarity), kamu harus tulis `1 - (... <=>...) > 0.3` agar nilainya jadi similarity dulu.

#### RRF — *Reciprocal Rank Fusion*
Algoritma menggabungkan beberapa daftar ranking menjadi satu ranking tunggal. Rumusnya: untuk setiap dokumen, tambahkan `1 / (k + rank)` dari masing-masing jalur retrieval. Konstanta `k = 60` adalah nilai default yang sudah terbukti stabil di banyak penelitian — gunanya agar dokumen di peringkat atas tidak mendapat skor yang terlalu jauh dibanding peringkat bawah. Keunggulan RRF: tidak perlu menyamakan skala skor dari kedua jalur (skor cosine similarity dan skor BM25 range-nya berbeda, tapi RRF hanya peduli pada **posisi ranking**, bukan nilai absolut skornya).

#### Hybrid Search
Istilah umum untuk sistem retrieval yang menggabungkan **dense retrieval** (vector search) dan **sparse retrieval** (BM25/keyword). Cara penggabungannya bisa bermacam-macam — systemmu pakai **RRF** sebagai metode fusion-nya. Alternatif lain yang umum: *linear combination* (rata-rata tertimbang skor langsung), tapi ini butuh normalisasi skor karena range-nya berbeda.

---

### Arsitektur Sistem

#### RAG — *Retrieval-Augmented Generation*
Pola arsitektur AI di mana model LLM (Gemini) tidak menjawab dari pengetahuannya sendiri saja, tapi **pertama mencari dokumen relevan dulu** (retrieval), lalu menyuntikkan dokumen itu ke dalam prompt sebagai konteks (augmented), baru LLM menghasilkan jawaban (generation). Tanpa RAG, LLM bisa berhalusinasi karena tidak tahu katalog produk Rendy Audio. Dengan RAG, LLM "disuapi" data produk yang relevan dulu sebelum menjawab.

#### Application Layer vs Database Layer
Pembagian tanggung jawab antara kode Python (aplikasi) dan SQL (database):
- **Database layer** (`search_problem_hybrid()` di PostgreSQL): menangani operasi yang intensif data — vector search, BM25, JOIN antar tabel besar. Lebih efisien karena data tidak perlu dikirim ke Python dulu baru dihitung.
- **Application layer** (`chat.py` di Python): menangani logika bisnis dan orkestrasi — keputusan "pakai jalur mana", fallback, format respons, manajemen sesi. Lebih fleksibel untuk logika kondisional yang kompleks.

Intinya: kalau bisa dikerjakan di database tanpa bolak-balik, taruh di database. Kalau butuh keputusan bisnis yang kompleks, taruh di aplikasi.

#### Fallback Pattern
Pola desain sistem di mana ada **jalur utama** dan **jalur cadangan**. Jika jalur utama tidak menghasilkan hasil (atau gagal), sistem otomatis beralih ke jalur cadangan. Di sistemmu: jalur utama = `search_problem_hybrid()` → `get_recommendations()`, jalur fallback = `get_products_by_brand()` atau `search_product_hybrid()` langsung. Ini umum disebut *graceful degradation* — sistem tetap bisa memberikan respons berguna meski jalur optimalnya tidak berhasil.

#### Round-trip Jaringan
Setiap kali kode Python mengirim query ke database PostgreSQL dan menunggu hasilnya, itu satu *round-trip*. Kalau vector search dan BM25 diimplementasikan terpisah di Python (fetch semua dokumen, hitung di Python), butuh setidaknya dua round-trip plus transfer data besar. Dengan dikemas dalam satu fungsi SQL, kedua jalur plus RRF fusion selesai dalam **satu round-trip** — data tidak perlu keluar-masuk jaringan, PostgreSQL menghitung semuanya di dalam.

---

## Ringkasan Perubahan yang Dilakukan di Laporan (Bab-4-5.md)

| # | Perubahan | Lokasi |
|---|-----------|--------|
| 1 | Istilah CTE (*Common Table Expression*) ditambahkan dan dijelaskan di paragraf pembuka | Sub-bab 4.1.6 |
| 2 | Snippet SQL dilengkapi menjadi 4 CTE penuh (sebelumnya hanya 2 CTE + SELECT tanpa definisi `rrf_scores`) | Sub-bab 4.1.6 |
| 3 | Komentar SQL ditambahkan di setiap CTE untuk menjelaskan perannya | Sub-bab 4.1.6 |
| 4 | Klarifikasi ditambahkan bahwa *fallback routing* diimplementasikan di Python, bukan di SQL | Sub-bab 4.1.6 |
| 5 | Klarifikasi ditambahkan bahwa konversi *embedding* (proses 1 di Gambar 3.5) dilakukan di Python sebelum SQL dipanggil, sehingga SQL hanya merepresentasikan proses (2)–(4) | Sub-bab 4.1.6 |
