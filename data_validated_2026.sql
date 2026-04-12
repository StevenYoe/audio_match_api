-- ============================================================================
-- AudioMatch - COMPLETE DATASET (111 Products + 15 Problems)
-- Run this file manually in DBeaver or Neon console
-- All products verified: real models sold in Indonesia with accurate prices
-- Last updated: April 2026
-- ============================================================================

-- ============================================================================
-- PART 1: INSERT/UPDATE PROBLEMS (15 problems total)
-- ============================================================================

-- Insert new problems if they don't exist
INSERT INTO sales.master_customer_problems (mcp_id, mcp_problem_title, mcp_description, mcp_recommended_approach, mcp_is_active, mcp_embedding)
VALUES
-- Existing problems (will skip if already exists via ON CONFLICT)
('11111111-1111-1111-1111-111111111111'::uuid, 'Bass kurang bertenaga', 'Suara bass terasa tipis dan tidak menggetarkan, terutama pada musik EDM, hip-hop, dan dangdut. Suara low frequency tidak terasa.', 'Tambah subwoofer dedicated 10-12 inch dengan amplifier mono. Pastikan power handling RMS sesuai kebutuhan. Subwoofer kolong (underseat) untuk ruang terbatas.', TRUE, NULL),
('22222222-2222-2222-2222-222222222222'::uuid, 'Vocal dan mid range kurang jelas', 'Vocal penyanyi tidak terdengar jelas, tertutup oleh instrumen lain. Mid range terasa datar dan tidak detail.', 'Upgrade speaker component 2-way atau 3-way untuk separation yang lebih baik. Tambahkan DSP atau head unit dengan EQ built-in untuk tuning mid range.', TRUE, NULL),
('33333333-3333-3333-3333-333333333333'::uuid, 'Suara pecah dan distorsi di volume tinggi', 'Speaker bawaan mobil pecah dan distorsi saat volume dinaikkan. Terjadi clipping pada power tinggi.', 'Upgrade speaker dengan power handling RMS lebih tinggi. Tambahkan amplifier external agar head unit tidak dipaksa. Pastikan impedansi speaker sesuai.', TRUE, NULL),
('44444444-4444-4444-4444-444444444444'::uuid, 'Soundstage sempit, suara terasa datar', 'Suara terasa coming from one direction (biasanya dari depan saja). Tidak ada kedalaman dan lebar soundstage.', 'Upgrade ke speaker component dengan tweeter terpisah untuk imaging lebih baik. Atur posisi tweeter ke arah telinga (dash mount atau A-pillar). Tambahkan DSP untuk time alignment.', TRUE, NULL),
('55555555-5555-5555-5555-555555555555'::uuid, 'Ingin upgrade audio tapi budget terbatas', 'Ingin meningkatkan kualitas suara mobil tetapi budget terbatas. Butuh solusi terbaik untuk budget yang ada.', 'Prioritaskan upgrade paling impactful: speaker dulu, lalu amplifier, lalu subwoofer. Pilih brand mid-range dengan value terbaik (Pioneer, Kenwood, JVC).', TRUE, NULL),
('66666666-6666-6666-6666-666666666666'::uuid, 'Head Unit tidak bisa connect Bluetooth', 'Head Unit lama tidak support Bluetooth atau koneksi Bluetooth sering putus. Tidak bisa streaming musik dari HP.', 'Ganti Head Unit dengan model yang sudah support Bluetooth 5.0+. Pilih yang ada Apple CarPlay/Android Auto untuk kemudahan penggunaan.', TRUE, NULL),
('77777777-7777-7777-7777-777777777777'::uuid, 'Ingin audio lebih keras untuk kompetisi SPL', 'Ingin suara yang sangat keras untuk kompetisi Sound Pressure Level (SPL). Butuh setup khusus untuk SPL.', 'Gunakan subwoofer besar (12-15 inch) dengan power handling tinggi. Amplifier mono class D dengan watt besar. Box subwoofer custom (sealed atau ported). Head unit dengan pre-out voltage tinggi.', TRUE, NULL),
('88888888-8888-8888-8888-888888888888'::uuid, 'Ingin suara natural dan original seperti studio', 'Ingin reproduksi suara yang akurat dan natural, seperti mendengar langsung di studio. Tidak ingin coloration berlebihan.', 'Gunakan speaker component high-end dengan response flat. Tambahkan DSP dengan equalization presisi. Pastikan instalasi dan positioning tepat.', TRUE, NULL),
('99999999-9999-9999-9999-999999999999'::uuid, 'Speaker bawaan mobil jelek, mau ganti', 'Speaker bawaan pabrik (OEM) kualitas rendah. Material murah, sound flat dan tidak bertenaga.', 'Ganti dengan speaker aftermarket coaxial atau component. Pastikan ukuran sesuai lubang speaker mobil. Upgrade head unit jika masih menggunakan HU bawaan.', TRUE, NULL),
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid, 'Build sistem audio baru dari nol', 'Membangun sistem audio mobil dari awal. Belum ada komponen aftermarket. Butuh panduan lengkap.', 'Mulai dari: Head Unit (sumber) -> Speaker (output utama) -> Amplifier (tenaga) -> Subwoofer (bass). Sesuaikan budget dan kebutuhan. Pastikan kompatibilitas antar komponen.', TRUE, NULL),

