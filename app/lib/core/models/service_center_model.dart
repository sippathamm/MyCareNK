class ServiceCenterModel {
  final String name;
  final String? imageUrl;
  final String? description;
  final String? address;
  final List<Map<String, String>> contacts;
  final double? latitude;
  final double? longitude;
  final int displayOrder;
  final String? operatingHours;
  final bool condomServiceEnabled;
  final bool appointmentServiceEnabled;
  final List<String> pickupTimes;
  final List<String> appointmentTimes;

  const ServiceCenterModel({
    required this.name,
    this.imageUrl,
    this.description,
    this.address,
    required this.contacts,
    this.latitude,
    this.longitude,
    required this.displayOrder,
    this.operatingHours,
    this.condomServiceEnabled = true,
    this.appointmentServiceEnabled = false,
    this.pickupTimes = const ['10:00', '14:00'],
    this.appointmentTimes = const [],
  });

  factory ServiceCenterModel.fromMap(Map<String, dynamic> map) {
    return ServiceCenterModel(
      name: map['name'] as String,
      imageUrl: map['image_url'] as String?,
      description: map['description'] as String?,
      address: map['address'] as String?,
      contacts: (map['contacts'] as List<dynamic>? ?? [])
          .map((c) => Map<String, String>.from(c as Map))
          .toList(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      displayOrder: map['display_order'] as int? ?? 0,
      operatingHours: map['operating_hours'] as String?,
      condomServiceEnabled: map['condom_service_enabled'] as bool? ?? true,
      appointmentServiceEnabled: map['appointment_service_enabled'] as bool? ?? false,
      pickupTimes: List<String>.from(map['pickup_times'] ?? ['10:00', '14:00']),
      appointmentTimes: List<String>.from(map['appointment_times'] ?? []),
    );
  }
}
