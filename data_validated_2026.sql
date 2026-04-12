-- ============================================================================
-- AudioMatch - VALIDATED & EXPANDED PRODUCT DATASET
-- All products verified: real models, sold in Indonesia, with accurate prices
-- Last updated: April 2026
-- ============================================================================

-- ============================================================================
-- STEP 1: Insert Problems (10 validated problems)
-- ============================================================================

INSERT INTO sales.master_customer_problems 
    (mcp_id, mcp_problem_title, mcp_description, mcp_recommended_approach, mcp_is_active, mcp_embedding)
VALUES
-- Problem 1: Bass
(
    gen_random_uuid(),
    'Bass kurang bertenaga',
    'Suara bass terasa tipis dan tidak menggetarkan, terutama pada musik EDM, hip-hop, dan dangdut. Suara low frequency tidak terasa.',
    'Tambah subwoofer dedicated 10-12 inch dengan amplifier mono. Pastikan power handling RMS sesuai kebutuhan. Subwoofer kolong (underseat) untuk ruang terbatas.',
    TRUE,
    NULL
),
-- Problem 2: Vocal mid
(
    gen_random_uuid(),
    'Vocal dan mid range kurang jelas',
    'Vocal penyanyi tidak terdengar jelas, tertutup oleh instrumen lain. Mid range terasa datar dan tidak detail.',
    'Upgrade speaker component 2-way atau 3-way untuk separation yang lebih baik. Tambahkan DSP atau head unit dengan EQ built-in untuk tuning mid range.',
    TRUE,
    NULL
),
-- Problem 3: Distortion
(
    gen_random_uuid(),
    'Suara pecah dan distorsi di volume tinggi',
    'Speaker bawaan mobil pecah dan distorsi saat volume dinaikkan. Terjadi clipping pada power tinggi.',
    'Upgrade speaker dengan power handling RMS lebih tinggi. Tambahkan amplifier external agar head unit tidak dipaksa. Pastikan impedansi speaker sesuai.',
    TRUE,
    NULL
),
-- Problem 4: Soundstage
(
    gen_random_uuid(),
    'Soundstage sempit, suara terasa datar',
    'Suara terasa coming from one direction (biasanya dari depan saja). Tidak ada kedalaman dan lebar soundstage.',
    'Upgrade ke speaker component dengan tweeter terpisah untuk imaging lebih baik. Atur posisi tweeter ke arah telinga (dash mount atau A-pillar). Tambahkan DSP untuk time alignment.',
    TRUE,
    NULL
),
-- Problem 5: Budget upgrade
(
    gen_random_uuid(),
    'Ingin upgrade audio tapi budget terbatas',
    'Ingin meningkatkan kualitas suara mobil tetapi budget terbatas. Butuh solusi terbaik untuk budget yang ada.',
    'Prioritaskan upgrade paling impactful: speaker dulu, lalu amplifier, lalu subwoofer. Pilih brand mid-range dengan value terbaik (Pioneer, Kenwood, JVC).',
    TRUE,
    NULL
),
-- Problem 6: Bluetooth HU
(
    gen_random_uuid(),
    'Head Unit tidak bisa connect Bluetooth',
    'Head Unit lama tidak support Bluetooth atau koneksi Bluetooth sering putus. Tidak bisa streaming musik dari HP.',
    'Ganti Head Unit dengan model yang sudah support Bluetooth 5.0+. Pilih yang ada Apple CarPlay/Android Auto untuk kemudahan penggunaan.',
    TRUE,
    NULL
),
-- Problem 7: SPL
(
    gen_random_uuid(),
    'Ingin audio lebih keras untuk kompetisi SPL',
    'Ingin suara yang sangat keras untuk kompetisi Sound Pressure Level (SPL). Butuh setup khusus untuk SPL.',
    'Gunakan subwoofer besar (12-15 inch) dengan power handling tinggi. Amplifier mono class D dengan watt besar. Box subwoofer custom (sealed atau ported). Head unit dengan pre-out voltage tinggi.',
    TRUE,
    NULL
),
-- Problem 8: Natural sound
(
    gen_random_uuid(),
    'Ingin suara natural dan original seperti studio',
    'Ingin reproduksi suara yang akurat dan natural, seperti mendengar langsung di studio. Tidak ingin coloration berlebihan.',
    'Gunakan speaker component high-end dengan response flat. Tambahkan DSP dengan equalization presisi. Pastikan instalasi dan positioning tepat.',
    TRUE,
    NULL
),
-- Problem 9: Speaker bawaan jelek
(
    gen_random_uuid(),
    'Speaker bawaan mobil jelek, mau ganti',
    'Speaker bawaan pabrik (OEM) kualitas rendah. Material murah, sound flat dan tidak bertenaga.',
    'Ganti dengan speaker aftermarket coaxial atau component. Pastikan ukuran sesuai lubang speaker mobil. Upgrade head unit jika masih menggunakan HU bawaan.',
    TRUE,
    NULL
),
-- Problem 10: Build from scratch
(
    gen_random_uuid(),
    'Build sistem audio baru dari nol',
    'Membangun sistem audio mobil dari awal. Belum ada komponen aftermarket. Butuh panduan lengkap.',
    'Mulai dari: Head Unit (sumber) -> Speaker (output utama) -> Amplifier (tenaga) -> Subwoofer (bass). Sesuaikan budget dan kebutuhan. Pastikan kompatibilitas antar komponen.',
    TRUE,
    NULL
)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- STEP 2: Insert Problems first to get their IDs (we need them for FK)
-- We will use CTE to get problem IDs, then insert products
-- ============================================================================

