class ConsultationModel {
  final String id;
  final String referenceNumber;
  final String reason;
  final String selectedServiceCenter;
  final DateTime selectedDate;
  final String selectedTime;
  final String? note;
  final String consultationStatus;
  final String? cancelReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ConsultationModel({
    required this.id,
    required this.referenceNumber,
    required this.reason,
    required this.selectedServiceCenter,
    required this.selectedDate,
    required this.selectedTime,
    this.note,
    required this.consultationStatus,
    this.cancelReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConsultationModel.fromMap(Map<String, dynamic> map) {
    return ConsultationModel(
      id: map['id'].toString(),
      referenceNumber: map['reference_number'] ?? '',
      reason: map['reason'] ?? '',
      selectedServiceCenter: map['selected_service_center'] ?? '',
      selectedDate: DateTime.parse(map['selected_date']),
      selectedTime: map['selected_time'] ?? '',
      note: map['note'] as String?,
      consultationStatus: map['consultation_status'] ?? '',
      cancelReason: map['cancel_reason'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : DateTime.now(),
    );
  }

  static String reasonLabel(String key) =>
      const {
        'pep': 'รับยา PEP (ฉุกเฉิน)',
        'prep': 'รับยา PrEP',
        'hiv': 'ตรวจเลือด',
        'consult': 'ปรึกษาทั่วไป',
      }[key] ??
      key;

}
