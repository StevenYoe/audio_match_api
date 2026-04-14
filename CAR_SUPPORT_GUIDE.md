# Car Type-Aware Recommendation System - Implementation Guide

## Overview

This implementation adds **car type awareness** to the AudioMatch recommendation system. Now when users ask for recommendations for specific car models (e.g., "untuk mobil Xpander" or "buat Brio"), the system will provide **different, appropriate recommendations** based on the car's specifications.

## What Was Added

### 1. Database Schema

#### New Table: `sales.master_cars`
Stores specifications for 58 popular Indonesian cars across 6 types:
- **MPV** (13 cars): Xpander, Avanza, Xenia, Innova, Ertiga, Mobilio, etc.
- **City Car** (8 cars): Brio, Agya, Ayla, S-Presso, Calya, Sigra, etc.
- **SUV** (12 cars): Fortuner, Pajero Sport, CR-V, Tucson, Rush, Terios, etc.
- **Sedan** (8 cars): Civic, Accord, Camry, Corolla Altis, City, Vios, etc.
- **Hatchback** (6 cars): Jazz, Baleno, Swift, Yaris, HR-V, etc.
- **Pickup/Commercial** (9 cars): L300, Carry, Gran Max, Hilux, Ranger, etc.
- **Van/Minibus** (3 cars): HiAce, Luxio, APV

Each car record includes:
- `mc_type`: Vehicle type (MPV, SUV, City Car, etc.)
- `mc_size_category`: Cabin size (small, medium, large)
- `mc_dashboard_type`: Head unit compatibility (single_din, double_din, android_custom)
- `mc_subwoofer_space`: Available space for subwoofer (spacious, moderate, limited)
- `mc_factory_speaker_size`: Original speaker size
- `mc_factory_speaker_count`: Number of factory speakers
- `mc_special_notes`: Installation notes

#### New Columns in `sales.master_products`
- `mp_compatible_car_types`: Array of car types this product works with (e.g., `['MPV', 'SUV']`)
- `mp_recommended_car_sizes`: Array of cabin sizes this product is best for (e.g., `['medium', 'large']`)

### 2. SQL Functions

#### `sales.search_car(brand TEXT, model TEXT)`
Searches for cars by brand and model name with fuzzy matching.

**Example:**
```sql
SELECT * FROM sales.search_car('Honda', 'Brio');
-- Returns: Honda Brio (City Car, small cabin, single_din dashboard)
```

#### `sales.get_products_for_car(car_type TEXT, car_size TEXT)`
Returns products compatible with a specific car type and size, ordered by compatibility score.

**Scoring:**
- **100**: Perfect match (both type AND size compatible)
- **80**: Good match (type compatible)
- **70**: Decent match (size compatible)
- **60**: Universal product (no restrictions)
- **50**: Not ideal but available

**Example:**
```sql
SELECT * FROM sales.get_products_for_car('City Car', 'small');
-- Returns compact products: underseat subwoofers, 5.25" speakers, slim amplifiers
```

### 3. Python Code Updates

#### `database_service.py` - New Methods

```python
async def search_car(brand: str, model: str) -> List[Dict]
async def get_products_for_car(car_type: str, car_size: str) -> List[Dict]
async def get_car_recommendations_context(car: Dict) -> Tuple[str, List]
```

#### `chat.py` - Car Mention Extraction

New function `_extract_car_mention(text)` detects car models in user messages using a comprehensive keyword database of 50+ car models.

**Flow:**
1. User says: "Rekomendasi audio untuk Brio"
2. System extracts: `{'brand': 'Honda', 'model': 'Brio', 'type': 'City Car'}`
3. Searches database: Finds Honda Brio (small, single_din, limited space)
4. Gets compatible products: Filters products for City Car + small size
5. Injects into LLM context: "RECOMMENDED FOR: HONDA BRIO (City Car, small cabin)"
6. LLM generates response using ONLY car-specific products

### 4. Product Compatibility Mapping

All 111 products have been tagged with car compatibility:

| Product Category | Compatible Car Types | Recommended Sizes |
|-----------------|---------------------|-------------------|
| **Head Unit Single DIN** | City Car, Sedan, Hatchback, Pickup | small, medium, large |
| **Head Unit Double DIN** | MPV, SUV, Sedan, Hatchback | medium, large |
| **Head Unit Android 9"** | MPV, SUV, Sedan, Hatchback | medium, large |
| **Head Unit Android 10"** | MPV, SUV, Sedan | large |
| **Head Unit Android 7"** | All types | small, medium, large |
| **Speaker 6.5"** | MPV, SUV, Sedan, Hatchback | medium, large |
| **Speaker 5.25"** | City Car, Sedan, Hatchback | small, medium |
| **Speaker 6x9"** | MPV, SUV, Sedan | medium, large |
| **Subwoofer Kolong/Underseat** | City Car, MPV, SUV, Sedan | small, medium |
| **Subwoofer Boxed** | MPV, SUV, Sedan | medium, large |
| **Amplifier 40-60W** | All types | small, medium, large |
| **Amplifier 75W+** | MPV, SUV, Sedan | medium, large |
| **Amplifier Mono** | MPV, SUV, Sedan | medium, large |
| **Processor/DSP** | MPV, SUV, Sedan, Hatchback | medium, large |