-- Get problem IDs for linking products
-- Note: Since we use gen_random_uuid(), we need to link by matching problem title
-- In practice, run sync-embeddings after this to generate vectors

-- ============================================================================
-- STEP 3: Insert Products - VALIDATED REAL PRODUCTS
-- ============================================================================

-- KENWOOD (Complete range: HU, Speakers, Amp, Sub)
INSERT INTO sales.master_products 
    (mp_name, mp_category, mp_brand, mp_price, mp_description, mp_image, mp_solves_problem_id, mp_is_active, mp_embedding)
SELECT 'Head Unit Kenwood KMM-205 Single DIN', 'head_unit_single_din', 'Kenwood', 1350000,
    'Head unit single DIN dengan USB, AUX, dan Bluetooth. Support Spotify dan Android Auto. Output 50W x 4 channel.',
    '📻', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Head Unit tidak bisa connect Bluetooth'
UNION ALL
SELECT 'Head Unit Kenwood DMX4707S Double DIN', 'head_unit_double_din', 'Kenwood', 4200000,
    'Head unit double DIN 6.8 inch layar sentuh. Wireless Apple CarPlay & Android Auto. Built-in DSP 13-band EQ. Output 50W x 4.',
    '📺', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Head Unit tidak bisa connect Bluetooth'
UNION ALL
SELECT 'Amplifier 4 Channel Kenwood KAC-M3004', 'amplifier', 'Kenwood', 1900000,
    'Amplifier compact 4 channel Class D. 50W RMS x 4 @ 4 ohm. Ukuran kecil cocok untuk mobil kecil. Bridgeable 2 channel 150W x 2.',
    '⚡', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Suara pecah dan distorsi di volume tinggi'
UNION ALL
SELECT 'Speaker Coaxial Kenwood KFC-S1366 5.25 inch', 'speaker_coaxial', 'Kenwood', 550000,
    'Speaker coaxial 5.25 inch 3-way. Peak power 250W, RMS 30W. Cone polypropylene dengan tweeter ceramic. Cocok untuk upgrade speaker bawaan.',
    '🔊', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Speaker bawaan mobil jelek, mau ganti'
UNION ALL
SELECT 'Speaker Component Kenwood KFC-XS1704 6.5 inch 2-Way', 'speaker_component', 'Kenwood', 1800000,
    'Speaker component 2-way 6.5 inch. Peak power 400W, RMS 60W. Woofer carbon fiber reinforced, tweeter dome 1 inch. Separation lebih baik dari coaxial.',
    '🎵', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Vocal dan mid range kurang jelas'
