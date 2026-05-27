# BAB II
STUDI LITERATUR

## 2.1 Penelitian Terdahulu

Lewis et al. (2020) dalam penelitiannya yang berjudul "Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks" memperkenalkan arsitektur RAG sebagai pendekatan general purpose untuk menggabungkan parametric memory dan non-parametric memory dalam model bahasa. Sistem ini menggunakan Dense Passage Retriever (DPR) sebagai komponen retrieval dan model BART sebagai generator seq2seq, di mana keduanya dilatih secara end-to-end. RAG mencapai state-of-the-art pada tiga tugas QA open-domain dan menghasilkan teks yang lebih faktual, spesifik, serta beragam dibandingkan model generatif murni. Perbedaan dari penelitian terdahulu dan penelitian sekarang adalah bahwa penelitian ini menerapkan RAG pada domain konsultasi audio mobil menggunakan Hybrid Search berbasis RRF yang tidak terdapat pada sistem yang diusulkan Lewis et al.

Shuster et al. (2021) dalam penelitiannya yang berjudul "Retrieval Augmentation Reduces Hallucination in Conversation" mengkaji berbagai arsitektur retrieval-augmented neural untuk tugas dialog berbasis pengetahuan pada domain open-domain. Penelitian ini menguji berbagai kombinasi komponen berupa retriever, ranker, dan encoder-decoder pada dua benchmark dialog berbasis pengetahuan, yaitu Wizard of Wikipedia dan CMU Document Grounded Conversations. Model terbaik yang dihasilkan mampu menekan tingkat halusinasi lebih dari 60 persen dibandingkan model tanpa augmentasi retrieval, dengan peningkatan yang lebih menonjol pada topik di luar distribusi data pelatihan. Perbedaan dari penelitian terdahulu dan penelitian sekarang adalah bahwa penelitian ini berfokus pada percakapan tanpa komponen deteksi konteks kendaraan, sedangkan AudioMatch menerapkan RAG pada domain teknis audio mobil yang spesifik dengan tambahan Hybrid Search berbasis RRF dan deteksi kendaraan.

Jeong et al. (2024) dalam penelitiannya yang berjudul "Adaptive-RAG: Learning to Adapt Retrieval-Augmented Large Language Models through Question Complexity" mengusulkan kerangka kerja QA adaptif yang menyesuaikan strategi retrieval berdasarkan kompleksitas kueri yang masuk. Sistem ini menggunakan sebuah classifier kecil yang dilatih secara otomatis untuk memprediksi kompleksitas kueri, kemudian memilih strategi antara no-retrieval, single-step retrieval, atau iterative multi-step retrieval. Pendekatan Adaptive-RAG meningkatkan akurasi dan efisiensi secara bersamaan dibandingkan pendekatan adaptive sebelumnya pada berbagai benchmark QA open-domain. Perbedaan dari penelitian terdahulu dan penelitian sekarang adalah bahwa Adaptive-RAG berfokus pada QA open-domain generalis tanpa domain pengetahuan spesifik maupun deteksi konteks objek, sedangkan AudioMatch menerapkan RAG pada domain audio mobil dengan Hybrid Search berbasis RRF dan deteksi kendaraan.

Adam et al. (2021) dalam penelitiannya yang berjudul "AI-based chatbots in customer service and their effects on user compliance" mengkaji pengaruh desain komunikatif chatbot berbasis AI terhadap kepatuhan pengguna dalam konteks layanan pelanggan e-commerce. Penelitian ini menggunakan eksperimen online terandomisasi untuk menguji pengaruh anthropomorphism verbal dan teknik foot-in-the-door terhadap kecenderungan pengguna mengikuti permintaan chatbot. Hasil penelitian menunjukkan bahwa anthropomorphism dan kebutuhan konsistensi perilaku secara nyata meningkatkan kepatuhan pengguna, dengan social presence sebagai mediator pengaruh anthropomorphism tersebut. Perbedaan dari penelitian terdahulu dan penelitian sekarang adalah bahwa penelitian ini berfokus pada aspek desain komunikatif pada chatbot layanan pelanggan generalis tanpa komponen RAG maupun mekanisme retrieval berbasis domain teknis.

Arslan et al. (2024) dalam penelitiannya yang berjudul "A Survey on RAG with LLMs" melakukan tinjauan sistematis atas berbagai aplikasi RAG yang dikombinasikan dengan Large Language Models di berbagai domain dan tugas. Penelitian ini mengklasifikasikan 51 studi RAG ke dalam dua kategori, yaitu task-based classification mencakup Question Answering, Text Generation, dan Information Retrieval, serta discipline-based classification mencakup domain biomedis, finansial, pendidikan, dan pengembangan perangkat lunak. Tinjauan ini mengonfirmasi bahwa RAG berhasil diimplementasikan pada berbagai tugas dan domain, dengan pertumbuhan publikasi dari satu studi pada 2020 menjadi 28 studi pada 2023. Perbedaan dari penelitian terdahulu dan penelitian sekarang adalah bahwa Arslan et al. melakukan survei literatur tanpa mengembangkan sistem konkret, sedangkan penelitian ini mengimplementasikan RAG secara langsung pada domain audio mobil dengan tambahan Hybrid Search berbasis RRF dan komponen deteksi kendaraan.

Berdasarkan penelitian-penelitian terdahulu di atas, terdapat beberapa celah yang menjadi landasan penelitian ini:

1. Belum ada sistem RAG yang diimplementasikan secara khusus untuk domain konsultasi audio mobil dengan basis pengetahuan yang dikurasi secara domain-spesifik, sehingga potensi RAG dalam meningkatkan akurasi konsultasi teknis audio mobil belum pernah dikaji.

2. Penggunaan Hybrid Search berbasis RRF sebagai strategi retrieval dalam sistem RAG untuk domain teknis yang memerlukan pencocokan nama produk eksak sekaligus pemahaman semantik belum mendapat perhatian yang memadai dalam penelitian terdahulu, di mana sebagian besar penelitian RAG menggunakan pure dense atau pure sparse retrieval.

