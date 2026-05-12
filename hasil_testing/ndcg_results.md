# Hasil Pengujian Kualitas Retrieval — AudioMatch

**Tanggal Pengujian:** 2026-05-13 01:27:00
**Metode:** Hybrid Search (Vector + BM25 RRF, bobot 0.6/0.4)
**Model Embedding:** VoyageAI voyage-3.5-lite (1024 dimensi)
**Jumlah Kueri:** 30 kueri dari 4 kategori

---

## Ringkasan Hasil vs Target (Tabel 3.11 Bab 3)

| Metrik | Score | Target | Status |
|--------|-------|--------|--------|
| NDCG@3 | **0.8100** | > 0.75 | ✅ Pass |
| NDCG@5 | **0.8878** | > 0.7 | ✅ Pass |
| Precision@3 | **0.6445** | > 0.7 | ❌ Fail |
| Precision@5 | **0.5667** | > 0.65 | ❌ Fail |

---

## Hasil per Kategori Kueri (Tabel 3.10 Bab 3)

| Kategori | Jumlah Kueri | NDCG@3 | NDCG@5 | Precision@3 | Precision@5 |
|----------|-------------|--------|--------|-------------|-------------|
| Kompatibilitas Komponen | 8 | 0.6713 | 0.7651 | 0.4167 | 0.3000 |
| Produk Spesifik | 7 | 0.8753 | 0.9308 | 0.5714 | 0.4571 |
| Konseptual dan Edukatif | 8 | 0.8831 | 0.9472 | 0.7917 | 0.6750 |
| Berbasis Kendaraan | 7 | 0.8198 | 0.9171 | 0.8095 | 0.8571 |
| **Rata-rata Keseluruhan** | 30 | **0.8100** | **0.8878** | **0.6445** | **0.5667** |

---

## Detail Hasil per Kueri