## How It Works

### Before (Old System)
```
User: "Rekomendasi buat Xpander"
  ↓
No problem matched → Fallback: Show ALL 111 products
  ↓
Same result for Xpander, Brio, Fortuner, etc. ❌
```

### After (New System)
```
User: "Rekomendasi buat Xpander"
  ↓
Car detected: Mitsubishi Xpander (MPV, large, double_din, spacious)
  ↓
Get products for MPV + large:
  - Head Unit Android 9-10" (double DIN compatible)
  - Speaker component 6.5" front
  - Speaker coaxial 6x9" rear (deck space available)
  - Subwoofer 10-12" boxed (trunk space available)
  - Amplifier 75W+ (powerful for large cabin)
  ↓
Car-specific recommendations ✅

User: "Rekomendasi buat Brio"
  ↓
Car detected: Honda Brio (City Car, small, single_din, limited)
  ↓
Get products for City Car + small:
  - Head Unit single DIN or 7" Android (compact)
  - Speaker 5.25" or 6.5" (factory size compatible)
  - Subwoofer KOLONG/underseat ONLY (limited trunk)
  - Amplifier compact 40-60W (small cabin doesn't need much power)
  ↓
Compact, space-efficient recommendations ✅
```

## Migration Files

Three migration files handle database changes:

1. **`001_add_car_support.sql`**: Creates tables, columns, and functions
2. **`002_populate_car_data.sql`**: Inserts 58 car models with specifications
3. **`003_update_product_compatibility.sql`**: Updates 111 products with compatibility tags

Run them with:
```bash
python run_migrations.py
```

## Testing

### Test Script
```bash
python test_car_support.py
```

This verifies:
- ✅ 58 cars in database
- ✅ 100+ products with compatibility
- ✅ Car search works (Honda Brio → City Car, small)
- ✅ Car search works (Mitsubishi Xpander → MPV, large)
- ✅ Product filtering by type and size
- ✅ Subwoofer recommendations differ between small and large cars

### Manual Testing

**Test 1: City Car**
```
User: "Saya mau upgrade audio untuk Honda Brio"
Expected: Recommends compact products (subwoofer kolong, speaker 5.25", etc.)
```

**Test 2: MPV**
```
User: "Rekomendasi audio untuk Xpander"
Expected: Recommends full system (boxed subwoofer, 6x9" rear, powerful amp)
```

**Test 3: SUV**
```
User: "Buatin paket audio buat Fortuner dong"
Expected: Premium components, DSP processor, powerful subwoofer
```

**Test 4: Sedan**
```
User: "Audio yang cocok untuk Civic"
Expected: Sound quality focus, component speakers, sealed box subwoofer
```

## Usage Examples

### Example 1: Xpander (Large MPV)

**User:** "Rekomendasi audio untuk Xpander budget 10 juta"

**System Response:**
```
### Rekomendasi Audio untuk Mitsubishi Xpander

**Spesifikasi Mobil:**
- Tipe: MPV, Kabin Besar
- Dashboard: Double DIN
- Ruang Subwoofer: Luas
- Speaker Pabrik: 6.5 inch (4 speaker)

### Paket Audio Lengkap (Total: Rp 9.850.000)

1. **Head Unit Android Kenwood 9 inch 4/64GB** - Rp 3.200.000
   - Double DIN, cocok untuk dashboard Xpander
   - Layar 9 inch, DSP built-in

2. **Speaker Component Kenwood KFC-XS1704 6.5 inch** - Rp 1.800.000
   - Untuk speaker depan (door)
   - Sesuai dengan ukuran factory speaker

3. **Speaker Coaxial Pioneer TS-A6996R 6x9 inch** - Rp 1.100.000
   - Untuk deck belakang (Xpander punya space luas)

4. **Subwoofer Pioneer TS-W311D4 12 inch** - Rp 1.800.000
   - Boxed subwoofer (bagasi Xpander luas)

5. **Amplifier 4 Channel Kenwood KAC-M5004** - Rp 2.800.000
   - 75W RMS, power yang cukup untuk kabin besar
```

### Example 2: Brio (Small City Car)

**User:** "Rekomendasi audio untuk Brio budget 5 juta"

