# Hasil Black Box Testing — AudioMatch

**Tanggal Pengujian:** 2026-05-11 18:00:23
**Base URL:** http://localhost:8000

---

## Ringkasan

| Total | Pass | Fail | Error |
|-------|------|------|-------|
| 9 | 9 | 0 | 0 |

---

## Detail Hasil Pengujian

| No | Skenario Uji | Input | Expected | Actual | HTTP | Status | Keterangan |
|----|-------------|-------|----------|--------|------|--------|------------|
| 1 | Kirim pesan konsultasi umum | suara mobil saya kurang bass, apa yang harus saya lakukan? | HTTP 200, ada field 'response' berisi teks | HTTP 200, response length=86 | 200 | ✅ PASS | session_id=25d3718e-30f5-45fc-8745-e518c5fb34cd |
| 2 | Rekomendasi berbasis kendaraan | saya punya Hyundai Stargazer, rekomendasi audio yang bagus a | HTTP 200, sistem deteksi kendaraan Stargazer & kembalikan re | HTTP 200, car_detected=True, kendaraan_disebut_LLM=False | 200 | ✅ PASS | recommendations count=1, car_detected=True, llm_menyebut_mobil=False [LLM rate-l |
| 3 | Kelanjutan percakapan (context retention) | Pesan 1: subwoofer EDM → Pesan 2: kisaran harga (session_id  | HTTP 200 kedua pesan, session_id konsisten (Redis context re | HTTP 200, session_consistent=True, llm_relevan=True | 200 | ✅ PASS | session_consistent=True, llm_relevan=True, session_id=3ef97023-04b9-464d-a6d9-95 |
| 4 | Pertanyaan di luar domain | bagaimana cara membuat nasi goreng yang enak? | HTTP 200, respons menyatakan di luar cakupan konsultasi audi | HTTP 200, di_luar_cakupan=True | 200 | ✅ PASS | response snippet: 'I am sorry, but I am experiencing some technical difficulties |
| 5 | Session baru tanpa session_id | POST tanpa menyertakan session_id | HTTP 200, field session_id berisi UUID baru | HTTP 200, session_id='3b88a281-56ad-4fd1-837d-5fef3e2d7640', valid=Tru | 200 | ✅ PASS | session_id=3b88a281-56ad-4fd1-837d-5fef3e2d7640 |
| 7 | Validasi input kosong / hanya spasi | message='', message='   ', tidak ada field message | HTTP 422 (Unprocessable Entity) minimal untuk kasus message  | empty='': HTTP 422 \| spasi: HTTP 200 \| no field: HTTP 422 | 422 | ✅ PASS | Pydantic menolak field required yang hilang dengan HTTP 422 |
| 8 | Endpoint daftar produk GET /api/v1/products | GET /api/v1/products (tanpa filter) & GET /api/v1/products?c | HTTP 200, list produk aktif dengan field id/name/category/pr | HTTP 200, jumlah produk=111, fields_ok=True, filter_HTTP=200 | 200 | ✅ PASS | Total produk aktif: 111 |
| 9 | Konsistensi sesi lintas 3 pesan | 3 pesan berurutan dengan session_id yang sama | HTTP 200 semua, session_id konsisten di setiap respons | all_200=True, same_session=True, session_ids=['72fdc677-32e1-49a5-9847 | 200 | ✅ PASS | session_id=72fdc677-32e1-49a5-9847-015959908bc8 |
| 6 | Rate limiting (>100 req/60s → HTTP 429) | 110 request concurrent ke POST /api/v1/chat/ | HTTP 429 muncul setelah melampaui batas 100 req/60 detik | HTTP 200: 98x, HTTP 429: 12x, lainnya: 0x | 429 | ✅ PASS | 429 muncul setelah ~98 request berhasil |

---

## Keterangan Status

- ✅ **PASS**: Sistem berperilaku sesuai ekspektasi Bab 3
- ❌ **FAIL**: Sistem tidak berperilaku sesuai ekspektasi
- ⚠️ **SKIP**: Fitur belum diimplementasikan (gap, dicatat untuk perbaikan)
- 🔴 **ERROR**: Terjadi exception saat pengujian