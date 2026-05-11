"""
NDCG Testing Fase 1 — Generate Annotation Template
Bab 3 Section 3.3.2 — Pengujian Kualitas Retrieval

Menjalankan 30 kueri uji melalui Hybrid Search AudioMatch,
lalu menghasilkan file Excel untuk dianotasi oleh domain expert (pemilik Rendy Audio).

Prasyarat:
    File .env dengan DATABASE_URL dan VOYAGE_API_KEY

Jalankan:
    python test_bab3_ndcg_generate.py

Output:
    hasil_testing/ndcg_annotation_template.xlsx
    hasil_testing/ndcg_raw_results.json

Langkah selanjutnya:
    1. Buka ndcg_annotation_template.xlsx
    2. Isi kolom rel_1 s/d rel_5 untuk setiap kueri (skala 0-2):
       0 = tidak relevan
       1 = relevan
       2 = sangat relevan
    3. Simpan file lalu jalankan: python test_bab3_ndcg_calculate.py
"""
import asyncio
import json
import os
import sys
from datetime import datetime
from pathlib import Path

import asyncpg
import httpx
import pandas as pd
from dotenv import load_dotenv

load_dotenv()

OUTPUT_DIR = Path("hasil_testing")

# ─────────────────────────────────────────────
# 30 Kueri Uji (sesuai distribusi Tabel 3.10 Bab 3)
# ─────────────────────────────────────────────
TEST_QUERIES = [
    # ── Kategori 1: Kompatibilitas Komponen (8 kueri) ──────────────────────
    {
        "id": "K01",
        "kategori": "Kompatibilitas Komponen",
        "query": "amplifier 4 channel 75 watt cocok untuk berapa speaker?",
    },
    {
        "id": "K02",
        "kategori": "Kompatibilitas Komponen",
        "query": "berapa watt amplifier yang dibutuhkan untuk subwoofer 12 inch?",
    },
    {
        "id": "K03",
        "kategori": "Kompatibilitas Komponen",
        "query": "speaker impedansi 4 ohm bisa dipasang di amplifier 8 ohm?",
    },
    {
        "id": "K04",
        "kategori": "Kompatibilitas Komponen",
        "query": "cara setting gain amplifier agar speaker tidak distorsi",
    },
    {
        "id": "K05",
        "kategori": "Kompatibilitas Komponen",
        "query": "bisa pasang 6 speaker ke amplifier 4 channel?",
    },
    {
        "id": "K06",
        "kategori": "Kompatibilitas Komponen",
        "query": "perbedaan RCA output 4V dan 2V pada head unit untuk amplifier",
    },
    {
        "id": "K07",
        "kategori": "Kompatibilitas Komponen",
        "query": "cara memilih crossover yang tepat untuk speaker component 2 way",
    },
    {
        "id": "K08",
        "kategori": "Kompatibilitas Komponen",
        "query": "ukuran kabel power amplifier yang direkomendasikan",
    },

    # ── Kategori 2: Produk Spesifik — menyebut merek/kode (7 kueri) ────────
    {
        "id": "P01",
        "kategori": "Produk Spesifik",
        "query": "pioneer DEH-S6250BT head unit",
    },
    {
        "id": "P02",
        "kategori": "Produk Spesifik",
        "query": "kenwood KDC-BT560U spesifikasi dan harga",
    },
    {
        "id": "P03",
        "kategori": "Produk Spesifik",
        "query": "nakamichi na3605 fitur dan keunggulan",
    },
    {
        "id": "P04",
        "kategori": "Produk Spesifik",
        "query": "hertz dieci speaker component DCX 165.3",
    },
    {
        "id": "P05",
        "kategori": "Produk Spesifik",
        "query": "JVC KD-X371BT head unit bluetooth",
    },
    {
        "id": "P06",
        "kategori": "Produk Spesifik",
        "query": "subwoofer rockford fosgate punch p3",
    },
    {
        "id": "P07",
        "kategori": "Produk Spesifik",
        "query": "tweeter JL Audio C1 075ct",
    },

    # ── Kategori 3: Konseptual dan Edukatif (8 kueri) ──────────────────────
    {
        "id": "C01",
        "kategori": "Konseptual dan Edukatif",
        "query": "apa fungsi head unit di sistem audio mobil?",
    },
    {
        "id": "C02",
        "kategori": "Konseptual dan Edukatif",
        "query": "perbedaan speaker coaxial dan speaker component",
    },
    {
        "id": "C03",
        "kategori": "Konseptual dan Edukatif",
        "query": "kenapa bass mobil tidak terasa nendang padahal sudah pasang subwoofer?",
    },
    {
        "id": "C04",
        "kategori": "Konseptual dan Edukatif",
        "query": "bagaimana cara upgrade audio mobil untuk pemula dengan budget terbatas?",
    },
    {
        "id": "C05",
        "kategori": "Konseptual dan Edukatif",
        "query": "apa itu DSP digital signal processor dalam audio mobil?",
    },
    {
        "id": "C06",
        "kategori": "Konseptual dan Edukatif",
        "query": "perbedaan subwoofer sealed box dan ported box untuk kualitas bass",
    },
    {
        "id": "C07",
        "kategori": "Konseptual dan Edukatif",
        "query": "cara menghilangkan noise suara dengung di audio mobil",
    },
    {
        "id": "C08",
        "kategori": "Konseptual dan Edukatif",
        "query": "mengapa suara speaker mobil pecah distorsi saat volume tinggi?",
    },

    # ── Kategori 4: Berbasis Kendaraan (7 kueri) ───────────────────────────
    {
        "id": "V01",
        "kategori": "Berbasis Kendaraan",
        "query": "rekomendasi upgrade audio untuk Mitsubishi Xpander",
    },
    {
        "id": "V02",
        "kategori": "Berbasis Kendaraan",
        "query": "speaker yang cocok untuk Honda Brio city car",
    },
    {
        "id": "V03",
        "kategori": "Berbasis Kendaraan",
        "query": "subwoofer terbaik untuk Toyota Avanza MPV",
    },
    {
        "id": "V04",
        "kategori": "Berbasis Kendaraan",
        "query": "setup audio lengkap untuk Toyota Fortuner SUV",
    },
    {
        "id": "V05",
        "kategori": "Berbasis Kendaraan",
        "query": "upgrade head unit android untuk Honda Jazz",
    },
    {
        "id": "V06",
        "kategori": "Berbasis Kendaraan",
        "query": "rekomendasi audio system untuk Suzuki Ertiga",
    },
    {
        "id": "V07",
        "kategori": "Berbasis Kendaraan",
        "query": "tweeter dan speaker depan untuk Hyundai Stargazer",
    },
]


