
enum RequestStatus {
  submitted,
  preparing,
  completed,
  cancelled,
}

class CondomRequestModel {
  final String id;
  final String userId;
  final Map<int, int> condomQuantities;
  final int lubricantQuantity;
  final String? selectedLocation;
  final String? selectedDate;
  final String? selectedTime;
  final String message;
  final String referenceNumber;
  final RequestStatus status;
  final DateTime createdAt;

  CondomRequestModel({
    required this.id,
    required this.userId,
    required this.condomQuantities,
    required this.lubricantQuantity,
    this.selectedLocation,
    this.selectedDate,
    this.selectedTime,
    required this.message,
    required this.referenceNumber,
    required this.status,
    required this.createdAt,
  });

  factory CondomRequestModel.fromJson(Map<String, dynamic> json) {
    // Parse quantities
    Map<int, int> parsedQuantities = {};
    if (json['condom_quantities'] != null) {
      final q = json['condom_quantities'] as Map<String, dynamic>;
      q.forEach((key, value) {
        parsedQuantities[int.tryParse(key) ?? 0] = value as int;
      });
    }

    return CondomRequestModel(
      id: json['id'].toString(),
      userId: json['user_id'] ?? '',
      condomQuantities: parsedQuantities,
      lubricantQuantity: json['lubricant_quantity'] ?? 0,
      selectedLocation: json['selected_location'],
      selectedDate: json['selected_date'],
      selectedTime: json['selected_time'],
      message: json['message'] ?? '',
      referenceNumber: json['reference_number'] ?? '',
      status: _parseStatus(json['status'] as String?),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  static RequestStatus _parseStatus(String? statusStr) {
    switch (statusStr?.toLowerCase()) {
      case 'pending':
      case 'submitted':
        return RequestStatus.submitted;
      case 'preparing':
      case 'approved':
        return RequestStatus.preparing;
      case 'completed':
      case 'delivered':
        return RequestStatus.completed;
      case 'cancelled':
      case 'rejected':
      default:
        return RequestStatus.cancelled;
    }
  }
}
