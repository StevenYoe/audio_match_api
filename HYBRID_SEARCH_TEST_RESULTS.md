# HYBRID SEARCH - TEST RESULTS & ISSUES FOUND

## ✅ HYBRID SEARCH STATUS: WORKING

Migration `004_hybrid_search.sql` sudah berhasil diimplementasikan dan berfungsi dengan baik.

### Database Functions Created:
- ✅ `search_problem_hybrid` - Hybrid search untuk customer problems
- ✅ `search_product_hybrid` - Hybrid search untuk products
- ✅ `search_problem_hybrid_simple` - Wrapper sederhana
- ✅ `search_product_hybrid_simple` - Wrapper sederhana

### Database Indexes Created:
- ✅ `idx_problems_fts_title_desc` - GIN index pada problems
- ✅ `idx_products_fts_name_desc` - GIN index pada products
- ✅ `mcp_search_vector` - Generated tsvector column
- ✅ `mp_search_vector` - Generated tsvector column

### BM25 FTS Test Results:
✅ **Berhasil match dengan sempurna:**
- "bass" → "Bass kurang bertenaga" (score: 0.3000)
- "bluetooth" → "Head Unit tidak bisa connect Bluetooth" (score: 0.2000)
- "vocal" → "Vocal dan mid range kurang jelas" (score: 0.2000)
- "distorsi" → "Suara pecah dan distorsi" (score: 0.2000)
- "Kenwood" → 5 produk Kenwood (score: 0.2000)
- "subwoofer" → Subwoofer products (score: 0.3000)
- "double DIN" → Double DIN head units (score: 0.3256)

---

## ❌ ISSUES FOUND IN CHATBOT LOGIC

### Issue #1: Brand Query Hanya Tampil 1 Produk

**Problem:**
- User: "Cari produk Kenwood"
- Chatbot hanya menampilkan 1 produk (Speaker Coaxial Kenwood KFC-S1366)
- Padahal database punya **12 produk Kenwood** di semua kategori

**Root Cause:**
Di `chat.py`, flow logic:
1. STEP 2A: Check car mention → Skip (no car)
2. STEP 2B: Hybrid search problem → Match "Speaker bawaan mobil jelek"
   - Query "Cari produk Kenwood" secara vector mirip dengan problem speaker
3. Get recommendations → Dapat produk yang linked ke problem tersebut
4. Karena `recommendations` sudah terisi, STEP Fallback **TIDAK DIJALANKAN**
5. Result: Hanya tampil produk yang linked ke "Speaker bawaan mobil jelek"

**Database Fact:**
- 12 Kenwood products di database:
  - 2 Amplifier
  - 2 Head Unit Android
  - 2 Head Unit Double DIN
  - 2 Head Unit Single DIN
  - 1 Speaker Coaxial
  - 1 Speaker Component
  - 1 Subwoofer
  - 1 Tweeter

**Expected Behavior:**
- Ketika user sebut brand ("Kenwood"), harusnya masuk ke **BRAND FALLBACK** logic
- Tampilkan SEMUA produk Kenwood di semua kategori
- Organize by category: Head Unit, Speaker, Subwoofer, Amplifier, Tweeter

---

### Issue #2: Tweeter Tidak Direkomendasikan untuk Vocal Problem

**Problem:**
- User: "Vocal tidak jelas"
- Chatbot hanya rekomendasikan speaker component
- Tidak rekomendasikan tweeter, padahal tweeter spesialis untuk vocal/frekuensi tinggi

**Database Fact:**
- Tweeter Kenwood KFC-ST1 **SUDAH linked** ke vocal problem (ID: d71440dd)
- Tweeter Hertz MPX 170.30 linked ke soundstage problem
- `get_recommendations()` mengembalikan 12 produk termasuk tweeter

**Expected Behavior:**
- Untuk vocal problem, rekomendasi seharusnya:
  1. **Tweeter** (prioritas utama untuk vocal)
  2. Speaker Component 2-way (dengan tweeter terpisah)
  3. Amplifier (untuk power tweeter)

**Current Behavior:**
- Chatbot hanya tampilkan speaker component
- Tweeter ada di context tapi tidak di-highlight sebagai solusi utama

**Possible Causes:**
1. LLM tidak di-instruct secara eksplisit tentang prioritas category
2. Context tidak menekankan bahwa tweeter = vocal solution
3. Chatbot meng-organize by category tapi tidak prioritize tweeter untuk vocal

---

## 🔧 RECOMMENDED FIXES

### Fix #1: Prioritize Brand Search Over Problem Match

**File:** `app/api/v1/endpoints/chat.py`

