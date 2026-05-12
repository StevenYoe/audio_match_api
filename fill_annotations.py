"""
Script untuk mengisi anotasi relevansi ke ndcg_annotation_template.xlsx
Relevansi dinilai berdasarkan kesesuaian problem dengan intent kueri:
  2 = sangat relevan (problem langsung menjawab kueri)
  1 = relevan (problem berhubungan tapi tidak langsung)
  0 = tidak relevan
"""
import pandas as pd
from pathlib import Path

ANNOTATION_FILE = Path("hasil_testing/ndcg_annotation_template.xlsx")

# Anotasi per query_id: [rel_1, rel_2, rel_3, rel_4, rel_5]
# Urutan sesuai rank yang dikembalikan oleh hybrid search
ANNOTATIONS = {
    # ── Kompatibilitas Komponen ────────────────────────────────────────────
    # K01: amplifier 4 channel 75 watt cocok untuk berapa speaker?
    # Rank: Butuh keluarga, Speaker OEM jelek, Suara distorsi, Kompetisi, Soundstage
    "K01": [0, 0, 1, 0, 0],

    # K02: berapa watt amplifier untuk subwoofer 12 inch?
    # Rank: Kompetisi, Budget terbatas, Butuh keluarga, Speaker OEM, Bass kurang
    "K02": [1, 0, 0, 0, 2],

    # K03: speaker 4 ohm di amplifier 8 ohm?
    # Rank: Install tdk potong kabel, Distorsi, Speaker OEM, Budget, Soundstage
    "K03": [0, 1, 0, 0, 0],

    # K04: cara setting gain amplifier agar tidak distorsi
    # Rank: Distorsi, Install kabel, Kompetisi, Speaker OEM, Bass
    "K04": [2, 0, 1, 0, 0],

    # K05: bisa pasang 6 speaker ke amplifier 4 channel?
    # Rank: Install kabel, Distorsi, Budget, Keluarga, Speaker OEM
    "K05": [1, 1, 0, 0, 0],

    # K06: perbedaan RCA output 4V vs 2V pada head unit untuk amplifier
    # Rank: Distorsi, Upgrade single→double DIN, Vocal mid range, Install kabel, Bass
    "K06": [1, 1, 0, 0, 0],

    # K07: cara memilih crossover untuk speaker component 2 way
    # Rank: Install kabel, Keluarga, Kompetisi, Distorsi, Speaker OEM
    "K07": [0, 0, 0, 1, 0],

    # K08: ukuran kabel power amplifier yang direkomendasikan
    # Rank: Install kabel, Kompetisi, Budget, Keluarga, Upgrade single→double DIN
    "K08": [2, 0, 0, 0, 0],

    # ── Produk Spesifik ────────────────────────────────────────────────────
    # P01: pioneer DEH-S6250BT head unit
    # Rank: HU Bluetooth, Upgrade single→double DIN, Kompetisi, Keluarga, Build dari nol
    "P01": [2, 1, 0, 0, 1],

    # P02: kenwood KDC-BT560U spesifikasi dan harga
    # Rank: Upgrade single→double DIN, Keluarga, Kompetisi, Speaker OEM, Bass
    "P02": [1, 0, 0, 0, 0],

    # P03: nakamichi na3605 fitur dan keunggulan
    # Rank: Build dari nol  (hanya 1 hasil, rank 2-5 tidak ada = 0)
    "P03": [1, 0, 0, 0, 0],

    # P04: hertz dieci speaker component DCX 165.3
    # Rank: Distorsi, Speaker OEM jelek, Kompetisi, Soundstage, Bass
    "P04": [1, 2, 0, 1, 0],

    # P05: JVC KD-X371BT head unit bluetooth
    # Rank: HU Bluetooth, Keluarga, Install kabel, Build dari nol, Bass
    "P05": [2, 0, 0, 1, 0],

    # P06: subwoofer rockford fosgate punch p3
    # Rank: Kompetisi, Bass kurang, Distorsi, Speaker OEM, Bass contained
    "P06": [2, 2, 0, 0, 1],

    # P07: tweeter JL Audio C1 075ct
    # Rank: Speaker OEM, Soundstage, Vocal mid range, Distorsi, Install kabel
    "P07": [1, 2, 2, 0, 0],

    # ── Konseptual & Edukatif ──────────────────────────────────────────────
    # C01: apa fungsi head unit di sistem audio mobil?
    # Rank: HU Bluetooth, Upgrade single→double DIN, Audio trouble panas, Keluarga, Build dari nol
    "C01": [2, 2, 1, 0, 1],

    # C02: perbedaan speaker coaxial dan speaker component
    # Rank: Distorsi, Speaker OEM, Install kabel, Vocal mid range, Soundstage
    "C02": [1, 2, 1, 2, 1],

    # C03: kenapa bass mobil tidak terasa nendang padahal sudah pasang subwoofer?
    # Rank: Bass kurang, Soundstage, Vocal mid range, Speaker OEM, Bass contained
    "C03": [2, 1, 0, 0, 1],

    # C04: cara upgrade audio mobil untuk pemula dengan budget terbatas
    # Rank: Budget terbatas, Build dari nol, Install kabel, Speaker OEM, Upgrade single→double DIN
    "C04": [2, 2, 1, 1, 1],

    # C05: apa itu DSP digital signal processor dalam audio mobil?
    # Rank: Build dari nol, Upgrade single→double DIN, Distorsi, Kompetisi, Audio trouble panas
    "C05": [1, 0, 1, 0, 0],

    # C06: perbedaan subwoofer sealed box dan ported box untuk kualitas bass
    # Rank: Bass kurang, Soundstage, Distorsi, Bass contained, Kompetisi
    "C06": [2, 1, 0, 2, 1],

    # C07: cara menghilangkan noise suara dengung di audio mobil
    # Rank: Distorsi, Speaker OEM, Audio trouble panas, Install kabel, Kompetisi
    "C07": [2, 0, 1, 0, 0],

    # C08: mengapa suara speaker mobil pecah distorsi saat volume tinggi?
    # Rank: Distorsi, Speaker OEM, Audio trouble panas, Kompetisi, Soundstage
    "C08": [2, 1, 0, 0, 0],

    # ── Berbasis Kendaraan ─────────────────────────────────────────────────
    # V01: rekomendasi upgrade audio untuk Mitsubishi Xpander
    # Rank: Budget terbatas, Install kabel, Build dari nol, Speaker OEM, Keluarga
    "V01": [2, 1, 2, 2, 1],

    # V02: speaker yang cocok untuk Honda Brio city car
    # Rank: Speaker OEM, Keluarga, Bass contained, Build dari nol, Install kabel
    "V02": [2, 1, 1, 1, 1],

    # V03: subwoofer terbaik untuk Toyota Avanza MPV
    # Rank: Speaker OEM, Kompetisi, Bass kurang, Keluarga, Build dari nol
    "V03": [1, 0, 2, 1, 1],

    # V04: setup audio lengkap untuk Toyota Fortuner SUV
    # Rank: Build dari nol, Install kabel, Keluarga, Upgrade single→double DIN, Speaker OEM
    "V04": [2, 1, 1, 1, 1],

    # V05: upgrade head unit android untuk Honda Jazz
    # Rank: Upgrade single→double DIN, Speaker OEM, HU Bluetooth, Budget, Install kabel
    "V05": [2, 0, 1, 1, 1],

    # V06: rekomendasi audio system untuk Suzuki Ertiga
    # Rank: Keluarga, Kompetisi, Build dari nol, Budget, Install kabel
    "V06": [2, 0, 2, 1, 1],

    # V07: tweeter dan speaker depan untuk Hyundai Stargazer
    # Rank: Speaker OEM, Upgrade single→double DIN, Install kabel, Vocal mid range, Keluarga
    "V07": [2, 0, 1, 2, 0],
}


