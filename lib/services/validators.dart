/// Validasi input sesuai standar data kependudukan & telekomunikasi Indonesia.
class Validators {
  Validators._();

  static final _emailRegex = RegExp(
    r"^[a-zA-Z0-9]([a-zA-Z0-9._%+-]{0,62}[a-zA-Z0-9])?@[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z]{2,})+$",
  );
  static final _nameRegex = RegExp(r"^[A-Za-z][A-Za-z .'\-]*$");
  // Seluler Indonesia: 08xx (10-13 digit) setelah dinormalisasi.
  static final _phoneRegex = RegExp(r'^08[1-9][0-9]{7,10}$');

  static String? name(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Nama lengkap wajib diisi.';
    if (s.length < 3) return 'Nama minimal 3 karakter.';
    if (s.length > 100) return 'Nama maksimal 100 karakter.';
    if (!_nameRegex.hasMatch(s)) {
      return 'Nama hanya boleh huruf, spasi, titik, apostrof, dan strip.';
    }
    return null;
  }

  static String? email(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Alamat email wajib diisi.';
    if (s.length > 254 || !_emailRegex.hasMatch(s) || s.contains('..')) {
      return 'Format email tidak valid. Contoh: nama@gmail.com';
    }
    return null;
  }

  /// Normalisasi ke format 08xxxxxxxxxx (menerima +62, 62, atau 0).
  static String normalizePhone(String v) {
    var s = v.replaceAll(RegExp(r'[\s\-().]'), '');
    if (s.startsWith('+62')) {
      s = '0${s.substring(3)}';
    } else if (s.startsWith('62')) {
      s = '0${s.substring(2)}';
    }
    return s;
  }

  static String? phone(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Nomor WhatsApp/HP wajib diisi.';
    if (!RegExp(r'^[+0-9\s\-().]+$').hasMatch(s)) {
      return 'Nomor HP hanya boleh berisi angka.';
    }
    if (!_phoneRegex.hasMatch(normalizePhone(s))) {
      return 'Nomor HP Indonesia tidak valid. Contoh: 0812 3456 7890 atau +62 812 3456 7890';
    }
    return null;
  }

  static String? address(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Alamat rumah wajib diisi.';
    if (s.length < 15) return 'Alamat terlalu singkat (min. 15 karakter).';
    if (s.length > 250) return 'Alamat maksimal 250 karakter.';
    final up = s.toUpperCase();
    if (!RegExp(r'\bRT\b\.?\s*\d{1,3}').hasMatch(up) ||
        !RegExp(r'\bRW\b\.?\s*\d{1,3}').hasMatch(up)) {
      return 'Cantumkan RT dan RW. Contoh: Kampung Badran RT 04 RW 11, Bumijo, Jetis';
    }
    return null;
  }

  static String? password(String? v, {String? email}) {
    final s = v ?? '';
    if (s.isEmpty) return 'Kata sandi wajib diisi.';
    if (s.length < 8) return 'Kata sandi minimal 8 karakter.';
    if (s.length > 72) return 'Kata sandi maksimal 72 karakter.';
    if (!RegExp(r'[A-Z]').hasMatch(s)) return 'Harus mengandung huruf besar.';
    if (!RegExp(r'[a-z]').hasMatch(s)) return 'Harus mengandung huruf kecil.';
    if (!RegExp(r'[0-9]').hasMatch(s)) return 'Harus mengandung angka.';
    if (s.contains(' ')) return 'Kata sandi tidak boleh mengandung spasi.';
    final local = (email ?? '').split('@').first.toLowerCase();
    if (local.length >= 4 && s.toLowerCase().contains(local)) {
      return 'Kata sandi tidak boleh mengandung nama email Anda.';
    }
    return null;
  }

  static String? otp(String? v) {
    final s = (v ?? '').trim();
    if (!RegExp(r'^\d{6,8}$').hasMatch(s)) {
      return 'Masukkan kode verifikasi 6–8 digit dari email.';
    }
    return null;
  }
}
