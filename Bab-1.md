# BAB I
PENDAHULUAN

## 1.1 Latar Belakang

Pasar audio mobil global terus menunjukkan pertumbuhan yang stabil dari tahun ke tahun. Nilai pasar car audio global diperkirakan mencapai sekitar USD 10,89 hingga 12,24 miliar pada tahun 2025, dengan tingkat pertumbuhan tahunan (CAGR) berkisar antara 6,4% hingga 9,9% hingga periode 2030–2035 (Fortune Business Insights, 2026). Wilayah Asia Pasifik memegang pangsa pasar terbesar, yaitu sekitar 39%–54%, yang didorong oleh tingginya produksi kendaraan dan meningkatnya permintaan terhadap teknologi otomotif canggih di kawasan tersebut (Mordor Intelligence, 2026). Pertumbuhan ini menunjukkan signifikansi sektor audio mobil sebagai bagian integral dari industri otomotif modern yang semakin memprioritaskan pengalaman hiburan di dalam kabin kendaraan.

Produk audio mobil memiliki rantai kompatibilitas yang kompleks dan memerlukan pemahaman teknis yang mendalam tentang kesesuaian antarkomponennya. Setiap komponen mulai dari head unit, amplifier, speaker, hingga subwoofer harus dipilih dengan mempertimbangkan spesifikasi kendaraan dan komponen lainnya agar dapat bekerja secara optimal. Tidak semua pelanggan memiliki pengetahuan yang memadai untuk memutuskan kombinasi komponen yang tepat, sehingga proses konsultasi dengan tenaga ahli menjadi bagian yang tidak terpisahkan dari pembelian produk audio mobil. Rekomendasi yang tidak tepat dapat berujung pada kerusakan komponen atau investasi yang terbuang sia-sia bagi pemilik kendaraan, sehingga ketepatan informasi teknis menjadi kebutuhan utama bagi konsumen dalam melakukan modifikasi sistem audio kendaraannya.

Perkembangan teknologi kecerdasan buatan telah mendorong pemanfaatan chatbot secara luas di berbagai sektor pelayanan. Pertumbuhan minat terhadap chatbot, terutama setelah tahun 2016, telah dicatat oleh Adamopoulou & Moussiades (2020) di mana teknologi ini kini banyak diterapkan dalam bidang pemasaran, layanan pelanggan, pendidikan, hingga kesehatan. Pemanfaatan chatbot berbasis AI ini memiliki potensi besar dalam mentransformasi standar layanan pelanggan di industri modern.

Transformasi layanan tersebut berupa pengurangan biaya operasional yang substansial sekaligus kemampuan sistem untuk menangani sebagian besar pertanyaan rutin secara otomatis. Adam et al. (2021) menunjukkan bahwa chatbot berbasis AI memungkinkan tenaga ahli manusia difokuskan pada permasalahan yang memerlukan penilaian lebih mendalam, sementara sistem menangani interaksi repetitif. Dengan kemampuan pemrosesan bahasa alami yang semakin maju, chatbot tidak lagi sekadar menjadi alat penjawab otomatis, melainkan telah menjadi asisten digital yang mampu memberikan respons yang lebih kontekstual dan relevan bagi pengguna.

Toko audio mobil konvensional merupakan salah satu layanan teknis dengan rentang pengetahuan pelanggan yang sangat lebar. Berdasarkan hasil wawancara dengan pemilik Rendy Audio pada Februari 2026, toko tersebut menerima sekitar 20–70 pertanyaan konsultasi setiap minggunya. Sekitar 70% dari total pertanyaan tersebut merupakan pertanyaan yang serupa atau berulang, yang menunjukkan adanya beban kerja repetitif yang tinggi bagi staf ahli di toko. Karakteristik pertanyaan pelanggan pun sangat beragam. Sebagian pelanggan baru pertama kali mengenal komponen dasar, sementara sebagian lain sudah memahami parameter teknis yang rumit seperti sensitivitas speaker atau desain crossover. Kondisi ini menjadikan toko audio mobil sebagian domain yang relevan untuk penerapan chatbot sebagai lini pertama layanan konsultasi.

