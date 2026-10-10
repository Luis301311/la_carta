class LocationModel {
  final double? lat;
  final double? lng;
  final String address;

  LocationModel({
    this.lat,
    this.lng,
    this.address = '',
  });

  bool get hasCoordinates => lat != null && lng != null;
}
