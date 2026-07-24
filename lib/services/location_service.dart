import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  // Check and request location permissions
  static Future<bool> checkPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Get current GPS coordinates
  static Future<Position> getCurrentLocation() async {
    final hasPermission = await checkPermission();
    if (!hasPermission) {
      throw StateError(
        'Location access is unavailable. Enable location services and '
        'grant location permission in your device settings.',
      );
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Reverse geocode coordinates to Nairobi neighborhood name
  static Future<String> getNeighborhoodFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // Extract relevant Nairobi locality/suburb
        // Try subLocality, then locality, then administrativeArea
        final neighborhood =
            place.subLocality ??
            place.locality ??
            place.subAdministrativeArea ??
            'Unknown';

        // Clean up and standardize common Nairobi neighborhoods
        final normalized = _normalizeNeighborhood(neighborhood);
        return normalized;
      }
    } catch (_) {
      // Return the default city when reverse geocoding is unavailable.
    }

    return 'Nairobi';
  }

  // Normalize neighborhood names to known list
  static String _normalizeNeighborhood(String input) {
    final lower = input.toLowerCase().trim();

    // Map common variations to standardized names
    final mapping = {
      'westlands': 'Westlands',
      'kilimani': 'Kilimani',
      'karen': 'Karen',
      'eastlands': 'Eastlands',
      'kasarani': 'Kasarani',
      'lavington': 'Lavington',
      'parklands': 'Parklands',
      'thika road': 'Thika Rd',
      'thika rd': 'Thika Rd',
      'cbd': 'CBD',
      'nairobi cbd': 'CBD',
      'nairobi': 'Nairobi',
      'kileleshwa': 'Kileleshwa',
      'langata': 'Langata',
      'hurlingham': 'Hurlingham',
      'kensington': 'Kensington',
      'spring valley': 'Spring Valley',
      'muthaiga': 'Muthaiga',
      'runda': 'Runda',
      'gigiri': 'Gigiri',
      'loresho': 'Loresho',
      'kitisuru': 'Kitisuru',
    };

    return mapping[lower] ?? input;
  }

  // Calculate distance between two coordinates in km
  static double calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;
  }

  // Get distance from current location to a point
  static Future<double> getDistanceTo(
    double targetLat,
    double targetLng,
  ) async {
    try {
      final currentPosition = await getCurrentLocation();
      return calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        targetLat,
        targetLng,
      );
    } catch (_) {
      return 0.0;
    }
  }

  // Check if location services are enabled
  static Future<bool> isLocationEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  // Open app location settings
  static Future<void> openSettings() async {
    await Geolocator.openAppSettings();
  }
}
