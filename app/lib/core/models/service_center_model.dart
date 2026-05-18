class ServiceCenterModel {
  final String name;
  final List<Map<String, String>> contacts;
  final bool isActive;
  final int displayOrder;
  final String? operatingHours;

  const ServiceCenterModel({
    required this.name,
    required this.contacts,
    required this.isActive,
    required this.displayOrder,
    this.operatingHours,
  });

  factory ServiceCenterModel.fromMap(Map<String, dynamic> map) {
    return ServiceCenterModel(
      name: map['name'] as String,
      contacts: (map['contacts'] as List<dynamic>? ?? [])
          .map((c) => Map<String, String>.from(c as Map))
          .toList(),
      isActive: map['is_active'] as bool? ?? true,
      displayOrder: map['display_order'] as int? ?? 0,
      operatingHours: map['operating_hours'] as String?,
    );
  }
}
