"""
NDCG Testing Fase 2 — Hitung NDCG@K dari Hasil Anotasi
Bab 3 Section 3.3.2 — Pengujian Kualitas Retrieval

Membaca file Excel yang sudah dianotasi oleh domain expert,
menghitung NDCG@3, NDCG@5, Precision@3, Precision@5,
dan menghasilkan laporan untuk Bab 4.

Prasyarat:
    hasil_testing/ndcg_annotation_template.xlsx sudah diisi rel_1 s/d rel_5

Jalankan:
    python test_bab3_ndcg_calculate.py

Output:
    hasil_testing/ndcg_results.md
    hasil_testing/ndcg_results.json
"""
import json
import math
import sys
from datetime import datetime
from pathlib import Path

import pandas as pd

OUTPUT_DIR = Path("hasil_testing")
ANNOTATION_FILE = OUTPUT_DIR / "ndcg_annotation_template.xlsx"

# Target skor sesuai Bab 3 Tabel 3.11
TARGETS = {
    "NDCG@3": 0.75,
    "NDCG@5": 0.70,
    "Precision@3": 0.70,
    "Precision@5": 0.65,
}


# ─────────────────────────────────────────────
# Metric Calculations
# ─────────────────────────────────────────────

def dcg_at_k(relevances: list, k: int) -> float:
    """DCG@K = Σ (2^rel_i - 1) / log2(i+1) untuk i = 1..K"""
    score = 0.0
    for i, rel in enumerate(relevances[:k], start=1):
        if rel and rel != "":
            try:
                r = float(rel)
                score += (2**r - 1) / math.log2(i + 1)
            except (ValueError, TypeError):
                pass
    return score


def idcg_at_k(relevances: list, k: int) -> float:
    """IDCG@K = DCG dari urutan ideal (diurutkan descending)"""
    clean = []
    for r in relevances:
        if r is not None and r != "":
            try:
                clean.append(float(r))
            except (ValueError, TypeError):
                pass
    ideal = sorted(clean, reverse=True)
    return dcg_at_k(ideal, k)


def ndcg_at_k(relevances: list, k: int) -> float:
    """NDCG@K = DCG@K / IDCG@K"""
    idcg = idcg_at_k(relevances, k)
    if idcg == 0:
        return 0.0
    return dcg_at_k(relevances, k) / idcg


def precision_at_k(relevances: list, k: int) -> float:
    """Precision@K = count(rel_i >= 1) / K"""
    count = 0
    for rel in relevances[:k]:
        if rel is not None and rel != "":
            try:
                if float(rel) >= 1:
                    count += 1
            except (ValueError, TypeError):
                pass
    return count / k


# ─────────────────────────────────────────────
# Load & Validate Annotation File
# ─────────────────────────────────────────────

def load_annotations(path: Path) -> pd.DataFrame:
    if not path.exists():
        print(f"❌ File tidak ditemukan: {path}")
        print("   Jalankan dulu: python test_bab3_ndcg_generate.py")
        sys.exit(1)

    df = pd.read_excel(path, sheet_name="Anotasi")

    # Cek apakah ada data anotasi
    rel_cols = [f"rel_{i}" for i in range(1, 6)]
    has_annotation = df[rel_cols].notna().any().any()
    if not has_annotation:
        print("⚠️  Kolom rel_1 s/d rel_5 masih kosong semua.")
        print("   Isi terlebih dahulu template anotasi sebelum menjalankan script ini.")
        sys.exit(1)

    return df


# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────

