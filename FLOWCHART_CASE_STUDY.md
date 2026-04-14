# AudioMatch API - Real Case Study Flowchart

## 📋 Case: Stargazer Audio Recommendation (High-End vs Mid-Range)

### User Question:
> "rekomendasi audio untuk mobil stargazer, berikan saya 2 opsi, opsi satu high end dan opsi kedua mid range"

---

## Complete Process Flowchart

```mermaid
graph TB
    A([👤 User: Rekomendasi audio untuk Stargazer, 2 opsi high-end & mid-range]) --> B[POST /api/v1/chat/]
    
    B --> C{Session ID Valid?}
    C -->|No| D[Generate New UUID]
    D --> E[Initialize Empty History]
    
    E --> F[Get Current Time: 14:30 WIB]
    F --> G[Analyze Message: Extract Keywords]
    
    G --> H{Detect Car Mention}
    H -->|Found: stargazer| I[Lookup Car Database]
    
    I --> J[Match: Hyundai Stargazer, MPV]
    J --> K[Retrieve Car Specs from Database]
    
    K --> L[Car Details]
    L --> L1[Type: MPV]
    L --> L2[Size: Medium/Large]
    L --> L3[Dashboard: Double DIN]
    L --> L4[Subwoofer Space: Box/Lega]
    L --> L5[Factory Speaker: Standard]
    
    L1 --> M[Call: get_products_for_car]
    L2 --> M
    L3 --> M
    L4 --> M
    
    M --> N[SQL: Filter by Type=MPV, Size=Medium]
    N --> O[Get Compatible Products]
    
    O --> P[Products Retrieved: 111 Active Products]
    P --> Q[Filter: Compatible with MPV]
    
    Q --> R[Group Products by Category]
    R --> R1[Head Unit Android: 22 products]
    R --> R2[Speaker Component: 14 products]
    R --> R3[Speaker Coaxial: 14 products]
    R --> R4[Subwoofer: 15 products]
    R --> R5[Amplifier 4ch: 7 products]
    R --> R6[Amplifier Mono: 4 products]
    R --> R7[Processor DSP: 3 products]
    
    R1 --> S[Sort by Brand Tier & Price]
    R2 --> S
    R3 --> S
    R4 --> S
    R5 --> S
    R6 --> S
    R7 --> S
    
    S --> T[Tier 1 Premium: Nakamichi, JL Audio, Rockford, Hertz, JBL]
    S --> U[Tier 2 Mid: Pioneer, Kenwood, JVC, Exxent]
    S --> V[Tier 3 Budget: Venom, DHD, Skeleton]
    
    T --> W[Build Car Context String]
    U --> W
    V --> W
    
    W --> X[Context Structure]
    X --> X1[RECOMMENDED FOR: HYUNDAI STARGAZER MPV]
    X --> X2[Dashboard: Double DIN]
    X --> X3[Subwoofer Space: Box/Lega]
    X --> X4[Products by Category with Prices]
    
    X1 --> Y[Inject into System Prompt]
    X2 --> Y
    X3 --> Y
    X4 --> Y
    
    Y --> Z[System Prompt Assembly]
    Z --> Z1[Identity: AudioMatch Expert]
    Z --> Z2[Time: 14:30 WIB]
    Z --> Z3[Critical Rules: NO hallucination, USE only database]
    Z --> Z4[Car Rules: MPV = full system possible]
    Z --> Z5[Budget Rules: High >10jt = premium, Mid 5-10jt = mid-range]
    Z --> Z6[Format Rules: Markdown, numbered lists, Rp prices]
    Z --> Z7[Database Context: All 111 products listed]
    
    Z1 --> AA[Add Conversation History]
    Z2 --> AA
    Z3 --> AA
    Z4 --> AA
    Z5 --> AA
    Z6 --> AA
    Z7 --> AA
    
    AA --> AB[History: Empty - First Message]
    AB --> AC[Add Current User Message]
    
    AC --> AD[Format for Gemini API]
    AD --> AD1[System Instruction: Full Prompt]
    AD --> AD2[Contents: User Message]
    
    AD1 --> AE[Build Payload]
    AD2 --> AE
    
    AE --> AE1[system_instruction: {rules + context}]
    AE --> AE2[contents: [{role: user, parts: [{text: message}]}]]
    AE --> AE3[generationConfig: {maxTokens: 8192, temp: 0.1}]
    
    AE1 --> AF[POST to Gemini API]
    AE2 --> AF
    AE3 --> AF
    
    AF --> AG[generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent]
    
    AG --> AH{HTTP Status?}
    AH -->|200 OK| AI[Parse Response]
    AH -->|429/5xx| AJ[Retry - Exponential Backoff]
    AJ --> AF
    
    AI --> AK[Extract: candidates[0].content.parts[0].text]
    AK --> AL[LLM Response Text - 3000+ characters]
    
    AL --> AM[AI Generates Response Based on Prompt]
    AM --> AM1[Detects: User wants 2 options for Stargazer]
    AM --> AM2[Option 1 High-End: Select Premium Brands]
    AM --> AM3[Option 2 Mid-Range: Select Mid-Range Brands]
    
    AM1 --> AN[Build Recommendation Packages]
    AM2 --> AN
    AM3 --> AN
    
    AN --> AN1[High-End Package]
    AN --> AN1a[Head Unit: Nakamichi Legend Pro 12 Rp 11.1jt]
    AN --> AN1b[Speaker Component: JBL Stadium 62F Rp 3.7jt]
    AN --> AN1c[Speaker Coaxial: Hertz Diecec K 165 Rp 1.8jt]
    AN --> AN1d[Subwoofer: JL Audio 10W3V3-4 Rp 8.7jt]
    AN --> AN1e[Amp 4ch: Rockford R2-500x4 Rp 4.8jt]
    AN --> AN1f[Amp Mono: Rockford T500.1BD Rp 5.5jt]
    AN --> AN1g[Processor: Venom VPR 3.6 DSP Rp 4.2jt]
    AN1a --> AN1h[Total: Rp 40.8jt]
    AN1b --> AN1h
    AN1c --> AN1h
    AN1d --> AN1h
    AN1e --> AN1h
    AN1f --> AN1h
    AN1g --> AN1h
    
    AN --> AN2[Mid-Range Package]
    AN --> AN2a[Head Unit: Nakamichi Saga NA-3102i Rp 2.08jt]
    AN --> AN2b[Speaker Component: Hertz K 165 UNO Rp 1.62jt]
    AN --> AN2c[Speaker Coaxial: Pioneer TS-A1670F Rp 850rb]
    AN --> AN2d[Subwoofer: JBL Stage2 124B Rp 1.5jt]
    AN --> AN2e[Amp 4ch: Venom VO 406 MKII Rp 1.71jt]
    AN --> AN2f[Amp Mono: Venom V1500XD Rp 1.5jt]
    AN2a --> AN2g[Total: Rp 9.26jt]
    AN2b --> AN2g
    AN2c --> AN2g
    AN2d --> AN2g
    AN2e --> AN2g
    AN2f --> AN2g
    
    AN1h --> AO[Format Response with Markdown]
    AN2g --> AO
    
    AO --> AO1[### Header Sections]
    AO --> AO2[**Bold** Product Names]
    AO --> AO3[Numbered Lists]
    AO --> AO4[Harga: Rp X format]
    AO --> AO5[Penjelasan per produk]
    
    AO1 --> AP[Final Response Text]
    AO2 --> AP
    AO3 --> AP
    AO4 --> AP
    AO5 --> AP
    
    AP --> AQ[Append User Message to History]
    AP --> AR[Append Assistant Response to History]
    
    AQ --> AS[Save Session to Redis]
    AR --> AS
    
    AS --> AS1[Key: session:{uuid}]
    AS --> AS2[Value: {history: [{user msg}, {assistant msg}]}]
    AS --> AS3[TTL: 86400s 24 hours]
    
    AS1 --> AT[Build ChatResponse JSON]
    AS2 --> AT
    AS3 --> AT
    
    AT --> AT1[session_id: uuid]
    AT --> AT2[response: AI text 3000+ chars]
    AT --> AT3[recommendations: [{solution + products}]]
    
    AT1 --> AU([📤 Return JSON to User])
    AT2 --> AU
    AT3 --> AU
    
    style C fill:#ff9
    style H fill:#ff9
    style N fill:#9cf
    style S fill:#ff9
    style AH fill:#ff9
    style AF fill:#f9f
    style AM fill:#f9f
    style AS fill:#9cf
    style AU fill:#9f9
    
    classDef decision fill:#ff9,stroke:#333
    classDef database fill:#9cf,stroke:#333
    classDef ai fill:#f9f,stroke:#333
    classDef success fill:#9f9,stroke:#333
```

