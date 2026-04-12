# AudioMatch - Implementation Summary

## ✅ Files Created/Modified

### 1. **migration.sql** - Database Migration (Run First!)
- Migrates database dari 6 tables → 2 tables
- **Otomatis migrate existing data** (problems, solutions, products)
- Preserves semua embeddings yang sudah ada
- Drop tabel lama yang tidak diperlukan

**Usage:**
```bash
psql -d your_database -f migration.sql
```

---

### 2. **data_lengkap.sql** - Complete Data Insert (Run After Migration)
Berisi data lengkap dengan **produk real Indonesia**:

#### **10 Problems:**
1. Bass kurang bertenaga
2. Vocal dan mid range kurang jelas
3. Suara pecah dan distorsi di volume tinggi
4. Soundstage sempit, suara terasa datar
5. Ingin upgrade audio tapi budget terbatas
6. Head Unit tidak bisa connect Bluetooth
7. Ingin audio lebih keras untuk kompetisi/SPL
8. Ingin suara natural dan original seperti studio
9. Speaker bawaan mobil jelek, mau ganti
10. Build sistem audio baru dari nol

#### **30+ Products dari Brand Real:**

**Head Unit Android (7):**
- Exxent X10 10 inch - Rp 3.500.000
- Skeleton SK-808 8 inch - Rp 2.200.000
- DHD H-9500 9 inch - Rp 2.800.000
- Avix AV-1050 10 inch - Rp 3.200.000
- Clarion CZ209 9 inch - Rp 4.500.000
- Nakamichi NQ915 9 inch - Rp 4.200.000
- Orca OR-770 7 inch - Rp 1.800.000

**Head Unit Single DIN (3):**
- Pioneer DEH-S5250BT - Rp 1.650.000
- Kenwood KMM-205 - Rp 1.350.000
- JVC KD-X265BT - Rp 1.250.000

**Head Unit Double DIN (2):**
- Pioneer DMH-G225BT - Rp 3.800.000
- Kenwood DMX4707S - Rp 4.200.000

**Speaker Coaxial (4):**
- Pioneer TS-A1670F 6.5" - Rp 850.000
- Kenwood KFC-S1366 5.25" - Rp 550.000
- JVC CS-J620U 6.5" - Rp 650.000
- Nakamichi NXC62 6.5" - Rp 1.200.000

**Speaker Component/Split (4):**
- Pioneer TS-Z170C 6.5" 2-Way - Rp 2.800.000
- Kenwood KFC-XS1704 6.5" 2-Way - Rp 1.800.000
- JVC CS-HX1304 6.5" 2-Way - Rp 1.500.000
- Nakamichi NCS1654 6.5" 2-Way - Rp 3.200.000

**Subwoofer (5):**
- Pioneer TS-WX130EA 8" Aktif - Rp 2.200.000
- Rockford Fosgate P300-10 10" Aktif - Rp 3.500.000
- JL Audio 10TW3-D4 10" Passive - Rp 4.500.000
- Skeleton SKW-1229 12" Passive - Rp 1.500.000
- Nakamichi NRSW104 10" Passive - Rp 2.800.000

**Amplifier (5):**
- Pioneer GM-A5702 4 Channel - Rp 2.200.000
- Kenwood KAC-M3004 4 Channel - Rp 1.900.000
- JVC KS-AX302 2 Channel - Rp 1.200.000
- Hertz HCP4D 4 Channel - Rp 4.500.000
- Soundstream TA5.2000D Mono Block - Rp 3.200.000

**Usage:**
```bash
psql -d your_database -f data_lengkap.sql
```

---

### 3. **chat.py** - Updated System Prompt
Ditambahkan kemampuan:
- ✅ **Product Comparison**: Bisa bandingkan produk berdasarkan price, features, power, quality
- ✅ **Budget-based Recommendation**: Rekomendasi sesuai budget user
- ✅ **Brand Positioning Knowledge**:
  * Budget: Skeleton, DHD, Avix, Orca
  * Mid-range: Pioneer, Kenwood, JVC, Exxent
  * Premium: Nakamichi, Clarion, Hertz, JL Audio, Rockford Fosgate

---

## 📋 Complete Setup Steps

### Step 1: Run Migration
```bash
psql -d "your_database_connection_string" -f migration.sql
```

### Step 2: Insert Data
```bash
psql -d "your_database_connection_string" -f data_lengkap.sql
```

### Step 3: Install Dependencies
```bash
pip install -r requirements.txt
```

### Step 4: Sync Embeddings
```bash
curl -X POST http://localhost:8000/api/v1/admin/sync-embeddings
```

