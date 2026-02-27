Berikut adalah rincian kolom yang Wajib Anda Isi secara manual di database sebelum memanggil endpoint /api/v1/admin/sync-embeddings:

  1. Tabel sales.master_customer_problems (Data Masalah Pelanggan)
  Tabel ini digunakan untuk mendeteksi apa masalah atau kebutuhan audio mobil si user.
   * `mcp_problem_title` (Wajib): Judul singkat masalah (misal: "Suara Bass Kurang Bertenaga").
   * `mcp_description` (Sangat Disarankan): Penjelasan detail masalah. Keduanya akan digabung (title + description) untuk dijadikan vector agar
     pencarian lebih akurat.
   * `mcp_is_active` (Wajib): Pastikan diset TRUE. Data FALSE akan diabaikan oleh sistem sync.
   * `mcp_embedding`: Biarkan NULL. Inilah kolom yang akan diisi otomatis oleh sistem.


  2. Tabel sales.master_knowledge_chunks (Data Pengetahuan Umum)
  Tabel ini berisi informasi umum seperti garansi, tips instalasi, atau kebijakan toko agar chatbot tidak "halu".
   * `mkc_content` (Wajib): Teks informasi yang ingin di-embed (misal: "Garansi instalasi di toko kami berlaku selama 1 tahun...").
   * `mkc_is_active` (Wajib): Pastikan diset TRUE.
   * `mkc_embedding`: Biarkan NULL. Akan diisi otomatis oleh sistem.

  ---

  3. Tabel Pendukung (Relasi Produk & Solusi)
  Agar chatbot bisa memberikan rekomendasi produk setelah menemukan masalah, Anda juga harus mengisi tabel relasi berikut (ini tidak di-embed,
  tapi penting untuk output chatbot):


   * `sales.master_products`: Masukkan semua daftar produk audio Anda (nama, brand, harga, dsb).
   * `sales.master_solutions`: Buat solusi yang terhubung ke mcp_id (masalah) yang sudah Anda buat di poin 1.
   * `sales.master_solution_products`: Hubungkan solution_id dengan product_id (produk mana saja yang menjadi solusi untuk masalah tersebut).

  ---


  Alur Kerja Sinkronisasi (Logika yang Saya Terapkan):
   1. Filter NULL: Query SQL saya menggunakan WHERE mcp_embedding IS NULL (untuk masalah) dan WHERE mkc_embedding IS NULL (untuk knowledge).
   2. Koleksi Data: Sistem hanya mengambil ID dan Teks dari baris yang belum punya vector.
   3. Embedding: Hanya data "baru" tersebut yang dikirim ke Voyage AI.
   4. Update: Hasil vector disimpan ke baris tersebut.


  Catatan Penting: Jika suatu saat Anda mengubah isi teks (content atau description) pada data yang sudah ada dan ingin memperbarui vector-nya,
  Anda cukup mengosongkan (set NULL) kolom embedding-nya secara manual di database, lalu panggil kembali endpoint sync tersebut.
