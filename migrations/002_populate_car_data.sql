-- ============================================================================
-- MIGRATION 2: Populate master_cars with popular Indonesian cars
-- ============================================================================
-- Purpose: Add comprehensive car data for recommendation system
-- Date: 2026-04-14
-- ============================================================================

-- MPV (Multi Purpose Vehicle) - Large
INSERT INTO sales.master_cars (mc_id, mc_brand, mc_model, mc_type, mc_size_category, mc_dashboard_type, mc_door_count, mc_cabin_volume, mc_subwoofer_space, mc_factory_speaker_size, mc_factory_speaker_count, mc_special_notes) VALUES
('11111111-1111-1111-1111-111111111101', 'Mitsubishi', 'Xpander', 'MPV', 'large', 'double_din', 4, 'Luas, 3 row seats', 'spacious', '6.5 inch', 4, 'Dashboard tinggi, perlu dash kit untuk double DIN'),
('11111111-1111-1111-1111-111111111102', 'Toyota', 'Avanza', 'MPV', 'large', 'double_din', 4, 'Luas, 3 row seats', 'spacious', '6.5 inch', 4, 'Sangat populer, banyak pilihan head unit'),
('11111111-1111-1111-1111-111111111103', 'Daihatsu', 'Xenia', 'MPV', 'large', 'double_din', 4, 'Luas, 3 row seats', 'spacious', '6.5 inch', 4, 'Sama platform dengan Avanza'),
('11111111-1111-1111-1111-111111111104', 'Toyota', 'Innova', 'MPV', 'large', 'double_din', 4, 'Sangat luas, premium MPV', 'spacious', '6x9 inch', 6, 'Premium MPV, speaker factory sudah bagus'),
('11111111-1111-1111-1111-111111111105', 'Suzuki', 'Ertiga', 'MPV', 'medium', 'double_din', 4, 'Sedang, 3 row seats compact', 'moderate', '6.5 inch', 4, 'Dashboard lebih rendah dari Xpander'),
('11111111-1111-1111-1111-111111111106', 'Honda', 'Mobilio', 'MPV', 'medium', 'double_din', 4, 'Sedang, 3 row seats', 'moderate', '6.5 inch', 4, 'Honda sensitivity steering, perlu adapter'),
('11111111-1111-1111-1111-111111111107', 'Wuling', 'Confero', 'MPV', 'medium', 'double_din', 4, 'Sedang, 3 row seats', 'moderate', '6.5 inch', 4, 'Value MPV, budget audio friendly'),
('11111111-1111-1111-1111-111111111108', 'Nissan', 'Livina', 'MPV', 'large', 'double_din', 4, 'Luas, 3 row seats', 'spacious', '6.5 inch', 4, 'Platform sama dengan Xpander'),
('11111111-1111-1111-1111-111111111109', 'Hyundai', 'Stargazer', 'MPV', 'large', 'double_din', 4, 'Luas, 3 row seats premium', 'spacious', '6.5 inch', 4, 'MPV baru, fitur modern'),
('11111111-1111-1111-1111-111111111110', 'Toyota', 'Alphard', 'MPV', 'large', 'android_custom', 4, 'Sangat luas, luxury MPV', 'spacious', '6x9 inch', 8, 'Luxury MPV, head unit custom Android'),
('11111111-1111-1111-1111-111111111111', 'Toyota', 'Veloz', 'MPV', 'large', 'double_din', 4, 'Luas, 3 row seats', 'spacious', '6.5 inch', 4, 'New Avanza generasi baru'),
('11111111-1111-1111-1111-111111111112', 'Daihatsu', 'Xenia (New)', 'MPV', 'large', 'double_din', 4, 'Luas, 3 row seats', 'spacious', '6.5 inch', 4, 'New Xenia, sama dengan Veloz');