3. Integrasi deteksi konteks kendaraan dalam pipeline RAG untuk konsultasi produk teknis belum pernah diteliti, padahal relevansi rekomendasi produk audio sangat bergantung pada spesifikasi kendaraan pengguna seperti tipe dashboard, ukuran speaker bawaan, dan kapasitas kabin.

---

### Tabel Perbandingan Penelitian Terdahulu

| Peneliti (Tahun) | Metode Retrieval | Domain | Deteksi Konteks | Perbedaan dengan Penelitian Ini |
|---|---|---|---|---|
| Lewis et al. (2020) | Dense (DPR) | Open-domain QA | Tidak ada | Penelitian ini menerapkan RAG + Hybrid Search (RRF) pada domain audio mobil |
| Shuster et al. (2021) | Dense + Ranker | Open-domain dialogue | Tidak ada | Penelitian ini menggunakan domain teknis spesifik dengan deteksi kendaraan |
| Jeong et al. (2024) | Adaptive dense | Open-domain QA | Tidak ada | Penelitian ini menerapkan RAG + Hybrid Search + (RRF) pada domain audio mobil |
| Adam et al. (2021) | Tidak ada | Layanan pelanggan | Tidak ada | Penelitian ini menambahkan RAG + Hybrid Search untuk konsultasi produk teknis |
| Arslan et al. (2024) | Berbagai (survei) | Multi-domain | Tidak ada | Penelitian ini mengimplementasikan sistem konkret, yaitu audio mobil + Hybrid Search (RRF) |

Sumber: Pengolahan dari beberapa jurnal ilmiah

Kerangka konseptual penelitian ini berfokus pada akurasi dan relevansi informasi sebagai pilar utama dalam pengembangan chatbot konsultasi teknis. Pilar ini diwujudkan melalui arsitektur Retrieval-Augmented Generation (RAG) dengan mekanisme Hybrid Search berbasis RRF yang menjamin jawaban chatbot berlandaskan pada basis pengetahuan audio mobil yang valid dan minim halusinasi. Diksi "minim halusinasi" digunakan secara sadar karena RAG menekan halusinasi secara signifikan namun tidak menghilangkannya sepenuhnya dimana apabila hasil retrieval tidak mencakup informasi yang relevan atau basis pengetahuan memiliki celah, LLM tetap berpotensi mengisi celah tersebut menggunakan pengetahuan parametriknya sendiri yang tidak terverifikasi. Shuster et al. (2021) sendiri mencatat reduksi halusinasi lebih dari 60 persen bukan eliminasi penuh yang mengonfirmasi bahwa kualitas retrieval dan kelengkapan basis pengetahuan menjadi penentu utama seberapa jauh halusinasi dapat ditekan. Relevansi rekomendasi produk lebih lanjut ditingkatkan melalui komponen deteksi konteks kendaraan yang mengidentifikasi merek dan model kendaraan pengguna untuk menyajikan produk yang kompatibel. Sinergi antara ketepatan faktual dari RAG, efisiensi retrieval dari Hybrid Search, dan relevansi kontekstual dari deteksi kendaraan diharapkan menghasilkan sistem AudioMatch yang mampu memberikan pengalaman konsultasi yang akurat, relevan, dan dapat diandalkan.

---

## 2.2 Landasan Teori

### 2.2.1 Komponen Sistem Audio Mobil

Sistem audio mobil terdiri dari serangkaian komponen elektronika yang bekerja secara terintegrasi untuk menghasilkan reproduksi suara di dalam kabin kendaraan. Komponen utama dalam sistem ini meliputi unit sumber sinyal (head unit), penguat sinyal (amplifier), pengubah sinyal elektrik menjadi gelombang suara (speaker dan subwoofer), serta media penghubung berupa sistem pengkabelan. Setiap komponen memiliki karakteristik teknis yang harus selaras satu sama lain untuk mencapai kualitas suara yang optimal dan menjaga keamanan sistem kelistrikan kendaraan (Wawancara, Pemilik Rendy Audio, Februari 2026).

Head unit merupakan pusat kontrol utama dari seluruh sistem audio mobil yang berfungsi sebagai sumber pemutar media dan pemroses sinyal audio awal. Amplifier berfungsi untuk meningkatkan amplitudo sinyal audio dari head unit agar memiliki daya yang cukup untuk menggerakkan driver speaker. Speaker dan subwoofer memiliki peran vital dalam mereproduksi rentang frekuensi suara, di mana speaker umumnya menangani frekuensi menengah hingga tinggi, sedangkan subwoofer dikhususkan untuk frekuensi rendah atau bass. Adapun sistem pengkabelan yang mencakup kabel daya, kabel sinyal (RCA), dan kabel speaker menentukan kualitas transmisi energi serta data antar komponen tanpa gangguan noise yang berarti (Wawancara, Pemilik Rendy Audio, Februari 2026).

---

### 2.2.2 Chatbot dan Conversational AI

Chatbot merupakan program komputer yang dirancang untuk berinteraksi dengan pengguna melalui percakapan berbasis teks atau suara menggunakan Natural Language Processing (Adamopoulou & Moussiades, 2020). Adam et al. (2021) mendefinisikan chatbot sebagai sistem perangkat lunak percakapan yang mampu berkomunikasi dengan pengguna melalui antarmuka natural language, dirancang untuk menggantikan atau melengkapi agen layanan manusia dalam berbagai konteks. Chatbot dapat diklasifikasikan berdasarkan domain pengetahuan yang dikuasai, kebutuhan yang dilayani, dan teknologi yang mendasarinya.

