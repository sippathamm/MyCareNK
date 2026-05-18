class ServiceCenterModel {
  final String name;
  final String? imageUrl;
  final String? description;
  final List<Map<String, String>> contacts;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final int displayOrder;
  final String? operatingHours;

  const ServiceCenterModel({
    required this.name,
    this.imageUrl,
    this.description,
    required this.contacts,
    this.latitude,
    this.longitude,
    required this.isActive,
    required this.displayOrder,
    this.operatingHours,
  });

  factory ServiceCenterModel.fromMap(Map<String, dynamic> map) {
    return ServiceCenterModel(
      name: map['name'] as String,
      imageUrl: map['image_url'] as String?,
      description: map['description'] as String?,
      contacts: (map['contacts'] as List<dynamic>? ?? [])
          .map((c) => Map<String, String>.from(c as Map))
          .toList(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      isActive: map['is_active'] as bool? ?? true,
      displayOrder: map['display_order'] as int? ?? 0,
      operatingHours: map['operating_hours'] as String?,
    );
  }
}