-- City Car / ACGC (Affordable Green Car) - Small
INSERT INTO sales.master_cars (mc_id, mc_brand, mc_model, mc_type, mc_size_category, mc_dashboard_type, mc_door_count, mc_cabin_volume, mc_subwoofer_space, mc_factory_speaker_size, mc_factory_speaker_count, mc_special_notes) VALUES
('22222222-2222-2222-2222-222222222201', 'Honda', 'Brio', 'City Car', 'small', 'single_din', 4, 'Kecil, 2 row seats', 'limited', '5.25 inch', 2, 'Dashboard single DIN, space subwoofer terbatas'),
('22222222-2222-2222-2222-222222222202', 'Toyota', 'Agya', 'City Car', 'small', 'single_din', 4, 'Kecil, 2 row seats', 'limited', '5.25 inch', 2, 'Sama platform dengan Ayla'),
('22222222-2222-2222-2222-222222222203', 'Daihatsu', 'Ayla', 'City Car', 'small', 'single_din', 4, 'Kecil, 2 row seats', 'limited', '5.25 inch', 2, 'City car populer, audio budget friendly'),
('22222222-2222-2222-2222-222222222204', 'Suzuki', 'S-Presso', 'City Car', 'small', 'single_din', 4, 'Kecil, 2 row seats', 'limited', '4 inch', 2, 'Sangat compact, perlu speaker adapter'),
('22222222-2222-2222-2222-222222222205', 'Toyota', 'Calya', 'City Car', 'small', 'single_din', 4, 'Kecil-Sedang, 2 row seats', 'limited', '5.25 inch', 2, 'Lebih besar dari Agya, 3 row opsional'),
('22222222-2222-2222-2222-222222222206', 'Daihatsu', 'Sigra', 'City Car', 'small', 'single_din', 4, 'Kecil-Sedang, 3 row compact', 'limited', '5.25 inch', 2, 'Sama platform dengan Calya'),
('22222222-2222-2222-2222-222222222207', 'Wuling', 'Air EV', 'City Car', 'small', 'android_custom', 2, 'Kecil, 2 door EV', 'limited', '4 inch', 2, 'Electric vehicle, perlu instalasi khusus'),
('22222222-2222-2222-2222-222222222208', 'Hyundai', 'i10', 'City Car', 'small', 'single_din', 4, 'Kecil, 2 row seats', 'limited', '5.25 inch', 2, 'City car premium, audio quality bagus');

-- SUV (Sport Utility Vehicle) - Medium to Large
INSERT INTO sales.master_cars (mc_id, mc_brand, mc_model, mc_type, mc_size_category, mc_dashboard_type, mc_door_count, mc_cabin_volume, mc_subwoofer_space, mc_factory_speaker_size, mc_factory_speaker_count, mc_special_notes) VALUES
('33333333-3333-3333-3333-333333333301', 'Toyota', 'Fortuner', 'SUV', 'large', 'double_din', 4, 'Luas, premium SUV', 'spacious', '6x9 inch', 6, 'Premium SUV, factory audio sudah bagus'),
('33333333-3333-3333-3333-333333333302', 'Mitsubishi', 'Pajero Sport', 'SUV', 'large', 'double_din', 4, 'Luas, premium SUV', 'spacious', '6x9 inch', 6, 'Sama platform dengan Fortuner'),
('33333333-3333-3333-3333-333333333303', 'Honda', 'CR-V', 'SUV', 'medium', 'double_din', 4, 'Sedang-Luas, 2 row+opsi 3', 'spacious', '6.5 inch', 4, 'SUV premium, sound quality focus'),
('33333333-3333-3333-3333-333333333304', 'Mazda', 'CX-5', 'SUV', 'medium', 'double_din', 4, 'Sedang, premium interior', 'spacious', '6.5 inch', 4, 'Bose audio system factory, upgrade path'),
('33333333-3333-3333-3333-333333333305', 'Hyundai', 'Tucson', 'SUV', 'medium', 'double_din', 4, 'Sedang, modern SUV', 'spacious', '6.5 inch', 4, 'SUV baru, fitur modern'),
('33333333-3333-3333-3333-333333333306', 'Hyundai', 'Santa Fe', 'SUV', 'large', 'double_din', 4, 'Luas, 3 row seats', 'spacious', '6x9 inch', 6, 'SUV besar, premium audio'),
('33333333-3333-3333-3333-333333333307', 'Toyota', 'Rush', 'SUV', 'medium', 'double_din', 4, 'Sedang, 3 row compact', 'moderate', '6.5 inch', 4, 'Sama platform dengan Xenia/Avanza'),
('33333333-3333-3333-3333-333333333308', 'Daihatsu', 'Terios', 'SUV', 'medium', 'double_din', 4, 'Sedang, 3 row compact', 'moderate', '6.5 inch', 4, 'Sama dengan Rush, styling berbeda'),
('33333333-3333-3333-3333-333333333309', 'Suzuki', 'XL7', 'SUV', 'medium', 'double_din', 4, 'Sedang, 3 row seats', 'moderate', '6.5 inch', 4, 'Crossover dari Ertiga, lebih tinggi'),
('33333333-3333-3333-3333-333333333310', 'Wuling', 'Almaz', 'SUV', 'medium', 'android_custom', 4, 'Sedang, tech-focused SUV', 'spacious', '6.5 inch', 4, 'Head unit Android besar factory'),
('33333333-3333-3333-3333-333333333311', 'Toyota', 'Corolla Cross', 'SUV', 'medium', 'double_din', 4, 'Sedang, compact SUV', 'spacious', '6.5 inch', 4, 'Premium compact, hybrid option'),
('33333333-3333-3333-3333-333333333312', 'Mitsubishi', 'Xpander Cross', 'SUV', 'medium', 'double_din', 4, 'Sedang, raised MPV', 'moderate', '6.5 inch', 4, 'Xpander dengan ground clearance tinggi');