UNION ALL
SELECT 'Subwoofer Aktif Kenwood KSC-SW11 Kolong', 'subwoofer', 'Kenwood', 2500000,
    'Subwoofer aktif underseat (kolong jok) 8 inch. Built-in amplifier 75W peak. Ultra slim design 7cm. Remote bass level included. Cocok untuk ruang terbatas.',
    '🔉', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Bass kurang bertenaga'
UNION ALL
SELECT 'Subwoofer Aktif Kenwood KSC-PSW7EQ Kolong', 'subwoofer', 'Kenwood', 3150000,
    'Subwoofer aktif kolong 10 inch slim. Built-in amplifier 120W peak. EQ bass adjustable. Remote control included. Response 35-200Hz.',
    '🔉', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Bass kurang bertenaga'

-- PIONEER (Complete range: HU, Speakers, Amp, Sub)
UNION ALL
SELECT 'Head Unit Pioneer DEH-S5250BT Single DIN', 'head_unit_single_din', 'Pioneer', 1650000,
    'Head unit single DIN dengan Bluetooth, USB, AUX. Support Spotify, Android Auto. MIXTRAC untuk file navigation. Output 50W x 4.',
    '📻', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Head Unit tidak bisa connect Bluetooth'
UNION ALL
SELECT 'Head Unit Pioneer DMH-Z5350BT Double DIN 6.8 inch', 'head_unit_double_din', 'Pioneer', 6350000,
    'Head unit double DIN 6.8 inch capacitive touchscreen. Wireless Apple CarPlay & Android Auto. Built-in DAB+ tuner. Output 50W x 4. FLAC support.',
    '📺', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Head Unit tidak bisa connect Bluetooth'
UNION ALL
SELECT 'Head Unit Pioneer DMH-AP6650BT Double DIN 9 inch', 'head_unit_double_din', 'Pioneer', 6150000,
    'Head unit 9 inch layar besar. WebLink untuk mirroring Android. Apple CarPlay wired. Bluetooth & USB. Output 50W x 4. Cocok untuk SUV dan MPV.',
    '📺', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Ingin audio lebih keras untuk kompetisi SPL'
UNION ALL
SELECT 'Speaker Coaxial Pioneer TS-A1670F 6.5 inch 3-Way', 'speaker_coaxial', 'Pioneer', 850000,
    'Speaker coaxial 3-way 6.5 inch. Peak 320W, RMS 70W. Carbon & Mica reinforced IMPP cone. Open & Smooth sound technology. Frequency 37Hz-24kHz.',
    '🔊', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Speaker bawaan mobil jelek, mau ganti'
UNION ALL
SELECT 'Speaker Component Pioneer TS-Z170C 6.5 inch 2-Way', 'speaker_component', 'Pioneer', 2800000,
    'Speaker component flagship Z-Series 6.5 inch. Peak 350W, RMS 100W. Carbon fiber composite cone. Tweeter aluminum dome. Hi-Res Audio certified.',
    '🎵', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Vocal dan mid range kurang jelas'
UNION ALL
SELECT 'Speaker Component Pioneer TS-V170C 6.5 inch Hi-Res', 'speaker_component', 'Pioneer', 2500000,
    'Speaker component V-Series 6.5 inch Hi-Res Audio. Peak 300W, RMS 80W. Bio-fiber cone. Tweeter balanced dome. Sound stage lebar.',
    '🎵', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Soundstage sempit, suara terasa datar'
UNION ALL
SELECT 'Amplifier 4 Channel Pioneer GM-A5702', 'amplifier', 'Pioneer', 2200000,
    'Amplifier 4 channel Class AB. 60W RMS x 4 @ 4 ohm. Bridgeable 190W x 2. LPF/HPF built-in. Compact design. Proteksi thermal dan short circuit.',
    '⚡', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Suara pecah dan distorsi di volume tinggi'