Perkembangan chatbot dapat ditelusuri hingga tahun 1966 ketika ELIZA, chatbot pertama yang dikenal, dikembangkan untuk mensimulasikan sesi psikoterapi menggunakan pattern matching sederhana (Adamopoulou & Moussiades, 2020). Tonggak berikutnya adalah ALICE yang menggunakan Artificial Intelligence Markup Language (AIML) dan meraih penghargaan Loebner Prize pada tahun 2000, 2001, dan 2004. Perkembangan lebih lanjut menghadirkan asisten virtual berbasis AI berupa Apple Siri, Microsoft Cortana, Amazon Alexa, dan Google Assistant yang memperluas penggunaan chatbot ke perangkat seluler dan rumah tangga. Berdasarkan data Scopus yang dianalisis Adamopoulou & Moussiades (2020), terjadi pertumbuhan pesat dalam jumlah publikasi riset chatbot terutama setelah tahun 2016.

Chatbot dapat dibedakan menjadi dua kategori utama, yaitu task-oriented chatbot yang berfokus pada penyelesaian tugas spesifik seperti layanan pelanggan dan penjawab pertanyaan, serta social chatbot yang berfokus pada percakapan bebas dan interaksi sosial (Adamopoulou & Moussiades, 2020). Huang et al. (2022) menambahkan bahwa chatbot memiliki tiga keunggulan teknologi utama, yaitu ketepatan waktu respons, kemudahan penggunaan, dan kemampuan personalisasi yang menjadikannya pilihan efektif sebagai asisten digital di berbagai domain. Dalam penelitian ini, AudioMatch dikembangkan sebagai task-oriented chatbot yang berfokus pada domain konsultasi audio mobil.

---

### 2.2.3 Human-Chatbot Interaction

Human-chatbot interaction merupakan bidang yang mengkaji bagaimana pengguna berinteraksi, membangun persepsi, dan membentuk hubungan dengan sistem chatbot (Skjuve et al., 2021). Skjuve et al. (2021) menemukan bahwa pengguna mampu membentuk hubungan dengan chatbot yang memiliki dimensi afektif, di mana tingkat keterbukaan dan kepercayaan pengguna berkembang seiring bertambahnya frekuensi interaksi. Temuan ini didasarkan pada Social Penetration Theory yang mendeskripsikan perkembangan hubungan sebagai proses pendalaman bertahap melalui pengungkapan diri yang semakin personal.

Adam et al. (2021) mengkaji pengaruh desain komunikatif chatbot terhadap kepatuhan pengguna dalam mengikuti rekomendasi yang diberikan sistem. Mereka menemukan bahwa dua faktor desain utama, yaitu anthropomorphism dan teknik foot-in-the-door dimana secara nyata meningkatkan kemungkinan pengguna mengikuti permintaan chatbot. Social presence, yaitu persepsi pengguna tentang kehadiran nyata entitas sosial di balik chatbot, terbukti memediasi pengaruh anthropomorphism tersebut terhadap tingkat kepatuhan pengguna.

Huang et al. (2022) menunjukkan bahwa chatbot yang mampu merespons secara personal dan kontekstual mendorong keterlibatan pengguna yang lebih aktif dibandingkan sistem yang memberikan respons generik. Dalam konteks konsultasi audio mobil, kualitas interaksi antara pengguna dan chatbot mempengaruhi tidak hanya kepuasan pelanggan, tetapi juga kemungkinan rekomendasi chatbot diikuti oleh pengguna. Oleh karena itu, AudioMatch dirancang untuk memberikan informasi teknis yang akurat dan relevan dengan mempertimbangkan konteks kendaraan pengguna melalui mekanisme deteksi kendaraan berbasis basis data.

---

### 2.2.4 Natural Language Processing (NLP)

Natural Language Processing (NLP) merupakan cabang kecerdasan buatan yang berfokus pada pemrosesan dan pemahaman bahasa manusia secara komputasional, mencakup aspek sintaksis, semantik, dan sentimental dari teks (Patil et al., 2023). NLP terdiri dari dua komponen inti, yaitu representasi teks masukan ke dalam format numerik berupa vektor atau matriks, dan perancangan model untuk memproses representasi tersebut guna mencapai tujuan tertentu. Kemajuan di bidang NLP telah memungkinkan berbagai aplikasi berupa penerjemahan mesin, pengenalan entitas bernama, analisis sentimen, dan sistem chatbot.

Salah satu tantangan dalam sistem NLP adalah permasalahan bias yang dapat muncul dalam model bahasa. Blodgett et al. (2020) melakukan tinjauan atas 146 paper tentang bias dalam sistem NLP dan menemukan bahwa motivasi penelitian bias seringkali tidak konsisten serta kurang memiliki landasan normatif yang jelas. Mereka mengklasifikasikan dampak bias ke dalam dua kategori, yaitu allocational harms di mana sistem mengalokasikan sumber daya atau peluang secara tidak adil kepada kelompok tertentu, dan representational harms di mana sistem merepresentasikan kelompok sosial tertentu secara tidak proporsional atau merendahkan. Sainz et al. (2023) menambahkan permasalahan kontaminasi data dalam evaluasi LLM, yaitu ketika model telah melihat data test set selama pelatihan sehingga performa yang dilaporkan menjadi overestimasi dari kemampuan model yang sesungguhnya.

Dalam penelitian ini, komponen NLP digunakan oleh AudioMatch pada tahap utama pemrosesan pertanyaan pengguna, meliputi ekstraksi intent, pembuatan embedding query, dan pencarian berbasis teks penuh (full-text search) menggunakan mekanisme BM25 untuk mendukung pipeline Hybrid Search.

---

### 2.2.5 Text Representation dan Embedding

Text representation merupakan proses mengubah teks masukan ke dalam format numerik yang dapat diproses oleh model machine learning (Patil et al., 2023). Patil et al. (2023) mengklasifikasikan teknik representasi teks ke dalam tiga pendekatan utama, yaitu rule-based, statistical, dan neural network-based. Pendekatan rule-based menggunakan aturan tata bahasa, pendekatan statistik mencakup teknik seperti Bag of Words (BoW), TF-IDF, dan n-gram, sedangkan pendekatan neural network menghasilkan representasi yang lebih kaya dan konteks-sensitif.