| ID | Kategori | Kueri | Relevansi (1-5) | NDCG@3 | NDCG@5 | P@3 | P@5 |
|----|----------|-------|----------------|--------|--------|-----|-----|
| K01 | Kompatibilitas Komponen | amplifier 4 channel 75 watt cocok untuk berapa speaker? | [0, 0, 1, 0, 0] | 0.5000 | 0.5000 | 0.3333 | 0.2000 |
| K02 | Kompatibilitas Komponen | berapa watt amplifier yang dibutuhkan untuk subwoofer 1 | [1, 0, 0, 0, 2] | 0.2754 | 0.5950 | 0.3333 | 0.4000 |
| K03 | Kompatibilitas Komponen | speaker impedansi 4 ohm bisa dipasang di amplifier 8 oh | [0, 1, 0, 0, 0] | 0.6309 | 0.6309 | 0.3333 | 0.2000 |
| K04 | Kompatibilitas Komponen | cara setting gain amplifier agar speaker tidak distorsi | [2, 0, 1, 0, 0] | 0.9639 | 0.9639 | 0.6667 | 0.4000 |
| K05 | Kompatibilitas Komponen | bisa pasang 6 speaker ke amplifier 4 channel? | [1, 1, 0, 0, 0] | 1.0000 | 1.0000 | 0.6667 | 0.4000 |
| K06 | Kompatibilitas Komponen | perbedaan RCA output 4V dan 2V pada head unit untuk amp | [1, 1, 0, 0, 0] | 1.0000 | 1.0000 | 0.6667 | 0.4000 |
| K07 | Kompatibilitas Komponen | cara memilih crossover yang tepat untuk speaker compone | [0, 0, 0, 1, 0] | 0.0000 | 0.4307 | 0.0000 | 0.2000 |
| K08 | Kompatibilitas Komponen | ukuran kabel power amplifier yang direkomendasikan | [2, 0, 0, 0, 0] | 1.0000 | 1.0000 | 0.3333 | 0.2000 |
| P01 | Produk Spesifik | pioneer DEH-S6250BT head unit | [2, 1, 0, 0, 1] | 0.8790 | 0.9726 | 0.6667 | 0.6000 |
| P02 | Produk Spesifik | kenwood KDC-BT560U spesifikasi dan harga | [1, 0, 0, 0, 0] | 1.0000 | 1.0000 | 0.3333 | 0.2000 |
| P03 | Produk Spesifik | nakamichi na3605 fitur dan keunggulan | [1, 0, 0, 0, 0] | 1.0000 | 1.0000 | 0.3333 | 0.2000 |
| P04 | Produk Spesifik | hertz dieci speaker component DCX 165.3 | [1, 2, 0, 1, 0] | 0.7003 | 0.8045 | 0.6667 | 0.6000 |
| P05 | Produk Spesifik | JVC KD-X371BT head unit bluetooth | [2, 0, 0, 1, 0] | 0.8262 | 0.9448 | 0.3333 | 0.4000 |
| P06 | Produk Spesifik | subwoofer rockford fosgate punch p3 | [2, 2, 0, 0, 1] | 0.9073 | 0.9790 | 0.6667 | 0.6000 |
| P07 | Produk Spesifik | tweeter JL Audio C1 075ct | [1, 2, 2, 0, 0] | 0.8146 | 0.8146 | 1.0000 | 0.6000 |
| C01 | Konseptual dan Edukatif | apa fungsi head unit di sistem audio mobil? | [2, 2, 1, 0, 1] | 1.0000 | 0.9925 | 1.0000 | 0.8000 |
| C02 | Konseptual dan Edukatif | perbedaan speaker coaxial dan speaker component | [1, 2, 1, 2, 1] | 0.6291 | 0.8167 | 1.0000 | 1.0000 |
| C03 | Konseptual dan Edukatif | kenapa bass mobil tidak terasa nendang padahal sudah pa | [2, 1, 0, 0, 1] | 0.8790 | 0.9726 | 0.6667 | 0.6000 |
| C04 | Konseptual dan Edukatif | bagaimana cara upgrade audio mobil untuk pemula dengan  | [2, 2, 1, 1, 1] | 1.0000 | 1.0000 | 1.0000 | 1.0000 |
| C05 | Konseptual dan Edukatif | apa itu DSP digital signal processor dalam audio mobil? | [1, 0, 1, 0, 0] | 0.9197 | 0.9197 | 0.6667 | 0.4000 |
| C06 | Konseptual dan Edukatif | perbedaan subwoofer sealed box dan ported box untuk kua | [2, 1, 0, 2, 1] | 0.6733 | 0.9118 | 0.6667 | 0.8000 |
| C07 | Konseptual dan Edukatif | cara menghilangkan noise suara dengung di audio mobil | [2, 0, 1, 0, 0] | 0.9639 | 0.9639 | 0.6667 | 0.4000 |
| C08 | Konseptual dan Edukatif | mengapa suara speaker mobil pecah distorsi saat volume  | [2, 1, 0, 0, 0] | 1.0000 | 1.0000 | 0.6667 | 0.4000 |
| V01 | Berbasis Kendaraan | rekomendasi upgrade audio untuk Mitsubishi Xpander | [2, 1, 2, 2, 1] | 0.8026 | 0.9445 | 1.0000 | 1.0000 |
| V02 | Berbasis Kendaraan | speaker yang cocok untuk Honda Brio city car | [2, 1, 1, 1, 1] | 1.0000 | 1.0000 | 1.0000 | 1.0000 |
| V03 | Berbasis Kendaraan | subwoofer terbaik untuk Toyota Avanza MPV | [1, 0, 2, 1, 1] | 0.6052 | 0.7273 | 0.6667 | 0.8000 |
| V04 | Berbasis Kendaraan | setup audio lengkap untuk Toyota Fortuner SUV | [2, 1, 1, 1, 1] | 1.0000 | 1.0000 | 1.0000 | 1.0000 |
| V05 | Berbasis Kendaraan | upgrade head unit android untuk Honda Jazz | [2, 0, 1, 1, 1] | 0.8473 | 0.9465 | 0.6667 | 0.8000 |
| V06 | Berbasis Kendaraan | rekomendasi audio system untuk Suzuki Ertiga | [2, 0, 2, 1, 1] | 0.8344 | 0.9131 | 0.6667 | 0.8000 |
| V07 | Berbasis Kendaraan | tweeter dan speaker depan untuk Hyundai Stargazer | [2, 0, 1, 2, 0] | 0.6490 | 0.8886 | 0.6667 | 0.6000 |

---

## Interpretasi

### Formula (Bab 3 Section 3.3.2)
```
DCG@K  = Σ (2^rel_i - 1) / log2(i+1)  untuk i = 1..K
IDCG@K = DCG dari urutan ideal (relevansi diurutkan descending)
NDCG@K = DCG@K / IDCG@K
Precision@K = count(rel_i ≥ 1) / K

Skala relevansi: 0 = tidak relevan | 1 = relevan | 2 = sangat relevan
```

### Konfigurasi Hybrid Search
| Parameter | Nilai |
|-----------|-------|
| Bobot Vector (dense) | 0.6 |
| Bobot BM25 (sparse) | 0.4 |
| RRF Konstanta k | 60 |
| Threshold Cosine | 0.3 |
| Bahasa FTS | Indonesian |