---

## Detailed Step-by-Step Breakdown

### Step 1: Message Reception & Session Check

```
Input: POST /api/v1/chat/
{
  "message": "rekomendasi audio untuk mobil stargazer, berikan saya 2 opsi, opsi satu high end dan opsi kedua mid range"
}
```

**Process:**
- Check if session_id provided → No (first message)
- Generate new UUID: `abc-123-def-456-ghi`
- Initialize empty history: `[]`
- Get current time: `14:30` (Asia/Jakarta WIB)

---

### Step 2: Car Detection

**Message Analysis:**
```python
text_lower = "rekomendasi audio untuk mobil stargazer, berikan saya 2 opsi..."
```

**Keyword Matching:**
```python
car_keywords = {
    'stargazer': ('Hyundai', 'Stargazer', 'MPV')  # ✅ MATCH!
}
```

**Result:**
```python
{
    'brand': 'Hyundai',
    'model': 'Stargazer',
    'type': 'MPV'
}
```

---

### Step 3: Car Specification Retrieval

**Database Query:**
```sql
SELECT * FROM sales.search_car('Hyundai', 'Stargazer')
```

**Car Details Retrieved:**
```
mc_id: uuid-xyz
mc_brand: Hyundai
mc_model: Stargazer
mc_type: MPV
mc_size_category: medium
mc_dashboard_type: double_din
mc_subwoofer_space: boxed
mc_cabin_volume: luas
mc_factory_speaker_size: 6.5 inch
mc_special_notes: "MPV modern dengan kabin luas"
```

