Masukan/pertanyaan dari dosen:

Pertama:
Km tau jenis query ini kan?
WITH vector*results AS (
SELECT p.mcp_id, ...,
1 - (p.mcp_embedding <=> query_embedding) AS similarity,
ROW_NUMBER() OVER (ORDER BY similarity DESC) AS
rank
FROM sales.master_customer_problems p
WHERE similarity > 0.3 -- ambang batas cosine similarity
),
bm25_results AS (
SELECT p.mcp_id, ...,
ts_rank_cd(p.mcp_search_vector,
plainto_tsquery('indonesian', query_text), 32) AS similarity,
ROW_NUMBER() OVER (ORDER BY similarity DESC) AS
rank
FROM sales.master_customer_problems p
WHERE p.mcp_search_vector @@ plainto_tsquery('indonesian',
query_text)
)
SELECT mcp_id,
(0.6 * COALESCE(vector*score, 0.0) +
0.4 * COALESCE(bm25_score, 0.0)) AS hybrid_score
FROM rrf_scores
ORDER BY hybrid_score DESC
LIMIT 5;

WITH vector_results AS ( => ini apa istilahnya

Kedua:
Pertanyaan :
ada WITH vector_results AS
dan
bm25_results AS

ini kpn dipake?
di bwhnya tidak ada memanggil vector_results dan bm25_results

Ketiga:
Vector search menggunakan operator `<=>` dari ekstensi pgvector untuk
menghitung cosine distance, sedangkan BM25 menggunakan fungsi
`ts_rank_cd` dari PostgreSQL bawaan dengan kolom `tsvector` berindeks GIN.
Hanya dokumen dengan cosine similarity di atas 0,3 yang diikutsertakan dari
jalur vector search. Apabila tidak ada dokumen yang melampaui ambang batas
tersebut, sistem beralih ke jalur product-only fallback yang mencari langsung
pada tabel `master_products` melalui fungsi `get_products_by_brand()` atau
Hybrid Search langsung.

Apabila tidak ada dokumen yang melampaui ambang batas
tersebut, sistem beralih ke jalur product-only fallback yang mencari langsung
pada tabel `master_products` melalui fungsi `get_products_by_brand()` atau
Hybrid Search langsung.

Apakah ini ada query tersebut?

Keempat:
kn km menjelaskannya begini:
Gambar 3.5 pada Bab III dirancang sebagai arsitektur logis yang
menggambarkan what yaitu komponen apa saja yang terlibat dan bagaimana
alur data mengalir secara konseptual, mulai dari konversi kueri menjadi vektor
embedding, jalur vector search, jalur BM25, hingga penggabungan skor melalui
RRF. Sementara itu, sub-bab ini menggambarkan how, yaitu bagaimana seluruh
komponen logis tersebut diwujudkan secara teknis. Dalam implementasinya,
seluruh alur yang digambarkan pada Gambar 3.5 dikemas ke dalam satu fungsi
SQL search_problem_hybrid() yang berjalan di sisi basis data. Pemisahan
antara arsitektur logis dan implementasi teknis ini adalah praktik umum dalam
perancangan sistem, di mana diagram konseptual sengaja dibuat lebih rinci agar
setiap tahap proses dapat dipahami secara independen, sementara
implementasinya dioptimalkan untuk efisiensi dengan meminimalkan roundtrip
jaringan antara lapisan aplikasi dan basis data.

Intinya ini dioptimalkan.

Pertanyaannya : apakah semua proses di gambar 3.5 itu sudah terwakilkan di query tersebut?
