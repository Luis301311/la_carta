class LocationModel {
  final double lat;
  final double lng;
  final String address;

  LocationModel({
    required this.lat,
    required this.lng,
    required this.address,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      lat: json['lat'],
      lng: json['lng'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'address': address,
    };
  }
}