---

### Step 4: Get Compatible Products

**Database Query:**
```sql
SELECT * FROM sales.get_products_for_car(
    car_type = 'MPV',
    car_size = 'medium'
)
```

**Products Retrieved (111 total, filtered to MPV-compatible):**

| Category | Count | Examples |
|----------|-------|----------|
| Head Unit Android | 22 | Nakamichi Legend Pro 12, Nakamichi Saga, Kenwood, Pioneer |
| Speaker Component | 14 | JBL Stadium 62F, Hertz K 165 UNO, Pioneer TS series |
| Speaker Coaxial | 14 | Hertz Dieci K 165, Pioneer TS-A1670F, JBL |
| Subwoofer | 15 | JL Audio 10W3V3-4, JBL Stage2 124B, Rockford Fosgate |
| Amplifier 4ch | 7 | Rockford R2-500x4, Venom VO 406 MKII |
| Amplifier Mono | 4 | Rockford T500.1BD, Venom V1500XD |
| Processor DSP | 3 | Venom VPR 3.6 DSP |

---

### Step 5: Sort & Group Products

**Sorting Strategy:**
```
Tier 1 (Premium) - Price DESC:
  - JL Audio 10W3V3-4: Rp 8.715.000
  - Rockford Fosgate T500.1BD: Rp 5.500.000
  - JBL Stadium 62F: Rp 3.733.000
  - Nakamichi Legend Pro 12: Rp 11.100.000
  - Hertz Dieci K 165: Rp 1.800.000

Tier 2 (Mid-Range) - Price DESC:
  - Pioneer TS-A1670F: Rp 850.000
  - Nakamichi Saga NA-3102i: Rp 2.080.000
  - Hertz K 165 UNO: Rp 1.620.000

Tier 3 (Budget) - Price DESC:
  - Venom VO 406 MKII: Rp 1.710.000
  - Venom V1500XD: Rp 1.500.000
  - Venom VPR 3.6 DSP: Rp 4.200.000
```

---

### Step 6: Build Context String