# ─────────────────────────────────────────────
# Embedding via VoyageAI REST (menggunakan httpx langsung)
# ─────────────────────────────────────────────
async def get_embedding(client: httpx.AsyncClient, text: str) -> list:
    api_key = os.getenv("VOYAGE_API_KEY", "")
    if not api_key:
        return []

    payload = {
        "input": [text],
        "model": "voyage-3.5-lite",
        "input_type": "query",
    }
    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}

    for attempt in range(3):
        try:
            r = await client.post(
                "https://api.voyageai.com/v1/embeddings",
                headers=headers,
                json=payload,
                timeout=30,
            )
            r.raise_for_status()
            return r.json()["data"][0]["embedding"]
        except httpx.HTTPStatusError as e:
            if e.response.status_code == 429 and attempt < 2:
                print(f"    ⏳ Rate limit VoyageAI, tunggu 22 detik...")
                await asyncio.sleep(22)
            else:
                raise
    return []


# ─────────────────────────────────────────────
# Hybrid Search via asyncpg
# ─────────────────────────────────────────────
async def run_hybrid_search(conn, query_text: str, embedding: list, k: int = 5) -> list:
    if embedding:
        rows = await conn.fetch(
            """
            SELECT
                mcp_id::text,
                mcp_problem_title,
                mcp_description,
                vector_score,
                bm25_score,
                hybrid_score,
                vector_rank,
                bm25_rank
            FROM sales.search_problem_hybrid($1, $2::vector, $3, 60, 0.6, 0.4)
            ORDER BY hybrid_score DESC
            """,
            query_text,
            str(embedding),
            k,
        )
    else:
        # Fallback: BM25 only jika embedding tidak tersedia
        rows = await conn.fetch(
            """
            SELECT
                mcp_id::text,
                mcp_problem_title,
                mcp_description,
                0.0::float AS vector_score,
                ts_rank_cd(mcp_search_vector, plainto_tsquery('indonesian', $1)) AS bm25_score,
                ts_rank_cd(mcp_search_vector, plainto_tsquery('indonesian', $1)) AS hybrid_score,
                0 AS vector_rank,
                ROW_NUMBER() OVER (
                    ORDER BY ts_rank_cd(mcp_search_vector, plainto_tsquery('indonesian', $1)) DESC
                )::int AS bm25_rank
            FROM sales.master_customer_problems
            WHERE mcp_is_active = TRUE
              AND mcp_search_vector @@ plainto_tsquery('indonesian', $1)
            ORDER BY bm25_score DESC
            LIMIT $2
            """,
            query_text,
            k,
        )

    return [dict(row) for row in rows]


# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────
async def main():
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print("=" * 70)
    print("NDCG FASE 1 — Generate Annotation Template")
    print("AudioMatch Bab 3 Section 3.3.2")
    print(f"Timestamp : {timestamp}")
    print(f"Jumlah kueri: {len(TEST_QUERIES)}")
    print("=" * 70)

    db_url = os.getenv("DATABASE_URL", "")
    if not db_url:
        print("❌ DATABASE_URL tidak ditemukan di .env")
        sys.exit(1)

    voyage_key = os.getenv("VOYAGE_API_KEY", "")
    if not voyage_key:
        print("⚠️  VOYAGE_API_KEY tidak ada — akan pakai BM25 saja (tanpa vector)")

    conn = await asyncpg.connect(db_url, ssl=True)
    http_client = httpx.AsyncClient()
    all_results = []

    try:
        for i, item in enumerate(TEST_QUERIES, 1):
            qid = item["id"]
            kat = item["kategori"]
            q   = item["query"]

            print(f"\n[{i:02d}/30] [{qid}] {q[:60]}")

            # 1. Get embedding (dengan rate-limit awareness)
            embedding = []
            if voyage_key:
                try:
                    embedding = await get_embedding(http_client, q)
                except Exception as e:
                    print(f"  ⚠️ Embedding gagal: {e} — pakai BM25 saja")

            # 2. Hybrid search
            search_results = await run_hybrid_search(conn, q, embedding, k=5)

            print(f"  → {len(search_results)} problem ditemukan")
            for j, sr in enumerate(search_results, 1):
                print(f"    {j}. [{sr['hybrid_score']:.4f}] {sr['mcp_problem_title']}")

            # 3. Kumpulkan data
            entry = {
                "query_id": qid,
                "kategori": kat,
                "query_text": q,
                "embedding_available": bool(embedding),
                "retrieved_problems": search_results,
            }
            all_results.append(entry)

            # Rate limit mitigation: jeda kecil antar kueri
            if voyage_key and i < len(TEST_QUERIES):
                await asyncio.sleep(1.5)

    finally:
        await conn.close()
        await http_client.aclose()

    # ─────────────────────────────────────────
    # Generate Excel template untuk anotasi
    # ─────────────────────────────────────────
    OUTPUT_DIR.mkdir(exist_ok=True)

    rows = []
    for entry in all_results:
        problems = entry["retrieved_problems"]
        row = {
            "query_id":   entry["query_id"],
            "kategori":   entry["kategori"],
            "query_text": entry["query_text"],
            "embedding_available": entry["embedding_available"],
        }
        for rank in range(1, 6):
            if rank <= len(problems):
                p = problems[rank - 1]
                row[f"rank_{rank}_problem_title"] = p["mcp_problem_title"]
                row[f"rank_{rank}_hybrid_score"]  = round(p["hybrid_score"], 6)
                row[f"rank_{rank}_vector_score"]  = round(p["vector_score"], 6)
                row[f"rank_{rank}_bm25_score"]    = round(p["bm25_score"], 6)
                row[f"rank_{rank}_problem_id"]    = p["mcp_id"]
            else:
                row[f"rank_{rank}_problem_title"] = ""
                row[f"rank_{rank}_hybrid_score"]  = ""
                row[f"rank_{rank}_vector_score"]  = ""
                row[f"rank_{rank}_bm25_score"]    = ""
                row[f"rank_{rank}_problem_id"]    = ""
            # Kolom relevansi — diisi oleh domain expert
            row[f"rel_{rank}"] = ""

        rows.append(row)

    df = pd.DataFrame(rows)

    # Susun ulang kolom agar mudah dianotasi
    base_cols = ["query_id", "kategori", "query_text", "embedding_available"]
    detail_cols = []
    for rank in range(1, 6):
        detail_cols += [
            f"rank_{rank}_problem_title",
            f"rank_{rank}_hybrid_score",
            f"rank_{rank}_vector_score",
            f"rank_{rank}_bm25_score",
            f"rank_{rank}_problem_id",
            f"rel_{rank}",
        ]
    df = df[base_cols + detail_cols]

    excel_path = OUTPUT_DIR / "ndcg_annotation_template.xlsx"
    with pd.ExcelWriter(excel_path, engine="openpyxl") as writer:
        df.to_excel(writer, sheet_name="Anotasi", index=False)

        # Sheet petunjuk
        petunjuk = pd.DataFrame({
            "Petunjuk": [
                "CARA PENGISIAN TEMPLATE ANOTASI RELEVANSI",
                "",
                "Isi kolom rel_1 hingga rel_5 untuk setiap kueri.",
                "Gunakan skala berikut:",
                "  0 = Tidak relevan (problem tidak berhubungan dengan kueri)",
                "  1 = Relevan (problem berhubungan dengan kueri)",
                "  2 = Sangat relevan (problem adalah jawaban terbaik untuk kueri)",
                "",
                "Jika rank_X_problem_title KOSONG, biarkan rel_X tetap kosong.",
                "",
                "Setelah selesai, simpan file ini dan jalankan:",
                "  python test_bab3_ndcg_calculate.py",
            ]
        })
        petunjuk.to_excel(writer, sheet_name="Petunjuk", index=False)

    print(f"\n✅ Template anotasi: {excel_path}")

    # Simpan raw JSON
    json_path = OUTPUT_DIR / "ndcg_raw_results.json"
    json_path.write_text(
        json.dumps({"timestamp": timestamp, "queries": all_results}, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )
    print(f"✅ Raw JSON: {json_path}")

    print(f"\n{'='*70}")
    print("FASE 1 SELESAI")
    print(f"{'='*70}")
    print(f"  → Buka '{excel_path}' dan isi kolom rel_1 s/d rel_5")
    print(f"  → Skala: 0 = tidak relevan | 1 = relevan | 2 = sangat relevan")
    print(f"  → Setelah selesai: python test_bab3_ndcg_calculate.py")


if __name__ == "__main__":
    asyncio.run(main())