def main():
    df = pd.read_excel(ANNOTATION_FILE, sheet_name="Anotasi")

    for idx, row in df.iterrows():
        qid = row["query_id"]
        if qid not in ANNOTATIONS:
            continue
        rels = ANNOTATIONS[qid]
        for rank, val in enumerate(rels, 1):
            if val is not None:
                df.at[idx, f"rel_{rank}"] = val
            # Jika None, biarkan kosong (result tidak ada)

    # Baca sheet Petunjuk agar tidak hilang
    petunjuk_df = pd.read_excel(ANNOTATION_FILE, sheet_name="Petunjuk")

    with pd.ExcelWriter(ANNOTATION_FILE, engine="openpyxl") as writer:
        df.to_excel(writer, sheet_name="Anotasi", index=False)
        petunjuk_df.to_excel(writer, sheet_name="Petunjuk", index=False)

    print(f"✅ Anotasi berhasil diisi untuk {len(ANNOTATIONS)} kueri")
    print(f"   File: {ANNOTATION_FILE}")

    # Verifikasi — tampilkan ringkasan nilai
    print("\nRingkasan nilai relevansi per kueri:")
    for qid, rels in ANNOTATIONS.items():
        clean = [str(r) if r is not None else "-" for r in rels]
        print(f"  {qid}: [{', '.join(clean)}]")


if __name__ == "__main__":
    main()
