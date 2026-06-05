Masukan/pertanyaan dari dosen:

Logika fallback ke jalur
product-only, yaitu beralih ke pencarian langsung pada tabel `master_products`
melalui fungsi `get_products_by_brand()`

Apakah ini fungsi yg terpisah dari querynya?

Km bisa masukkan jg ya script python nya yg manggil fungsi ini. biar jelas

---

## Jawaban / Revisi

### 1. Apakah `get_products_by_brand()` fungsi yang terpisah?

Ya, `get_products_by_brand()` adalah **method Python yang berdiri sendiri** (terpisah dari query hybrid search), didefinisikan di dalam kelas `DatabaseService` pada file `app/services/database_service.py`.

Fungsi ini **tidak memanggil SQL Function di database**, melainkan menjalankan query SQL biasa secara langsung ke tabel `sales.master_products`. Berbeda dengan `search_problem_hybrid()` yang memanggil stored function di PostgreSQL, `get_products_by_brand()` menggunakan query SQL inline (ditulis langsung di dalam method Python).

### 2. Script Python — Definisi Fungsi `get_products_by_brand()`

Berikut adalah definisi fungsi di `app/services/database_service.py`:

```python
# app/services/database_service.py

class DatabaseService:

    async def get_products_by_brand(self, brand: str) -> List[Dict[str, Any]]:
        query = """
        SELECT
            mp_id as product_id,
            mp_name as product_name,
            mp_category as product_category,
            mp_brand as product_brand,
            mp_price as product_price,
            mp_description as product_description,
            mp_image as product_image
        FROM sales.master_products
        WHERE LOWER(mp_brand) = LOWER($1)
          AND mp_is_active = TRUE
        ORDER BY mp_price DESC;
        """
        return await self.fetch(query, brand)
```

Fungsi ini menerima parameter `brand` (nama merek produk), lalu menjalankan query SQL langsung ke tabel `sales.master_products` untuk mengambil semua produk aktif dari merek tersebut, diurutkan berdasarkan harga tertinggi (premium first).

### 3. Script Python — Pemanggilan Fungsi di Endpoint Chat

Fungsi `get_products_by_brand()` dipanggil di `app/api/v1/endpoints/chat.py` pada **dua titik** dalam alur pencarian:

#### a) Jalur Brand Detection (Sebelum Hybrid Search — Langsung ke Brand)

Apabila sistem mendeteksi nama merek audio di dalam pesan pengguna **sebelum** melakukan hybrid search, sistem langsung memanggil `get_products_by_brand()`:

```python
# app/api/v1/endpoints/chat.py — STEP 2A2

# Daftar merek yang dikenali sistem
known_brands = [
    'kenwood', 'pioneer', 'jvc', 'nakamichi', 'clarion',
    'hertz', 'jl audio', 'rockford fosgate', 'skeleton',
    'dhd', 'avix', 'orca', 'exxent'
]

# Deteksi merek yang disebut dalam query pengguna
mentioned_brands = [brand for brand in known_brands if brand in query_lower]

if mentioned_brands:
    # Untuk setiap merek yang terdeteksi, panggil get_products_by_brand()
    for brand in mentioned_brands:
        brand_products = await db.get_products_by_brand(brand)
        if brand_products:
            # Simpan semua produk merek tersebut sebagai konteks rekomendasi
            all_products_context.extend(brand_products)
```

#### b) Jalur Fallback (Setelah Hybrid Search Gagal Menemukan Masalah)

Apabila hybrid search tidak berhasil mencocokkan masalah pengguna dengan data di tabel `master_customer_problems`, sistem masuk ke jalur fallback dan kembali memanggil `get_products_by_brand()`:

```python
# app/api/v1/endpoints/chat.py — Fallback: No problem matched

if not recommendations:
    # Cek kembali apakah ada nama merek dalam query
    mentioned_brands = [brand for brand in known_brands if brand in query_lower]

    if mentioned_brands:
        # Fallback ke pencarian langsung berdasarkan merek
        for brand in mentioned_brands:
            brand_products = await db.get_products_by_brand(brand)
            if brand_products:
                all_products_context.extend(brand_products)
    else:
        # Tidak ada merek → fallback ke hybrid search pada tabel master_products
        embedding = await embedding_service.get_embedding(search_query, input_type="query")
        all_products = await db.search_product_hybrid(
            query_text=search_query,
            embedding=embedding,
            match_count=30
        )
```

### Ringkasan Alur Fallback

```
Query pengguna
      │
      ▼
Deteksi mobil? ──Ya──► search_car() + get_car_recommendations_context()
      │
      No
      ▼
Deteksi merek? ──Ya──► get_products_by_brand()  ◄── (pencarian langsung, tanpa hybrid)
      │
      No
      ▼
Hybrid search (vector + BM25) pada master_customer_problems
      │
      Cocok? ──Ya──► get_recommendations() → produk terkait masalah
      │
      No (tidak ada masalah yang cocok)
      ▼
Fallback: Deteksi merek lagi?
      ├──Ya──► get_products_by_brand()  ◄── (jalur product-only yang dimaksud)
      └──No──► search_product_hybrid() pada master_products (max 30 produk)
```

Jadi, `get_products_by_brand()` adalah fungsi Python tersendiri yang berisi query SQL langsung ke `master_products`, dan dipanggil dari endpoint chat sebagai **jalur pintas** ketika merek audio spesifik disebutkan — baik sebelum maupun sesudah proses hybrid search.
