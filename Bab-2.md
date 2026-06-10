# BAB II
STUDI LITERATUR

## 2.1 Penelitian Terdahulu

Lewis et al. (2020) dalam penelitian berjudul "Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks" memperkenalkan arsitektur RAG sebagai solusi untuk menjembatani parametric memory dan non-parametric memory dalam model bahasa. Sistem ini memanfaatkan Dense Passage Retriever (DPR) dan generator BART yang dilatih secara end-to-end dalam satu kerangka terpadu. Hasilnya, RAG berhasil mencapai performa terbaik pada tiga tugas QA open-domain dengan menghasilkan teks yang lebih faktual dibandingkan model tanpa retrieval. Perbedaan penelitian terdahulu dan penelitian ini adalah Lewis et al. tidak mencakup strategi Hybrid Search berbasis RRF maupun domain konsultasi audio mobil yang menjadi fokus penelitian ini.

Shuster et al. (2021) dalam penelitian bertajuk "Retrieval Augmentation Reduces Hallucination in Conversation" meneliti masalah halusinasi dalam dialog berbasis pengetahuan. Berbagai kombinasi retriever, ranker, dan encoder-decoder diuji pada dua benchmark, yaitu Wizard of Wikipedia dan CMU Document Grounded Conversations. Model terbaik berhasil menekan tingkat halusinasi lebih dari 60% dibandingkan model tanpa augmentasi retrieval. Perbedaan penelitian terdahulu dan penelitian ini adalah Shuster et al. berfokus pada dialog terbuka tanpa komponen deteksi konteks kendaraan, sedangkan penelitian ini menerapkan RAG pada domain teknis audio mobil yang spesifik.

Jeong et al. (2024) melalui penelitian "Adaptive-RAG: Learning to Adapt Retrieval-Augmented Large Language Models through Question Complexity" mengajukan sistem yang menyesuaikan strategi pengambilan dokumen berdasarkan kompleksitas kueri. Sebuah classifier kecil yang dilatih secara otomatis bertugas memilih antara no-retrieval, single-step retrieval, atau iterative multi-step retrieval. Pendekatan ini terbukti meningkatkan akurasi sekaligus efisiensi pada berbagai benchmark QA open-domain. Perbedaan penelitian terdahulu dan penelitian ini adalah Adaptive-RAG beroperasi pada QA generalis tanpa domain pengetahuan spesifik, sedangkan penelitian ini menyasar domain audio mobil dengan Hybrid Search berbasis RRF dan deteksi kendaraan.

Adam et al. (2021) melalui penelitian "AI-based chatbots in customer service and their effects on user compliance" meneliti pengaruh anthropomorphism verbal terhadap kecenderungan pengguna mengikuti permintaan chatbot di konteks layanan pelanggan e-commerce. Eksperimen online terandomisasi menunjukkan bahwa anthropomorphism dan kebutuhan konsistensi perilaku meningkatkan kepatuhan pengguna, dengan social presence sebagai mediator. Perbedaan penelitian terdahulu dan penelitian ini adalah Adam et al. tidak menyertakan komponen RAG maupun mekanisme retrieval berbasis domain teknis, sedangkan penelitian ini menggunakan RAG dan Hybrid Search sebagai inti sistem konsultasi.

Arslan et al. (2024) melalui karya bertajuk "A Survey on RAG with LLMs" melakukan tinjauan terhadap 51 studi RAG yang diklasifikasikan ke dalam task-based dan discipline-based classification. Survei ini mencatat lonjakan publikasi dari satu studi pada 2020 menjadi 28 studi pada 2023. Perbedaan penelitian terdahulu dan penelitian ini adalah Arslan et al. tidak mengembangkan sistem konkret, sedangkan penelitian ini mengimplementasikan RAG secara langsung pada domain audio mobil dengan Hybrid Search berbasis RRF dan komponen deteksi kendaraan.

Berdasarkan penelitian-penelitian terdahulu di atas, terdapat beberapa celah yang menjadi landasan penelitian ini:

1. Belum ada sistem RAG yang diimplementasikan secara khusus untuk domain konsultasi audio mobil dengan basis pengetahuan yang dikurasi secara domain-spesifik.

2. Penggunaan Hybrid Search berbasis RRF dalam sistem RAG untuk domain teknis yang memerlukan pencocokan nama produk eksak sekaligus pemahaman semantik belum mendapat perhatian yang memadai dalam penelitian terdahulu.

3. Integrasi deteksi konteks kendaraan dalam pipeline RAG untuk konsultasi produk teknis belum pernah diteliti, padahal relevansi rekomendasi produk audio sangat bergantung pada spesifikasi kendaraan pengguna seperti tipe dashboard, ukuran speaker bawaan, dan kapasitas kabin.

---

### Tabel Perbandingan Penelitian Terdahulu

| Peneliti (Tahun) | Metode Retrieval | Domain | Deteksi Konteks | Perbedaan dengan Penelitian Ini |
|---|---|---|---|---|
| Lewis et al. (2020) | Dense (DPR) | Open-domain QA | Tidak ada | Penelitian ini menerapkan RAG + Hybrid Search (RRF) pada domain audio mobil |
| Shuster et al. (2021) | Dense + Ranker | Open-domain dialogue | Tidak ada | Penelitian ini menggunakan domain teknis spesifik dengan deteksi kendaraan |
| Jeong et al. (2024) | Adaptive dense | Open-domain QA | Tidak ada | Penelitian ini menerapkan RAG + Hybrid Search (RRF) pada domain audio mobil |
| Adam et al. (2021) | Tidak ada | Layanan pelanggan | Tidak ada | Penelitian ini menambahkan RAG + Hybrid Search untuk konsultasi produk teknis |
| Arslan et al. (2024) | Berbagai (survei) | Multi-domain | Tidak ada | Penelitian ini mengimplementasikan sistem konkret pada domain audio mobil + Hybrid Search (RRF) |

Sumber: Pengolahan dari beberapa jurnal ilmiah

Kerangka konseptual penelitian ini menempatkan akurasi dan relevansi informasi sebagai pilar utama pengembangan chatbot konsultasi teknis. Pilar tersebut diwujudkan melalui arsitektur RAG dengan mekanisme Hybrid Search berbasis RRF yang memastikan jawaban chatbot senantiasa berpijak pada basis pengetahuan audio mobil yang valid dan minim halusinasi. Catatan Shuster et al. (2021) mengenai reduksi halusinasi lebih dari 60% menegaskan bahwa kualitas retrieval dan kelengkapan basis pengetahuan merupakan penentu utama sejauh mana halusinasi dapat ditekan.

Relevansi rekomendasi produk diperkuat melalui komponen deteksi konteks kendaraan, yang mengidentifikasi merek dan model kendaraan pengguna untuk menyajikan produk yang kompatibel. Sinergi antara ketepatan faktual dari RAG, efisiensi retrieval dari Hybrid Search, dan relevansi kontekstual dari deteksi kendaraan menjadi dasar perancangan sistem AudioMatch.

---

## 2.2 Landasan Teori

### 2.2.1 Komponen Sistem Audio Mobil

Sistem audio mobil tersusun atas serangkaian komponen elektronika yang bekerja secara terintegrasi untuk menghasilkan reproduksi suara di dalam kabin kendaraan. Komponen utama yang membentuk sistem ini antara lain unit sumber sinyal (head unit), penguat sinyal (amplifier), pengubah sinyal elektrik menjadi gelombang suara berupa speaker dan subwoofer, serta sistem pengkabelan sebagai media penghubung. Karakteristik teknis setiap komponen harus selaras satu sama lain agar kualitas suara yang dihasilkan optimal dan keamanan sistem kelistrikan kendaraan tetap terjaga (Wawancara, Pemilik Rendy Audio, Februari 2026).