```
RECOMMENDED FOR: HYUNDAI STARGAZER (MPV, medium cabin)
Dashboard: Double DIN
Cabin Volume: Luas
Subwoofer Space: Boxed
Factory Speaker: 6.5 inch (standard)

COMPATIBLE PRODUCTS (organized by category, best match first):

[HEAD UNIT ANDROID]
Opsi 1. Nakamichi Legend Pro 12 9 inch 12/256GB - Rp 11100000
   Head unit Android flagship dengan QLED 9 inch, RAM 12GB, storage 256GB, DSP 48-band
Opsi 2. Nakamichi Saga NA-3102i 9 inch 4/64GB - Rp 2080000
   Head unit Android 9 inch QLED dengan CarPlay & Android Auto wireless

[SPEAKER COMPONENT]
Opsi 3. JBL Stadium 62F 6.5 inch 2-Way - Rp 3733000
   Speaker component flagship 2-way, RMS 100W, Hi-Res capable
Opsi 4. Hertz K 165 UNO 6.5 inch 2-Way - Rp 1620000
   Speaker component 2-way, RMS 75W

[SPEAKER COAXIAL]
Opsi 5. Hertz Dieci K 165 6.5 inch - Rp 1800000
   Speaker coaxial premium 2-way
Opsi 6. Pioneer TS-A1670F 6.5 inch 3-Way - Rp 850000
   Speaker coaxial 3-way, RMS 70W

[SUBWOOFER]
Opsi 7. JL Audio 10W3V3-4 10 inch - Rp 8715000
   Subwoofer passive flagship 10 inch
Opsi 8. JBL Stage2 124B 12 inch - Rp 1500000
   Subwoofer passive 12 inch

[AMPLIFIER 4 CHANNEL]
Opsi 9. Rockford Fosgate R2-500x4 - Rp 4800000
   Amplifier 4 channel, 125W RMS x 4 @ 4 ohm
Opsi 10. Venom VO 406 MKII Diablo - Rp 1710000
   Amplifier 4 channel, 80W x 4 @ 4 ohm

[AMPLIFIER MONOBLOK]
Opsi 11. Rockford Fosgate T500.1BD - Rp 5500000
   Amplifier monoblok flagship, 500W RMS @ 2 ohm
Opsi 12. Venom V1500XD - Rp 1500000
   Amplifier monoblok, 500W RMS @ 2 ohm

[PROCESSOR DSP]
Opsi 13. Venom VPR 3.6 DSP - Rp 4200000
   Processor DSP 6 channel dengan 31-band EQ
```

---

### Step 7: Build System Prompt

```python
system_prompt = """
You are AudioMatch Expert, a car audio product recommendation assistant.
Time: 14:30 (WIB).

CRITICAL RULES:
- You MUST ONLY recommend products that appear in the DATABASE CONTEXT below.
- NEVER invent, hallucinate, or suggest products that are not explicitly listed in the context.
- If NO products are found in the context, say "Saya tidak menemukan produk..."
- Do NOT make up product names, prices, or specifications.

RULES:
- Help users find the right products based on their problems, budget, car type, or questions.
- If user mentions a SPECIFIC CAR MODEL (e.g., "Stargazer"):
  * ALWAYS prioritize products shown in the "RECOMMENDED FOR" section
  * Explain WHY each product is suitable for that specific car
  * Consider cabin size, dashboard type, subwoofer space limitations
  * For MPV (Stargazer, Avanza, Xpander): Full system possible
    - Head Unit Android 9-10" (double DIN)
    - Speaker component 6.5" front, coaxial 6x9" rear
    - Subwoofer 10-12" boxed (trunk space available)
    - Amplifier 4 channel 75W+

- If user mentions BUDGET:
  * For HIGH BUDGET (above 10 juta): RECOMMEND ALL products from the context including premium brands
    (JL Audio, Rockford Fosgate, Hertz, Nakamichi, Clarion, JBL)
  * For MEDIUM BUDGET (5-10 juta): Focus on mid-range brands (Pioneer, Kenwood, JVC, Exxent) but also mention premium options
  * Recommend products within their budget range
  * Mention "Harga: Rp [price]" for each product

- If user asks for PACKAGE/PAKET recommendations:
  * Include products from MULTIPLE categories to form a complete system
  * Example: Head Unit + Speaker Depan + Speaker Belakang + Subwoofer + Amplifier
  * Calculate total package price and mention it
  * Explain what each component contributes to the system

- Use Markdown formatting:
  * Use **bold** for product names, category headers, and important terms
  * Use *italic* for supplementary descriptions
  * Use numbered lists (1., 2., 3.) for product recommendations
  * Use ### for section headers

DATABASE CONTEXT:
RECOMMENDED FOR: HYUNDAI STARGAZER (MPV, medium cabin)
Dashboard: Double DIN
Cabin Volume: Luas
Subwoofer Space: Boxed
[... all 111 products listed by category ...]
"""
```