-- Sedan - Small to Medium
INSERT INTO sales.master_cars (mc_id, mc_brand, mc_model, mc_type, mc_size_category, mc_dashboard_type, mc_door_count, mc_cabin_volume, mc_subwoofer_space, mc_factory_speaker_size, mc_factory_speaker_count, mc_special_notes) VALUES
('44444444-4444-4444-4444-444444444401', 'Honda', 'Civic', 'Sedan', 'medium', 'double_din', 4, 'Sedang, sporty sedan', 'moderate', '6.5 inch', 4, 'Sporty sedan, sound quality focus'),
('44444444-4444-4444-4444-444444444402', 'Honda', 'Accord', 'Sedan', 'large', 'double_din', 4, 'Luas, premium sedan', 'spacious', '6x9 inch', 6, 'Premium sedan, factory audio bagus'),
('44444444-4444-4444-4444-444444444403', 'Toyota', 'Camry', 'Sedan', 'large', 'double_din', 4, 'Luas, executive sedan', 'spacious', '6x9 inch', 6, 'Executive sedan, JBL factory option'),
('44444444-4444-4444-4444-444444444404', 'Toyota', 'Corolla Altis', 'Sedan', 'medium', 'double_din', 4, 'Sedang, popular sedan', 'moderate', '6.5 inch', 4, 'Sedan populer, banyak pilihan audio'),
('44444444-4444-4444-4444-444444444405', 'Mazda', 'Mazda 3', 'Sedan', 'medium', 'double_din', 4, 'Sedang, premium sedan', 'moderate', '6.5 inch', 4, 'Premium interior, Bose option'),
('44444444-4444-4444-4444-444444444406', 'Hyundai', 'Elantra', 'Sedan', 'medium', 'double_din', 4, 'Sedang, modern sedan', 'moderate', '6.5 inch', 4, 'Design modern, fitur lengkap'),
('44444444-4444-4444-4444-444444444407', 'Honda', 'City', 'Sedan', 'small', 'single_din', 4, 'Kecil-Sedang, compact sedan', 'limited', '6.5 inch', 2, 'Compact sedan, space terbatas'),
('44444444-4444-4444-4444-444444444408', 'Toyota', 'Vios', 'Sedan', 'small', 'single_din', 4, 'Kecil-Sedang, compact sedan', 'limited', '6.5 inch', 2, 'Sama platform dengan City');

-- Hatchback - Small to Medium
INSERT INTO sales.master_cars (mc_id, mc_brand, mc_model, mc_type, mc_size_category, mc_dashboard_type, mc_door_count, mc_cabin_volume, mc_subwoofer_space, mc_factory_speaker_size, mc_factory_speaker_count, mc_special_notes) VALUES
('55555555-5555-5555-5555-555555555501', 'Honda', 'Jazz', 'Hatchback', 'small', 'single_din', 4, 'Kecil-Sedang, magic seats', 'moderate', '6.5 inch', 4, 'Flexibel, space bagus untuk hatchback'),
('55555555-5555-5555-5555-555555555502', 'Suzuki', 'Baleno', 'Hatchback', 'small', 'single_din', 4, 'Kecil-Sedang, 5 door', 'moderate', '6.5 inch', 4, 'Hatchback value, audio budget friendly'),
('55555555-5555-5555-5555-555555555503', 'Suzuki', 'Swift', 'Hatchback', 'small', 'single_din', 4, 'Kecil, sporty hatchback', 'limited', '6.5 inch', 2, 'Sporty, space audio terbatas'),
('55555555-5555-5555-5555-555555555504', 'Mitsubishi', 'Xforce', 'Hatchback', 'medium', 'double_din', 4, 'Sedang, crossover hatchback', 'moderate', '6.5 inch', 4, 'New model, crossover styling'),
('55555555-5555-5555-5555-555555555505', 'Toyota', 'Yaris', 'Hatchback', 'small', 'single_din', 4, 'Kecil, sporty hatchback', 'limited', '6.5 inch', 4, 'Sporty hatch, populer untuk modifikasi'),
('55555555-5555-5555-5555-555555555506', 'Honda', 'HR-V', 'Hatchback', 'medium', 'double_din', 4, 'Sedang, crossover', 'moderate', '6.5 inch', 4, 'Crossover, space cukup');

