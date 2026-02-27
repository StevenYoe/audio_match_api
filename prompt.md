Saya ingin membangun **AI Sales Chatbot untuk Toko Audio Mobil & Aksesoris Mobil**.

Chatbot ini harus mampu menganalisis kebutuhan customer dan memberikan rekomendasi upgrade audio yang tepat serta mengarahkan ke pembelian produk yang tersedia di toko.

---

## 🎯 Tujuan Sistem

Chatbot harus:

1. Menganalisis keluhan audio user
2. Mengidentifikasi kategori masalah (bass kurang, suara pecah, kurang detail, kurang power, dll)
3. Memberikan beberapa opsi solusi
4. Mengajukan pertanyaan klarifikasi
5. Mengarahkan user ke produk yang tersedia di database
6. Menggunakan pendekatan persuasif (sales-oriented)

---

## 📦 Database

Saya **sudah menyediakan schema database**.

Silakan:

* Baca isi file schema yang tersedia (database_schemas.sql)
* Pahami relasi antar tabel
* Identifikasi di mana data produk, kategori, dan (jika ada) vector disimpan
* Gunakan schema yang ada tanpa redesign besar

Jika memang perlu, hanya berikan saran modifikasi minor (misalnya tambahan kolom atau index), bukan perubahan struktur besar.

Tolong jelaskan:

* Bagaimana chatbot akan mengambil data berdasarkan schema tersebut
* Bagaimana mapping antara “masalah user” → “solusi” → “produk”
* Bagaimana jika satu produk relevan untuk beberapa solusi

---

## 🧠 Domain Knowledge

Toko menjual:

* Head Unit
* Speaker
* Subwoofer
* Power Amplifier
* DSP / Equalizer
* Kabel audio
* Aksesoris mobil (wiper, kaca film, sarung jok, dll)

Chatbot harus bisa membedakan:

* Masalah tuning vs kekurangan hardware
* Upgrade ringan vs upgrade full system
* Budget rendah vs premium

---

## 🧩 Contoh Use Case

Input:

> “Treble sudah oke tapi bass kurang terasa.”

Chatbot harus:

1. Mengidentifikasi kemungkinan penyebab
2. Memberikan beberapa opsi solusi:

   * Tambah subwoofer aktif
   * Tambah amplifier
   * Upgrade head unit
   * Tambah DSP
3. Mengajukan pertanyaan lanjutan:

   * Sudah pakai subwoofer?
   * Budget range?
   * Mobil tipe apa?
   * Mau instalasi minimalis atau tidak masalah pakai box belakang?

---

## 🧠 Logika Rekomendasi

Tolong jelaskan bagaimana sistem bekerja:

1. Apakah menggunakan rule-based classification?
2. Apakah menggunakan semantic search?
3. Apakah hybrid approach lebih cocok?
4. Apakah perlu scoring untuk memilih solusi terbaik?

Karena ini chatbot sales, sistem harus:

* Tidak terlalu teknis
* Tidak terlalu generik
* Mengarah ke closing
* Memberikan beberapa opsi, bukan satu solusi saja

---

## ⚙️ Output yang Saya Harapkan

1. Penjelasan bagaimana schema yang ada digunakan
2. Flow sistem rekomendasi
3. Strategi agar tetap sales-oriented
4. Jika ada kekurangan di konsep saya, tolong beri saran
5. Untuk API Key yg akan digunakan saya sudah menyiapkannya dan parameternya sudah saya tentukan di file .env.example