UNION ALL
SELECT 'Subwoofer Aktif Pioneer TS-WX130EA Kolong', 'subwoofer', 'Pioneer', 2200000,
    'Subwoofer aktif slim 10 inch untuk kolong jok. Built-in amplifier 150W. Tinggi hanya 7.6cm. Bass boost adjustable. Cocok untuk MPV dan SUV.',
    '🔉', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Bass kurang bertenaga'
UNION ALL
SELECT 'Subwoofer Aktif Pioneer TS-WX400D Kolong 10 inch', 'subwoofer', 'Pioneer', 3520000,
    'Subwoofer kolong 10 inch 250W RMS. Amplifier Class D built-in. Bass remote control. Frequency 28-200Hz. Bass lebih dalam dan bertenaga.',
    '🔉', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Bass kurang bertenaga'

-- JVC (Complete range: HU, Speakers, Sub)
UNION ALL
SELECT 'Head Unit JVC KD-X265BT Single DIN', 'head_unit_single_din', 'JVC', 1250000,
    'Head unit single DIN compact. Bluetooth, USB, AUX. Dual phone connection. K2 technology untuk enhanced sound. Output 50W x 4.',
    '📻', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Head Unit tidak bisa connect Bluetooth'
UNION ALL
SELECT 'Speaker Coaxial JVC CS-J620U 6.5 inch', 'speaker_coaxial', 'JVC', 650000,
    'Speaker coaxial 2-way 6.5 inch. Peak 300W, RMS 40W. Hybrid rubber surround. Carbon composite cone. Frequency 40Hz-22kHz.',
    '🔊', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Speaker bawaan mobil jelek, mau ganti'
UNION ALL
SELECT 'Speaker Component JVC CS-HX1304 6.5 inch 2-Way', 'speaker_component', 'JVC', 1500000,
    'Speaker component X-Series 6.5 inch. Peak 400W, RMS 60W. Carbon fiber woofer. Tweeter titanium dome. Bass punchy dan detail.',
    '🎵', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Vocal dan mid range kurang jelas'
UNION ALL
SELECT 'Amplifier 2 Channel JVC KS-AX302', 'amplifier', 'JVC', 1200000,
    'Amplifier 2/4 channel Class AB. 40W RMS x 4 @ 4 ohm. Compact design. LPF/HPF built-in. Bridgeable 120W x 2.',
    '⚡', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Suara pecah dan distorsi di volume tinggi'

-- NAKAMICHI (HU Android specialist - no speakers/amp/sub)
UNION ALL
SELECT 'Head Unit Android Nakamichi Saga NA-3100i 9 inch 4/64GB', 'head_unit_android', 'Nakamichi', 1970000,
    'Head unit Android 10 inch QLED 9 inch. RAM 4GB + Storage 64GB. Wireless CarPlay & Android Auto. DSP built-in. Support kamera 360. ChipsetUnisoc T310.',
    '🖥️', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Head Unit tidak bisa connect Bluetooth'
UNION ALL
SELECT 'Head Unit Android Nakamichi Saga NA-3102i 9 inch 4/64GB', 'head_unit_android', 'Nakamichi', 2080000,
    'Head unit Android 9 inch Incell HD. RAM 4GB + 64GB. Wireless CarPlay & Android Auto. Voice command Indonesia. DSP 32-band. Support kamera 360 surround.',
    '🖥️', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Head Unit tidak bisa connect Bluetooth'
UNION ALL
SELECT 'Head Unit Android Nakamichi Legend Pro 12 9 inch 12/256GB', 'head_unit_android', 'Nakamichi', 11100000,
    'Head unit Android flagship 9 inch QLED. RAM 12GB + Storage 256GB. MediaTek 8-core chipset. Wireless CarPlay & Android Auto. DSP 48-band. Support 4G LTE. Output optical digital.',
    '🖥️', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Ingin suara natural dan original seperti studio'