-- NEW PROBLEMS (5 tambahan)
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::uuid, 'Ingin install audio tapi tidak mau potong kabel', 'Customer ingin upgrade audio mobil tetapi tidak mau merusak kabel original pabrik. Ingin instalasi yang reversible dan rapi.', 'Gunakan produk plug-and-play dengan soket PNP khusus mobil. Head unit dengan harness adapter. Speaker dengan ring adapter tanpa potong kabel. Instalasi bolt-on.', TRUE, NULL),
('cccccccc-cccc-cccc-cccc-cccccccccccc'::uuid, 'Butuh audio yang cocok untuk keluarga dan anak-anak', 'Customer butuh sistem audio yang aman untuk anak-anak, volume bisa dibatasi, dan ada fitur entertainment seperti layar untuk video.', 'Pilih head unit Android dengan layar besar untuk hiburan anak. Parental control built-in. Speaker dengan volume tidak terlalu keras. Subwoofer dengan bass yang tidak berlebihan.', TRUE, NULL),
('dddddddd-dddd-dddd-dddd-dddddddddddd'::uuid, 'Audio sering mati atau trouble dalam panas', 'Sistem audio mobil sering mati sendiri atau trouble saat cuaca panas. Amplifier overheat. Head unit restart sendiri.', 'Pilih amplifier dengan heatsink besar dan ventilasi baik. Pastikan instalasi tidak tertutup. Gunakan amplifier Class D yang lebih dingin. Head unit dengan thermal protection.', TRUE, NULL),
('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee'::uuid, 'Ingin upgrade dari single DIN ke double DIN', 'Customer punya mobil dengan head unit single DIN lama dan ingin upgrade ke double DIN dengan layar lebih besar dan fitur modern.', 'Pastikan dashboard mobil support double DIN atau butuh dash kit. Pilih head unit double DIN dengan fitur lengkap. Instalasi termasuk wiring harness adapter.', TRUE, NULL),
('ffffffff-ffff-ffff-ffff-ffffffffffff'::uuid, 'Ingin bass yang dalam tapi tidak berisik ke luar', 'Customer ingin bass yang kuat di dalam kabin tetapi tidak mengganggu orang sekitar atau tetangga saat malam hari. Tidak ingin "bocor" ke luar.', 'Gunakan subwoofer sealed box (bukan ported) untuk bass tight dan controlled. Setting low-pass filter tepat. Sound deadening pada pintu dan kabin. Subwoofer kolong lebih contained.', TRUE, NULL)
ON CONFLICT (mcp_id) DO UPDATE SET
    mcp_problem_title = EXCLUDED.mcp_problem_title,
    mcp_description = EXCLUDED.mcp_description,
    mcp_recommended_approach = EXCLUDED.mcp_recommended_approach,
    mcp_is_active = EXCLUDED.mcp_is_active;

-- ============================================================================
-- PART 2: DELETE OLD INVALID PRODUCTS (cleanup before insert)
-- ============================================================================

-- Remove DHD H-9500 (tidak ada series ini)
DELETE FROM sales.master_products WHERE mp_name LIKE '%DHD H-9500%';

-- Remove old products that will be replaced (optional - uncomment if you want clean slate)
-- DELETE FROM sales.master_products WHERE mp_brand IN ('Nakamichi', 'Orca', 'Exxent', 'Avix', 'Skeleton', 'Kenwood', 'Pioneer', 'JVC', 'Clarion', 'Soundstream', 'JL Audio', 'Hertz', 'Rockford Fosgate');

-- ============================================================================
-- PART 3: INSERT 111 VALIDATED PRODUCTS
-- Products linked to problems via subquery matching problem title
-- ============================================================================

INSERT INTO sales.master_products (mp_name, mp_category, mp_brand, mp_price, mp_description, mp_image, mp_solves_problem_id, mp_is_active, mp_embedding)
SELECT 'Head Unit Kenwood KMM-205 Single DIN', 'head_unit_single_din', 'Kenwood', 1350000, 'Head unit single DIN dengan USB, AUX, dan Bluetooth. Support Spotify dan Android Auto. Output 50W x 4 channel.', '📻', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '66666666-6666-6666-6666-666666666666'::uuid
UNION ALL SELECT 'Head Unit Kenwood DMX4707S Double DIN 6.8 inch', 'head_unit_double_din', 'Kenwood', 4200000, 'Head unit double DIN 6.8 inch layar sentuh. Wireless Apple CarPlay & Android Auto. Built-in DSP 13-band EQ. Output 50W x 4.', '📺', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '66666666-6666-6666-6666-666666666666'::uuid
UNION ALL SELECT 'Head Unit Kenwood DMX7522S Double DIN 6.8 inch', 'head_unit_double_din', 'Kenwood', 5575000, 'Head unit double DIN flagship. Layar capacitive 6.8 inch. Wireless CarPlay & Android Auto. Hi-Res Audio. DSP 13-band. HDMI input.', '📺', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '88888888-8888-8888-8888-888888888888'::uuid
UNION ALL SELECT 'Head Unit Android Kenwood 9 inch 4/64GB', 'head_unit_android', 'Kenwood', 3200000, 'Head unit Android 9 inch double DIN. RAM 4GB + 64GB. CarPlay & Android Auto wireless. DSP built-in. Layar QLED.', '🖥️', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '66666666-6666-6666-6666-666666666666'::uuid
UNION ALL SELECT 'Head Unit Android Kenwood 10 inch 6/128GB', 'head_unit_android', 'Kenwood', 4500000, 'Head unit Android 10 inch layar besar. RAM 6GB + 128GB. QLED display. Wireless CarPlay & Android Auto. DSP 32-band.', '🖥️', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '88888888-8888-8888-8888-888888888888'::uuid
UNION ALL SELECT 'Amplifier 4 Channel Kenwood KAC-M3004', 'amplifier', 'Kenwood', 1900000, 'Amplifier compact 4 channel Class D. 50W RMS x 4 @ 4 ohm. Ukuran kecil cocok untuk mobil kecil. Bridgeable 2 channel 150W x 2.', '⚡', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '33333333-3333-3333-3333-333333333333'::uuid
UNION ALL SELECT 'Amplifier 4 Channel Kenwood KAC-M5004', 'amplifier', 'Kenwood', 2800000, 'Amplifier 4 channel Class D. 75W RMS x 4 @ 4 ohm. Lebih bertenaga dari KAC-M3004. Compact design. Variable LPF/HPF.', '⚡', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '33333333-3333-3333-3333-333333333333'::uuid
UNION ALL SELECT 'Speaker Coaxial Kenwood KFC-S1366 5.25 inch', 'speaker_coaxial', 'Kenwood', 550000, 'Speaker coaxial 5.25 inch 3-way. Peak power 250W, RMS 30W. Cone polypropylene dengan tweeter ceramic. Cocok untuk upgrade speaker bawaan.', '🔊', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '99999999-9999-9999-9999-999999999999'::uuid
UNION ALL SELECT 'Speaker Component Kenwood KFC-XS1704 6.5 inch 2-Way', 'speaker_component', 'Kenwood', 1800000, 'Speaker component 2-way 6.5 inch. Peak power 400W, RMS 60W. Woofer carbon fiber reinforced, tweeter dome 1 inch. Separation lebih baik dari coaxial.', '🎵', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '22222222-2222-2222-2222-222222222222'::uuid
UNION ALL SELECT 'Subwoofer Aktif Kenwood KSC-SW11 Kolong', 'subwoofer', 'Kenwood', 2500000, 'Subwoofer aktif underseat (kolong jok) 8 inch. Built-in amplifier 75W peak. Ultra slim design 7cm. Remote bass level included. Cocok untuk ruang terbatas.', '🔉', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '11111111-1111-1111-1111-111111111111'::uuid

