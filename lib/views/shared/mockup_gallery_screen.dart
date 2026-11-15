import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class MockupGalleryScreen extends StatelessWidget {
  const MockupGalleryScreen({super.key});

  final List<Map<String, String>> _mockups = const [
    {
      'title': 'A. Akses Warga & Kebijakan Privasi',
      'section': 'Proposal Bab 8 & 9.A',
      'path': 'assets/mockups/Akses warga.png',
      'desc': 'Layar pendaftaran & login warga dengan persetujuan privasi UU PDP No. 27/2022.',
    },
    {
      'title': 'B. Beranda Warga (Home)',
      'section': 'Proposal Bab 8.A (Gambar 6)',
      'path': 'assets/mockups/Beranda warga.png',
      'desc': 'Aksi cepat jemput sampah, saldo poin, mitra terdekat, dan materi Mas JOS.',
    },
    {
      'title': 'C. Pemilihan Material Penjemputan',
      'section': 'Proposal Bab 8.B (Gambar 7)',
      'path': 'assets/mockups/Pilih material jemput.png',
      'desc': 'Pemilihan komoditas (Jelantah liter / Botol PET kg) dan petunjuk persiapan wadah.',
    },
    {
      'title': 'D. Mitra BSU, Alamat & Jadwal',
      'section': 'Proposal Bab 8.B & 6.F',
      'path': 'assets/mockups/Mitra alamat dan jadwal.png',
      'desc': 'Pencarian BSU terdekat (Haversine), tanggal jemput, dan titik koordinat rumah.',
    },
    {
      'title': 'E. Status Penjemputan Warga',
      'section': 'Proposal Bab 6.D & 8.B',
      'path': 'assets/mockups/Status penjemputan warga.png',
      'desc': 'Visual timeline status pesanan (Draf → Mitra → Petugas → Timbang → Selesai).',
    },
    {
      'title': 'F. Tugas & Verifikasi Petugas',
      'section': 'Proposal Bab 8.E (Gambar 10)',
      'path': 'assets/mockups/Tugas dan verifikasi petugas.png',
      'desc': 'Formulir input hasil timbang aktual, pengali mutu (0.8x / 1.0x / 1.1x) dan foto bukti.',
    },
    {
      'title': 'G. Konfirmasi Hasil Timbang Warga',
      'section': 'Proposal Bab 6.D & 9.A',
      'path': 'assets/mockups/Konfirmasi hasil timbang.png',
      'desc': 'Warga memvalidasi hasil ukur petugas; opsi konfirmasi terima poin atau sengketa.',
    },
    {
      'title': 'H. Dompet Poin & Katalog Reward',
      'section': 'Proposal Bab 8.C (Gambar 8)',
      'path': 'assets/mockups/Dompet dan katalog reward.png',
      'desc': 'Saldo reward, buku besar transaksi audit, dan penukaran sembako/kupon.',
    },
    {
      'title': 'I. Akademi Mas JOS & Kuis',
      'section': 'Proposal Bab 8.D (Gambar 9)',
      'path': 'assets/mockups/Akademi Pilah Jogja.png',
      'desc': '5 Aksi Mas JOS Kota Yogyakarta dan kuis interaktif evaluasi literasi pemilahan.',
    },
    {
      'title': 'J. Dashboard Admin BSU',
      'section': 'Proposal Bab 8.E & 7.D',
      'path': 'assets/mockups/Dashboard Admin BSU.png',
      'desc': 'Monitoring penugasan kader, penyelesaian sengketa, dan rekap indikator dampak pilot.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Galeri Mockup Bab 8 Proposal'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _mockups.length,
        itemBuilder: (context, index) {
          final m = _mockups[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  color: const Color(0xFFF1F8E9),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          m['title']!,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryGreen),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryMedium,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          m['section']!,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(m['desc']!, style: const TextStyle(fontSize: 12, color: Color(0xFF455A64))),
                ),
                Container(
                  height: 380,
                  width: double.infinity,
                  color: const Color(0xFFECEFF1),
                  child: Image.asset(
                    m['path']!,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text(m['path']!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}