Word embedding merupakan representasi vektor kontinu yang menangkap makna semantik sebuah kata berdasarkan konteks kemunculannya dalam teks (Patil et al., 2023). Pendekatan ini mengatasi keterbatasan teknik statistik yang tidak mampu menangkap sinonim atau keterkaitan makna antar kata. Perkembangan lebih lanjut menghasilkan contextual embedding berupa model seperti BERT, di mana representasi vektor setiap kata bervariasi tergantung konteks kalimatnya, memberikan pemahaman yang jauh lebih kaya dibandingkan representasi vektor statis.

Patil et al. (2023) menegaskan bahwa kemampuan neural embedding untuk mengidentifikasi sinonim, analogi, dan hubungan semantik menjadikannya pilihan yang tepat untuk sistem information retrieval yang membutuhkan pemahaman kontekstual. Dalam sistem AudioMatch, contextual embedding digunakan dalam komponen vector search pada mekanisme Hybrid Search, di mana setiap dokumen dalam basis pengetahuan audio mobil direpresentasikan sebagai vektor semantik 1024 dimensi menggunakan model VoyageAI voyage-3.5-lite.

---

### 2.2.6 Information Retrieval

Information Retrieval (IR) merupakan proses menemukan dokumen atau informasi yang relevan dari sekumpulan besar dokumen berdasarkan kueri yang diberikan oleh pengguna (Cuconasu et al., 2024). Metode IR tradisional berbasis sparse retrieval, di mana BM25 merupakan representasi paling umum, bekerja dengan mencocokkan kata kunci dalam kueri dengan kata kunci dalam dokumen menggunakan inverted index yang ditimbang berdasarkan frekuensi term (Fan et al., 2024). Metode ini bersifat transparan dan efisien secara komputasi, namun memiliki keterbatasan dalam memahami makna implisit atau sinonim yang tidak secara eksplisit muncul dalam teks.

Dense retrieval merupakan pendekatan IR yang mengubah kueri dan dokumen ke dalam representasi vektor kontinu di ruang semantik menggunakan model transformer sebagai encoder (Fan et al., 2024). Kemiripan antara kueri dan dokumen diukur menggunakan dot product atau cosine similarity di antara vektor-vektor tersebut. Dense Passage Retriever (DPR) adalah salah satu implementasi dense retrieval paling berpengaruh, dilatih secara khusus menggunakan pasangan pertanyaan-jawaban dan menunjukkan performa tinggi pada berbagai tugas QA (Lewis et al., 2020). Cuconasu et al. (2024) mengonfirmasi bahwa dense retrieval menggunakan encoder berbasis transformer yang menghasilkan embedding untuk kueri dan dokumen, kemudian mengukur relevansi melalui perkalian dot product antar vektor.

Dalam konteks sistem RAG, komponen retrieval berperan sebagai penyaring utama yang menentukan kualitas informasi yang akan diberikan kepada generator (Cuconasu et al., 2024). Fan et al. (2024) menunjukkan bahwa strategi retrieval dapat dibedakan berdasarkan tipe retriever, granularitas retrieval berupa dokumen, passage, token, atau entitas, serta proses pre-retrieval dan post-retrieval enhancement. Dalam penelitian ini, AudioMatch menerapkan mekanisme IR berupa Hybrid Search yang menggabungkan kekuatan sparse dan dense retrieval untuk memaksimalkan relevansi dokumen yang diambil dari basis pengetahuan audio mobil.

---

### 2.2.7 Retrieval-Augmented Generation (RAG)

Retrieval-Augmented Generation (RAG) merupakan arsitektur yang mengintegrasikan mekanisme information retrieval ke dalam proses generasi teks oleh model bahasa, sehingga respons yang dihasilkan memiliki landasan faktual dari basis pengetahuan eksternal (Lewis et al., 2020). Lewis et al. (2020) memperkenalkan arsitektur ini sebagai model yang menggabungkan parametric memory berupa model seq2seq yang terlatih dengan non-parametric memory berupa dense vector index, di mana komponen retrieval mengambil dokumen relevan sebelum generator menyusun respons. Arslan et al. (2024) mendefinisikan RAG sebagai pendekatan yang memadukan pengambilan data eksternal ke dalam proses generasi teks, sehingga meningkatkan akurasi dan relevansi keluaran yang dihasilkan oleh LLM.

Arsitektur RAG terdiri dari tiga komponen utama, yaitu retriever yang menemukan dokumen relevan dari basis pengetahuan eksternal, augmentation yang mengintegrasikan dokumen-dokumen tersebut ke dalam konteks input, serta generator yang menghasilkan respons berdasarkan gabungan kueri dan konteks yang diambil (Fan et al., 2024). Shuster et al. (2021) membuktikan bahwa pendekatan RAG mampu menekan tingkat halusinasi model percakapan lebih dari 60 persen dibandingkan model generatif tanpa augmentasi retrieval, dengan peningkatan keandalan yang bahkan lebih menonjol pada topik di luar distribusi data pelatihan. Fan et al. (2024) menambahkan bahwa arsitektur RAG bersifat fleksibel karena komponen dataset, retriever, dan LLM dapat dikembangkan dan diperbarui secara independen tanpa perlu fine-tuning ulang seluruh sistem, menjadikannya solusi yang adaptif untuk berbagai kebutuhan domain.