-- Pickup / Commercial Vehicle
INSERT INTO sales.master_cars (mc_id, mc_brand, mc_model, mc_type, mc_size_category, mc_dashboard_type, mc_door_count, mc_cabin_volume, mc_subwoofer_space, mc_factory_speaker_size, mc_factory_speaker_count, mc_special_notes) VALUES
('66666666-6666-6666-6666-666666666601', 'Mitsubishi', 'L300', 'Pickup', 'medium', 'single_din', 2, 'Kecil, 2 door cabin', 'limited', '5.25 inch', 2, 'Kendaraan niaga, vibration tinggi, perlu durable audio'),
('66666666-6666-6666-6666-666666666602', 'Suzuki', 'Carry', 'Pickup', 'small', 'single_din', 2, 'Kecil, 2 door cabin', 'limited', '4 inch', 2, 'Pickup kecil, budget audio priority'),
('66666666-6666-6666-6666-666666666603', 'Daihatsu', 'Gran Max', 'Pickup', 'small', 'single_din', 2, 'Kecil, 2 door cabin', 'limited', '4 inch', 2, 'Pickup niaga, simple audio setup'),
('66666666-6666-6666-6666-666666666604', 'Toyota', 'Hilux', 'Pickup', 'medium', 'double_din', 4, 'Sedang, 4 door pickup', 'moderate', '6.5 inch', 4, 'Double cabin, space lebih baik'),
('66666666-6666-6666-6666-666666666605', 'Ford', 'Ranger', 'Pickup', 'medium', 'double_din', 4, 'Sedang, 4 door pickup', 'moderate', '6x9 inch', 6, 'Premium pickup, factory audio bagus'),
('66666666-6666-6666-6666-666666666606', 'Isuzu', 'D-Max', 'Pickup', 'medium', 'double_din', 4, 'Sedang, 4 door pickup', 'moderate', '6.5 inch', 4, 'Pickup tangguh, audio durable perlu');

-- Van / Minibus
INSERT INTO sales.master_cars (mc_id, mc_brand, mc_model, mc_type, mc_size_category, mc_dashboard_type, mc_door_count, mc_cabin_volume, mc_subwoofer_space, mc_factory_speaker_size, mc_factory_speaker_count, mc_special_notes) VALUES
('77777777-7777-7777-7777-777777777701', 'Toyota', 'HiAce', 'Van', 'large', 'android_custom', 4, 'Sangat luas, minibus', 'spacious', '6x9 inch', 8, 'Minibus besar, multiple speaker zones'),
('77777777-7777-7777-7777-777777777702', 'Daihatsu', 'Luxio', 'Van', 'medium', 'single_din', 4, 'Sedang, minibus compact', 'moderate', '6.5 inch', 4, 'Minibus budget, simple audio'),
('77777777-7777-7777-7777-777777777703', 'Suzuki', 'APV', 'Van', 'medium', 'double_din', 4, 'Sedang, minibus', 'moderate', '6.5 inch', 4, 'Minibus populer, upgrade audio mudah');

-- Add synonyms/aliases for better search
-- These are alternate names people might use
INSERT INTO sales.master_cars (mc_id, mc_brand, mc_model, mc_type, mc_size_category, mc_dashboard_type, mc_door_count, mc_cabin_volume, mc_subwoofer_space, mc_factory_speaker_size, mc_factory_speaker_count, mc_special_notes) VALUES
('88888888-8888-8888-8888-888888888801', 'Mitsubishi', 'Xpander Hybrid', 'MPV', 'large', 'double_din', 4, 'Luas, 3 row seats', 'spacious', '6.5 inch', 4, 'Varian hybrid, audio sama dengan Xpander biasa'),
('88888888-8888-8888-8888-888888888802', 'Toyota', 'Avanza Veloz', 'MPV', 'large', 'double_din', 4, 'Luas, 3 row seats', 'spacious', '6.5 inch', 4, 'Nama lain Veloz/Avanza generasi baru'),
('88888888-8888-8888-8888-888888888803', 'Daihatsu', 'Xenia R', 'MPV', 'large', 'double_din', 4, 'Luas, 3 row seats', 'spacious', '6.5 inch', 4, 'Varian Xenia');