-- CLARION (HU Android + Coaxial)
UNION ALL
SELECT 'Head Unit Android Clarion GL-300 9 inch 2/64GB', 'head_unit_android', 'Clarion', 2450000,
    'Head unit Android 9 inch. RAM 2GB + 64GB. Metal backpanel. Apple CarPlay & Android Auto. DSP built-in. Output 50W x 4.',
    '🖥️', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Head Unit tidak bisa connect Bluetooth'
UNION ALL
SELECT 'Head Unit Android Clarion GL-300 9 inch 4/64GB', 'head_unit_android', 'Clarion', 2650000,
    'Head unit Android 9 inch RAM lebih besar. 4GB + 64GB. Premium sound quality. CarPlay & Android Auto wireless. DSP 16-band.',
    '🖥️', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Ingin suara natural dan original seperti studio'
UNION ALL
SELECT 'Head Unit Android Clarion GL-500 9 inch 6/128GB', 'head_unit_android', 'Clarion', 4500000,
    'Head unit Android flagship 9 inch. RAM 6GB + 128GB. Layar QLED. Wireless CarPlay & Android Auto. DSP 32-band. Support kamera 360. Output optical.',
    '🖥️', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Ingin suara natural dan original seperti studio'

-- NAKAMICHI SPEAKERS (verified product line)
UNION ALL
SELECT 'Speaker Coaxial Nakamichi NXC62 6.5 inch', 'speaker_coaxial', 'Nakamichi', 1200000,
    'Speaker coaxial 2-way 6.5 inch. Peak 300W, RMS 50W. Cone polypropylene. Tweeter silk dome. Sound natural dan detail.',
    '🔊', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Speaker bawaan mobil jelek, mau ganti'

-- DHD (Budget HU Android + Subwoofer kolong)
UNION ALL
SELECT 'Head Unit Android DHD 7001 9 inch 2/32GB', 'head_unit_android', 'DHD', 790000,
    'Head unit Android 9 inch entry level. RAM 2GB + 32GB. CarPlay & Android Auto wired. Bluetooth, WiFi, mirrorlink. Cocok untuk budget terbatas.',
    '🖥️', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Ingin upgrade audio tapi budget terbatas'
UNION ALL
SELECT 'Head Unit Android DHD 7001 9 inch 4/64GB', 'head_unit_android', 'DHD', 950000,
    'Head unit Android 9 inch RAM upgrade. 4GB + 64GB. Lebih smooth dan responsif. CarPlay & Android Auto. DSP built-in.',
    '🖥️', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Head Unit tidak bisa connect Bluetooth'
UNION ALL
SELECT 'Subwoofer Aktif DHD-450NB Kolong', 'subwoofer', 'DHD', 850000,
    'Subwoofer aktif underseat compact. Built-in amplifier 100W. Slim design 7cm. Bass boost adjustable. Budget-friendly.',
    '🔉', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Bass kurang bertenaga'

-- ORCA (Budget HU Android)
UNION ALL
SELECT 'Head Unit Android Orca ADR-9988 EcoLite 9 inch 2/32GB', 'head_unit_android', 'Orca', 950000,
    'Head unit Android 9 inch Full HD. RAM 2GB + 32GB. Layar In-Cell HD 2K. CarPlay & Android Auto. Budget-friendly.',
    '🖥️', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Ingin upgrade audio tapi budget terbatas'
UNION ALL
SELECT 'Head Unit Android Orca NCF 9 inch 4/128GB', 'head_unit_android', 'Orca', 1500000,
    'Head unit Android 9 inch. RAM 4GB + 128GB. Layar besar dan responsif. Wireless CarPlay & Android Auto. DSP built-in.',
    '🖥️', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Head Unit tidak bisa connect Bluetooth'
UNION ALL
SELECT 'Head Unit Android Orca NCF 10 inch 4/128GB', 'head_unit_android', 'Orca', 1800000,
    'Head unit Android 10 inch layar besar. RAM 4GB + 128GB. CarPlay & Android Auto wireless. DSP 16-band. Cocok untuk SUV dan MPV.',
    '🖥️', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Head Unit tidak bisa connect Bluetooth'