Sebagai pusat kendali sistem, head unit bertanggung jawab atas pemutaran media dan pemrosesan sinyal audio awal. Sinyal kemudian diperkuat oleh amplifier sehingga memiliki daya yang memadai untuk menggerakkan driver speaker. Speaker umumnya menangani frekuensi menengah hingga tinggi, sedangkan subwoofer dikhususkan untuk frekuensi rendah. Sistem pengkabelan yang mencakup kabel daya, kabel sinyal RCA, dan kabel speaker menentukan seberapa bersih transmisi energi antar komponen (Wawancara, Pemilik Rendy Audio, Februari 2026).

---

### 2.2.2 Chatbot dan Conversational AI

Chatbot adalah program komputer yang berinteraksi dengan pengguna melalui percakapan berbasis teks atau suara dengan memanfaatkan Natural Language Processing (Adamopoulou & Moussiades, 2020). Adam et al. (2021) mendefinisikannya sebagai sistem perangkat lunak percakapan yang berkomunikasi melalui antarmuka natural language, dirancang untuk menggantikan atau melengkapi agen layanan manusia di berbagai konteks.

Dari sisi tipologi, chatbot terbagi menjadi dua kategori utama, yaitu task-oriented chatbot yang berfokus pada penyelesaian tugas spesifik seperti layanan pelanggan dan penjawab pertanyaan, serta social chatbot yang dirancang untuk percakapan bebas dan interaksi sosial (Adamopoulou & Moussiades, 2020). Dalam penelitian ini, AudioMatch dikembangkan sebagai task-oriented chatbot yang berfokus pada domain konsultasi audio mobil dan dirancang memberikan informasi teknis yang akurat berdasarkan konteks kendaraan pengguna.

---

### 2.2.3 Natural Language Processing dan Embedding

Natural Language Processing (NLP) adalah cabang kecerdasan buatan yang berfokus pada pemrosesan dan pemahaman bahasa manusia secara komputasional, mencakup aspek sintaksis dan semantik dari teks (Patil et al., 2023). Salah satu komponen inti NLP adalah representasi teks ke dalam format numerik berupa vektor, yang memungkinkan model machine learning memproses teks sebagai data terstruktur.

Word embedding adalah representasi vektor kontinu yang menangkap makna semantik sebuah kata berdasarkan konteks kemunculannya dalam teks (Patil et al., 2023). Perkembangan lebih lanjut melahirkan contextual embedding seperti yang diwujudkan oleh model BERT, di mana representasi vektor setiap kata bervariasi bergantung pada konteks kalimat sehingga pemahaman makna menjadi lebih kaya. Dalam sistem AudioMatch, contextual embedding digunakan dalam komponen vector search pada mekanisme Hybrid Search, di mana setiap dokumen direpresentasikan sebagai vektor semantik 1024 dimensi menggunakan model VoyageAI voyage-3.5-lite.

---

### 2.2.4 Information Retrieval dan Hybrid Search (Dense + Sparse Retrieval)

Information Retrieval (IR) adalah proses menemukan dokumen atau informasi yang relevan dari sekumpulan besar dokumen berdasarkan kueri yang diberikan (Cuconasu et al., 2024). Metode IR tradisional bertumpu pada sparse retrieval berupa BM25, yang bekerja dengan mencocokkan kata kunci dalam kueri terhadap kata kunci dalam dokumen menggunakan inverted index berbasis frekuensi term (Fan et al., 2024). Metode ini efisien secara komputasi tetapi tidak mampu menangkap makna implisit atau sinonim yang tidak eksplisit muncul dalam teks.

Pendekatan dense retrieval mengubah kueri dan dokumen ke dalam representasi vektor kontinu menggunakan model transformer sebagai encoder, kemudian mengukur relevansi melalui cosine similarity antar vektor (Fan et al., 2024). Dense retrieval mampu menangkap kemiripan makna antara kueri dan dokumen meski tidak ada kata yang identik, namun kurang presisi untuk pencocokan kata kunci atau nama yang eksak (Cuconasu et al., 2024).