def main():
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print("=" * 70)
    print("NDCG FASE 2 — Kalkulasi Metrik Kualitas Retrieval")
    print("AudioMatch Bab 3 Section 3.3.2")
    print(f"Timestamp : {timestamp}")
    print("=" * 70)

    df = load_annotations(ANNOTATION_FILE)
    print(f"✅ File anotasi dimuat: {len(df)} kueri\n")

    rel_cols = [f"rel_{i}" for i in range(1, 6)]
    per_query_results = []

    for _, row in df.iterrows():
        qid  = row["query_id"]
        kat  = row["kategori"]
        qtxt = row["query_text"]
        rels = [row[c] for c in rel_cols]

        metrics = {
            "query_id":    qid,
            "kategori":    kat,
            "query_text":  qtxt,
            "NDCG@3":      round(ndcg_at_k(rels, 3), 4),
            "NDCG@5":      round(ndcg_at_k(rels, 5), 4),
            "Precision@3": round(precision_at_k(rels, 3), 4),
            "Precision@5": round(precision_at_k(rels, 5), 4),
            "relevances":  [str(r) if (r is not None and r != "") else "-" for r in rels],
        }
        per_query_results.append(metrics)

        print(f"  [{qid}] NDCG@3={metrics['NDCG@3']:.4f} NDCG@5={metrics['NDCG@5']:.4f} "
              f"P@3={metrics['Precision@3']:.4f} P@5={metrics['Precision@5']:.4f} | {qtxt[:50]}")

    # ─────────────────────────────────────────
    # Rata-rata keseluruhan
    # ─────────────────────────────────────────
    n = len(per_query_results)
    avg_metrics = {
        "NDCG@3":      round(sum(r["NDCG@3"]      for r in per_query_results) / n, 4),
        "NDCG@5":      round(sum(r["NDCG@5"]      for r in per_query_results) / n, 4),
        "Precision@3": round(sum(r["Precision@3"] for r in per_query_results) / n, 4),
        "Precision@5": round(sum(r["Precision@5"] for r in per_query_results) / n, 4),
    }

    # ─────────────────────────────────────────
    # Rata-rata per kategori
    # ─────────────────────────────────────────
    categories = df["kategori"].unique().tolist()
    cat_metrics = {}
    for cat in categories:
        cat_rows = [r for r in per_query_results if r["kategori"] == cat]
        nc = len(cat_rows)
        cat_metrics[cat] = {
            "count":       nc,
            "NDCG@3":      round(sum(r["NDCG@3"]      for r in cat_rows) / nc, 4),
            "NDCG@5":      round(sum(r["NDCG@5"]      for r in cat_rows) / nc, 4),
            "Precision@3": round(sum(r["Precision@3"] for r in cat_rows) / nc, 4),
            "Precision@5": round(sum(r["Precision@5"] for r in cat_rows) / nc, 4),
        }

    # ─────────────────────────────────────────
    # Pass/Fail terhadap target Bab 3
    # ─────────────────────────────────────────
    def pf(val, target):
        return "✅ Pass" if val >= target else "❌ Fail"

    print(f"\n{'='*70}")
    print("HASIL AKHIR")
    print(f"{'='*70}")
    for metric, target in TARGETS.items():
        val = avg_metrics[metric]
        print(f"  {metric:15s}: {val:.4f}  (target > {target}) → {pf(val, target)}")

    # ─────────────────────────────────────────
    # Generate Markdown
    # ─────────────────────────────────────────
    md_lines = [
        "# Hasil Pengujian Kualitas Retrieval — AudioMatch",
        f"\n**Tanggal Pengujian:** {timestamp}",
        f"**Metode:** Hybrid Search (Vector + BM25 RRF, bobot 0.6/0.4)",
        f"**Model Embedding:** VoyageAI voyage-3.5-lite (1024 dimensi)",
        f"**Jumlah Kueri:** {n} kueri dari 4 kategori",
        "\n---\n",
        "## Ringkasan Hasil vs Target (Tabel 3.11 Bab 3)",
        "",
        "| Metrik | Score | Target | Status |",
        "|--------|-------|--------|--------|",
    ]
    for metric, target in TARGETS.items():
        val = avg_metrics[metric]
        md_lines.append(f"| {metric} | **{val:.4f}** | > {target} | {pf(val, target)} |")

    md_lines += [
        "",
        "---",
        "",
        "## Hasil per Kategori Kueri (Tabel 3.10 Bab 3)",
        "",
        "| Kategori | Jumlah Kueri | NDCG@3 | NDCG@5 | Precision@3 | Precision@5 |",
        "|----------|-------------|--------|--------|-------------|-------------|",
    ]
    for cat, cm in cat_metrics.items():
        md_lines.append(
            f"| {cat} | {cm['count']} | {cm['NDCG@3']:.4f} | {cm['NDCG@5']:.4f} "
            f"| {cm['Precision@3']:.4f} | {cm['Precision@5']:.4f} |"
        )
    md_lines.append(
        f"| **Rata-rata Keseluruhan** | {n} | **{avg_metrics['NDCG@3']:.4f}** "
        f"| **{avg_metrics['NDCG@5']:.4f}** | **{avg_metrics['Precision@3']:.4f}** "
        f"| **{avg_metrics['Precision@5']:.4f}** |"
    )

    md_lines += [
        "",
        "---",
        "",
        "## Detail Hasil per Kueri",
        "",
        "| ID | Kategori | Kueri | Relevansi (1-5) | NDCG@3 | NDCG@5 | P@3 | P@5 |",
        "|----|----------|-------|----------------|--------|--------|-----|-----|",
    ]

    def esc(s):
        return str(s).replace("|", "\\|")

    for r in per_query_results:
        rel_str = ", ".join(r["relevances"])
        md_lines.append(
            f"| {r['query_id']} | {esc(r['kategori'])} | {esc(r['query_text'])[:55]} "
            f"| [{rel_str}] | {r['NDCG@3']:.4f} | {r['NDCG@5']:.4f} "
            f"| {r['Precision@3']:.4f} | {r['Precision@5']:.4f} |"
        )

    md_lines += [
        "",
        "---",
        "",
        "## Interpretasi",
        "",
        "### Formula (Bab 3 Section 3.3.2)",
        "```",
        "DCG@K  = Σ (2^rel_i - 1) / log2(i+1)  untuk i = 1..K",
        "IDCG@K = DCG dari urutan ideal (relevansi diurutkan descending)",
        "NDCG@K = DCG@K / IDCG@K",
        "Precision@K = count(rel_i ≥ 1) / K",
        "",
        "Skala relevansi: 0 = tidak relevan | 1 = relevan | 2 = sangat relevan",
        "```",
        "",
        "### Konfigurasi Hybrid Search",
        "| Parameter | Nilai |",
        "|-----------|-------|",
        "| Bobot Vector (dense) | 0.6 |",
        "| Bobot BM25 (sparse) | 0.4 |",
        "| RRF Konstanta k | 60 |",
        "| Threshold Cosine | 0.3 |",
        "| Bahasa FTS | Indonesian |",
    ]

    # Tulis file
    OUTPUT_DIR.mkdir(exist_ok=True)
    md_path = OUTPUT_DIR / "ndcg_results.md"
    md_path.write_text("\n".join(md_lines), encoding="utf-8")
    print(f"\n📄 Markdown : {md_path}")

    json_path = OUTPUT_DIR / "ndcg_results.json"
    json_path.write_text(
        json.dumps(
            {
                "timestamp": timestamp,
                "summary": avg_metrics,
                "targets": TARGETS,
                "pass_fail": {m: avg_metrics[m] >= t for m, t in TARGETS.items()},
                "per_category": cat_metrics,
                "per_query": per_query_results,
            },
            indent=2,
            ensure_ascii=False,
        ),
        encoding="utf-8",
    )
    print(f"📊 JSON     : {json_path}")

    print(f"\n{'='*70}")
    print("FASE 2 SELESAI — File siap dimasukkan ke Bab 4")
    print(f"{'='*70}")


if __name__ == "__main__":
    main()
