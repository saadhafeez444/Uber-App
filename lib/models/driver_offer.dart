import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationData {
  final String title;
  final String subtitle;
  final LatLng coordinates;

  LocationData(this.title, this.subtitle, {required this.coordinates});

  Map<String, dynamic> toMap() => {
    'title': title,
    'subtitle': subtitle,
    'lat': coordinates.latitude,
    'lng': coordinates.longitude,
  };

  static LocationData fromMap(Map<String, dynamic> map) {
    final lat = (map['lat'] as num).toDouble();
    final lng = (map['lng'] as num).toDouble();
    return LocationData(
      map['title'] ?? '',
      map['subtitle'] ?? '',
      coordinates: LatLng(lat, lng),
    );
  }
}

class DriverOffer {
  final String id;
  final String driverName;
  final double fare;
  final double distance;
  final String truckType;

  DriverOffer(
    this.id,
    this.driverName,
    this.fare,
    this.distance,
    this.truckType,
  );

  Map<String, dynamic> toMap() => {
    'driverName': driverName,
    'fare': fare,
    'distance': distance,
    'truckType': truckType,
  };

  static DriverOffer fromMap(String id, Map<String, dynamic> map) {
    return DriverOffer(
      id,
      map['driverName'] ?? '',
      (map['fare'] as num?)?.toDouble() ?? 0.0,
      (map['distance'] as num?)?.toDouble() ?? 0.0,
      map['truckType'] ?? '',
    );
  }
}