---

### Step 8: Format Messages for Gemini API

**Convert to Gemini Native Format:**
```python
payload = {
    "system_instruction": {
        "parts": [{"text": system_prompt}]
    },
    "contents": [
        {
            "role": "user",
            "parts": [{
                "text": "rekomendasi audio untuk mobil stargazer, berikan saya 2 opsi, opsi satu high end dan opsi kedua mid range"
            }]
        }
    ],
    "generationConfig": {
        "maxOutputTokens": 8192,
        "temperature": 0.1
    }
}
```

---

### Step 9: Call Gemini API

**HTTP Request:**
```
POST https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={GEMINI_API_KEY}
Content-Type: application/json

{payload from step 8}
```

**API Processing (Internal to Gemini):**
1. Parse system instruction → understand rules & context
2. Parse user message → understand intent (wants 2 options for Stargazer)
3. Generate response following rules:
   - Use ONLY products from database context
   - Build high-end package (premium brands, no budget limit)
   - Build mid-range package (mid-tier brands, 5-10jt range)
   - Explain why each product suits Stargazer
   - Format with Markdown, include prices, calculate totals

---

### Step 10: AI Generates Response

**AI Decision Process:**

```
User Request Analysis:
  ✓ Car: Stargazer (MPV)
  ✓ Requirement: 2 options
  ✓ Option 1: High-end (premium brands, >10jt)
  ✓ Option 2: Mid-range (mid brands, 5-10jt)

High-End Package Construction:
  Head Unit: Nakamichi Legend Pro 12 (Rp 11.1jt) ← Premium, flagship
  Speaker Front: JBL Stadium 62F (Rp 3.7jt) ← Premium, flagship
  Speaker Rear: Hertz Dieci K 165 (Rp 1.8jt) ← Premium brand
  Subwoofer: JL Audio 10W3V3-4 (Rp 8.7jt) ← Premium, flagship
  Amp 4ch: Rockford R2-500x4 (Rp 4.8jt) ← Premium, high power
  Amp Mono: Rockford T500.1BD (Rp 5.5jt) ← Premium, flagship
  DSP: Venom VPR 3.6 (Rp 4.2jt) ← Only DSP available
  Total: Rp 40.848.000

Mid-Range Package Construction:
  Head Unit: Nakamichi Saga NA-3102i (Rp 2.08jt) ← Mid-range option
  Speaker Front: Hertz K 165 UNO (Rp 1.62jt) ← Mid-tier
  Speaker Rear: Pioneer TS-A1670F (Rp 850rb) ← Mid-range, affordable
  Subwoofer: JBL Stage2 124B (Rp 1.5jt) ← Budget JBL option
  Amp 4ch: Venom VO 406 MKII (Rp 1.71jt) ← Budget brand
  Amp Mono: Venom V1500XD (Rp 1.5jt) ← Budget brand
  Total: Rp 9.260.000

Explanation Generation:
  For each product:
    ✓ Why suitable for Stargazer?
    ✓ Key specs mentioned?
    ✓ How it fits MPV characteristics?
```

---

### Step 11: AI Response Received