Arslan et al. (2024) mengidentifikasi pertumbuhan nyata dalam riset aplikasi RAG, dari satu publikasi pada tahun 2020 menjadi 28 publikasi pada tahun 2023, mencakup domain biomedis, finansial, pendidikan, pengembangan perangkat lunak, dan komunikasi. Aplikasi RAG yang paling banyak dikaji adalah Question Answering, diikuti oleh Text Generation, Information Retrieval and Extraction, serta Decision Making. Dalam penelitian ini, AudioMatch mengimplementasikan RAG sebagai mekanisme utama untuk menjamin akurasi informasi teknis dalam konsultasi audio mobil, di mana basis pengetahuan yang dikurasi secara manual menjadi sumber retrieval yang terstruktur.

---

### 2.2.8 Hybrid Search dan Reciprocal Rank Fusion (RRF)

Hybrid Search merupakan pendekatan information retrieval yang menggabungkan sparse retrieval berbasis kata kunci dengan dense retrieval berbasis semantik dalam satu pipeline yang terintegrasi (Fan et al., 2024). Pendekatan sparse, misalnya BM25, sangat efektif dalam mencocokkan kata kunci eksak dan nama produk spesifik karena bekerja dengan inverted index berbasis frekuensi term, namun tidak mampu memahami makna implisit atau sinonim yang tidak eksplisit muncul dalam teks (Fan et al., 2024). Adapun pendekatan dense bekerja di ruang vektor semantik sehingga mampu menangkap kemiripan makna antara kueri dan dokumen meski tidak mengandung kata yang identik, namun kurang presisi untuk pencocokan kata kunci atau nama yang eksak (Cuconasu et al., 2024).

Fan et al. (2024) menunjukkan bahwa sparse retrieval memiliki keterbatasan mendasar berupa sifatnya yang tidak memerlukan pelatihan, sehingga bergantung sepenuhnya pada kualitas teks dan kueri itu sendiri, serta hanya mendukung pencocokan berbasis term yang bersifat tetap. Dense retrieval, sebaliknya, bersifat trainable dan mampu beradaptasi pada domain tertentu melalui fine-tuning, menjadikannya lebih fleksibel untuk keperluan semantic matching. Mekanisme penggabungan skor dari kedua pendekatan ini, salah satunya menggunakan teknik Reciprocal Rank Fusion (RRF), memungkinkan sistem mengoptimalkan relevansi hasil retrieval dengan memanfaatkan kekuatan masing-masing metode secara bersamaan.

Salah satu teknik penggabungan yang umum digunakan adalah Reciprocal Rank Fusion (RRF), yang diperkenalkan oleh Cormack et al. (2009) sebagai metode untuk menggabungkan hasil dari beberapa sistem retrieval yang berbeda tanpa memerlukan kalibrasi skor lintas sistem. RRF menghitung skor gabungan setiap dokumen berdasarkan posisi ranking-nya dalam masing-masing jalur retrieval menggunakan formula berikut:

RRFscore(d∈D)=∑_(r∈R)▒1/(k+r(d))

Di mana R adalah himpunan daftar ranking, r(d) adalah posisi dokumen d pada daftar ranking r, dan k adalah konstanta yang berfungsi meredam dampak dokumen berperingkat sangat tinggi (umumnya k = 60). Dokumen yang secara konsisten muncul di posisi tinggi pada beberapa jalur retrieval akan memperoleh skor RRF yang lebih besar, terlepas dari perbedaan skala skor antar jalur. Dalam sistem AudioMatch, RRF diimplementasikan dengan konstanta k = 60 dan bobot tertimbang antara jalur vector search (bobot 0,6) dan jalur BM25 (bobot 0,4), sehingga skor hybrid akhir dihitung sebagai:

0,6×RRf_vector  +0,4×RRf_BM25

Pembobotan lebih tinggi pada jalur vector search (0,6) dibandingkan jalur BM25 (0,4) mencerminkan temuan Karpukhin et al. (2020) bahwa dense retrieval secara konsisten mengungguli BM25 sebesar 9–19% pada tugas yang memerlukan pemahaman semantik, sementara komponen BM25 tetap dipertahankan dengan bobot signifikan untuk memastikan pencocokan eksak nama produk dan merek dalam domain audio mobil.

Dalam domain konsultasi audio mobil, Hybrid Search memberikan manfaat yang nyata. Pengguna sering menyebut nama merek atau kode model produk tertentu yang membutuhkan lexical matching presisi, sekaligus mengajukan pertanyaan konseptual tentang kompatibilitas komponen atau perbandingan spesifikasi yang membutuhkan semantic matching. Cuconasu et al. (2024) mengonfirmasi bahwa jenis dokumen yang diambil retriever berdampak nyata pada kualitas respons generator, di mana dokumen yang mengganggu namun tidak relevan dapat menurunkan akurasi jawaban hingga lebih dari 25 persen. Oleh karena itu, AudioMatch menggunakan Hybrid Search untuk memaksimalkan relevansi dan presisi dokumen yang diterima oleh komponen generator RAG.

---

### 2.2.9 Caching dengan Redis

Caching merupakan teknik penyimpanan sementara hasil komputasi atau data yang sering diakses agar permintaan berikutnya dapat dilayani tanpa mengulang proses yang sama dari awal. Redis (Remote Dictionary Server) adalah sistem penyimpanan struktur data dalam memori (in-memory data store) yang bersifat open-source dan umum digunakan sebagai layer caching, message broker, maupun penyimpanan sesi. Redis mendukung berbagai struktur data berupa string, hash, list, dan set, serta menyediakan mekanisme Time-to-Live (TTL) untuk mengatur masa berlaku entri cache secara otomatis. Adam et al. (2021) menekankan bahwa kemampuan chatbot untuk mempertahankan konteks percakapan secara konsisten merupakan faktor penting dalam meningkatkan kecenderungan pengguna mengikuti rekomendasi sistem, di mana caching sesi percakapan menjadi mekanisme teknis yang mendukung konsistensi konteks tersebut.