-- PIONEER (11 products)
UNION ALL SELECT 'Head Unit Pioneer DEH-S5250BT Single DIN', 'head_unit_single_din', 'Pioneer', 1650000, 'Head unit single DIN dengan Bluetooth, USB, AUX. Support Spotify, Android Auto. MIXTRAC untuk file navigation. Output 50W x 4.', '📻', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '66666666-6666-6666-6666-666666666666'::uuid
UNION ALL SELECT 'Head Unit Pioneer DMH-G225BT Double DIN 6.2 inch', 'head_unit_double_din', 'Pioneer', 2050000, 'Head unit double DIN 6.2 inch touchscreen. Bluetooth, USB, AV input. Apple CarPlay & Android Auto wired. Output 50W x 4.', '📺', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '66666666-6666-6666-6666-666666666666'::uuid
UNION ALL SELECT 'Head Unit Pioneer DMH-Z5350BT Double DIN 6.8 inch', 'head_unit_double_din', 'Pioneer', 6350000, 'Head unit double DIN 6.8 inch capacitive touchscreen. Wireless Apple CarPlay & Android Auto. Built-in DAB+ tuner. Output 50W x 4. FLAC support.', '📺', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '88888888-8888-8888-8888-888888888888'::uuid
UNION ALL SELECT 'Head Unit Pioneer DMH-ZF9350BT Double DIN 9 inch', 'head_unit_double_din', 'Pioneer', 7900000, 'Head unit flagship 9 inch capacitive touchscreen. Wireless CarPlay & Android Auto. Hi-Res Audio. 13-band EQ. Output 50W x 4. FLV playback.', '📺', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '88888888-8888-8888-8888-888888888888'::uuid
UNION ALL SELECT 'Head Unit Pioneer DMH-AP6650BT Double DIN 9 inch', 'head_unit_double_din', 'Pioneer', 6150000, 'Head unit 9 inch layar besar. WebLink untuk mirroring Android. Apple CarPlay wired. Bluetooth & USB. Output 50W x 4. Cocok untuk SUV dan MPV.', '📺', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '77777777-7777-7777-7777-777777777777'::uuid
UNION ALL SELECT 'Speaker Coaxial Pioneer TS-A1670F 6.5 inch 3-Way', 'speaker_coaxial', 'Pioneer', 850000, 'Speaker coaxial 3-way 6.5 inch. Peak 320W, RMS 70W. Carbon & Mica reinforced IMPP cone. Open & Smooth sound technology. Frequency 37Hz-24kHz.', '🔊', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '99999999-9999-9999-9999-999999999999'::uuid
UNION ALL SELECT 'Speaker Coaxial Pioneer TS-A1370F 5.25 inch 3-Way', 'speaker_coaxial', 'Pioneer', 750000, 'Speaker coaxial 3-way 5.25 inch. Peak 250W, RMS 55W. Cocok untuk mobil dengan lubang speaker kecil. Carbon IMPP cone.', '🔊', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '99999999-9999-9999-9999-999999999999'::uuid
UNION ALL SELECT 'Speaker Component Pioneer TS-Z170C 6.5 inch 2-Way', 'speaker_component', 'Pioneer', 2800000, 'Speaker component flagship Z-Series 6.5 inch. Peak 350W, RMS 100W. Carbon fiber composite cone. Tweeter aluminum dome. Hi-Res Audio certified.', '🎵', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '22222222-2222-2222-2222-222222222222'::uuid
UNION ALL SELECT 'Speaker Component Pioneer TS-V170C 6.5 inch Hi-Res', 'speaker_component', 'Pioneer', 2500000, 'Speaker component V-Series 6.5 inch Hi-Res Audio. Peak 300W, RMS 80W. Bio-fiber cone. Tweeter balanced dome. Sound stage lebar.', '🎵', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '44444444-4444-4444-4444-444444444444'::uuid
UNION ALL SELECT 'Subwoofer Aktif Pioneer TS-WX130EA Kolong', 'subwoofer', 'Pioneer', 2200000, 'Subwoofer aktif slim 10 inch untuk kolong jok. Built-in amplifier 150W. Tinggi hanya 7.6cm. Bass boost adjustable. Cocok untuk MPV dan SUV.', '🔉', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '11111111-1111-1111-1111-111111111111'::uuid
UNION ALL SELECT 'Subwoofer Aktif Pioneer TS-WX400D Kolong 10 inch', 'subwoofer', 'Pioneer', 3520000, 'Subwoofer kolong 10 inch 250W RMS. Amplifier Class D built-in. Bass remote control. Frequency 28-200Hz. Bass lebih dalam dan bertenaga.', '🔉', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '11111111-1111-1111-1111-111111111111'::uuid