**System Response:**
```
### Rekomendasi Audio untuk Honda Brio

**Spesifikasi Mobil:**
- Tipe: City Car, Kabin Kecil
- Dashboard: Single DIN
- Ruang Subwoofer: Terbatas
- Speaker Pabrik: 5.25 inch (2 speaker)

### Paket Audio Compact (Total: Rp 4.750.000)

1. **Head Unit Pioneer DEH-S5250BT Single DIN** - Rp 1.650.000
   - Single DIN, cocok untuk dashboard Brio yang kecil

2. **Speaker Coaxial Kenwood KFC-S1366 5.25 inch** - Rp 550.000
   - Sesuai ukuran factory speaker Brio

3. **Subwoofer Aktif Kenwood KSC-SW11 Kolong** - Rp 2.500.000
   - Underseat/slim design (trunk Brio terbatas)
   - TINGGI HANYA 7CM, muat di kolong jok

4. **Amplifier 2 Channel JVC KS-AX302** - Rp 1.200.000
   - Compact design, cocok untuk space terbatas
```

**See the difference?** 
- Xpander gets boxed subwoofer + 6x9" rear speakers (space available)
- Brio gets underseat subwoofer + 5.25" speakers (space limited)

## API Endpoint

No changes to API endpoint structure. The enhancement is transparent to the client.

**Request:**
```json
POST /api/v1/chat/
{
  "session_id": "...",
  "message": "Rekomendasi untuk mobil Avanza"
}
```

**Response:** (same schema, different content)
```json
{
  "session_id": "...",
  "response": "Berikut rekomendasi untuk Toyota Avanza...",
  "recommendations": [
    {
      "solution_id": "car_11111111-1111-1111-1111-111111111102",
      "solution_title": "Rekomendasi untuk Toyota Avanza",
      "solution_description": "Produk audio yang kompatibel untuk Toyota Avanza (MPV, kabin large)...",
      "products": [...]
    }
  ]
}
```

## Adding New Cars

To add new car models:

```sql
INSERT INTO sales.master_cars (
    mc_brand, mc_model, mc_type, mc_size_category,
    mc_dashboard_type, mc_subwoofer_space,
    mc_factory_speaker_size, mc_factory_speaker_count
) VALUES (
    'Brand', 'Model', 'MPV', 'large',
    'double_din', 'spacious',
    '6.5 inch', 4
);
```

The car extraction function `_extract_car_mention()` in `chat.py` will automatically detect it if you add the keyword:

```python
car_keywords = {
    'newmodel': ('Brand', 'Model', 'MPV'),  # Add this line
}
```

## Adding New Products

When adding new products, set compatibility:

```sql
INSERT INTO sales.master_products (
    mp_name, mp_category, mp_brand, mp_price,
    mp_compatible_car_types, mp_recommended_car_sizes
) VALUES (
    'New Product Name', 'subwoofer', 'Brand', 2000000,
    ARRAY['City Car', 'MPV', 'SUV'],  -- Compatible types
    ARRAY['small', 'medium']           -- Recommended sizes
);
```

Or leave NULL for universal compatibility:
```sql
mp_compatible_car_types = NULL,  -- Works with ALL car types
mp_recommended_car_sizes = NULL  -- Works with ALL cabin sizes
```

## Benefits

1. **Better User Experience**: Users get relevant recommendations for their specific car
2. **Reduced Confusion**: No more "why recommend boxed subwoofer for Brio when it won't fit?"
3. **Professional Image**: Shows expertise in car audio installation
4. **Increased Trust**: Recommendations consider real-world constraints (space, dashboard type)
5. **Scalable**: Easy to add new car models and products

## Future Enhancements

Possible improvements:
- Add year ranges (e.g., "Brio 2015-2020" vs "Brio 2021+")
- Add trim levels (e.g., "Xpander Ultimate" vs "Xpander GLX")
- Add color/match images for dashboard compatibility
- Add installation difficulty ratings
- Add estimated installation time per car model
- Add wiring harness adapter recommendations per car
- Add sound deadening recommendations per car (noise levels)

## Files Modified/Created

### Modified Files:
- `app/services/database_service.py` - Added car query methods
- `app/api/v1/endpoints/chat.py` - Added car extraction and filtering
- `database_schemas.sql` - Added car schema documentation

### New Files:
- `migrations/001_add_car_support.sql` - Schema creation
- `migrations/002_populate_car_data.sql` - Car data insertion
- `migrations/003_update_product_compatibility.sql` - Product compatibility updates
- `run_migrations.py` - Migration runner script
- `test_car_support.py` - Test verification script
- `fix_search_car.py` - Hotfix for return type issue
- `CAR_SUPPORT_GUIDE.md` - This documentation file

## Deployment Checklist

- [x] Run migrations on production database
- [x] Verify 58 cars in `master_cars` table
- [x] Verify 100+ products have compatibility tags
- [x] Test car search function
- [x] Deploy updated Python code
- [x] Restart API server
- [x] Test endpoint with car model queries
- [x] Monitor logs for car detection accuracy
- [ ] Update frontend to show car specifications (optional)

## Support

For questions or issues:
- Check logs: Look for "Car mention detected" and "Car matched" messages
- Test manually: Use `test_car_support.py` script
- Database queries: Use functions `search_car()` and `get_products_for_car()`

---

**Implementation Date:** April 14, 2026  
**Version:** 1.0  
**Database Version:** PostgreSQL 17 with pgvector