Upstash Redis merupakan varian Redis yang mengekspos antarmuka berbasis HTTP/REST alih-alih koneksi TCP persisten yang lazim digunakan Redis konvensional. Arsitektur REST ini menjadikan Upstash Redis kompatibel dengan lingkungan serverless yang tidak mempertahankan koneksi jaringan antar invokasi fungsi, sehingga setiap permintaan dapat mengakses cache secara mandiri tanpa memerlukan connection pool. Wen et al. (2023) mencatat bahwa paradigma serverless mengharuskan aplikasi dirancang tanpa mengandalkan state yang tersimpan dalam memori proses, sehingga penggunaan cache eksternal seperti Redis menjadi komponen esensial dalam arsitektur chatbot berbasis serverless.

---

### 2.2.10 PostgreSQL sebagai Sistem Manajemen Basis Data

PostgreSQL merupakan sistem manajemen basis data relasional (Relational Database Management System/RDBMS) yang bersifat open-source dan mendukung penuh standar SQL. PostgreSQL dirancang dengan arsitektur yang mengutamakan reliabilitas, integritas data, dan kemampuan ekstensi, di mana fitur-fiturnya mencakup transaksi ACID, tipe data yang kaya, indeks yang beragam, dan dukungan terhadap data JSON maupun array. Lathkar (2023) menjelaskan bahwa PostgreSQL dapat diintegrasikan ke dalam aplikasi FastAPI menggunakan driver asinkronus seperti asyncpg dan aiopg, yang memungkinkan pengelolaan koneksi database secara non-blocking sesuai dengan model asinkronus Python modern.

Alasan utama pemilihan PostgreSQL dalam sistem AudioMatch adalah keberadaan ekstensi pgvector yang menambahkan tipe data `vector` dan operator pencarian kemiripan berbasis cosine distance ke dalam PostgreSQL. Weng & Wu (2025) membandingkan PostgreSQL dengan MongoDB untuk kebutuhan sistem berbasis kecerdasan buatan dan menyimpulkan bahwa PostgreSQL unggul dalam skenario yang memerlukan konsistensi data yang ketat, kueri yang kompleks, dan data terstruktur dimana karakteristik yang sesuai dengan kebutuhan basis data AudioMatch yang menyimpan relasi antar entitas produk, masalah, dan solusi secara terstruktur.

Selain pgvector, PostgreSQL memiliki dukungan native untuk pencarian teks penuh (full-text search) menggunakan mekanisme `tsvector` dan `ts_rank_cd` dengan GIN index yang memungkinkan pencarian berbasis BM25 secara efisien. Kemampuan ganda ini menjadikan PostgreSQL sebagai satu-satunya komponen penyimpanan dalam sistem AudioMatch yang mampu menangani tiga kebutuhan sekaligus, yaitu penyimpanan data relasional, pencarian vektor untuk dense retrieval, dan full-text search untuk sparse retrieval BM25, menggantikan kebutuhan dua atau lebih sistem terpisah yang umumnya digunakan pada implementasi RAG konvensional.

---

### 2.2.11 Metodologi Pengembangan Perangkat Lunak (SDLC)

Software Development Life Cycle (SDLC) merupakan kerangka kerja terstruktur yang mendefinisikan tahapan sistematis dalam perencanaan, perancangan, pengembangan, pengujian, penerapan, dan pemeliharaan perangkat lunak (Pargaonkar, 2023). Yas et al. (2023) menjelaskan bahwa SDLC menyediakan berbagai model yang dapat disesuaikan dengan karakteristik dan kebutuhan proyek yang berbeda-beda, di mana setiap model menawarkan skenario yang berbeda untuk membuat proses pengembangan lebih efisien dan dapat diprediksi. SDLC memastikan bahwa seluruh tahapan pengembangan direncanakan dan dilaksanakan secara terstruktur, sehingga meminimalkan risiko kesalahan dan memaksimalkan kualitas produk akhir (Pargaonkar, 2023).

Model Waterfall merupakan salah satu model SDLC yang paling mendasar dan banyak digunakan, dengan pendekatan linier-sekuensial di mana setiap fase harus diselesaikan sebelum fase berikutnya dapat dimulai (Yas et al., 2023). Fase-fase dalam model Waterfall meliputi analisis kebutuhan (requirements analysis), desain sistem (system design), implementasi (implementation), pengujian (testing), penerapan (deployment), dan pemeliharaan (maintenance). Pendekatan ini sangat sesuai untuk proyek dengan kebutuhan yang sudah terdefinisi dengan baik dan relatif stabil sepanjang siklus pengembangan (Pargaonkar, 2023). Dengan mengikuti urutan fase yang ketat, tim pengembang dapat memastikan bahwa setiap komponen sistem dibangun di atas fondasi yang solid sebelum dilanjutkan ke tahap berikutnya, sehingga menghasilkan dokumentasi yang lengkap dan proses yang mudah diaudit.

---

### 2.2.12 Black Box Testing

Black Box Testing merupakan metode pengujian perangkat lunak yang berfokus pada verifikasi fungsionalitas sistem berdasarkan spesifikasi eksternal tanpa memeriksa atau mengetahui struktur kode internalnya (Maspupah, 2024). Penguji hanya berfokus pada input yang diberikan dan output yang dihasilkan, kemudian membandingkannya dengan keluaran yang diharapkan berdasarkan kebutuhan pengguna. Maspupah (2024) dalam tinjauan literaturnya terhadap 15 studi menyimpulkan bahwa Black Box Testing sangat efektif untuk mengevaluasi perilaku perangkat lunak dalam mengidentifikasi kesalahan pada fungsi, pemrosesan data, dan akses data eksternal, serta cocok diterapkan tanpa memerlukan pengetahuan mendalam tentang logika internal sistem.