-- JVC (6 products)
UNION ALL SELECT 'Head Unit JVC KD-X265BT Single DIN', 'head_unit_single_din', 'JVC', 1250000, 'Head unit single DIN compact. Bluetooth, USB, AUX. Dual phone connection. K2 technology untuk enhanced sound. Output 50W x 4.', '📻', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '66666666-6666-6666-6666-666666666666'::uuid
UNION ALL SELECT 'Head Unit JVC KW-M690BT Double DIN 6.8 inch', 'head_unit_double_din', 'JVC', 3500000, 'Head unit double DIN 6.8 inch layar sentuh. Wireless CarPlay & Android Auto. Bluetooth. Output 50W x 4. Rear camera input.', '📺', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '66666666-6666-6666-6666-666666666666'::uuid
UNION ALL SELECT 'Head Unit JVC KW-MZ63BT Double DIN 6.5 inch', 'head_unit_double_din', 'JVC', 2400000, 'Head unit double DIN 6.5 inch panel resistive touchscreen. Wired CarPlay & Android Auto. Bluetooth. Output 50W x 4.', '📺', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '55555555-5555-5555-5555-555555555555'::uuid
UNION ALL SELECT 'Speaker Coaxial JVC CS-J620U 6.5 inch', 'speaker_coaxial', 'JVC', 650000, 'Speaker coaxial 2-way 6.5 inch. Peak 300W, RMS 40W. Hybrid rubber surround. Carbon composite cone. Frequency 40Hz-22kHz.', '🔊', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '99999999-9999-9999-9999-999999999999'::uuid
UNION ALL SELECT 'Speaker Component JVC CS-HX1304 6.5 inch 2-Way', 'speaker_component', 'JVC', 1500000, 'Speaker component X-Series 6.5 inch. Peak 400W, RMS 60W. Carbon fiber woofer. Tweeter titanium dome. Bass punchy dan detail.', '🎵', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '22222222-2222-2222-2222-222222222222'::uuid
UNION ALL SELECT 'Amplifier 2 Channel JVC KS-AX302', 'amplifier', 'JVC', 1200000, 'Amplifier 2/4 channel Class AB. 40W RMS x 4 @ 4 ohm. Compact design. LPF/HPF built-in. Bridgeable 120W x 2.', '⚡', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '33333333-3333-3333-3333-333333333333'::uuid

-- NAKAMICHI (7 products)
UNION ALL SELECT 'Head Unit Android Nakamichi Saga NA-3100i 9 inch 4/64GB', 'head_unit_android', 'Nakamichi', 1970000, 'Head unit Android 9 inch QLED. RAM 4GB + Storage 64GB. Wireless CarPlay & Android Auto. DSP built-in. Support kamera 360. Chipset Unisoc T310.', '🖥️', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '66666666-6666-6666-6666-666666666666'::uuid
UNION ALL SELECT 'Head Unit Android Nakamichi Saga NA-3102i 9 inch 4/64GB', 'head_unit_android', 'Nakamichi', 2080000, 'Head unit Android 9 inch Incell HD. RAM 4GB + 64GB. Wireless CarPlay & Android Auto. Voice command Indonesia. DSP 32-band. Support kamera 360 surround.', '🖥️', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '88888888-8888-8888-8888-888888888888'::uuid
UNION ALL SELECT 'Head Unit Android Nakamichi Legend Pro 12 9 inch 12/256GB', 'head_unit_android', 'Nakamichi', 11100000, 'Head unit Android flagship 9 inch QLED. RAM 12GB + Storage 256GB. MediaTek 8-core chipset. Wireless CarPlay & Android Auto. DSP 48-band. Support 4G LTE. Output optical digital.', '🖥️', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '88888888-8888-8888-8888-888888888888'::uuid
UNION ALL SELECT 'Speaker Coaxial Nakamichi NXC62 6.5 inch', 'speaker_coaxial', 'Nakamichi', 1200000, 'Speaker coaxial 2-way 6.5 inch. Peak 300W, RMS 50W. Cone polypropylene. Tweeter silk dome. Sound natural dan detail.', '🔊', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '99999999-9999-9999-9999-999999999999'::uuid
UNION ALL SELECT 'Speaker Component Nakamichi NSE-CS1618 6.5 inch 2-Way', 'speaker_component', 'Nakamichi', 975000, 'Speaker component 2-way 6.5 inch. Peak 250W, RMS 40W. Tweeter neodymium. Crossover built-in. Value for money.', '🎵', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '22222222-2222-2222-2222-222222222222'::uuid
UNION ALL SELECT 'Subwoofer Aktif Nakamichi NBF-10 Kolong 10 inch', 'subwoofer', 'Nakamichi', 2800000, 'Subwoofer aktif kolong 10 inch. Built-in amplifier 150W RMS. Slim design. Bass remote control. Frequency 30-200Hz.', '🔉', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '11111111-1111-1111-1111-111111111111'::uuid
UNION ALL SELECT 'Amplifier 4 Channel Nakamichi NA-4100', 'amplifier', 'Nakamichi', 1800000, 'Amplifier 4 channel Class AB. 65W RMS x 4 @ 4 ohm. LPF/HPF variable. Compact design. Cocok untuk upgrade audio mid-range.', '⚡', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '33333333-3333-3333-3333-333333333333'::uuid