Hybrid Search menyatukan sparse retrieval berbasis kata kunci dengan dense retrieval berbasis semantik dalam satu pipeline yang terintegrasi (Fan et al., 2024). Kelebihan utama Hybrid Search dibandingkan pendekatan tunggal adalah kemampuannya menangani dua jenis pertanyaan sekaligus: pertanyaan yang menyebutkan nama produk atau merek spesifik ditangani oleh BM25 melalui pencocokan leksikal yang presisi, sedangkan pertanyaan konseptual tentang kompatibilitas atau perbandingan spesifikasi ditangani oleh vector search melalui pemahaman makna. Dengan menggabungkan kekuatan keduanya, Hybrid Search menghasilkan relevansi retrieval yang lebih baik dibandingkan menggunakan salah satu metode saja.

Salah satu teknik penggabungan yang umum digunakan adalah Reciprocal Rank Fusion (RRF), yang diperkenalkan oleh Cormack et al. (2009) sebagai metode untuk menyatukan hasil dari beberapa sistem retrieval yang berbeda tanpa memerlukan kalibrasi skor lintas sistem. RRF menghitung skor gabungan setiap dokumen berdasarkan posisi ranking-nya dalam masing-masing jalur retrieval menggunakan formula berikut:

RRFscore(d∈D)=∑_(r∈R)▒1/(k+r(d))

Di mana R adalah himpunan daftar ranking, r(d) adalah posisi dokumen d pada daftar ranking r, dan k adalah konstanta yang umumnya ditetapkan pada 60. Dokumen yang secara konsisten muncul di posisi tinggi pada beberapa jalur retrieval akan memperoleh skor RRF yang lebih besar. Dalam sistem AudioMatch, RRF diimplementasikan dengan bobot tertimbang antara jalur vector search (bobot 0,6) dan jalur BM25 (bobot 0,4):

0,6×RRf_vector  +0,4×RRf_BM25

Bobot lebih tinggi pada jalur vector search mencerminkan temuan Karpukhin et al. (2020) bahwa dense retrieval secara konsisten mengungguli BM25 pada tugas yang memerlukan pemahaman semantik, sementara komponen BM25 tetap dipertahankan untuk memastikan pencocokan eksak nama produk dan merek dalam domain audio mobil.

Cuconasu et al. (2024) mengonfirmasi bahwa jenis dokumen yang diambil retriever berdampak nyata pada kualitas respons generator dan dokumen yang tidak relevan dapat menurunkan akurasi jawaban hingga lebih dari 25%. Oleh sebab itu, AudioMatch menggunakan Hybrid Search untuk memaksimalkan relevansi dan presisi dokumen yang diterima oleh komponen generator RAG.

---

### 2.2.5 Retrieval-Augmented Generation (RAG)

Retrieval-Augmented Generation (RAG) adalah arsitektur yang mengintegrasikan mekanisme information retrieval ke dalam proses generasi teks oleh model bahasa, sehingga respons yang dihasilkan memiliki landasan faktual dari basis pengetahuan eksternal (Lewis et al., 2020). Arslan et al. (2024) mendefinisikan RAG sebagai pendekatan yang mengintegrasikan pengambilan data eksternal ke dalam proses generasi teks untuk meningkatkan akurasi dan relevansi keluaran LLM.

Arsitektur RAG bertumpu pada tiga komponen utama, yaitu retriever yang menemukan dokumen relevan dari basis pengetahuan eksternal, augmentation yang mengintegrasikan dokumen tersebut ke dalam konteks input, serta generator yang menghasilkan respons berdasarkan gabungan kueri dan konteks (Fan et al., 2024). Shuster et al. (2021) membuktikan bahwa RAG mampu menekan tingkat halusinasi model percakapan lebih dari 60% dibandingkan model tanpa augmentasi retrieval. Fan et al. (2024) mencatat pula bahwa komponen dataset, retriever, dan LLM dapat dikembangkan dan diperbarui secara independen tanpa fine-tuning ulang seluruh sistem.

