--
-- PostgreSQL database dump
--

-- Dumped from database version 17.8 (a48d9ca)
-- Dumped by pg_dump version 17.0

-- Started on 2026-04-13 03:55:13

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 8 (class 2615 OID 24915)
-- Name: sales; Type: SCHEMA; Schema: -; Owner: neondb_owner
--

CREATE SCHEMA sales;


ALTER SCHEMA sales OWNER TO neondb_owner;

--
-- TOC entry 318 (class 1255 OID 73734)
-- Name: get_recommendations(uuid); Type: FUNCTION; Schema: sales; Owner: neondb_owner
--

CREATE FUNCTION sales.get_recommendations(problem_id uuid) RETURNS TABLE(product_id uuid, product_name text, product_category text, product_brand text, product_price numeric, product_description text, product_image text, problem_title text, problem_description text, recommended_approach text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.mp_id,
        p.mp_name,
        p.mp_category,
        p.mp_brand,
        p.mp_price,
        p.mp_description,
        p.mp_image,
        prob.mcp_problem_title,
        prob.mcp_description,
        prob.mcp_recommended_approach
    FROM sales.master_products p
    JOIN sales.master_customer_problems prob ON prob.mcp_id = p.mp_solves_problem_id
    WHERE p.mp_solves_problem_id = problem_id
      AND p.mp_is_active = TRUE
      AND prob.mcp_is_active = TRUE
    ORDER BY p.mp_name ASC;
END;
$$;


ALTER FUNCTION sales.get_recommendations(problem_id uuid) OWNER TO neondb_owner;

--
-- TOC entry 309 (class 1255 OID 81920)
-- Name: search_knowledge(public.vector, double precision, integer); Type: FUNCTION; Schema: sales; Owner: neondb_owner
--

CREATE FUNCTION sales.search_knowledge(query_embedding public.vector, match_threshold double precision DEFAULT 0.70, match_count integer DEFAULT 5) RETURNS TABLE(mkc_id uuid, mkc_content text, similarity double precision)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        k.mkc_id,
        k.mkc_content,
        1 - (k.mkc_embedding <=> query_embedding) AS similarity
    FROM sales.master_knowledge_chunks k
    WHERE k.mkc_is_active = TRUE
      AND k.mkc_embedding IS NOT NULL
      AND 1 - (k.mkc_embedding <=> query_embedding) > match_threshold
    ORDER BY k.mkc_embedding <=> query_embedding
    LIMIT match_count;
END;
$$;


ALTER FUNCTION sales.search_knowledge(query_embedding public.vector, match_threshold double precision, match_count integer) OWNER TO neondb_owner;

--
-- TOC entry 236 (class 1255 OID 73733)
-- Name: search_problem(public.vector, double precision, integer); Type: FUNCTION; Schema: sales; Owner: neondb_owner
--

CREATE FUNCTION sales.search_problem(query_embedding public.vector, match_threshold double precision DEFAULT 0.40, match_count integer DEFAULT 3) RETURNS TABLE(mcp_id uuid, mcp_problem_title text, mcp_description text, mcp_recommended_approach text, similarity double precision)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.mcp_id,
        p.mcp_problem_title,
        p.mcp_description,
        p.mcp_recommended_approach,
        1 - (p.mcp_embedding <=> query_embedding) AS similarity
    FROM sales.master_customer_problems p
    WHERE p.mcp_is_active = TRUE
      AND p.mcp_embedding IS NOT NULL
      AND 1 - (p.mcp_embedding <=> query_embedding) > match_threshold
    ORDER BY p.mcp_embedding <=> query_embedding
    LIMIT match_count;
END;
$$;


ALTER FUNCTION sales.search_problem(query_embedding public.vector, match_threshold double precision, match_count integer) OWNER TO neondb_owner;

--
-- TOC entry 228 (class 1255 OID 81921)
-- Name: search_problem_lexical(text, integer); Type: FUNCTION; Schema: sales; Owner: neondb_owner
--

CREATE FUNCTION sales.search_problem_lexical(search_query text, match_count integer DEFAULT 3) RETURNS TABLE(mcp_id uuid, mcp_problem_title text, similarity double precision)
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN QUERY
	SELECT
		p.mcp_id,
		p.mcp_problem_title,
		ts_rank_cd(
			to_tsvector('english', p.mcp_problem_title || ' ' || COALESCE(p.mcp_description, '')),
			plainto_tsquery('english', search_query)
		)::FLOAT AS similarity
	FROM sales.master_customer_problems p
	WHERE p.mcp_is_active = TRUE
	AND to_tsvector('english', p.mcp_problem_title || ' ' || COALESCE(p.mcp_description, '')) @@ plainto_tsquery('english', search_query)
	ORDER BY similarity DESC
	LIMIT match_count;
END;
$$;


ALTER FUNCTION sales.search_problem_lexical(search_query text, match_count integer) OWNER TO neondb_owner;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 221 (class 1259 OID 24929)
-- Name: master_customer_problems; Type: TABLE; Schema: sales; Owner: neondb_owner
--

CREATE TABLE sales.master_customer_problems (
    mcp_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    mcp_problem_title text NOT NULL,
    mcp_keywords text[],
    mcp_description text,
    mcp_embedding public.vector(1024),
    mcp_is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    mcp_recommended_approach text
);


ALTER TABLE sales.master_customer_problems OWNER TO neondb_owner;

--
-- TOC entry 220 (class 1259 OID 24916)
-- Name: master_products; Type: TABLE; Schema: sales; Owner: neondb_owner
--

CREATE TABLE sales.master_products (
    mp_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    mp_name text NOT NULL,
    mp_category text NOT NULL,
    mp_brand text,
    mp_price numeric(12,2),
    mp_description text,
    mp_features text[],
    mp_power_spec text,
    mp_is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    mp_image text,
    mp_solves_problem_id uuid,
    mp_embedding public.vector(1024)
);


ALTER TABLE sales.master_products OWNER TO neondb_owner;

--
-- TOC entry 3631 (class 0 OID 24929)
-- Dependencies: 221
-- Data for Name: master_customer_problems; Type: TABLE DATA; Schema: sales; Owner: neondb_owner
--

COPY sales.master_customer_problems (mcp_id, mcp_problem_title, mcp_keywords, mcp_description, mcp_embedding, mcp_is_active, created_at, mcp_recommended_approach) FROM stdin;
4fe8ab59-0f18-411b-8d75-9c5c746e57fd	Suara pecah dan distorsi di volume tinggi	\N	Speaker mengalami distorsi saat volume dinaikkan. Suara tidak bersih dan pecah.	\N	t	2026-04-10 12:57:09.651084+00	1. Upgrade speaker dengan power handling lebih tinggi\n2. Tambah amplifier agar speaker tidak overwork\n3. Upgrade head unit dengan output lebih bersih\n4. Cek wiring dan grounding
bad8f281-a1ff-4abe-8238-89365e95e58d	Soundstage sempit, suara terasa datar	\N	Posisi suara terasa menyatu dan tidak ada kedalaman. Tidak terasa seperti live performance.	\N	t	2026-04-10 12:57:09.651084+00	1. Upgrade speaker component dengan tweeter terpisah\n2. Pasang head unit dengan DSP untuk tuning\n3. Tambah amplifier untuk dynamic range\n4. Setting time alignment dan staging
a1b2c3d4-e5f6-7890-abcd-ef1234567890	Head Unit tidak bisa connect Bluetooth	\N	Bluetooth di Head Unit tidak terdeteksi oleh HP atau sering putus-putus.	\N	t	2026-04-10 12:57:09.651084+00	1. Upgrade Head Unit dengan Bluetooth 5.0+\n2. Pastikan kompatibilitas dengan HP\n3. Reset pairing dan reconnect\n4. Alternatif: Pakai Bluetooth receiver external
c3d4e5f6-a7b8-9012-cdef-123456789012	Ingin suara natural dan original seperti studio	\N	Customer ingin suara yang akurat, tidak berlebihan, seperti rekaman asli di studio.	\N	t	2026-04-10 12:57:09.651084+00	1. Speaker component quality tinggi (flat response)\n2. Amplifier dengan THD rendah\n3. Head Unit dengan DAC bagus\n4. DSP untuk fine tuning dan time alignment
1c534f23-d636-41ca-9719-ee9493bf70ad	Bass kurang bertenaga	\N	Suara bass terasa tipis dan tidak menggetarkan, customer ingin bass yang lebih powerful untuk musik EDM, hip-hop, dan reggae.	\N	t	2026-04-10 12:57:09.651084+00	1. Pasang Subwoofer 10-12 inch dengan amplifier dedicated\n2. Upgrade amplifier mono untuk power lebih besar\n3. Setting gain dan crossover yang tepat\n4. Pastikan box subwoofer sesuai volume
d71440dd-5d04-4bf2-a4ca-c630d21063cc	Vocal dan mid range kurang jelas	\N	Suara vocal penyanyi tidak terdengar jelas, tertutup bass atau musik. Mid range terasa tipis.	\N	t	2026-04-10 14:10:41.044981+00	1. Upgrade speaker component 2-way untuk vocal lebih jelas\n2. Tambah amplifier untuk power lebih stabil\n3. Setting crossover dan EQ yang tepat\n4. Posisi speaker dan tweeter yang benar
8b507336-5b54-4035-be10-a437622a6d7a	Ingin upgrade audio tapi budget terbatas	\N	Customer mau upgrade sistem audio tapi perlu dilakukan bertahap sesuai budget.	\N	t	2026-04-10 14:10:41.044981+00	1. Mulai dari speaker dulu (paling terasa perbedaannya)\n2. Tambah subwoofer jika suka bass\n3. Upgrade head unit untuk fitur dan kontrol\n4. Tambah amplifier di akhir untuk penyempurnaan
55a2ab16-143c-466d-903a-08b454634306	Ingin audio lebih keras untuk kompetisi/sound pressure	\N	Customer ingin sistem audio yang sangat keras untuk keperluan kompetisi SPL atau sound pressure.	\N	t	2026-04-10 14:10:41.044981+00	1. Pasang subwoofer multiple dengan box besar\n2. Amplifier mono power besar (1000W+)\n3. Upgrade kelistrikan (alternator + aki)\n4. Head Unit dengan pre-out voltage tinggi
0745ed72-7722-4991-96a2-33948e00631f	Speaker bawaan mobil jelek, mau ganti	\N	Speaker original pabrik terasa flat dan tidak bertenaga. Customer ingin upgrade langsung terasa.	\N	t	2026-04-10 14:31:34.383893+00	1. Ganti dengan speaker coaxial plug-and-play (mudah)\n2. Upgrade ke component speaker (lebih baik)\n3. Tambah tweeter external untuk detail\n4. Pastikan ukuran sesuai dudukan original
8e2c0b60-4f07-4cd5-91ef-5bb2a59709b2	Build sistem audio baru dari nol	\N	Customer baru beli mobil dan mau langsung build sistem audio yang lengkap dan bagus.	\N	t	2026-04-10 14:31:34.383893+00	1. Head Unit dengan fitur lengkap (DSP, Bluetooth, USB)\n2. Speaker component 2-way atau 3-way\n3. Subwoofer 10-12 inch dengan box\n4. Amplifier 4 channel + mono\n5. Kabel dan instalasi yang benar
43e3985c-fbf1-43c1-bb95-14f57024ab54	Ingin install audio tapi tidak mau potong kabel	\N	Customer ingin upgrade audio mobil tetapi tidak mau merusak kabel original pabrik. Ingin instalasi yang reversible dan rapi.	\N	t	2026-04-12 20:31:05.251649+00	Gunakan produk plug-and-play dengan soket PNP khusus mobil. Head unit dengan harness adapter. Speaker dengan ring adapter tanpa potong kabel. Instalasi bolt-on.
4dcf193c-d484-4fe4-9814-73d5823bf132	Butuh audio yang cocok untuk keluarga dan anak-anak	\N	Customer butuh sistem audio yang aman untuk anak-anak, volume bisa dibatasi, dan ada fitur entertainment seperti layar untuk video.	\N	t	2026-04-12 20:31:05.251649+00	Pilih head unit Android dengan layar besar untuk hiburan anak. Parental control built-in. Speaker dengan volume tidak terlalu keras. Subwoofer dengan bass yang tidak berlebihan.
1e0f54ab-acb2-44be-86dd-15b20dd66f1c	Audio sering mati atau trouble dalam panas	\N	Sistem audio mobil sering mati sendiri atau trouble saat cuaca panas. Amplifier overheat. Head unit restart sendiri.	\N	t	2026-04-12 20:31:05.251649+00	Pilih amplifier dengan heatsink besar dan ventilasi baik. Pastikan instalasi tidak tertutup. Gunakan amplifier Class D yang lebih dingin. Head unit dengan thermal protection.
6451ad6c-a60b-4a92-91d8-73b020d802e1	Ingin upgrade dari single DIN ke double DIN	\N	Customer punya mobil dengan head unit single DIN lama dan ingin upgrade ke double DIN dengan layar lebih besar dan fitur modern.	\N	t	2026-04-12 20:31:05.251649+00	Pastikan dashboard mobil support double DIN atau butuh dash kit. Pilih head unit double DIN dengan fitur lengkap. Instalasi termasuk wiring harness adapter.
d9628a75-45ec-46ec-8229-213eed57dbf7	Ingin bass yang dalam tapi tidak berisik ke luar	\N	Customer ingin bass yang kuat di dalam kabin tetapi tidak mengganggu orang sekitar atau tetangga saat malam hari. Tidak ingin "bocor" ke luar.	\N	t	2026-04-12 20:31:05.251649+00	Gunakan subwoofer sealed box (bukan ported) untuk bass tight dan controlled. Setting low-pass filter tepat. Sound deadening pada pintu dan kabin. Subwoofer kolong lebih contained.
\.


--
-- TOC entry 3630 (class 0 OID 24916)
-- Dependencies: 220
-- Data for Name: master_products; Type: TABLE DATA; Schema: sales; Owner: neondb_owner
--

COPY sales.master_products (mp_id, mp_name, mp_category, mp_brand, mp_price, mp_description, mp_features, mp_power_spec, mp_is_active, created_at, updated_at, mp_image, mp_solves_problem_id, mp_embedding) FROM stdin;
469d3644-4d33-4ed1-a63c-deb48110325a	Head Unit Kenwood KMM-205 Single DIN	head_unit_single_din	Kenwood	1350000.00	Head unit single DIN dengan USB, AUX, dan Bluetooth. Support Spotify dan Android Auto. Output 50W x 4 channel.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	📻	a1b2c3d4-e5f6-7890-abcd-ef1234567890	\N
7a6e28dc-0c62-49ca-873a-ebb131b69ab9	Head Unit Kenwood DMX4707S Double DIN 6.8 inch	head_unit_double_din	Kenwood	4200000.00	Head unit double DIN 6.8 inch layar sentuh. Wireless Apple CarPlay & Android Auto. Built-in DSP 13-band EQ. Output 50W x 4.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	📺	a1b2c3d4-e5f6-7890-abcd-ef1234567890	\N
65630951-5cd1-4565-9766-83c578749217	Head Unit Kenwood DMX7522S Double DIN 6.8 inch	head_unit_double_din	Kenwood	5575000.00	Head unit double DIN flagship. Layar capacitive 6.8 inch. Wireless CarPlay & Android Auto. Hi-Res Audio. DSP 13-band. HDMI input.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	📺	c3d4e5f6-a7b8-9012-cdef-123456789012	\N
82fe2be4-0705-4d9b-9485-62754170a21b	Head Unit Android Kenwood 9 inch 4/64GB	head_unit_android	Kenwood	3200000.00	Head unit Android 9 inch double DIN. RAM 4GB + 64GB. CarPlay & Android Auto wireless. DSP built-in. Layar QLED.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🖥️	a1b2c3d4-e5f6-7890-abcd-ef1234567890	\N
260a6034-2060-45d9-87ad-9b06190da085	Head Unit Android Kenwood 10 inch 6/128GB	head_unit_android	Kenwood	4500000.00	Head unit Android 10 inch layar besar. RAM 6GB + 128GB. QLED display. Wireless CarPlay & Android Auto. DSP 32-band.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🖥️	c3d4e5f6-a7b8-9012-cdef-123456789012	\N
a952d6e0-7617-4976-96e9-e1ac2a8e4a11	Amplifier 4 Channel Kenwood KAC-M3004	amplifier	Kenwood	1900000.00	Amplifier compact 4 channel Class D. 50W RMS x 4 @ 4 ohm. Ukuran kecil cocok untuk mobil kecil. Bridgeable 2 channel 150W x 2.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	⚡	4fe8ab59-0f18-411b-8d75-9c5c746e57fd	\N
a25d4d03-af25-43ba-bc2e-1906f2f3cd92	Amplifier 4 Channel Kenwood KAC-M5004	amplifier	Kenwood	2800000.00	Amplifier 4 channel Class D. 75W RMS x 4 @ 4 ohm. Lebih bertenaga dari KAC-M3004. Compact design. Variable LPF/HPF.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	⚡	4fe8ab59-0f18-411b-8d75-9c5c746e57fd	\N
0cd30136-bc22-427f-a886-be63c87513f1	Speaker Coaxial Kenwood KFC-S1366 5.25 inch	speaker_coaxial	Kenwood	550000.00	Speaker coaxial 5.25 inch 3-way. Peak power 250W, RMS 30W. Cone polypropylene dengan tweeter ceramic. Cocok untuk upgrade speaker bawaan.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🔊	0745ed72-7722-4991-96a2-33948e00631f	\N
a3ccd90c-9e86-4d7e-ad61-4fb88e848358	Speaker Component Kenwood KFC-XS1704 6.5 inch 2-Way	speaker_component	Kenwood	1800000.00	Speaker component 2-way 6.5 inch. Peak power 400W, RMS 60W. Woofer carbon fiber reinforced, tweeter dome 1 inch. Separation lebih baik dari coaxial.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🎵	d71440dd-5d04-4bf2-a4ca-c630d21063cc	\N
41674012-fe4a-4e34-8f64-a80288c52409	Subwoofer Aktif Kenwood KSC-SW11 Kolong	subwoofer	Kenwood	2500000.00	Subwoofer aktif underseat (kolong jok) 8 inch. Built-in amplifier 75W peak. Ultra slim design 7cm. Remote bass level included. Cocok untuk ruang terbatas.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🔉	1c534f23-d636-41ca-9719-ee9493bf70ad	\N
cce942d0-87f3-464e-b95a-030ce9486042	Head Unit Pioneer DEH-S5250BT Single DIN	head_unit_single_din	Pioneer	1650000.00	Head unit single DIN dengan Bluetooth, USB, AUX. Support Spotify, Android Auto. MIXTRAC untuk file navigation. Output 50W x 4.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	📻	a1b2c3d4-e5f6-7890-abcd-ef1234567890	\N
edf5227c-967a-49e2-8ec5-224b3719ccbe	Head Unit Pioneer DMH-G225BT Double DIN 6.2 inch	head_unit_double_din	Pioneer	2050000.00	Head unit double DIN 6.2 inch touchscreen. Bluetooth, USB, AV input. Apple CarPlay & Android Auto wired. Output 50W x 4.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	📺	a1b2c3d4-e5f6-7890-abcd-ef1234567890	\N
9d78b761-6865-4e67-8616-7c7af89630cc	Head Unit Pioneer DMH-Z5350BT Double DIN 6.8 inch	head_unit_double_din	Pioneer	6350000.00	Head unit double DIN 6.8 inch capacitive touchscreen. Wireless Apple CarPlay & Android Auto. Built-in DAB+ tuner. Output 50W x 4. FLAC support.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	📺	c3d4e5f6-a7b8-9012-cdef-123456789012	\N
cffdba0c-e50a-4aac-b83c-ded95dc73764	Head Unit Pioneer DMH-ZF9350BT Double DIN 9 inch	head_unit_double_din	Pioneer	7900000.00	Head unit flagship 9 inch capacitive touchscreen. Wireless CarPlay & Android Auto. Hi-Res Audio. 13-band EQ. Output 50W x 4. FLV playback.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	📺	c3d4e5f6-a7b8-9012-cdef-123456789012	\N
ce8f3f6f-8027-4d93-8d13-0931bbd7f42a	Head Unit Pioneer DMH-AP6650BT Double DIN 9 inch	head_unit_double_din	Pioneer	6150000.00	Head unit 9 inch layar besar. WebLink untuk mirroring Android. Apple CarPlay wired. Bluetooth & USB. Output 50W x 4. Cocok untuk SUV dan MPV.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	📺	55a2ab16-143c-466d-903a-08b454634306	\N
7ec3e162-397a-4f52-8ec4-6d1654e2cae4	Speaker Coaxial Pioneer TS-A1670F 6.5 inch 3-Way	speaker_coaxial	Pioneer	850000.00	Speaker coaxial 3-way 6.5 inch. Peak 320W, RMS 70W. Carbon & Mica reinforced IMPP cone. Open & Smooth sound technology. Frequency 37Hz-24kHz.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🔊	0745ed72-7722-4991-96a2-33948e00631f	\N
f05c2cc7-44d5-43d4-81f1-7644a4fc6ad9	Speaker Coaxial Pioneer TS-A1370F 5.25 inch 3-Way	speaker_coaxial	Pioneer	750000.00	Speaker coaxial 3-way 5.25 inch. Peak 250W, RMS 55W. Cocok untuk mobil dengan lubang speaker kecil. Carbon IMPP cone.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🔊	0745ed72-7722-4991-96a2-33948e00631f	\N
3c441fae-c214-40f6-96fc-662d7f6e8dd3	Speaker Component Pioneer TS-Z170C 6.5 inch 2-Way	speaker_component	Pioneer	2800000.00	Speaker component flagship Z-Series 6.5 inch. Peak 350W, RMS 100W. Carbon fiber composite cone. Tweeter aluminum dome. Hi-Res Audio certified.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🎵	d71440dd-5d04-4bf2-a4ca-c630d21063cc	\N
e94e10a5-5d44-4b44-83f5-54461852cbef	Speaker Component Pioneer TS-V170C 6.5 inch Hi-Res	speaker_component	Pioneer	2500000.00	Speaker component V-Series 6.5 inch Hi-Res Audio. Peak 300W, RMS 80W. Bio-fiber cone. Tweeter balanced dome. Sound stage lebar.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🎵	bad8f281-a1ff-4abe-8238-89365e95e58d	\N
bfe1de02-1283-4538-a226-0c15906c85cb	Subwoofer Aktif Pioneer TS-WX130EA Kolong	subwoofer	Pioneer	2200000.00	Subwoofer aktif slim 10 inch untuk kolong jok. Built-in amplifier 150W. Tinggi hanya 7.6cm. Bass boost adjustable. Cocok untuk MPV dan SUV.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🔉	1c534f23-d636-41ca-9719-ee9493bf70ad	\N
9acdb9a1-7409-4950-bcf5-d6804e409a5d	Subwoofer Aktif Pioneer TS-WX400D Kolong 10 inch	subwoofer	Pioneer	3520000.00	Subwoofer kolong 10 inch 250W RMS. Amplifier Class D built-in. Bass remote control. Frequency 28-200Hz. Bass lebih dalam dan bertenaga.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🔉	1c534f23-d636-41ca-9719-ee9493bf70ad	\N
84981098-9063-4ef5-ac6c-d74ba4548c4d	Head Unit JVC KD-X265BT Single DIN	head_unit_single_din	JVC	1250000.00	Head unit single DIN compact. Bluetooth, USB, AUX. Dual phone connection. K2 technology untuk enhanced sound. Output 50W x 4.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	📻	a1b2c3d4-e5f6-7890-abcd-ef1234567890	\N
cb5e86c4-e232-4c55-b0b8-d8793360eec4	Head Unit JVC KW-M690BT Double DIN 6.8 inch	head_unit_double_din	JVC	3500000.00	Head unit double DIN 6.8 inch layar sentuh. Wireless CarPlay & Android Auto. Bluetooth. Output 50W x 4. Rear camera input.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	📺	a1b2c3d4-e5f6-7890-abcd-ef1234567890	\N
0b9165db-2d9b-4086-b787-7d3bb81c23f2	Head Unit JVC KW-MZ63BT Double DIN 6.5 inch	head_unit_double_din	JVC	2400000.00	Head unit double DIN 6.5 inch panel resistive touchscreen. Wired CarPlay & Android Auto. Bluetooth. Output 50W x 4.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	📺	8b507336-5b54-4035-be10-a437622a6d7a	\N
f11338fc-18be-43ea-ae5e-5b604fc82335	Speaker Coaxial JVC CS-J620U 6.5 inch	speaker_coaxial	JVC	650000.00	Speaker coaxial 2-way 6.5 inch. Peak 300W, RMS 40W. Hybrid rubber surround. Carbon composite cone. Frequency 40Hz-22kHz.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🔊	0745ed72-7722-4991-96a2-33948e00631f	\N
944510c9-adb3-467a-89ce-87283aacd369	Speaker Component JVC CS-HX1304 6.5 inch 2-Way	speaker_component	JVC	1500000.00	Speaker component X-Series 6.5 inch. Peak 400W, RMS 60W. Carbon fiber woofer. Tweeter titanium dome. Bass punchy dan detail.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🎵	d71440dd-5d04-4bf2-a4ca-c630d21063cc	\N
95153f11-3341-42e9-afc4-8ac17f46f24c	Amplifier 2 Channel JVC KS-AX302	amplifier	JVC	1200000.00	Amplifier 2/4 channel Class AB. 40W RMS x 4 @ 4 ohm. Compact design. LPF/HPF built-in. Bridgeable 120W x 2.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	⚡	4fe8ab59-0f18-411b-8d75-9c5c746e57fd	\N
b333b856-ca3f-414c-a980-75c92c3cb56f	Head Unit Android Nakamichi Saga NA-3100i 9 inch 4/64GB	head_unit_android	Nakamichi	1970000.00	Head unit Android 9 inch QLED. RAM 4GB + Storage 64GB. Wireless CarPlay & Android Auto. DSP built-in. Support kamera 360. Chipset Unisoc T310.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🖥️	a1b2c3d4-e5f6-7890-abcd-ef1234567890	\N
00b7672e-a1d3-4a26-98bc-04dd4c7eeaef	Head Unit Android Nakamichi Saga NA-3102i 9 inch 4/64GB	head_unit_android	Nakamichi	2080000.00	Head unit Android 9 inch Incell HD. RAM 4GB + 64GB. Wireless CarPlay & Android Auto. Voice command Indonesia. DSP 32-band. Support kamera 360 surround.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🖥️	c3d4e5f6-a7b8-9012-cdef-123456789012	\N
6288451f-6dff-4a10-b331-8e4e1974a82f	Head Unit Android Nakamichi Legend Pro 12 9 inch 12/256GB	head_unit_android	Nakamichi	11100000.00	Head unit Android flagship 9 inch QLED. RAM 12GB + Storage 256GB. MediaTek 8-core chipset. Wireless CarPlay & Android Auto. DSP 48-band. Support 4G LTE. Output optical digital.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🖥️	c3d4e5f6-a7b8-9012-cdef-123456789012	\N
54163f49-0400-452a-8b06-e4316f0fbb24	Speaker Coaxial Nakamichi NXC62 6.5 inch	speaker_coaxial	Nakamichi	1200000.00	Speaker coaxial 2-way 6.5 inch. Peak 300W, RMS 50W. Cone polypropylene. Tweeter silk dome. Sound natural dan detail.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🔊	0745ed72-7722-4991-96a2-33948e00631f	\N
40f28ca3-c8d1-410f-bc6f-2b6afb7bc5b5	Speaker Component Nakamichi NSE-CS1618 6.5 inch 2-Way	speaker_component	Nakamichi	975000.00	Speaker component 2-way 6.5 inch. Peak 250W, RMS 40W. Tweeter neodymium. Crossover built-in. Value for money.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🎵	d71440dd-5d04-4bf2-a4ca-c630d21063cc	\N
0a1502fa-e470-49b7-b54f-4c353816cc29	Subwoofer Aktif Nakamichi NBF-10 Kolong 10 inch	subwoofer	Nakamichi	2800000.00	Subwoofer aktif kolong 10 inch. Built-in amplifier 150W RMS. Slim design. Bass remote control. Frequency 30-200Hz.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🔉	1c534f23-d636-41ca-9719-ee9493bf70ad	\N
696af860-db05-44a2-8ea4-6c405c398a1a	Amplifier 4 Channel Nakamichi NA-4100	amplifier	Nakamichi	1800000.00	Amplifier 4 channel Class AB. 65W RMS x 4 @ 4 ohm. LPF/HPF variable. Compact design. Cocok untuk upgrade audio mid-range.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	⚡	4fe8ab59-0f18-411b-8d75-9c5c746e57fd	\N
cd7f554e-d625-4ba1-a7bf-079f59d1f132	Head Unit Android Clarion GL-300 9 inch 2/64GB	head_unit_android	Clarion	2450000.00	Head unit Android 9 inch. RAM 2GB + 64GB. Metal backpanel. Apple CarPlay & Android Auto. DSP built-in. Output 50W x 4.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🖥️	a1b2c3d4-e5f6-7890-abcd-ef1234567890	\N
837c473f-2ce3-4065-8d7c-5bb53e10a721	Head Unit Android Clarion GL-300 9 inch 4/64GB	head_unit_android	Clarion	2650000.00	Head unit Android 9 inch RAM lebih besar. 4GB + 64GB. Premium sound quality. CarPlay & Android Auto wireless. DSP 16-band.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🖥️	c3d4e5f6-a7b8-9012-cdef-123456789012	\N
7b9df964-8fc4-4bbe-96c6-dd6adc77c2a5	Head Unit Android Clarion GL-500 9 inch 6/128GB	head_unit_android	Clarion	4500000.00	Head unit Android flagship 9 inch. RAM 6GB + 128GB. Layar QLED. Wireless CarPlay & Android Auto. DSP 32-band. Support kamera 360. Output optical.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🖥️	c3d4e5f6-a7b8-9012-cdef-123456789012	\N
5386c59d-9993-4bc4-9f56-ba26c6daa44a	Head Unit Android DHD 7001 9 inch 2/32GB	head_unit_android	DHD	790000.00	Head unit Android 9 inch entry level. RAM 2GB + 32GB. CarPlay & Android Auto wired. Bluetooth, WiFi, mirrorlink. Cocok untuk budget terbatas.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🖥️	8b507336-5b54-4035-be10-a437622a6d7a	\N
4c5039df-b2f1-4b9a-9375-6fbd0fbe99c1	Head Unit Android DHD 7001 9 inch 4/64GB	head_unit_android	DHD	950000.00	Head unit Android 9 inch RAM upgrade. 4GB + 64GB. Lebih smooth dan responsif. CarPlay & Android Auto. DSP built-in.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🖥️	a1b2c3d4-e5f6-7890-abcd-ef1234567890	\N
69920917-0ed3-4038-81fa-0146605683e9	Speaker Coaxial DHD 620CV 6.5 inch	speaker_coaxial	DHD	350000.00	Speaker coaxial 2-way 6.5 inch. Peak 200W, RMS 30W. Budget-friendly. Cocok untuk upgrade speaker bawaan mobil. Include ring adapter.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🔊	0745ed72-7722-4991-96a2-33948e00631f	\N
f49cf81a-1e53-4a09-a4fd-910d86e65e8c	Speaker Component DHD-620CV 6.5 inch 2-Way	speaker_component	DHD	550000.00	Speaker component 2-way 6.5 inch. Peak 250W, RMS 40W. Tweeter dome. Crossover external. Harga terjangkau untuk pemula.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🎵	d71440dd-5d04-4bf2-a4ca-c630d21063cc	\N
22eead08-eef5-4b05-9179-d05bc042f32b	Subwoofer Aktif DHD-450NB Kolong 10 inch	subwoofer	DHD	850000.00	Subwoofer aktif underseat 10 inch. Built-in amplifier 100W. Slim design 7cm. Bass boost adjustable. Budget-friendly.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🔉	1c534f23-d636-41ca-9719-ee9493bf70ad	\N
8d217af7-493a-43e2-909f-f04d820d5058	Head Unit Android Orca ADR-9988 EcoLite 9 inch 2/32GB	head_unit_android	Orca	950000.00	Head unit Android 9 inch Full HD. RAM 2GB + 32GB. Layar In-Cell HD 2K. CarPlay & Android Auto. Budget-friendly.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🖥️	8b507336-5b54-4035-be10-a437622a6d7a	\N
60aadd3e-4ae1-4188-b541-dbdf7040261f	Head Unit Android Orca NCF 9 inch 4/128GB	head_unit_android	Orca	1500000.00	Head unit Android 9 inch. RAM 4GB + 128GB. Layar besar dan responsif. Wireless CarPlay & Android Auto. DSP built-in.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🖥️	a1b2c3d4-e5f6-7890-abcd-ef1234567890	\N
dde91190-dfbc-444f-9ecd-3f68004e2928	Head Unit Android Orca NCF 10 inch 4/128GB	head_unit_android	Orca	1800000.00	Head unit Android 10 inch layar besar. RAM 4GB + 128GB. CarPlay & Android Auto wireless. DSP 16-band. Cocok untuk SUV dan MPV.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🖥️	a1b2c3d4-e5f6-7890-abcd-ef1234567890	\N
6de50f48-4256-46d2-989a-e14875fcd5a1	Speaker Coaxial Orca 6.5 inch 2-Way	speaker_coaxial	Orca	400000.00	Speaker coaxial 2-way 6.5 inch. Peak 180W, RMS 25W. Harga terjangkau. Cocok untuk daily driver. Include grill.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🔊	0745ed72-7722-4991-96a2-33948e00631f	\N
a1537add-3914-4ffa-9f94-a874a4843571	Subwoofer Aktif Orca SW-2668 Kolong 8 inch	subwoofer	Orca	1060000.00	Subwoofer aktif kolong 8 inch. Built-in amplifier. Slim design. PWM Mosfet. RCA input. Cocok untuk ruang terbatas.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🔉	1c534f23-d636-41ca-9719-ee9493bf70ad	\N
b9cfc7c8-9124-4456-b8cf-de47104ed356	Head Unit Android Avix 9 inch 2/32GB	head_unit_android	Avix	930000.00	Head unit Android 9 inch. RAM 2GB + 32GB. Wired CarPlay & Android Auto. Bluetooth, WiFi. Support kamera mundur.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🖥️	8b507336-5b54-4035-be10-a437622a6d7a	\N
0e3b9b4e-b487-4eb2-bfc9-4897f43f48af	Head Unit Android Avix AX2AND10X13 Platinum 9 inch 2/32GB	head_unit_android	Avix	1300000.00	Head unit Android Platinum series 9 inch HD. RAM 2GB + 32GB. Layar capacitive full touch. Voice command Indonesia. Easy connection.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🖥️	a1b2c3d4-e5f6-7890-abcd-ef1234567890	\N
a6103671-e41b-4e31-b299-49a47cd4afcd	Head Unit Android Avix 10 inch 4/64GB	head_unit_android	Avix	2200000.00	Head unit Android 10 inch. RAM 4GB + 64GB. Layar besar. CarPlay & Android Auto wireless. DSP built-in.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🖥️	c3d4e5f6-a7b8-9012-cdef-123456789012	\N
b0700224-cbee-4ac1-ba17-024ecad4179f	Head Unit Android Skeleton SKT-8189 7 inch 2/32GB	head_unit_android	Skeleton	680000.00	Head unit Android 7 inch single DIN sliding. RAM 2GB + 32GB. Cocok untuk mobil lama yang butuh upgrade minimalis. Bluetooth, USB.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🖥️	8b507336-5b54-4035-be10-a437622a6d7a	\N
23a98d5e-02e5-4ba2-b3e3-ce9fb04fb77d	Head Unit Android Skeleton SKT-8189T 9 inch 2/32GB	head_unit_android	Skeleton	850000.00	Head unit Android 9 inch sliding single DIN. RAM 2GB + 32GB. Plug and play Toyota. Bluetooth, mirrorlink, WiFi.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🖥️	a1b2c3d4-e5f6-7890-abcd-ef1234567890	\N
6cbb1739-fb0a-4ecd-ab1c-f41e33427d73	Speaker Coaxial Skeleton 6.5 inch 2-Way	speaker_coaxial	Skeleton	300000.00	Speaker coaxial 2-way 6.5 inch. Peak 150W, RMS 20W. Budget-friendly. Include grill dan ring. Cocok untuk pemula.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🔊	0745ed72-7722-4991-96a2-33948e00631f	\N
e578e452-5923-47ea-b069-d80f8e1defb8	Speaker Component Skeleton SK-620C 6.5 inch 2-Way	speaker_component	Skeleton	450000.00	Speaker component 2-way 6.5 inch. Peak 200W, RMS 30W. Tweeter dome. Crossover passive. Harga terjangkau.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🎵	d71440dd-5d04-4bf2-a4ca-c630d21063cc	\N
9588cfeb-c181-419c-a7d4-30049692e7b4	Subwoofer Aktif Skeleton SKT-T550 Kolong 10 inch	subwoofer	Skeleton	1050000.00	Subwoofer kolong 10 inch aktif. Built-in amplifier. Basstube design. Bass boost. Remote control included.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🔉	1c534f23-d636-41ca-9719-ee9493bf70ad	\N
945ea381-6211-49cc-92a0-d2a1c0119a86	Speaker Coaxial Hertz X 165 6.5 inch	speaker_coaxial	Hertz	1400000.00	Speaker coaxial 2-way 6.5 inch. Peak 300W, RMS 75W. Cone treated cellulose pulp. Tweeter PEI dome 23mm. Italian sound quality.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🔊	d71440dd-5d04-4bf2-a4ca-c630d21063cc	\N
ba3c1345-ee35-42a7-8dc5-70c995253fe9	Speaker Component Hertz K 165 UNO 6.5 inch 2-Way	speaker_component	Hertz	1620000.00	Speaker component UNO series 6.5 inch. Peak 300W, RMS 75W. Tweeter dome 23mm neodymium. Crossover external 12dB/oct. Natural sound.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🎵	c3d4e5f6-a7b8-9012-cdef-123456789012	\N
3ec9366d-9ffa-4118-9886-16a5e87bcdf1	Tweeter Hertz Mille Pro MPX 170.30	tweeter	Hertz	2200000.00	Tweeter premium 1 inch dari Mille Pro series. Neodymium magnet. Tetolon dome. Response 2kHz-24kHz. Untuk soundstage lebar dan detail.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🎶	bad8f281-a1ff-4abe-8238-89365e95e58d	\N
5f23a448-6e9a-4ae0-bd17-f77fade28c72	Amplifier 4 Channel Hertz DP 4.300	amplifier	Hertz	4537000.00	Amplifier 4 channel Dieci series. 75W RMS x 4 @ 4 ohm. Class AB. Built-in DSP. Compactly designed. Italian engineering.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	⚡	4fe8ab59-0f18-411b-8d75-9c5c746e57fd	\N
93e13e9d-3271-468b-a4dd-96780bf2f451	Amplifier Mono Hertz DP 1.500	amplifier_mono	Hertz	5225000.00	Amplifier monoblok Class D untuk subwoofer. 500W RMS @ 2 ohm. LPF variable 50-400Hz. Bass boost 0-12dB. Premium Italian quality.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	⚡	1c534f23-d636-41ca-9719-ee9493bf70ad	\N
ec8cc185-2942-4d35-9e4e-796dd7a2a8dd	Subwoofer JL Audio 10W1V3-4 10 inch	subwoofer	JL Audio	3500000.00	Subwoofer passive 10 inch W1 series. RMS 200W. DMA-optimized motor. Rubber surround. Frequency 25-200Hz. Bass tight dan controlled.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🔉	1c534f23-d636-41ca-9719-ee9493bf70ad	\N
a2c51e4c-bdc9-4b32-bcdb-1c97e5f49037	Subwoofer JL Audio 10W3V3-4 10 inch	subwoofer	JL Audio	8715000.00	Subwoofer passive 10 inch W3 series flagship. RMS 300W. Elevated frame cooling. Injection-molded cone. Bass deep dan accurate. For SPL enthusiasts.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🔉	55a2ab16-143c-466d-903a-08b454634306	\N
cf68c7cb-1dd6-4f46-91fe-47ac7bd1c39f	Subwoofer JL Audio 12W0V3-4 12 inch	subwoofer	JL Audio	3600000.00	Subwoofer passive 12 inch entry level. RMS 200W. Larger cone area untuk bass lebih keras. Frequency 22-200Hz. Value for money.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🔉	1c534f23-d636-41ca-9719-ee9493bf70ad	\N
04fd6e61-70d1-4f6c-830e-d41321e8c53e	Amplifier 4 Channel Rockford Fosgate R2-300x4	amplifier	Rockford Fosgate	3350000.00	Amplifier 4 channel Class D. 75W RMS x 4 @ 4 ohm. Compact design. Crossover variable LPF/HPF. Punch EQ bass. American sound quality.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	⚡	4fe8ab59-0f18-411b-8d75-9c5c746e57fd	\N
06da7b5b-af70-4f30-b4b2-2fbd34936ed2	Amplifier 4 Channel Rockford Fosgate R2-500x4	amplifier	Rockford Fosgate	4800000.00	Amplifier 4 channel Class D high power. 125W RMS x 4 @ 4 ohm. Bridgeable 250W x 2. Crossover active built-in. For serious audio builds.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	⚡	55a2ab16-143c-466d-903a-08b454634306	\N
64f12117-b262-4b80-b818-12a9802e67b3	Amplifier Mono Rockford Fosgate R2-500X1	amplifier_mono	Rockford Fosgate	3200000.00	Amplifier mono Class D untuk subwoofer. 300W RMS @ 2 ohm. Low-pass filter variable. Bass boost EQ. Punch series.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	⚡	55a2ab16-143c-466d-903a-08b454634306	\N
1e65b6a2-939c-46c0-b8ff-616cf7ed27d7	Amplifier Mono Rockford Fosgate T500.1BD	amplifier_mono	Rockford Fosgate	5500000.00	Amplifier mono Class BD flagship. 500W RMS @ 2 ohm. CACT (Continuous A-Class Technology). Variable LPF 50-250Hz. Bass EQ 0-18dB.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	⚡	55a2ab16-143c-466d-903a-08b454634306	\N
ad708556-5c07-4791-8f36-2fc500b1f1ec	Head Unit Android Exxent Green 9 inch 6/128GB	head_unit_android	Exxent	3500000.00	Head unit Android 9 inch. RAM 6GB + 128GB. Layar QLED. Wireless CarPlay & Android Auto. Support kamera 360. DSP built-in. Champion of EMMA Indonesia 2024.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🖥️	c3d4e5f6-a7b8-9012-cdef-123456789012	\N
63749a59-5a43-4a40-a8d4-6fc01673410a	Head Unit Android Exxent Green 10 inch 6/128GB	head_unit_android	Exxent	4000000.00	Head unit Android 10 inch layar besar. RAM 6GB + 128GB. QLED display. CarPlay & Android Auto wireless. DSP 32-band. Support 4G LTE.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🖥️	a1b2c3d4-e5f6-7890-abcd-ef1234567890	\N
f6c3bc77-2101-4326-b06d-1af6c8f26dc8	Speaker Coaxial Cello One 6.5 inch 3-Way	speaker_coaxial	Cello	590000.00	Speaker coaxial 3-way 6.5 inch. Peak 250W, RMS 45W. Budget-friendly. Include grill dan ring adapter. Cocok untuk upgrade harian.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🔊	0745ed72-7722-4991-96a2-33948e00631f	\N
c651cd06-6b45-429e-a8ca-696f4d0409bb	Speaker Coaxial Cello 6 Pro 6.5 inch	speaker_coaxial	Cello	368000.00	Speaker coaxial 2-way 6.5 inch. Peak 200W, RMS 35W. Super sound quality. Harga terjangkau. Include ring Toyota universal.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🔊	0745ed72-7722-4991-96a2-33948e00631f	\N
388a33c8-44ef-401f-a30b-df888f19d358	Speaker Component Cello Performance FIT 6.5 inch 2-Way	speaker_component	Cello	2750000.00	Speaker component Performance series. Peak 350W, RMS 80W. Sound jernih hingga 22kHz. Upgrade audio OEM. Tweeter dome 25mm.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🎵	d71440dd-5d04-4bf2-a4ca-c630d21063cc	\N
059dec22-927e-4649-95b1-31589046ee02	Speaker Component Cello Performance MAX 6.5 inch 3-Way	speaker_component	Cello	1200000.00	Speaker component 3-way 6.5 inch. Peak 300W, RMS 60W. Midrange dedicated. Tweeter separate. Soundstage lebar.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🎵	bad8f281-a1ff-4abe-8238-89365e95e58d	\N
73a8aa12-7baf-45a4-a410-3e0999b5f2c6	Processor Cello Magic 4.6 Pro DSP	processor	Cello	3650000.00	Processor DSP 6 channel. Built-in amplifier 4x70W RMS. 31-band EQ per channel. Time alignment. Crossover active. Input RCA high/low level.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🎛️	bad8f281-a1ff-4abe-8238-89365e95e58d	\N
9cc5240a-3204-4bfe-b582-3e2289a107f3	Speaker Coaxial JBL Stage2 624 6.5 inch 2-Way	speaker_coaxial	JBL	575000.00	Speaker coaxial 2-way 6.5 inch. Peak 300W, RMS 50W. PlusOne cone technology. Tweeter PEI dome. Cocok untuk daily use.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🔊	0745ed72-7722-4991-96a2-33948e00631f	\N
ae936d69-c5ce-47b4-9e4c-816c8340a4be	Speaker Coaxial JBL Stage3 627 6.5 inch 2-Way	speaker_coaxial	JBL	816000.00	Speaker coaxial Stage3 series 6.5 inch. Peak 270W, RMS 75W. IMPP cone. Tweeter aluminum dome. Frequency 55Hz-40kHz. Sound detail.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🔊	d71440dd-5d04-4bf2-a4ca-c630d21063cc	\N
3cb8045f-49b3-4078-855d-3455b0098d66	Speaker Coaxial JBL Stage2 965M 6x9 inch 3-Way	speaker_coaxial	JBL	984000.00	Speaker coaxial 3-way oval 6x9 inch. Peak 420W, RMS 70W. Cone polypropylene. Cocok untuk pintu belakang atau deck mobil. Bass lebih besar.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🔊	1c534f23-d636-41ca-9719-ee9493bf70ad	\N
df6481d0-8269-4b73-9883-7076e5fea1eb	Speaker Component JBL Club 64C 6.5 inch 2-Way	speaker_component	JBL	1800000.00	Speaker component Club series 6.5 inch. Peak 300W, RMS 75W. PlusOne woofer. Tweeter edge-driven. Crossover external. American engineering.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🎵	d71440dd-5d04-4bf2-a4ca-c630d21063cc	\N
28c96c67-3e8f-4066-8e63-ae2f389098e6	Subwoofer Aktif JBL BassPro Lite 7 inch Kolong	subwoofer	JBL	2600000.00	Subwoofer aktif underseat 7 inch ultra slim. Built-in amplifier 200W peak. Tinggi 7.5cm. Remote bass control. Frequency 30-200Hz.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🔉	1c534f23-d636-41ca-9719-ee9493bf70ad	\N
e5095f5c-4bd9-4341-af62-fa22efade676	Subwoofer Aktif JBL BassPro SL2 8 inch Kolong	subwoofer	JBL	2750000.00	Subwoofer kolong 8 inch aktif. Built-in amplifier 250W peak. Slim design. Bass boost adjustable. Frequency 30-200Hz. Original Bergaransi.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🔉	1c534f23-d636-41ca-9719-ee9493bf70ad	\N
c0817c28-44f3-4ba1-b244-8e8f6a7b1c22	Speaker Component JBL Stadium 62F 6.5 inch 2-Way	speaker_component	JBL	3733000.00	Speaker component Stadium flagship 6.5 inch. Peak 400W, RMS 100W. PlusOne woofer. Tweeter aluminum dome. Hi-Res capable. Premium American sound.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🎵	c3d4e5f6-a7b8-9012-cdef-123456789012	\N
bfeabf8d-00d0-4530-8a54-87828582d966	Amplifier 4 Channel Venom VS 4930 Virus	amplifier	Venom	1660000.00	Amplifier 4 channel Virus series. 75W RMS x 4 @ 4 ohm. Class AB. LPF/HPF variable. Bass EQ. Harga terjangkau untuk power upgrade.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	⚡	4fe8ab59-0f18-411b-8d75-9c5c746e57fd	\N
4f187a63-8b44-430b-868e-667313158325	Amplifier 4 Channel Venom VO 406 MKII Diablo	amplifier	Venom	1710000.00	Amplifier 4 channel Diablo series. 80W RMS x 4 @ 4 ohm. Bridgeable 200W x 2. LPF/HPF built-in. Compact design.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	⚡	4fe8ab59-0f18-411b-8d75-9c5c746e57fd	\N
c66db5ac-83b0-44c3-a202-a440291fec6f	Amplifier 4 Channel Venom VT 480 Vertigo	amplifier	Venom	725000.00	Amplifier 4 channel budget. 60W RMS x 4 @ 4 ohm. Class AB. Cocok untuk pemula yang butuh power upgrade. Compact dan ringan.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	⚡	8b507336-5b54-4035-be10-a437622a6d7a	\N
d1dc5f6b-58f3-4bc6-8a6d-248d4b29f24f	Amplifier Mono Venom VETO 500.1 Elemento	amplifier_mono	Venom	1498000.00	Amplifier mono Elemento series. 500W max @ 2 ohm. LPF variable 40-250Hz. Bass boost 0-12dB. Cocok untuk subwoofer passive.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	⚡	1c534f23-d636-41ca-9719-ee9493bf70ad	\N
5ea2c75d-4bf1-43a2-b4bc-550230ab8d23	Amplifier Mono Venom V1500XD	amplifier_mono	Venom	1500000.00	Amplifier mono Class D. 500W RMS @ 2 ohm. Support 1 ohm stable. LPF variable. Dimensi kompak 40x26x6 cm. For serious bass.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	⚡	55a2ab16-143c-466d-903a-08b454634306	\N
d77118f8-c927-428a-9c2f-920441eba2e7	Amplifier Mono Venom PS800.1 Purple Storm	amplifier_mono	Venom	1563000.00	Amplifier monoblok Purple Storm series. 800W max @ 2 ohm. Class D efficient. LPF 40-250Hz. Subsonic filter 20Hz. Bass punchy.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	⚡	1c534f23-d636-41ca-9719-ee9493bf70ad	\N
ca543636-33a2-444e-834e-ead6b38210c2	Processor Venom VPR 3.6 DSP	processor	Venom	4200000.00	Processor DSP 6 channel. Built-in power 4 channel. 31-band EQ per channel. Time alignment. Crossover. Input RCA + optical. Resmi Venom Indonesia.	\N	\N	t	2026-04-12 20:46:08.995119+00	2026-04-12 20:46:08.995119+00	🎛️	bad8f281-a1ff-4abe-8238-89365e95e58d	\N
\.


--
-- TOC entry 3483 (class 2606 OID 24938)
-- Name: master_customer_problems master_customer_problems_pkey; Type: CONSTRAINT; Schema: sales; Owner: neondb_owner
--

ALTER TABLE ONLY sales.master_customer_problems
    ADD CONSTRAINT master_customer_problems_pkey PRIMARY KEY (mcp_id);


--
-- TOC entry 3478 (class 2606 OID 24926)
-- Name: master_products master_products_pkey; Type: CONSTRAINT; Schema: sales; Owner: neondb_owner
--

ALTER TABLE ONLY sales.master_products
    ADD CONSTRAINT master_products_pkey PRIMARY KEY (mp_id);


--
-- TOC entry 3479 (class 1259 OID 24939)
-- Name: idx_problems_active; Type: INDEX; Schema: sales; Owner: neondb_owner
--

CREATE INDEX idx_problems_active ON sales.master_customer_problems USING btree (mcp_is_active);


--
-- TOC entry 3480 (class 1259 OID 24940)
-- Name: idx_problems_embedding; Type: INDEX; Schema: sales; Owner: neondb_owner
--

CREATE INDEX idx_problems_embedding ON sales.master_customer_problems USING ivfflat (mcp_embedding public.vector_cosine_ops) WITH (lists='100');


--
-- TOC entry 3481 (class 1259 OID 49153)
-- Name: idx_problems_lexical; Type: INDEX; Schema: sales; Owner: neondb_owner
--

CREATE INDEX idx_problems_lexical ON sales.master_customer_problems USING gin (to_tsvector('english'::regconfig, ((mcp_problem_title || ' '::text) || COALESCE(mcp_description, ''::text))));


--
-- TOC entry 3474 (class 1259 OID 24928)
-- Name: idx_products_active; Type: INDEX; Schema: sales; Owner: neondb_owner
--

CREATE INDEX idx_products_active ON sales.master_products USING btree (mp_is_active);


--
-- TOC entry 3475 (class 1259 OID 24927)
-- Name: idx_products_category; Type: INDEX; Schema: sales; Owner: neondb_owner
--

CREATE INDEX idx_products_category ON sales.master_products USING btree (mp_category);


--
-- TOC entry 3476 (class 1259 OID 73735)
-- Name: idx_products_problem_fk; Type: INDEX; Schema: sales; Owner: neondb_owner
--

CREATE INDEX idx_products_problem_fk ON sales.master_products USING btree (mp_solves_problem_id);


--
-- TOC entry 3484 (class 2606 OID 73728)
-- Name: master_products master_products_mp_solves_problem_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: neondb_owner
--

ALTER TABLE ONLY sales.master_products
    ADD CONSTRAINT master_products_mp_solves_problem_id_fkey FOREIGN KEY (mp_solves_problem_id) REFERENCES sales.master_customer_problems(mcp_id) ON DELETE SET NULL;


-- Completed on 2026-04-13 03:55:16

--
-- PostgreSQL database dump complete
--