Terdapat beberapa teknik yang umum digunakan dalam Black Box Testing, di mana salah satu yang paling sering diterapkan adalah Equivalence Partitioning. Azizah et al. (2024) menjelaskan bahwa Equivalence Partitioning membagi domain input program ke dalam beberapa kelompok data sehingga memungkinkan pembuatan test case yang lebih spesifik dan efektif, dengan keunggulan berupa cakupan input yang lebih luas karena pemilihan perwakilan dari setiap kelompok data memastikan berbagai skenario dapat diuji secara menyeluruh. Teknik ini digunakan untuk menguji apakah sistem menangani data valid dan tidak valid dengan benar tanpa perlu menguji seluruh kemungkinan nilai input satu per satu. Dalam konteks sistem AudioMatch, Black Box Testing diterapkan untuk memverifikasi bahwa setiap endpoint API, pipeline RAG, mekanisme Hybrid Search, deteksi kendaraan, dan fitur percakapan berfungsi sesuai spesifikasi yang telah dirancang.

---

### 2.2.13 Evaluasi Kualitas Information Retrieval

Evaluasi sistem information retrieval memerlukan metrik yang mampu mengukur relevansi dan kualitas ranking dokumen yang dihasilkan oleh retriever. Metrik evaluasi information retrieval yang umum digunakan meliputi Precision@K, yaitu proporsi dokumen relevan di antara K dokumen teratas yang diambil oleh retriever, dan Recall@K yang mengukur proporsi dokumen relevan yang berhasil ditemukan dari keseluruhan yang tersedia (Manning et al., 2009). Mean Reciprocal Rank (MRR) mengukur peringkat rata-rata dokumen relevan pertama dalam hasil retrieval, di mana nilai lebih tinggi menunjukkan sistem yang lebih baik dalam menempatkan dokumen paling relevan di posisi teratas.

Normalized Discounted Cumulative Gain (NDCG@K) merupakan metrik standar yang lebih komprehensif untuk mengevaluasi kualitas ranking sistem retrieval karena mempertimbangkan baik posisi maupun tingkat relevansi dokumen secara bersamaan (Järvelin & Kekäläinen, 2002). NDCG didasarkan pada prinsip bahwa dokumen relevan yang muncul di posisi lebih tinggi memiliki nilai lebih besar, dengan bobot yang berkurang secara logaritmik seiring bertambahnya peringkat. Formula Discounted Cumulative Gain (DCG) pada posisi K adalah:

DCG@K=∑_(i=1)^K▒(2^(rel_i )-1)/log_2⁡〖(i+1)〗 

Di mana rel_i adalah tingkat relevansi dokumen pada posisi ke-i (misalnya, 0 = tidak relevan, 1 = relevan, 2 = sangat relevan). NDCG@K kemudian dinormalisasi dengan membagi DCG@K dengan nilai Ideal DCG@K (IDCG@K), yaitu nilai DCG maksimum yang dapat dicapai apabila seluruh dokumen relevan tersusun dalam urutan ideal:

NDCG@K =  (DCG@K)/(IDCG@K)

Nilai NDCG berada dalam rentang [0, 1], di mana nilai 1 menunjukkan urutan ranking yang sempurna. Järvelin & Kekäläinen (2002) membuktikan bahwa NDCG lebih sensitif terhadap posisi dokumen relevan dibandingkan metrik IR tradisional seperti Precision@K, menjadikannya pilihan yang tepat untuk mengevaluasi sistem retrieval yang menghasilkan ranked list.

Adapun Precision@K merupakan metrik yang mengukur proporsi dokumen relevan di antara K dokumen teratas yang dikembalikan oleh sistem retrieval. Berbeda dengan NDCG yang mempertimbangkan posisi dan tingkat relevansi secara bersamaan, Precision@K hanya mengukur ada-tidaknya relevansi pada setiap dokumen yang ditampilkan. Formula Precision@K didefinisikan sebagai berikut:

$$\text{Precision@K} = \frac{\sum_{i=1}^{K} \mathbb{1}[rel_i \geq 1]}{K}$$

Di mana $\mathbb{1}[rel_i \geq 1]$ bernilai 1 apabila dokumen pada posisi ke-$i$ dianggap relevan (skor relevansi ≥ 1), dan 0 apabila tidak relevan. Precision@K mengukur **cakupan relevansi** — yaitu berapa banyak dari dokumen yang ditampilkan benar-benar berguna bagi pengguna — tanpa mempertimbangkan posisi kemunculannya dalam ranking. Berbeda dengan NDCG yang sensitif terhadap posisi, Precision memberikan bobot yang setara apakah dokumen relevan muncul di posisi pertama maupun di posisi K (Manning et al., 2009).

Dalam penelitian ini, dua metrik evaluasi digunakan secara komplementer untuk memperoleh gambaran kualitas retrieval yang lebih menyeluruh. NDCG@K digunakan sebagai metrik utama untuk mengevaluasi kualitas urutan dokumen hasil Hybrid Search pada sistem AudioMatch, dengan menguji apakah dokumen yang paling relevan secara konsisten ditempatkan di posisi teratas. Precision@K digunakan sebagai metrik pelengkap untuk mengukur densitas relevansi dari keseluruhan hasil yang ditampilkan, yaitu berapa proporsi dokumen yang dikembalikan benar-benar relevan tanpa mempertimbangkan posisinya. Kedua metrik ini mengukur aspek yang berbeda: NDCG sensitif terhadap posisi dan tingkat relevansi, sedangkan Precision hanya mengukur ada-tidaknya relevansi pada tiap dokumen (Manning et al., 2009). Kombinasi keduanya memungkinkan identifikasi apakah sistem berhasil dalam hal peringkat sekaligus dalam hal cakupan relevansi, sehingga kelemahan pada salah satu dimensi dapat diidentifikasi secara spesifik.

---

### 2.2.14 Prompt Engineering

