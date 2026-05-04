class DoctorAppointmentModel {
  final String id;
  final String referenceNumber;
  final String reason;
  final String selectedServiceCenter;
  final DateTime selectedDate;
  final String selectedTime;
  final String? note;
  final String appointmentStatus;
  final String? cancelReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DoctorAppointmentModel({
    required this.id,
    required this.referenceNumber,
    required this.reason,
    required this.selectedServiceCenter,
    required this.selectedDate,
    required this.selectedTime,
    this.note,
    required this.appointmentStatus,
    this.cancelReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DoctorAppointmentModel.fromMap(Map<String, dynamic> map) {
    return DoctorAppointmentModel(
      id: map['id'].toString(),
      referenceNumber: map['reference_number'] ?? '',
      reason: map['reason'] ?? '',
      selectedServiceCenter: map['selected_service_center'] ?? '',
      selectedDate: DateTime.parse(map['selected_date']),
      selectedTime: map['selected_time'] ?? '',
      note: map['note'] as String?,
      appointmentStatus: map['appointment_status'] ?? '',
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
        'hiv': 'ตรวจเลือด HIV',
        'consult': 'ปรึกษาทั่วไป',
      }[key] ??
      key;

  static const locationKeyToServiceCenter = {
    'phonphisai': 'รพ.โพนพิสัย',
    'wat': 'รพ.สต.วัดหลวง',
    'abt': 'อบต.วัดหลวง',
    'ssj': 'สสจ.หนองคาย',
  };
}