**Response Text (3000+ characters):**
```
Tentu, saya akan berikan rekomendasi audio untuk mobil Hyundai Stargazer Anda 
dengan dua opsi, yaitu high-end dan mid-range, lengkap dengan penjelasan mengapa 
produk tersebut cocok untuk Stargazer.

Hyundai Stargazer adalah MPV dengan kabin yang luas dan dashboard double DIN, 
serta ruang subwoofer yang lega. Ini memungkinkan pemasangan sistem audio yang 
komprehensif untuk pengalaman mendengarkan yang optimal.

### Opsi 1: Paket Audio High-End (Total Harga: Rp 40.848.000)
Paket ini dirancang untuk Anda yang menginginkan kualitas suara premium, detail 
yang luar biasa, dan performa bass yang powerful di kabin Stargazer yang luas.

**Head Unit Android:**

1. **Nakamichi Legend Pro 12 9 inch 12/256GB** (Harga: Rp 11.100.000)
   Alasan: Sebagai MPV modern dengan dashboard double DIN, Stargazer sangat cocok 
   dengan head unit Android flagship berlayar 9 inci QLED ini. Dengan RAM 12GB dan 
   storage 256GB, performanya sangat cepat dan responsif.

**Speaker Component Depan (6.5 inch):**

2. **JBL Stadium 62F 6.5 inch 2-Way** (Harga: Rp 3.733.000)
   Alasan: Speaker component flagship ini memiliki RMS 100W dan Hi-Res capable, 
   sangat cocok untuk menghasilkan staging suara yang presisi dan detail di kabin 
   Stargazer yang luas.

[... continues for all 7 products in high-end package ...]

### Opsi 2: Paket Audio Mid-Range (Total Harga: Rp 9.260.000)
Paket ini menawarkan peningkatan kualitas suara yang signifikan dari sistem standar 
dengan harga yang lebih terjangkau, cocok untuk penggunaan harian di Stargazer.

[... continues for all 6 products in mid-range package ...]

Kedua opsi ini mempertimbangkan karakteristik Hyundai Stargazer sebagai MPV dengan 
kabin luas dan ruang subwoofer yang memadai, sehingga Anda bisa mendapatkan 
pengalaman audio yang maksimal sesuai dengan budget dan preferensi Anda.
```

---

### Step 12: Save Session & Return Response

**Update History:**
```python
history = [
    {
        "role": "user",
        "content": "rekomendasi audio untuk mobil stargazer, berikan saya 2 opsi, opsi satu high end dan opsi kedua mid range"
    },
    {
        "role": "assistant",
        "content": "[3000+ character response text]"
    }
]
```

**Save to Redis:**
```python
Key: "session:abc-123-def-456-ghi"
Value: {"history": [...]}
TTL: 86400 seconds (24 hours)
```

**Build ChatResponse:**
```json
{
  "session_id": "abc-123-def-456-ghi",
  "response": "Tentu, saya akan berikan rekomendasi audio...",
  "recommendations": [
    {
      "solution_id": "car_stargazer_uuid",
      "solution_title": "Rekomendasi untuk Hyundai Stargazer",
      "solution_description": "Produk audio yang kompatibel untuk Hyundai Stargazer (MPV, kabin medium).",
      "products": [
        {"product_id": "...", "product_name": "Nakamichi Legend Pro 12", "product_category": "Head Unit Android", "product_price": 11100000.0, "image": "⚡"},
        {"product_id": "...", "product_name": "JBL Stadium 62F", "product_category": "Speaker Component", "product_price": 3733000.0, "image": "⚡"},
        [... all 111 compatible products ...]
      ]
    }
  ]
}
```

**Return to User:**
```
HTTP 200 OK
Content-Type: application/json

{ChatResponse JSON above}
```

---

## 🔍 Key Decision Points

### Decision 1: Car Detected? ✅ YES
```
Input: "rekomendasi audio untuk mobil stargazer..."
Keyword: "stargazer" → Match: ('Hyundai', 'Stargazer', 'MPV')
Path: Car Detection → Get Car Specs → Get Car Products
```

### Decision 2: Products Found? ✅ YES
```
Query: get_products_for_car(type='MPV', size='medium')
Result: 111 products (all active products compatible with MPV)
Path: Build Car Context → Proceed to LLM
```