Penerapan chatbot generatif pada domain teknis seperti audio mobil menghadapi tantangan berupa risiko halusinasi informasi, yaitu model bahasa besar dapat menghasilkan jawaban yang meyakinkan namun tidak berdasar secara faktual sehingga berpotensi merugikan konsumen (Chang et al., 2024). Lewis et al. (2020) memperkenalkan arsitektur Retrieval-Augmented Generation (RAG) sebagai solusi dengan mengintegrasikan mekanisme pencarian berbasis semantik dari basis pengetahuan eksternal yang dapat diverifikasi ke dalam proses generasi teks. Pendekatan ini terbukti mampu menekan tingkat halusinasi lebih dari 60 persen dibandingkan model tanpa augmentasi retrieval, dengan keandalan yang semakin menonjol pada topik di luar distribusi data pelatihan (Shuster et al., 2021). Arslan et al. (2024) mengonfirmasi keberhasilan implementasi RAG pada berbagai domain teknis, sehingga metode ini relevan untuk diaplikasikan dalam sistem konsultasi audio mobil.

Sebagian besar sistem RAG yang telah dikembangkan, termasuk implementasi awal Lewis et al. (2020) yang menggunakan metode pencarian berbasis semantik secara tunggal, belum mengoptimalkan kombinasi antara pencarian berbasis kata kunci dan pencarian berbasis makna untuk domain teknis yang memiliki terminologi spesifik. Padahal, dalam konteks konsultasi audio mobil, pengguna kerap menyebutkan nama merek atau kode model produk secara spesifik sekaligus mengajukan pertanyaan konseptual yang membutuhkan pemahaman makna yang lebih luas. Selain itu, relevansi rekomendasi produk yang bergantung pada konteks kendaraan yang dimiliki pengguna juga belum mendapat perhatian memadai dalam implementasi RAG yang ada. Celah inilah yang menjadi titik berangkat pengembangan chatbot asisten konsultasi audio mobil yang dinamakan AudioMatch.

Berdasarkan celah tersebut, penelitian ini mengembangkan AudioMatch sebagai chatbot asisten konsultasi audio mobil yang menggabungkan dua pendekatan pencarian secara bersamaan agar hasil yang diperoleh lebih akurat dan relevan. Sistem ini juga dilengkapi dengan kemampuan mengenali informasi kendaraan yang disebutkan pengguna, sehingga rekomendasi produk yang diberikan dapat disesuaikan dengan spesifikasi kendaraan yang bersangkutan. Dengan pendekatan ini, AudioMatch diharapkan mampu menjawab berbagai jenis pertanyaan konsultasi baik yang menyebutkan nama produk spesifik maupun yang bersifat konseptual secara akurat dan konsisten.

Penelitian ini diharapkan dapat memberikan kontribusi nyata bagi pengembangan layanan konsultasi digital di sektor otomotif, khususnya dalam membantu pelaku usaha audio mobil melayani pelanggan dengan lebih efisien dan konsisten. Kerangka sistem yang dihasilkan diharapkan dapat menjadi referensi bagi pengembang yang ingin menerapkan pendekatan serupa pada domain teknis lain yang membutuhkan asisten konsultasi berbasis pengetahuan yang akurat dan minim halusinasi.

---

## 1.2 Rumusan Masalah

Berdasarkan uraian latar belakang yang telah dipaparkan, permasalahan penelitian ini dirumuskan sebagai berikut:

a. Bagaimana merancang dan mengembangkan chatbot AudioMatch berbasis arsitektur RAG dengan mekanisme Hybrid Search yang mampu menghasilkan respons faktual dalam domain konsultasi audio mobil?

b. Seberapa efektif sistem chatbot AudioMatch dalam memberikan layanan konsultasi audio mobil berdasarkan akurasi fungsionalitas sistem dan kualitas retrieval Hybrid Search?

---

## 1.3 Batasan Masalah

Agar penelitian ini dapat dilaksanakan secara terfokus dan mendalam, ditetapkan batasan-batasan sebagai berikut:

1. Domain pengetahuan sistem dibatasi pada topik dan produk yang berkaitan dengan audio mobil, mencakup komponen head unit, amplifier, speaker, subwoofer, dan sistem pengkabelan, termasuk panduan kompatibilitas antar komponen. Topik di luar ekosistem audio mobil tidak tercakup dalam sistem.