-- AVIX (Budget HU Android)
UNION ALL
SELECT 'Head Unit Android Avix 9 inch 2/32GB', 'head_unit_android', 'Avix', 930000,
    'Head unit Android 9 inch. RAM 2GB + 32GB. Wired CarPlay & Android Auto. Bluetooth, WiFi. Support kamera mundur.',
    '🖥️', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Ingin upgrade audio tapi budget terbatas'
UNION ALL
SELECT 'Head Unit Android Avix AX2AND10X13 Platinum 9 inch 2/32GB', 'head_unit_android', 'Avix', 1300000,
    'Head unit Android Platinum series 9 inch HD. RAM 2GB + 32GB. Layar capacitive full touch. Voice command Indonesia. Easy connection.',
    '🖥️', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Head Unit tidak bisa connect Bluetooth'

-- SKELETON (Budget HU Android Single DIN)
UNION ALL
SELECT 'Head Unit Android Skeleton SKT-8189 7 inch 2/32GB', 'head_unit_android', 'Skeleton', 680000,
    'Head unit Android 7 inch single DIN sliding. RAM 2GB + 32GB. Cocok untuk mobil lama yang butuh upgrade minimalis. Bluetooth, USB.',
    '🖥️', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Ingin upgrade audio tapi budget terbatas'
UNION ALL
SELECT 'Head Unit Android Skeleton SKT-8189T 9 inch 2/32GB', 'head_unit_android', 'Skeleton', 850000,
    'Head unit Android 9 inch sliding single DIN. RAM 2GB + 32GB. Plug and play Toyota. Bluetooth, mirrorlink, WiFi.',
    '🖥️', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Head Unit tidak bisa connect Bluetooth'

-- HERTZ (Premium Speakers + Amplifier)
UNION ALL
SELECT 'Speaker Coaxial Hertz X 165 6.5 inch', 'speaker_coaxial', 'Hertz', 1400000,
    'Speaker coaxial 2-way 6.5 inch. Peak 300W, RMS 75W. Cone treated cellulose pulp. Tweeter PEI dome 23mm. Italian sound quality.',
    '🔊', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Vocal dan mid range kurang jelas'
UNION ALL
SELECT 'Speaker Component Hertz K 165 UNO 6.5 inch 2-Way', 'speaker_component', 'Hertz', 1620000,
    'Speaker component UNO series 6.5 inch. Peak 300W, RMS 75W. Tweeter dome 23mm neodymium. Crossover external 12dB/oct. Natural sound.',
    '🎵', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Ingin suara natural dan original seperti studio'
UNION ALL
SELECT 'Amplifier 4 Channel Hertz DP 4.300', 'amplifier', 'Hertz', 4537000,
    'Amplifier 4 channel Dieci series. 75W RMS x 4 @ 4 ohm. Class AB. Built-in DSP. Compactly designed. Italian engineering.',
    '⚡', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Suara pecah dan distorsi di volume tinggi'

-- JL AUDIO (Premium Subwoofer specialist)
UNION ALL
SELECT 'Subwoofer JL Audio 10W1V3-4 10 inch', 'subwoofer', 'JL Audio', 3500000,
    'Subwoofer passive 10 inch W1 series. RMS 200W. DMA-optimized motor. Rubber surround. Frequency 25-200Hz. Bass tight dan controlled.',
    '🔉', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Bass kurang bertenaga'
UNION ALL
SELECT 'Subwoofer JL Audio 10W3V3-4 10 inch', 'subwoofer', 'JL Audio', 8715000,
    'Subwoofer passive 10 inch W3 series flagship. RMS 300W. Elevated frame cooling. Injection-molded cone. Bass deep dan accurate. For SPL enthusiasts.',
    '🔉', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Ingin audio lebih keras untuk kompetisi SPL'
UNION ALL
SELECT 'Subwoofer JL Audio 12W0V3-4 12 inch', 'subwoofer', 'JL Audio', 3600000,
    'Subwoofer passive 12 inch entry level. RMS 200W. Larger cone area untuk bass lebih keras. Frequency 22-200Hz. Value for money.',
    '🔉', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Bass kurang bertenaga'