### Decision 3: User Request Analysis (By AI)
```
Intent: User wants 2 package options
  - Option 1: High-end (premium brands, no budget limit)
  - Option 2: Mid-range (mid-tier brands, 5-10jt)
  
AI Strategy:
  High-end → Select Tier 1 brands (JL Audio, Rockford, JBL, Nakamichi, Hertz)
  Mid-range → Select Tier 2 brands (Pioneer, Hertz entry-level, Nakamichi entry, Venom)
```

### Decision 4: Product Selection Logic (By AI)
```
For each category (Head Unit, Speaker, Subwoofer, Amp, DSP):
  High-end → Pick most expensive/premium option from context
  Mid-range → Pick mid-priced option from context
  
Package Completeness:
  ✓ Head Unit (source)
  ✓ Front Speakers (main audio)
  ✓ Rear Speakers (passenger experience)
  ✓ Subwoofer (bass)
  ✓ Amplifier 4ch (power for speakers)
  ✓ Amplifier Mono (power for subwoofer)
  ✓ DSP (tuning & optimization)
```

---

## 📊 Response Composition Analysis

| Component | Characters | Percentage |
|-----------|-----------|------------|
| Introduction (Stargazer specs) | ~250 | 8% |
| High-End Package (7 products) | ~1800 | 60% |
| Mid-Range Package (6 products) | ~800 | 27% |
| Conclusion | ~150 | 5% |
| **Total** | **~3000** | **100%** |

---

## ⏱️ Performance Metrics (Estimated)

| Step | Time | Notes |
|------|------|-------|
| Session Check | ~5ms | UUID validation + Redis GET |
| Car Detection | ~2ms | Dictionary lookup |
| Car Specs Query | ~50ms | PostgreSQL query |
| Get Products Query | ~100ms | PostgreSQL query with filters |
| Context Building | ~10ms | String formatting |
| Prompt Assembly | ~5ms | Template filling |
| Gemini API Call | ~2000ms | Network + AI processing |
| Response Parsing | ~5ms | JSON extraction |
| Session Save | ~10ms | Redis SET |
| **Total** | **~2187ms** | **~2.2 seconds** |

---

## 🎯 Why This Response Was Generated

### 1. **Car-Specific Recommendations**
- AI detected "Stargazer" → Retrieved MPV specs
- Rules in prompt instructed: "For MPV, full system possible"
- AI recommended complete 7-component system

### 2. **Two Tiers (High-End vs Mid-Range)**
- User explicitly requested: "2 opsi, opsi satu high end dan opsi kedua mid range"
- AI followed budget tier rules:
  - High-end (>10jt): Premium brands (JL Audio, Rockford, JBL, Nakamichi)
  - Mid-range (5-10jt): Mid-tier brands (Pioneer, Hertz entry, Venom)

### 3. **Detailed Explanations**
- Prompt rules: "Explain WHY each product is recommended"
- AI generated per-product reasoning based on:
  - Stargazer characteristics (MPV, double DIN, spacious cabin)
  - Product specs (RMS, size, features)
  - Compatibility factors

### 4. **Markdown Formatting**
- Prompt rules: "Use **bold** for product names, ### for headers"
- AI formatted response with:
  - `###` section headers
  - `**bold**` product names
  - Numbered lists
  - "Harga: Rp X" format

### 5. **Total Package Price**
- Prompt rules: "Calculate total package price and mention it"
- AI summed up:
  - High-end: 11.1 + 3.7 + 1.8 + 8.7 + 4.8 + 5.5 + 4.2 = **Rp 40.848.000**
  - Mid-range: 2.08 + 1.62 + 0.85 + 1.5 + 1.71 + 1.5 = **Rp 9.260.000**

---

## 💡 Key Takeaways

✅ **Car Detection Works**: System correctly identified Stargazer and retrieved MPV-specific products

✅ **Context-Rich Prompt**: Database context with 111 products gave AI comprehensive data to work with

✅ **Rule Following**: AI followed prompt instructions (no hallucination, use only context, format properly)

✅ **Package Building**: AI successfully created complete audio systems from multiple categories

✅ **Price Awareness**: AI calculated totals and stayed within implied budget ranges

✅ **Session Persistence**: Conversation saved for follow-up questions (e.g., "Opsi 1 vs Opsi 2 lebih bagus mana?")