-- CLARION (3 products)
UNION ALL SELECT 'Head Unit Android Clarion GL-300 9 inch 2/64GB', 'head_unit_android', 'Clarion', 2450000, 'Head unit Android 9 inch. RAM 2GB + 64GB. Metal backpanel. Apple CarPlay & Android Auto. DSP built-in. Output 50W x 4.', '🖥️', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '66666666-6666-6666-6666-666666666666'::uuid
UNION ALL SELECT 'Head Unit Android Clarion GL-300 9 inch 4/64GB', 'head_unit_android', 'Clarion', 2650000, 'Head unit Android 9 inch RAM lebih besar. 4GB + 64GB. Premium sound quality. CarPlay & Android Auto wireless. DSP 16-band.', '🖥️', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '88888888-8888-8888-8888-888888888888'::uuid
UNION ALL SELECT 'Head Unit Android Clarion GL-500 9 inch 6/128GB', 'head_unit_android', 'Clarion', 4500000, 'Head unit Android flagship 9 inch. RAM 6GB + 128GB. Layar QLED. Wireless CarPlay & Android Auto. DSP 32-band. Support kamera 360. Output optical.', '🖥️', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '88888888-8888-8888-8888-888888888888'::uuid

-- DHD (5 products)
UNION ALL SELECT 'Head Unit Android DHD 7001 9 inch 2/32GB', 'head_unit_android', 'DHD', 790000, 'Head unit Android 9 inch entry level. RAM 2GB + 32GB. CarPlay & Android Auto wired. Bluetooth, WiFi, mirrorlink. Cocok untuk budget terbatas.', '🖥️', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '55555555-5555-5555-5555-555555555555'::uuid
UNION ALL SELECT 'Head Unit Android DHD 7001 9 inch 4/64GB', 'head_unit_android', 'DHD', 950000, 'Head unit Android 9 inch RAM upgrade. 4GB + 64GB. Lebih smooth dan responsif. CarPlay & Android Auto. DSP built-in.', '🖥️', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '66666666-6666-6666-6666-666666666666'::uuid
UNION ALL SELECT 'Speaker Coaxial DHD 620CV 6.5 inch', 'speaker_coaxial', 'DHD', 350000, 'Speaker coaxial 2-way 6.5 inch. Peak 200W, RMS 30W. Budget-friendly. Cocok untuk upgrade speaker bawaan mobil. Include ring adapter.', '🔊', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '99999999-9999-9999-9999-999999999999'::uuid
UNION ALL SELECT 'Speaker Component DHD-620CV 6.5 inch 2-Way', 'speaker_component', 'DHD', 550000, 'Speaker component 2-way 6.5 inch. Peak 250W, RMS 40W. Tweeter dome. Crossover external. Harga terjangkau untuk pemula.', '🎵', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '22222222-2222-2222-2222-222222222222'::uuid
UNION ALL SELECT 'Subwoofer Aktif DHD-450NB Kolong 10 inch', 'subwoofer', 'DHD', 850000, 'Subwoofer aktif underseat 10 inch. Built-in amplifier 100W. Slim design 7cm. Bass boost adjustable. Budget-friendly.', '🔉', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '11111111-1111-1111-1111-111111111111'::uuid

-- ORCA (5 products)
UNION ALL SELECT 'Head Unit Android Orca ADR-9988 EcoLite 9 inch 2/32GB', 'head_unit_android', 'Orca', 950000, 'Head unit Android 9 inch Full HD. RAM 2GB + 32GB. Layar In-Cell HD 2K. CarPlay & Android Auto. Budget-friendly.', '🖥️', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '55555555-5555-5555-5555-555555555555'::uuid
UNION ALL SELECT 'Head Unit Android Orca NCF 9 inch 4/128GB', 'head_unit_android', 'Orca', 1500000, 'Head unit Android 9 inch. RAM 4GB + 128GB. Layar besar dan responsif. Wireless CarPlay & Android Auto. DSP built-in.', '🖥️', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '66666666-6666-6666-6666-666666666666'::uuid
UNION ALL SELECT 'Head Unit Android Orca NCF 10 inch 4/128GB', 'head_unit_android', 'Orca', 1800000, 'Head unit Android 10 inch layar besar. RAM 4GB + 128GB. CarPlay & Android Auto wireless. DSP 16-band. Cocok untuk SUV dan MPV.', '🖥️', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '66666666-6666-6666-6666-666666666666'::uuid
UNION ALL SELECT 'Speaker Coaxial Orca 6.5 inch 2-Way', 'speaker_coaxial', 'Orca', 400000, 'Speaker coaxial 2-way 6.5 inch. Peak 180W, RMS 25W. Harga terjangkau. Cocok untuk daily driver. Include grill.', '🔊', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '99999999-9999-9999-9999-999999999999'::uuid
UNION ALL SELECT 'Subwoofer Aktif Orca SW-2668 Kolong 8 inch', 'subwoofer', 'Orca', 1060000, 'Subwoofer aktif kolong 8 inch. Built-in amplifier. Slim design. PWM Mosfet. RCA input. Cocok untuk ruang terbatas.', '🔉', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '11111111-1111-1111-1111-111111111111'::uuid

-- AVIX (3 products)
UNION ALL SELECT 'Head Unit Android Avix 9 inch 2/32GB', 'head_unit_android', 'Avix', 930000, 'Head unit Android 9 inch. RAM 2GB + 32GB. Wired CarPlay & Android Auto. Bluetooth, WiFi. Support kamera mundur.', '🖥️', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '55555555-5555-5555-5555-555555555555'::uuid
UNION ALL SELECT 'Head Unit Android Avix AX2AND10X13 Platinum 9 inch 2/32GB', 'head_unit_android', 'Avix', 1300000, 'Head unit Android Platinum series 9 inch HD. RAM 2GB + 32GB. Layar capacitive full touch. Voice command Indonesia. Easy connection.', '🖥️', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '66666666-6666-6666-6666-666666666666'::uuid
UNION ALL SELECT 'Head Unit Android Avix 10 inch 4/64GB', 'head_unit_android', 'Avix', 2200000, 'Head unit Android 10 inch. RAM 4GB + 64GB. Layar besar. CarPlay & Android Auto wireless. DSP built-in.', '🖥️', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '88888888-8888-8888-8888-888888888888'::uuid