### Step 5: Test Chatbot
```bash
# Test problem query
curl -X POST http://localhost:8000/api/v1/chat/ \
  -H "Content-Type: application/json" \
  -d '{"message": "Bass mobil kurang bertenaga, solusinya apa?"}'

# Test budget query
curl -X POST http://localhost:8000/api/v1/chat/ \
  -H "Content-Type: application/json" \
  -d '{"message": "Budget 2 juta mau upgrade speaker, apa yang bagus?"}'

# Test comparison query
curl -X POST http://localhost:8000/api/v1/chat/ \
  -H "Content-Type: application/json" \
  -d '{"message": "Bandingken Pioneer vs Nakamichi, mana lebih bagus?"}'

# Test specific product query
curl -X POST http://localhost:8000/api/v1/chat/ \
  -H "Content-Type: application/json" \
  -d '{"message": "Subwoofer Rockford Fosgate P300-10 bagus gak?"}'
```

---

## 🎯 Chatbot Capability

### ✅ What Chatbot CAN Do:
1. **Problem Matching**: "Bass mobil kurang" → recommend subwoofers
2. **Budget Recommendation**: "Budget 1.5 juta buat speaker" → show options within budget
3. **Product Comparison**: "Pioneer vs Nakamichi mana lebih bagus?" → compare based on data
4. **Specific Product Info**: "Jelasin subwoofer Rockford Fosgate P300" → details from database
5. **Brand Comparison**: "Mending Exxent atau DHD?" → explain brand positioning
6. **Upgrade Path**: "Mau upgrade bertahap dari mana dulu?" → step-by-step guide

### ❌ What Chatbot CANNOT Do (by design):
- General car audio knowledge outside database
- Installation instructions (unless in recommended_approach)
- Technical wiring diagrams
- Warranty claims process

---

## 📊 Database Schema (After Migration)

```
master_customer_problems (10 rows)
├── mcp_id (UUID, PK)
├── mcp_problem_title
├── mcp_description
├── mcp_recommended_approach (merged from solutions)
├── mcp_embedding (vector 1024)
└── mcp_is_active

master_products (30+ rows)
├── mp_id (UUID, PK)
├── mp_name
├── mp_category
├── mp_brand
├── mp_price
├── mp_description
├── mp_image
├── mp_solves_problem_id (FK → master_customer_problems)
├── mp_embedding (vector 1024)
└── mp_is_active
```

---

## 💡 Example User Queries & Expected Responses

### Query 1: Problem-based
**User:** "Bass mobil kurang bertenaga, solusinya apa?"

**Expected:** 
- Match problem "Bass kurang bertenaga"
- Show recommended products: subwoofers, amplifiers
- Explain approach: "Tambah subwoofer 10-12 inch dengan amplifier dedicated..."
- List options with prices

---

### Query 2: Budget-based
**User:** "Budget 2 juta mau upgrade speaker"

**Expected:**
- Show speakers within 2 juta range
- Kenwood KFC-S1366 (Rp 550.000)
- JVC CS-J620U (Rp 650.000)
- Pioneer TS-A1670F (Rp 850.000)
- Explain trade-offs

---

### Query 3: Brand Comparison
**User:** "Mending Exxent atau DHD head unit?"

**Expected:**
- Compare Exxent X10 (Rp 3.5jt) vs DHD H-9500 (Rp 2.8jt)
- Exxent: 10 inch, RAM 4GB, wireless CarPlay, DSP 16 band
- DHD: 9 inch IPS, DSP 32 band, wireless Android Auto
- Recommendation based on use case

---

### Query 4: Product-specific
**User:** "Jelasin subwoofer Rockford Fosgate P300-10"

**Expected:**
- Show product details
- Price: Rp 3.500.000
- 10 inch aktif, 300W RMS
- Built-in amplifier, tinggal pasang
- Solves: "Bass kurang bertenaga"

---

## 🚀 Next Steps untuk Enhancement

1. **Add More Products**: Import via CSV menggunakan endpoint `/api/v1/admin/import-data/products`
2. **Add More Problems**: Import via `/api/v1/admin/import-data/problems`
3. **Product Images**: Update `mp_image` dengan URL gambar real
4. **Price Updates**: Update prices sesuai harga terkini
5. **Categories**: Refine categories untuk filtering lebih detail

---

## 📝 Notes

- Semua harga dalam Rupiah (IDR)
- Products linked ke problems via `mp_solves_problem_id`
- Embeddings perlu di-sync setelah insert data baru
- Chatbot menggunakan vector similarity untuk match problems
- Response di-generate oleh Gemini berdasarkan database context
