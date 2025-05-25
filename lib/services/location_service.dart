import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<String> getAddressFromCoordinates(Position position) async {
    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return '${placemark.street}, ${placemark.locality}';
      }
      return 'Unknown location';
    } catch (_) {
      return 'Unknown location';
    }
  }

  double calculateDistanceMeters(Position start, double lat, double lng) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      lat,
      lng,
    );
  }

  int calculateDeliveryTimeMinutes(double meters) => (meters / 500).ceil(); // 500m/min
  int calculateDeliveryFee(double meters) => (meters / 1000 * 10).ceil();   // ₹10/km
}