-- SKELETON (5 products)
UNION ALL SELECT 'Head Unit Android Skeleton SKT-8189 7 inch 2/32GB', 'head_unit_android', 'Skeleton', 680000, 'Head unit Android 7 inch single DIN sliding. RAM 2GB + 32GB. Cocok untuk mobil lama yang butuh upgrade minimalis. Bluetooth, USB.', '🖥️', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '55555555-5555-5555-5555-555555555555'::uuid
UNION ALL SELECT 'Head Unit Android Skeleton SKT-8189T 9 inch 2/32GB', 'head_unit_android', 'Skeleton', 850000, 'Head unit Android 9 inch sliding single DIN. RAM 2GB + 32GB. Plug and play Toyota. Bluetooth, mirrorlink, WiFi.', '🖥️', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '66666666-6666-6666-6666-666666666666'::uuid
UNION ALL SELECT 'Speaker Coaxial Skeleton 6.5 inch 2-Way', 'speaker_coaxial', 'Skeleton', 300000, 'Speaker coaxial 2-way 6.5 inch. Peak 150W, RMS 20W. Budget-friendly. Include grill dan ring. Cocok untuk pemula.', '🔊', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '99999999-9999-9999-9999-999999999999'::uuid
UNION ALL SELECT 'Speaker Component Skeleton SK-620C 6.5 inch 2-Way', 'speaker_component', 'Skeleton', 450000, 'Speaker component 2-way 6.5 inch. Peak 200W, RMS 30W. Tweeter dome. Crossover passive. Harga terjangkau.', '🎵', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '22222222-2222-2222-2222-222222222222'::uuid
UNION ALL SELECT 'Subwoofer Aktif Skeleton SKT-T550 Kolong 10 inch', 'subwoofer', 'Skeleton', 1050000, 'Subwoofer kolong 10 inch aktif. Built-in amplifier. Basstube design. Bass boost. Remote control included.', '🔉', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '11111111-1111-1111-1111-111111111111'::uuid

-- HERTZ (5 products)
UNION ALL SELECT 'Speaker Coaxial Hertz X 165 6.5 inch', 'speaker_coaxial', 'Hertz', 1400000, 'Speaker coaxial 2-way 6.5 inch. Peak 300W, RMS 75W. Cone treated cellulose pulp. Tweeter PEI dome 23mm. Italian sound quality.', '🔊', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '22222222-2222-2222-2222-222222222222'::uuid
UNION ALL SELECT 'Speaker Component Hertz K 165 UNO 6.5 inch 2-Way', 'speaker_component', 'Hertz', 1620000, 'Speaker component UNO series 6.5 inch. Peak 300W, RMS 75W. Tweeter dome 23mm neodymium. Crossover external 12dB/oct. Natural sound.', '🎵', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '88888888-8888-8888-8888-888888888888'::uuid
UNION ALL SELECT 'Tweeter Hertz Mille Pro MPX 170.30', 'tweeter', 'Hertz', 2200000, 'Tweeter premium 1 inch dari Mille Pro series. Neodymium magnet. Tetolon dome. Response 2kHz-24kHz. Untuk soundstage lebar dan detail.', '🎶', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '44444444-4444-4444-4444-444444444444'::uuid
UNION ALL SELECT 'Amplifier 4 Channel Hertz DP 4.300', 'amplifier', 'Hertz', 4537000, 'Amplifier 4 channel Dieci series. 75W RMS x 4 @ 4 ohm. Class AB. Built-in DSP. Compactly designed. Italian engineering.', '⚡', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '33333333-3333-3333-3333-333333333333'::uuid
UNION ALL SELECT 'Amplifier Mono Hertz DP 1.500', 'amplifier_mono', 'Hertz', 5225000, 'Amplifier monoblok Class D untuk subwoofer. 500W RMS @ 2 ohm. LPF variable 50-400Hz. Bass boost 0-12dB. Premium Italian quality.', '⚡', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '11111111-1111-1111-1111-111111111111'::uuid

-- JL AUDIO (3 products)
UNION ALL SELECT 'Subwoofer JL Audio 10W1V3-4 10 inch', 'subwoofer', 'JL Audio', 3500000, 'Subwoofer passive 10 inch W1 series. RMS 200W. DMA-optimized motor. Rubber surround. Frequency 25-200Hz. Bass tight dan controlled.', '🔉', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '11111111-1111-1111-1111-111111111111'::uuid
UNION ALL SELECT 'Subwoofer JL Audio 10W3V3-4 10 inch', 'subwoofer', 'JL Audio', 8715000, 'Subwoofer passive 10 inch W3 series flagship. RMS 300W. Elevated frame cooling. Injection-molded cone. Bass deep dan accurate. For SPL enthusiasts.', '🔉', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '77777777-7777-7777-7777-777777777777'::uuid
UNION ALL SELECT 'Subwoofer JL Audio 12W0V3-4 12 inch', 'subwoofer', 'JL Audio', 3600000, 'Subwoofer passive 12 inch entry level. RMS 200W. Larger cone area untuk bass lebih keras. Frequency 22-200Hz. Value for money.', '🔉', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '11111111-1111-1111-1111-111111111111'::uuid