Prompt Engineering merupakan disiplin ilmu yang berfokus pada perancangan dan pengoptimalan instruksi teks (*prompt*) untuk mengarahkan perilaku Large Language Model (LLM) tanpa mengubah parameter atau bobot internal model itu sendiri (Brown et al., 2020). Berbeda dengan pendekatan *fine-tuning* yang memerlukan pembaruan bobot model melalui proses pelatihan ulang, Prompt Engineering bekerja sepenuhnya pada lapisan input, yakni dengan merumuskan instruksi yang tepat agar model menghasilkan keluaran yang sesuai dengan kebutuhan sistem. Brown et al. (2020) dalam penelitian pionirnya mengenai GPT-3 membuktikan bahwa LLM berkapasitas besar mampu menyelesaikan berbagai tugas baru dengan hanya memanfaatkan deskripsi tugas dan contoh-contoh yang disematkan dalam prompt, tanpa memerlukan proses pelatihan tambahan yang mahal.

Dalam konteks sistem RAG, Prompt Engineering memainkan peran yang sangat vital melalui pendekatan yang dikenal sebagai *Contextual Prompting*. *Contextual Prompting* adalah teknik di mana dokumen-dokumen yang diambil oleh komponen retriever disematkan secara dinamis ke dalam prompt yang diberikan kepada LLM, bersama dengan instruksi yang mengarahkan model agar hanya menggunakan informasi dari konteks tersebut sebagai dasar jawabannya (Brown et al., 2020). Pendekatan ini secara langsung mengatasi masalah halusinasi yang umum terjadi pada LLM generatif, yaitu kondisi di mana model menghasilkan informasi yang tampak meyakinkan namun tidak berdasarkan fakta. Dengan membatasi ruang jawaban LLM pada konteks yang telah diverifikasi dari basis pengetahuan, *Contextual Prompting* memungkinkan sistem memberikan respons yang akurat dan dapat dipertanggungjawabkan secara konsisten.

Komponen utama sebuah *contextual prompt* dalam sistem RAG terdiri dari tiga elemen yang saling melengkapi: (1) *system instruction*, yaitu instruksi peran dan batasan perilaku yang diberikan kepada model; (2) injeksi konteks retrieval, yaitu dokumen-dokumen relevan yang diperoleh dari basis pengetahuan melalui proses retrieval; dan (3) kueri pengguna, yaitu pertanyaan aktual yang diajukan oleh pengguna. Ketiga elemen ini digabungkan secara dinamis pada setiap permintaan sehingga LLM selalu menerima informasi terkini dari basis pengetahuan yang relevan dengan pertanyaan yang sedang diproses. Dalam sistem AudioMatch, prompt dikonstruksi secara dinamis pada setiap siklus percakapan berdasarkan dokumen-dokumen yang berhasil diambil oleh komponen Hybrid Search, sehingga memastikan bahwa respons yang dihasilkan Gemini 2.5 Flash Lite selalu berlandaskan informasi aktual dari katalog produk dan basis pengetahuan teknis Rendy Audio.

---

### 2.2.15 Justifikasi Pemilihan Nilai K pada Pengujian Retrieval

Pengujian kualitas retrieval pada sistem AudioMatch menggunakan dua nilai K, yaitu $K=3$ dan $K=5$, sebagai batas jumlah dokumen yang diambil dan dievaluasi dalam setiap siklus retrieval. Penetapan kedua nilai tersebut tidak dilakukan secara arbitrer, melainkan didasarkan pada justifikasi teoritis dan praktis yang telah ditetapkan dalam penelitian sebelumnya.

Pemilihan $K=3$ didasarkan pada dua landasan yang saling mendukung. Dari perspektif antarmuka pengguna, nilai $K=3$ merepresentasikan batas atensi visual yang dapat dijangkau pengguna pada layar pertama antarmuka chatbot berbasis *mobile* tanpa perlu melakukan *scrolling*. Informasi yang melampaui batas visual ini berisiko tidak terbaca oleh pengguna, sehingga relevansi dokumen yang muncul di posisi ketiga ke bawah memiliki dampak praktis yang lebih kecil terhadap kualitas pengalaman pengguna. Dari perspektif ilmiah, Lewis et al. (2020) dalam penelitian RAG mereka menunjukkan bahwa sistem QA berbasis retrieval umumnya mencapai efisiensi dan akurasi yang optimal pada rentang dokumen terambil yang terbatas, di mana kualitas dokumen teratas lebih menentukan kualitas jawaban akhir dibandingkan kuantitas dokumen yang diproses.

Pemilihan $K=5$ didasarkan pada *Cognitive Load Theory* yang dikemukakan oleh Sweller (1988), yang menyatakan bahwa kapasitas memori kerja manusia memiliki batas pemrosesan informasi simultan. Sweller (1988) menunjukkan bahwa pemrosesan lebih dari 5 hingga 7 elemen informasi secara bersamaan akan menurunkan efektivitas pemahaman dan kinerja kognitif pengguna. Dalam konteks sistem retrieval, nilai $K=5$ dipilih sebagai batas maksimum yang mampu diproses oleh LLM sekaligus batas yang tidak membebani konteks percakapan secara berlebihan. Melampaui nilai ini berpotensi menyebabkan *information overload* baik pada LLM yang memproses konteks maupun pada pengguna yang menerima respons, sehingga $K=5$ dipandang sebagai titik keseimbangan optimal antara kelengkapan informasi dan efisiensi pemrosesan.

Evaluasi sistem RAG juga memerlukan pengujian fungsionalitas sistem secara menyeluruh. Maspupah (2024) dalam tinjauan literaturnya menyimpulkan bahwa Black Box Testing sangat efektif untuk mengevaluasi perilaku perangkat lunak dalam mengidentifikasi kesalahan pada fungsi, pemrosesan data, dan akses data eksternal. Beale et al. (2025) mengevaluasi chatbot AI dalam konteks layanan medis menggunakan beberapa dimensi penilaian termasuk akurasi dan keterbacaan respons, menunjukkan pentingnya evaluasi yang tidak hanya mengukur metrik teknis tetapi juga ketepatan fungsional sistem secara keseluruhan.