2. Basis pengetahuan yang digunakan dalam mekanisme RAG dikurasi secara manual dari dokumen spesifikasi produk, panduan instalasi, dan materi konsultasi yang telah diverifikasi. Sistem tidak melakukan pengambilan data secara otomatis dari internet secara real-time selama sesi percakapan.

3. Pengembangan sistem menggunakan model bahasa besar yang tersedia melalui antarmuka API publik tanpa melakukan fine-tuning penuh pada model dasar, mengingat keterbatasan sumber daya komputasi dan cakupan penelitian yang ditetapkan.

4. Evaluasi sistem dilakukan melalui dua pendekatan pengujian berbasis teknis, yaitu pengujian fungsionalitas menggunakan metode Black Box Testing terhadap seluruh endpoint dan alur utama sistem, serta pengujian kualitas retrieval menggunakan metrik NDCG@K dan Precision@K terhadap 30 kueri uji yang teranotasi. Evaluasi tidak melibatkan pengujian berbasis responden pengguna nyata dan tidak mencakup pengujian dalam kondisi deployment produksi berskala besar.

5. Penelitian ini berfokus pada perancangan arsitektur teknis dan pengujian sistem chatbot AudioMatch, meliputi pipeline RAG, mekanisme Hybrid Search, dan kualitas retrieval. Perancangan antarmuka pengguna (UI/UX) tidak menjadi objek utama evaluasi dalam penelitian ini.

---

## 1.4 Tujuan Penelitian

Penelitian ini bertujuan untuk:

1. Merancang dan mengembangkan chatbot AudioMatch berbasis arsitektur RAG dengan mekanisme Hybrid Search yang mampu menghasilkan respons akurat dan minim halusinasi dari basis pengetahuan domain audio mobil.

2. Mengevaluasi efektivitas sistem AudioMatch melalui pengujian fungsionalitas sistem secara menyeluruh dan pengujian kualitas retrieval Hybrid Search menggunakan metrik information retrieval yang terstandarisasi.

---

## 1.5 Manfaat Penelitian

Hasil penelitian ini diharapkan memberikan manfaat pada dua tataran yang saling melengkapi.

**Manfaat Teoritis**

Penelitian ini berkontribusi pada pengembangan pemahaman tentang penerapan arsitektur RAG dengan mekanisme Hybrid Search berbasis RRF pada domain teknis yang spesifik. Pendekatan ini memperluas kajian mengenai bagaimana kombinasi sparse retrieval (BM25) dan dense retrieval (vector search) dapat dioptimalkan melalui algoritma fusion untuk meningkatkan akurasi konsultasi teknis berbasis chatbot. Penelitian ini juga menyumbangkan wawasan empiris tentang integrasi deteksi konteks kendaraan dalam pipeline RAG untuk meningkatkan relevansi rekomendasi produk, yang dapat menjadi landasan bagi penelitian lanjutan di bidang domain-specific conversational AI.

Bagi mahasiswa dan peneliti yang ingin mengkaji pendekatan serupa, penelitian ini menyediakan kerangka referensi implementatif untuk pengembangan sistem chatbot berbasis RAG dengan Hybrid Search pada domain teknis lainnya. Kerangka evaluasi yang meliputi pengujian fungsionalitas (Black Box Testing) dan evaluasi kualitas retrieval (NDCG@K) dapat diadopsi sebagai titik berangkat bagi penelitian di bidang serupa.

**Manfaat Praktis**

Dari sisi penerapan, kerangka kerja yang dihasilkan penelitian ini dapat dimanfaatkan oleh pelaku bisnis audio mobil, baik toko ritel maupun bengkel instalasi, untuk membangun asisten konsultasi digital yang mampu melayani pelanggan dari berbagai latar belakang pengetahuan. Sistem semacam ini berpotensi meningkatkan efisiensi operasional toko dengan mengotomasi penanganan pertanyaan berulang, serta meningkatkan kepercayaan pelanggan melalui rekomendasi produk yang akurat dan disesuaikan dengan spesifikasi kendaraan mereka. Penelitian ini juga dapat menjadi acuan bagi pengembang sistem serupa di domain teknis lain yang menghadapi kebutuhan untuk menyampaikan rekomendasi produk yang akurat kepada pengguna dengan berbagai jenis kendaraan.