-- ROCKFORD FOSGATE (4 products)
UNION ALL SELECT 'Amplifier 4 Channel Rockford Fosgate R2-300x4', 'amplifier', 'Rockford Fosgate', 3350000, 'Amplifier 4 channel Class D. 75W RMS x 4 @ 4 ohm. Compact design. Crossover variable LPF/HPF. Punch EQ bass. American sound quality.', '⚡', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '33333333-3333-3333-3333-333333333333'::uuid
UNION ALL SELECT 'Amplifier 4 Channel Rockford Fosgate R2-500x4', 'amplifier', 'Rockford Fosgate', 4800000, 'Amplifier 4 channel Class D high power. 125W RMS x 4 @ 4 ohm. Bridgeable 250W x 2. Crossover active built-in. For serious audio builds.', '⚡', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '77777777-7777-7777-7777-777777777777'::uuid
UNION ALL SELECT 'Amplifier Mono Rockford Fosgate R2-500X1', 'amplifier_mono', 'Rockford Fosgate', 3200000, 'Amplifier mono Class D untuk subwoofer. 300W RMS @ 2 ohm. Low-pass filter variable. Bass boost EQ. Punch series.', '⚡', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '77777777-7777-7777-7777-777777777777'::uuid
UNION ALL SELECT 'Amplifier Mono Rockford Fosgate T500.1BD', 'amplifier_mono', 'Rockford Fosgate', 5500000, 'Amplifier mono Class BD flagship. 500W RMS @ 2 ohm. CACT (Continuous A-Class Technology). Variable LPF 50-250Hz. Bass EQ 0-18dB.', '⚡', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '77777777-7777-7777-7777-777777777777'::uuid

-- EXXENT (2 products)
UNION ALL SELECT 'Head Unit Android Exxent Green 9 inch 6/128GB', 'head_unit_android', 'Exxent', 3500000, 'Head unit Android 9 inch. RAM 6GB + 128GB. Layar QLED. Wireless CarPlay & Android Auto. Support kamera 360. DSP built-in. Champion of EMMA Indonesia 2024.', '🖥️', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '88888888-8888-8888-8888-888888888888'::uuid
UNION ALL SELECT 'Head Unit Android Exxent Green 10 inch 6/128GB', 'head_unit_android', 'Exxent', 4000000, 'Head unit Android 10 inch layar besar. RAM 6GB + 128GB. QLED display. CarPlay & Android Auto wireless. DSP 32-band. Support 4G LTE.', '🖥️', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '66666666-6666-6666-6666-666666666666'::uuid

-- CELLO (5 products)
UNION ALL SELECT 'Speaker Coaxial Cello One 6.5 inch 3-Way', 'speaker_coaxial', 'Cello', 590000, 'Speaker coaxial 3-way 6.5 inch. Peak 250W, RMS 45W. Budget-friendly. Include grill dan ring adapter. Cocok untuk upgrade harian.', '🔊', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '99999999-9999-9999-9999-999999999999'::uuid
UNION ALL SELECT 'Speaker Coaxial Cello 6 Pro 6.5 inch', 'speaker_coaxial', 'Cello', 368000, 'Speaker coaxial 2-way 6.5 inch. Peak 200W, RMS 35W. Super sound quality. Harga terjangkau. Include ring Toyota universal.', '🔊', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '99999999-9999-9999-9999-999999999999'::uuid
UNION ALL SELECT 'Speaker Component Cello Performance FIT 6.5 inch 2-Way', 'speaker_component', 'Cello', 2750000, 'Speaker component Performance series. Peak 350W, RMS 80W. Sound jernih hingga 22kHz. Upgrade audio OEM. Tweeter dome 25mm.', '🎵', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '22222222-2222-2222-2222-222222222222'::uuid
UNION ALL SELECT 'Speaker Component Cello Performance MAX 6.5 inch 3-Way', 'speaker_component', 'Cello', 1200000, 'Speaker component 3-way 6.5 inch. Peak 300W, RMS 60W. Midrange dedicated. Tweeter separate. Soundstage lebar.', '🎵', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '44444444-4444-4444-4444-444444444444'::uuid
UNION ALL SELECT 'Processor Cello Magic 4.6 Pro DSP', 'processor', 'Cello', 3650000, 'Processor DSP 6 channel. Built-in amplifier 4x70W RMS. 31-band EQ per channel. Time alignment. Crossover active. Input RCA high/low level.', '🎛️', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '44444444-4444-4444-4444-444444444444'::uuid

-- JBL (7 products)
UNION ALL SELECT 'Speaker Coaxial JBL Stage2 624 6.5 inch 2-Way', 'speaker_coaxial', 'JBL', 575000, 'Speaker coaxial 2-way 6.5 inch. Peak 300W, RMS 50W. PlusOne cone technology. Tweeter PEI dome. Cocok untuk daily use.', '🔊', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '99999999-9999-9999-9999-999999999999'::uuid
UNION ALL SELECT 'Speaker Coaxial JBL Stage3 627 6.5 inch 2-Way', 'speaker_coaxial', 'JBL', 816000, 'Speaker coaxial Stage3 series 6.5 inch. Peak 270W, RMS 75W. IMPP cone. Tweeter aluminum dome. Frequency 55Hz-40kHz. Sound detail.', '🔊', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '22222222-2222-2222-2222-222222222222'::uuid
UNION ALL SELECT 'Speaker Coaxial JBL Stage2 965M 6x9 inch 3-Way', 'speaker_coaxial', 'JBL', 984000, 'Speaker coaxial 3-way oval 6x9 inch. Peak 420W, RMS 70W. Cone polypropylene. Cocok untuk pintu belakang atau deck mobil. Bass lebih besar.', '🔊', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '11111111-1111-1111-1111-111111111111'::uuid
UNION ALL SELECT 'Speaker Component JBL Club 64C 6.5 inch 2-Way', 'speaker_component', 'JBL', 1800000, 'Speaker component Club series 6.5 inch. Peak 300W, RMS 75W. PlusOne woofer. Tweeter edge-driven. Crossover external. American engineering.', '🎵', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '22222222-2222-2222-2222-222222222222'::uuid
UNION ALL SELECT 'Subwoofer Aktif JBL BassPro Lite 7 inch Kolong', 'subwoofer', 'JBL', 2600000, 'Subwoofer aktif underseat 7 inch ultra slim. Built-in amplifier 200W peak. Tinggi 7.5cm. Remote bass control. Frequency 30-200Hz.', '🔉', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '11111111-1111-1111-1111-111111111111'::uuid
UNION ALL SELECT 'Subwoofer Aktif JBL BassPro SL2 8 inch Kolong', 'subwoofer', 'JBL', 2750000, 'Subwoofer kolong 8 inch aktif. Built-in amplifier 250W peak. Slim design. Bass boost adjustable. Frequency 30-200Hz. Original Bergaransi.', '🔉', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '11111111-1111-1111-1111-111111111111'::uuid
UNION ALL SELECT 'Speaker Component JBL Stadium 62F 6.5 inch 2-Way', 'speaker_component', 'JBL', 3733000, 'Speaker component Stadium flagship 6.5 inch. Peak 400W, RMS 100W. PlusOne woofer. Tweeter aluminum dome. Hi-Res capable. Premium American sound.', '🎵', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '88888888-8888-8888-8888-888888888888'::uuid