Dalam penelitian ini, AudioMatch mengimplementasikan RAG sebagai mekanisme utama untuk menjamin akurasi informasi teknis dalam konsultasi audio mobil. Sistem menekan halusinasi melalui tiga cara: basis pengetahuan yang dikurasi secara manual sehingga setiap dokumen sudah terjamin akurasinya, Hybrid Search yang secara konsisten mengambil dokumen paling relevan, dan system prompt yang secara eksplisit menginstruksikan LLM agar hanya menggunakan informasi dari konteks retrieval dan tidak menggunakan pengetahuan parametrik internalnya yang tidak terverifikasi.

---

### 2.2.6 Prompt Engineering

Prompt Engineering adalah disiplin yang berfokus pada perancangan dan pengoptimalan instruksi teks untuk mengarahkan perilaku LLM tanpa mengubah parameter atau bobot internal model itu sendiri (Brown et al., 2020). Dalam konteks sistem RAG, Prompt Engineering diterapkan melalui Contextual Prompting, yaitu teknik di mana dokumen yang diambil oleh retriever disematkan secara dinamis ke dalam prompt yang diberikan kepada LLM, disertai instruksi agar model hanya menggunakan informasi dari konteks tersebut sebagai dasar jawabannya (Brown et al., 2020).

Sebuah contextual prompt dalam sistem RAG terdiri dari tiga elemen, yaitu system instruction berupa instruksi peran dan batasan perilaku, injeksi konteks retrieval berupa dokumen relevan yang diperoleh dari basis pengetahuan, dan kueri pengguna. Dalam sistem AudioMatch, prompt dikonstruksi secara dinamis pada setiap siklus percakapan berdasarkan dokumen yang diambil Hybrid Search, sehingga respons Gemini 2.5 Flash Lite selalu berlandaskan informasi aktual dari katalog produk dan basis pengetahuan teknis Rendy Audio.

---

### 2.2.7 Infrastruktur Sistem: PostgreSQL dan Caching dengan Redis

PostgreSQL adalah sistem manajemen basis data relasional bersifat open-source yang mengutamakan reliabilitas, integritas data, dan kemampuan ekstensi, mencakup transaksi ACID, tipe data yang kaya, dan dukungan data JSON (Lathkar, 2023). Dalam sistem AudioMatch, PostgreSQL dipilih karena tiga kapabilitas yang terpenuhi dalam satu komponen: ekstensi pgvector menambahkan pencarian vektor untuk dense retrieval, dukungan full-text search menggunakan tsvector dan GIN index memungkinkan sparse retrieval berbasis BM25, serta penyimpanan relasional standar untuk entitas produk, masalah, dan kendaraan.

Sistem AudioMatch juga memerlukan mekanisme penyimpanan sementara untuk mendukung kontinuitas percakapan. Upstash Redis merupakan implementasi Redis berbasis HTTP/REST yang kompatibel dengan lingkungan serverless karena tidak memerlukan koneksi TCP persisten. Setiap sesi percakapan disimpan dengan TTL 24 jam, memungkinkan LLM mengakses konteks percakapan sebelumnya tanpa bergantung pada state dalam memori proses. Kombinasi PostgreSQL sebagai lapisan penyimpanan persisten dan Upstash Redis sebagai lapisan caching sesi membentuk infrastruktur data yang lengkap bagi sistem AudioMatch.

---

### 2.2.8 Metodologi Pengembangan Perangkat Lunak (SDLC)

Software Development Life Cycle (SDLC) adalah kerangka kerja terstruktur yang mendefinisikan tahapan sistematis dalam perencanaan, perancangan, pengembangan, pengujian, penerapan, dan pemeliharaan perangkat lunak (Pargaonkar, 2023). Model Waterfall merupakan salah satu model SDLC dengan pendekatan linier-sekuensial di mana setiap fase diselesaikan sebelum fase berikutnya dimulai, mulai dari analisis kebutuhan, desain sistem, implementasi, pengujian, hingga penerapan (Yas et al., 2023). Model ini dipilih dalam penelitian ini karena kebutuhan sistem AudioMatch sudah terdefinisi dengan baik sejak awal, sehingga urutan fase yang ketat memungkinkan pembangunan yang terstruktur dan dokumentasi yang mudah diaudit.

