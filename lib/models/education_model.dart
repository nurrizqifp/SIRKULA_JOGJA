class EducationModule {
  final String id;
  final String title;
  final String actionNumber;    // 'Aksi 1', 'Aksi 2', etc.
  final String subtitle;
  final String fullContent;
  final List<String> practicalTips;
  final String jogjaPolicyRef;   // e.g. "Perwal Kota Yogyakarta No. 40/2024"
  final String iconKey;

  const EducationModule({
    required this.id,
    required this.title,
    required this.actionNumber,
    required this.subtitle,
    required this.fullContent,
    required this.practicalTips,
    required this.jogjaPolicyRef,
    required this.iconKey,
  });

  static const List<EducationModule> masJosModules = [
    EducationModule(
      id: 'masjos_1',
      actionNumber: 'Aksi 1 Mas JOS',
      title: 'Memilah Sampah Sejak dari Dapur',
      subtitle: 'Pisahkan anorganik daur ulang, organik dapur, dan residu sejak timbul.',
      fullContent:
          'Kunci utama sirkular ekonomi Kota Yogyakarta adalah pemilahan di hulu. Sediakan minimal 3 wadah di rumah: (1) Wadah wadah kering untuk botol PET, kardus, kaleng; (2) Wadah tertutup untuk sisa minyak jelantah; (3) Wadah organik untuk sisa sayur dan bahan olahan pangan.',
      practicalTips: [
        'Jangan campur botol plastik basah dengan kertas atau kardus.',
        'Kumpulkan jelantah dalam jeriken tertutup, bukan dibuang ke saluran air/got.',
        'Remas botol plastik untuk menghemat ruang penyimpanan di rumah.',
      ],
      jogjaPolicyRef: 'Gerakan Mas JOS - DLH Kota Yogyakarta 2026',
      iconKey: 'sort',
    ),
    EducationModule(
      id: 'masjos_2',
      actionNumber: 'Aksi 2 Mas JOS',
      title: 'Menyetorkan Anorganik Bernilai ke BSU',
      subtitle: 'Salurkan botol PET dan minyak jelantah ke Bank Sampah Unit terdekat.',
      fullContent:
          'Kota Yogyakarta telah memiliki lebih dari 713 Bank Sampah Unit aktif. Menyetorkan sampah terpilah ke BSU menjaga material bernilai tetap berputar ke industri daur ulang, sekaligus memberikan poin reward bernilai ekonomis bagi keluarga nasabah.',
      practicalTips: [
        'Gunakan aplikasi SIRKULA-JOGJA untuk melihat jadwal jemput BSU terdekat.',
        'Pastikan botol PET telah dikosongkan dari cairan manis agar tidak mengundang semut.',
        'Catat jadwal operasional BSU di lingkungan RW Anda.',
      ],
      jogjaPolicyRef: 'Warta Pemkot Yogyakarta Juli 2026 (713 BSU Kota Jogja)',
      iconKey: 'account_balance',
    ),
    EducationModule(
      id: 'masjos_3',
      actionNumber: 'Aksi 3 Mas JOS',
      title: 'Mengolah Sampah Organik Mandiri',
      subtitle: 'Gunakan metode biopori, losida, atau ember tumpuk skala rumah tangga.',
      fullContent:
          'Sekitar 50-60% sampah perkotaan adalah sisa organik. Karena aplikasi ini memfokuskan layanan jemput pada anorganik kering dan jelantah, sampah organik wajib dikelola mandiri menggunakan komposter ember tumpuk, lorong sisa dapur (losida), atau budidaya maggot BSF di tingkat RW.',
      practicalTips: [
        'Gunakan lubang biopori di halaman untuk sisa dedaunan dan kulit buah.',
        'Manfaatkan ember tumpuk untuk memanen pupuk organik cair (POC).',
        'Hindari memasukkan daging atau tulang berlebih ke komposter sederhana.',
      ],
      jogjaPolicyRef: 'Instruksi Pengelolaan Sampah Organik Mandiri Pemkot Yogyakarta',
      iconKey: 'compost',
    ),
    EducationModule(
      id: 'masjos_4',
      actionNumber: 'Aksi 4 Mas JOS',
      title: 'Menghabiskan Makanan (Cegah Food Waste)',
      subtitle: 'Rencanakan porsi makan keluarga untuk mencegah timbulan sampah makanan.',
      fullContent:
          'Sampah makanan yang membusuk di TPA menghasilkan gas metana pemicu pemanasan global. Kebiasaan mengambil makanan secukupnya dan menyimpan bahan pangan dengan baik dapat memangkas volume sampah harian Kota Jogja secara signifikan.',
      practicalTips: [
        'Belanja bahan makanan sesuai menu mingguan yang direncanakan.',
        'Simpan sayuran dalam wadah kedap udara di kulkas agar tahan lama.',
        'Habiskan sajian piring tanpa menyisakan nasi atau lauk.',
      ],
      jogjaPolicyRef: 'Kampanye Stop Boros Pangan DLH Kota Yogyakarta',
      iconKey: 'restaurant',
    ),
    EducationModule(
      id: 'masjos_5',
      actionNumber: 'Aksi 5 Mas JOS',
      title: 'Gunakan Wadah Berulang & Cegah Plastik',
      subtitle: 'Bawa tas belanja sendiri dan kurangi kemasan plastik sekali pakai.',
      fullContent:
          'Sesuai Peraturan Wali Kota Yogyakarta Nomor 40 Tahun 2024 tentang Pengurangan Timbulan Sampah Plastik Sekali Pakai, pelaku usaha dan masyarakat didorong membiasakan tas kain, tumbler minum, dan wadah guna ulang saat berbelanja di pasar maupun supermarket.',
      practicalTips: [
        'Selalu sediakan tas lipat kain di dalam tas kerja atau bagasi motor.',
        'Tolak sedotan plastik dan kantong kresek untuk pembelian jumlah kecil.',
        'Bawa kotak bekal saat membeli makanan bawa pulang (take-away).',
      ],
      jogjaPolicyRef: 'Peraturan Wali Kota Yogyakarta No. 40 Tahun 2024',
      iconKey: 'shopping_bag',
    ),
  ];
}

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  static const List<QuizQuestion> sampleQuestions = [
    QuizQuestion(
      id: 'q1',
      question: 'Bagaimana cara terbaik menyiapkan botol plastik PET sebelum dijemput kader BSU?',
      options: [
        'Biarkan terisi air penuh agar berat timbangan lebih banyak',
        'Kosongkan cairan, bilas bersih, dan remas/pipihkan botol',
        'Campur dengan sampah basah sisa makanan',
        'Bakar label plastik langsung di halaman rumah',
      ],
      correctIndex: 1,
      explanation:
          'Mengosongkan cairan dan memipihkan botol PET menghemat volume penyimpanan dan menjaga kualitas daur ulang bernilai tinggi.',
    ),
    QuizQuestion(
      id: 'q2',
      question: 'Mengapa minyak jelantah rumah tangga tidak boleh dibuang ke saluran wastafel atau got?',
      options: [
        'Menyumbat pipa saluran air dan mencemari ekosistem sungai Jogja',
        'Dapat berubah menjadi pupuk organik secara instan',
        'Akan menguap sendiri menjadi udara bersih',
        'Membunuh bakteri baik di instalasi pengolahan limbah tanpa sisa',
      ],
      correctIndex: 0,
      explanation:
          'Minyak jelantah yang membeku di saluran pipa membentuk gumpalan lemak (fatberg), menyumbat drainase kota, dan mencemari sungai.',
    ),
    QuizQuestion(
      id: 'q3',
      question: 'Apa kepanjangan dan tujuan dari gerakan Mas JOS di Kota Yogyakarta?',
      options: [
        'Masyarakat Jogja Olah Sampah, mewujudkan 5 aksi penanganan sampah sejak hulu',
        'Makan Semua Jogja Organik Sampah, program bagi-bagi makanan',
        'Mesin Otomatis Sampah Jogja, robot pemilah sampah otomatis',
        'Mobil Angkut Sampah Jogja, pengadaan armada truk baru',
      ],
      correctIndex: 0,
      explanation:
          'Mas JOS adalah gerakan Masyarakat Jogja Olah Sampah dengan 5 pilar aksi pengurangan dan pengolahan sampah sejak dari rumah tangga.',
    ),
    QuizQuestion(
      id: 'q4',
      question: 'Berapa faktor pengali kualitas maksimal yang dapat diberikan kader BSU untuk pemilahan sangat baik di SIRKULA-JOGJA?',
      options: [
        '0.5x pengali',
        '1.0x pengali',
        '1.1x pengali (bonus apresiasi pemilahan rapi)',
        '2.5x pengali',
      ],
      correctIndex: 2,
      explanation:
          'Sistem SIRKULA-JOGJA menyediakan faktor 1.1x sebagai bonus insentif bagi warga yang memilah material dengan standar sangat bersih dan rapi.',
    ),
  ];
}