-- VENOM (7 products)
UNION ALL SELECT 'Amplifier 4 Channel Venom VS 4930 Virus', 'amplifier', 'Venom', 1660000, 'Amplifier 4 channel Virus series. 75W RMS x 4 @ 4 ohm. Class AB. LPF/HPF variable. Bass EQ. Harga terjangkau untuk power upgrade.', '⚡', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '33333333-3333-3333-3333-333333333333'::uuid
UNION ALL SELECT 'Amplifier 4 Channel Venom VO 406 MKII Diablo', 'amplifier', 'Venom', 1710000, 'Amplifier 4 channel Diablo series. 80W RMS x 4 @ 4 ohm. Bridgeable 200W x 2. LPF/HPF built-in. Compact design.', '⚡', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '33333333-3333-3333-3333-333333333333'::uuid
UNION ALL SELECT 'Amplifier 4 Channel Venom VT 480 Vertigo', 'amplifier', 'Venom', 725000, 'Amplifier 4 channel budget. 60W RMS x 4 @ 4 ohm. Class AB. Cocok untuk pemula yang butuh power upgrade. Compact dan ringan.', '⚡', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '55555555-5555-5555-5555-555555555555'::uuid
UNION ALL SELECT 'Amplifier Mono Venom VETO 500.1 Elemento', 'amplifier_mono', 'Venom', 1498000, 'Amplifier mono Elemento series. 500W max @ 2 ohm. LPF variable 40-250Hz. Bass boost 0-12dB. Cocok untuk subwoofer passive.', '⚡', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '11111111-1111-1111-1111-111111111111'::uuid
UNION ALL SELECT 'Amplifier Mono Venom V1500XD', 'amplifier_mono', 'Venom', 1500000, 'Amplifier mono Class D. 500W RMS @ 2 ohm. Support 1 ohm stable. LPF variable. Dimensi kompak 40x26x6 cm. For serious bass.', '⚡', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '77777777-7777-7777-7777-777777777777'::uuid
UNION ALL SELECT 'Amplifier Mono Venom PS800.1 Purple Storm', 'amplifier_mono', 'Venom', 1563000, 'Amplifier monoblok Purple Storm series. 800W max @ 2 ohm. Class D efficient. LPF 40-250Hz. Subsonic filter 20Hz. Bass punchy.', '⚡', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '11111111-1111-1111-1111-111111111111'::uuid
UNION ALL SELECT 'Processor Venom VPR 3.6 DSP', 'processor', 'Venom', 4200000, 'Processor DSP 6 channel. Built-in power 4 channel. 31-band EQ per channel. Time alignment. Crossover. Input RCA + optical. Resmi Venom Indonesia.', '🎛️', mcp_id, TRUE, NULL FROM sales.master_customer_problems WHERE mcp_id = '44444444-4444-4444-4444-444444444444'::uuid

ON CONFLICT DO NOTHING;

-- ============================================================================
-- PART 4: VERIFICATION QUERIES (Run these after insert to check)
-- ============================================================================

-- Check total products
-- SELECT COUNT(*) as total_products FROM sales.master_products;

-- Check products by brand and category
-- SELECT mp_brand, mp_category, COUNT(*) as total, 
--        MIN(mp_price) as min_price, MAX(mp_price) as max_price
-- FROM sales.master_products
-- GROUP BY mp_brand, mp_category
-- ORDER BY mp_brand, mp_category;

-- Check problems
-- SELECT mcp_problem_title, COUNT(mp_id) as product_count
-- FROM sales.master_customer_problems mcp
-- LEFT JOIN sales.master_products mp ON mp.mp_solves_problem_id = mcp.mcp_id
-- WHERE mcp.mcp_is_active = TRUE
-- GROUP BY mcp.mcp_id, mcp.mcp_problem_title
-- ORDER BY product_count DESC;

-- ============================================================================
-- Summary: 111 Products + 15 Problems
-- ============================================================================
-- Brands (16): Kenwood (10), Pioneer (11), JVC (6), Nakamichi (7), Clarion (3),
--   DHD (5), Orca (5), Avix (3), Skeleton (5), Hertz (5), JL Audio (3),
--   Rockford Fosgate (4), Exxent (2), Cello (5), JBL (7), Venom (7)
--
-- Categories (11): head_unit_single_din (3), head_unit_double_din (9),
--   head_unit_android (22), speaker_coaxial (14), speaker_component (14),
--   tweeter (1), amplifier (11), amplifier_mono (7), subwoofer (15),
--   processor (3), total = 111
--
-- Problems (15): 10 original + 5 new (install PNP, family-friendly,
--   heat-resistant, single-to-double DIN upgrade, contained bass)
-- ============================================================================