**Current Logic:**
```python
# STEP 2B: Problem hybrid search
if not recommendations:
    problems = await db.search_problem_hybrid(...)
    if problems:
        recommendations = [...]  # Set recommendations

# Fallback: Brand search
if not recommendations:
    if mentioned_brands:
        brand_products = await db.search_product_hybrid(...)
```

**Fixed Logic:**
```python
# STEP 2B: Check for BRAND mention FIRST (before problem search)
query_lower = search_query.lower()
known_brands = ['kenwood', 'pioneer', 'jvc', ...]
mentioned_brands = [brand for brand in known_brands if brand in query_lower]

if mentioned_brands:
    # Brand query - go directly to brand fallback
    logger.info(f"Brand detected: {mentioned_brands}, skipping problem search")
else:
    # Problem query - use hybrid search
    if not recommendations:
        problems = await db.search_problem_hybrid(...)
        if problems:
            recommendations = [...]
```

**Rationale:**
- Ketika user explicitly sebut brand, itu bukan problem query
- Harus langsung masuk ke brand product listing
- Problem search hanya untuk query yang mendeskripsikan masalah

---

### Fix #2: Enhance System Prompt for Tweeter/Vocal

**File:** `app/api/v1/endpoints/chat.py` (system_prompt)

**Add to prompt:**
```
PRODUCT CATEGORY GUIDE:
- **TWEETER**: Specialist untuk vocal, detail suara, dan frekuensi tinggi (2kHz-24kHz). 
  ALWAYS recommend tweeter untuk masalah: "vocal tidak jelas", "suara datar", 
  "soundstage sempit", "detail kurang", "treble kurang".
- **SPEAKER COMPONENT 2-WAY**: Solusi upgrade speaker dengan tweeter terpisah. 
  Bagus untuk vocal DAN soundstage.
- **SPEAKER COAXIAL**: Upgrade plug-and-play dari speaker bawaan. All-in-one.
- **SUBWOOFER**: Specialist untuk bass, low frequency (20Hz-200Hz).
- **AMPLIFIER**: Power booster untuk semua speaker/subwoofer.

PRIORITAS REKOMENDASI:
- Vocal/Mid range masalah: Tweeter → Component Speaker → Amplifier
- Bass masalah: Subwoofer → Amplifier → Speaker
- Soundstage/Staging: Tweeter → Component Speaker → DSP/Head Unit
- Distorsi: Speaker Component → Amplifier → Head Unit
- Bluetooth/Connectivity: Head Unit dengan Bluetooth
```

---

### Fix #3: Update Tweeter Linkages

**SQL Migration:**
```sql
-- Tweeter Hertz MPX 170.30 should ALSO solve vocal problem
UPDATE sales.master_products
SET mp_solves_problem_id = 'd71440dd-5d04-4bf2-a4ca-c630d21063cc'
WHERE mp_name = 'Tweeter Hertz Mille Pro MPX 170.30';

-- Or better: Add tweeter as secondary solution via tags/keywords
-- (if you want multiple problem linkages per product)
```

---

## 📋 TEST QUERIES FOR VERIFICATION

### Test Brand Query:
```
User: "Cari produk Kenwood"
Expected: Show ALL 12 Kenwood products organized by category
- Head Unit (4 products)
- Speaker (2 products)
- Subwoofer (1 product)
- Amplifier (2 products)
- Tweeter (1 product)
```

### Test Vocal Problem:
```
User: "Vocal tidak jelas"
Expected: Prioritize tweeter + component speakers
1. Tweeter Kenwood KFC-ST1 (highlight: specialist vocal)
2. Speaker Component 2-way (with tweeter terpisah)
3. Amplifier (for power)
```

### Test Tweeter Specific:
```
User: "Cari tweeter"
Expected: Show all tweeter products
- Tweeter Kenwood KFC-ST1 - Rp 350.000
- Tweeter Hertz Mille Pro MPX 170.30 - Rp 2.200.000
```

---

## 🎯 CONCLUSION

✅ **Hybrid Search Migration**: SUCCESSFULLY IMPLEMENTED
✅ **BM25 Full-Text Search**: WORKING PERFECTLY
❌ **Chatbot Logic**: NEEDS FIXES for brand queries & tweeter recommendations

**Priority Fixes:**
1. **HIGH**: Brand query logic (Fix #1) - Kenwood harus tampil semua produk
2. **HIGH**: Tweeter recommendation (Fix #2) - Vocal = tweeter priority
3. **MEDIUM**: Tweeter problem linkage (Fix #3) - Link tweeter ke vocal problem
