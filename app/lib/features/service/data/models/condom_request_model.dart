
enum RequestStatus {
  pending,
  preparing,
  ready,
  completed,
  cancelledByUser,
  cancelledByStaff,
}

extension RequestStatusX on RequestStatus {
  bool get isCancelled =>
      this == RequestStatus.cancelledByUser ||
      this == RequestStatus.cancelledByStaff;
}

class CondomRequestModel {
  final String id;
  final String userId;
  final Map<int, int> condomQuantities;
  final int lubricantQuantity;
  final String? selectedServiceCenter;
  final String? selectedDate;
  final String? selectedTime;
  final String message;
  final String referenceNumber;
  final RequestStatus status;
  final String? cancelReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  CondomRequestModel({
    required this.id,
    required this.userId,
    required this.condomQuantities,
    required this.lubricantQuantity,
    this.selectedServiceCenter,
    this.selectedDate,
    this.selectedTime,
    required this.message,
    required this.referenceNumber,
    required this.status,
    this.cancelReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CondomRequestModel.fromJson(Map<String, dynamic> json) {
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
      selectedServiceCenter: json['selected_service_center'],
      selectedDate: json['selected_date'],
      selectedTime: json['selected_time'],
      message: json['message'] ?? '',
      referenceNumber: json['reference_number'] ?? '',
      status: _parseStatus(json['request_status'] as String?),
      cancelReason: json['cancel_reason'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now()),
    );
  }

  static RequestStatus _parseStatus(String? statusStr) {
    switch (statusStr) {
      case 'pending':
        return RequestStatus.pending;
      case 'preparing':
        return RequestStatus.preparing;
      case 'ready':
        return RequestStatus.ready;
      case 'completed':
        return RequestStatus.completed;
      case 'cancelled_by_user':
        return RequestStatus.cancelledByUser;
      case 'cancelled_by_staff':
        return RequestStatus.cancelledByStaff;
      default:
        return RequestStatus.pending;
    }
  }
}
