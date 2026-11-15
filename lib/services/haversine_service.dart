import 'dart:math' as math;

class HaversineService {
  /// Earth radius in kilometers
  static const double _earthRadiusKm = 6371.0;

  /// Calculates straight-line distance in kilometers between two GPS coordinates
  static double calculateDistanceKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final distance = _earthRadiusKm * c;

    // Return rounded to 1 decimal place
    return (distance * 10).round() / 10.0;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// Formatted distance string e.g. "1.2 km (perkiraan)"
  static String formatDistance(double distanceKm) {
    return '${distanceKm.toStringAsFixed(1)} km (perkiraan)';
  }
}