---

### 2.2.9 Evaluasi Sistem: Black Box Testing dan Evaluasi Kualitas Information Retrieval

Black Box Testing adalah metode pengujian perangkat lunak yang berfokus pada verifikasi fungsionalitas sistem berdasarkan spesifikasi eksternal tanpa memeriksa atau mengetahui struktur kode internalnya (Maspupah, 2024). Penguji hanya berfokus pada input yang diberikan dan output yang dihasilkan, kemudian membandingkannya dengan keluaran yang diharapkan berdasarkan kebutuhan pengguna. Dari tinjauan literaturnya terhadap 15 studi, Maspupah (2024) menyimpulkan bahwa Black Box Testing sangat efektif untuk mengevaluasi perilaku perangkat lunak dalam mengidentifikasi kesalahan pada fungsi dan pemrosesan data eksternal.

Teknik Equivalence Partitioning membagi domain input program ke dalam beberapa kelompok data untuk memungkinkan pembuatan test case yang lebih spesifik dan efektif (Azizah et al., 2024). Keunggulannya terletak pada cakupan input yang lebih luas karena pemilihan perwakilan dari setiap kelompok data memastikan berbagai skenario dapat diuji tanpa perlu menguji seluruh kemungkinan nilai input. Dalam konteks sistem AudioMatch, Black Box Testing diterapkan untuk memverifikasi setiap endpoint API, pipeline RAG, mekanisme Hybrid Search, deteksi kendaraan, dan fitur percakapan sesuai spesifikasi yang dirancang.

Pengujian fungsionalitas melalui Black Box Testing dilengkapi dengan evaluasi kualitas retrieval secara kuantitatif. Normalized Discounted Cumulative Gain (NDCG@K) merupakan metrik yang mengukur kualitas ranking sistem retrieval dengan mempertimbangkan posisi dan tingkat relevansi dokumen secara bersamaan (Järvelin & Kekäläinen, 2002). NDCG didasarkan pada prinsip bahwa dokumen relevan yang muncul di posisi lebih tinggi memiliki nilai lebih besar. Formula DCG@K adalah:

DCG@K=∑_(i=1)^K▒(2^(rel_i )-1)/log_2⁡〖(i+1)〗 

Di mana rel_i adalah tingkat relevansi dokumen pada posisi ke-i. NDCG@K kemudian dinormalisasi dengan membagi DCG@K dengan nilai ideal IDCG@K:

NDCG@K =  (DCG@K)/(IDCG@K)

Nilai NDCG berada dalam rentang [0, 1], di mana nilai 1 menunjukkan urutan ranking yang sempurna (Järvelin & Kekäläinen, 2002).

Precision@K mengukur proporsi dokumen relevan di antara K dokumen teratas yang dikembalikan sistem retrieval. Berbeda dari NDCG yang mempertimbangkan posisi dan tingkat relevansi secara bersamaan, Precision@K hanya mengukur ada-tidaknya relevansi pada setiap dokumen yang ditampilkan. Formula Precision@K adalah sebagai berikut:

$$\text{Precision@K} = \frac{\sum_{i=1}^{K} \mathbb{1}[rel_i \geq 1]}{K}$$

Di mana $\mathbb{1}[rel_i \geq 1]$ bernilai 1 apabila dokumen pada posisi ke-$i$ dianggap relevan, dan 0 apabila tidak relevan. Precision memberikan bobot yang setara pada seluruh posisi dalam K dokumen yang ditampilkan (Manning et al., 2009).

Dalam penelitian ini, Black Box Testing dan evaluasi kualitas retrieval digunakan secara komplementer untuk memperoleh gambaran performa sistem AudioMatch. NDCG@K digunakan sebagai metrik utama untuk mengevaluasi kualitas urutan dokumen hasil Hybrid Search, sedangkan Precision@K digunakan sebagai metrik pelengkap untuk mengukur densitas relevansi dari keseluruhan hasil. Pengujian dilakukan pada K=3 dan K=5 untuk menilai performa sistem pada rentang dokumen yang berbeda.