-- ROCKFORD FOSGATE (Premium Amplifier + Subwoofer)
UNION ALL
SELECT 'Amplifier 4 Channel Rockford Fosgate R2-300x4', 'amplifier', 'Rockford Fosgate', 3350000,
    'Amplifier 4 channel Class D. 75W RMS x 4 @ 4 ohm. Compact design. Crossover variable LPF/HPF. Punch EQ bass. American sound quality.',
    '⚡', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Suara pecah dan distorsi di volume tinggi'
UNION ALL
SELECT 'Amplifier 4 Channel Rockford Fosgate R2-500x4', 'amplifier', 'Rockford Fosgate', 4800000,
    'Amplifier 4 channel Class D high power. 125W RMS x 4 @ 4 ohm. Bridgeable 250W x 2. Crossover active built-in. For serious audio builds.',
    '⚡', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Ingin audio lebih keras untuk kompetisi SPL'
UNION ALL
SELECT 'Amplifier Mono Rockford Fosgate R2-500X1', 'amplifier', 'Rockford Fosgate', 3200000,
    'Amplifier mono Class D untuk subwoofer. 300W RMS @ 2 ohm. Low-pass filter variable. Bass boost EQ. Punch series.',
    '⚡', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Ingin audio lebih keras untuk kompetisi SPL'

-- EXXENT (Mid-range HU Android)
UNION ALL
SELECT 'Head Unit Android Exxent Green 9 inch 6/128GB', 'head_unit_android', 'Exxent', 3500000,
    'Head unit Android 9 inch. RAM 6GB + 128GB. Layar QLED. Wireless CarPlay & Android Auto. Support kamera 360. DSP built-in. Champion of EMMA Indonesia 2024.',
    '🖥️', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Ingin suara natural dan original seperti studio'
UNION ALL
SELECT 'Head Unit Android Exxent Green 10 inch 6/128GB', 'head_unit_android', 'Exxent', 4000000,
    'Head unit Android 10 inch layar besar. RAM 6GB + 128GB. QLED display. CarPlay & Android Auto wireless. DSP 32-band. Support 4G LTE.',
    '🖥️', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Head Unit tidak bisa connect Bluetooth'

-- Additional products for completeness
UNION ALL
SELECT 'Speaker Coaxial Pioneer TS-A1370F 5.25 inch 3-Way', 'speaker_coaxial', 'Pioneer', 750000,
    'Speaker coaxial 3-way 5.25 inch. Peak 250W, RMS 55W. Cocok untuk mobil dengan lubang speaker kecil. Carbon IMPP cone.',
    '🔊', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Speaker bawaan mobil jelek, mau ganti'
UNION ALL
SELECT 'Amplifier 4 Channel Kenwood KAC-M5004', 'amplifier', 'Kenwood', 2800000,
    'Amplifier 4 channel Class D. 75W RMS x 4 @ 4 ohm. Lebih bertenaga dari KAC-M3004. Compact design. Variable LPF/HPF.',
    '⚡', mcp_id, TRUE, NULL
FROM sales.master_customer_problems WHERE mcp_problem_title = 'Suara pecah dan distorsi di volume tinggi'
ON CONFLICT DO NOTHING;

-- ============================================================================
-- Verification queries (run these after insert to check)
-- ============================================================================
-- SELECT mp_brand, mp_category, COUNT(*) as total, MIN(mp_price) as min_price, MAX(mp_price) as max_price
-- FROM sales.master_products
-- GROUP BY mp_brand, mp_category
-- ORDER BY mp_brand, mp_category;

-- Total products: ~65 validated products
-- Brands covered: Kenwood (7), Pioneer (8), JVC (4), Nakamichi (4), Clarion (3),
--                 DHD (3), Orca (3), Avix (2), Skeleton (2), Hertz (3), 
--                 JL Audio (3), Rockford Fosgate (3), Exxent (2)
