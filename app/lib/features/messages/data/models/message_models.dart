import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Message types
// ---------------------------------------------------------------------------

enum MsgType {
  submitted, preparing, ready, completed, cancelled,
  consultationPending, consultationConfirmed, consultationCompleted, consultationCancelled,
}

MsgType parseMsgType(String? sourceType, String? eventType) {
  if (sourceType == 'consultation') {
    switch (eventType) {
      case 'confirmed':          return MsgType.consultationConfirmed;
      case 'completed':          return MsgType.consultationCompleted;
      case 'cancelled_by_user':
      case 'cancelled_by_staff': return MsgType.consultationCancelled;
      default:                   return MsgType.consultationPending;
    }
  }
  switch (eventType) {
    case 'preparing':          return MsgType.preparing;
    case 'ready':              return MsgType.ready;
    case 'completed':          return MsgType.completed;
    case 'cancelled_by_staff':
    case 'cancelled_by_user':  return MsgType.cancelled;
    default:                   return MsgType.submitted;
  }
}

class MsgItem {
  final String id;
  final MsgType type;
  final String text;
  final List<InlineSpan>? textSpans;
  final DateTime createdAt;
  bool isNew;

  MsgItem({
    required this.id,
    required this.type,
    required this.text,
    this.textSpans,
    required this.createdAt,
    required this.isNew,
  });
}

class RequestGroup {
  final String requestId;
  final String referenceNumber;
  final String serviceCenter;
  final List<MsgItem> messages; // newest first

  RequestGroup({
    required this.requestId,
    required this.referenceNumber,
    required this.serviceCenter,
    required this.messages,
  });

  int get unreadCount => messages.where((m) => m.isNew).length;
  MsgItem get latestMessage => messages.first;
  DateTime get latestDate => latestMessage.createdAt;
}

// ---------------------------------------------------------------------------
// Thai date helpers
// ---------------------------------------------------------------------------

String formatThaiDate(DateTime utc) {
  final dt = utc.add(const Duration(hours: 7));
  final l10n = AppLocalizations.current;
  return '${dt.day} ${l10n.monthsShort[dt.month - 1]} ${dt.year + 543}';
}

String formatTime(DateTime utc) {
  final dt = utc.add(const Duration(hours: 7));
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

// ---------------------------------------------------------------------------
// Type config — ตรงกับ request_history_page
// ---------------------------------------------------------------------------

class TypeConfig {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;

  const TypeConfig({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
  });
}

Map<MsgType, TypeConfig> buildTypeConfigs(AppLocalizations l10n) => {
  MsgType.submitted: TypeConfig(
    icon: Icons.assignment_outlined,
    iconColor: AppColors.primary,
    iconBg: AppColors.statusPendingLight,
    label: l10n.statusPending,
  ),
  MsgType.preparing: TypeConfig(
    icon: Icons.inventory_2_outlined,
    iconColor: AppColors.statusPreparing,
    iconBg: AppColors.statusPreparingLight,
    label: l10n.statusPreparing,
  ),
  MsgType.ready: TypeConfig(
    icon: Icons.local_shipping_outlined,
    iconColor: AppColors.statusReady,
    iconBg: AppColors.statusReadyLight,
    label: l10n.statusReady,
  ),
  MsgType.completed: TypeConfig(
    icon: Icons.check_circle_outline,
    iconColor: AppColors.statusCompleted,
    iconBg: AppColors.statusCompletedLight,
    label: l10n.statusSuccess,
  ),
  MsgType.cancelled: TypeConfig(
    icon: Icons.cancel_outlined,
    iconColor: Colors.grey,
    iconBg: const Color(0xFFEEEEEE),
    label: l10n.statusCancelled,
  ),
  MsgType.consultationPending: TypeConfig(
    icon: Icons.calendar_today_outlined,
    iconColor: AppColors.primary,
    iconBg: AppColors.statusPendingLight,
    label: l10n.statusPendingConsultation,
  ),
  MsgType.consultationConfirmed: TypeConfig(
    icon: Icons.event_available_outlined,
    iconColor: AppColors.statusReady,
    iconBg: AppColors.statusReadyLight,
    label: l10n.statusConfirmedConsultation,
  ),
  MsgType.consultationCompleted: TypeConfig(
    icon: Icons.check_circle_outline,
    iconColor: AppColors.statusCompleted,
    iconBg: AppColors.statusCompletedLight,
    label: l10n.statusCompleted,
  ),
  MsgType.consultationCancelled: TypeConfig(
    icon: Icons.cancel_outlined,
    iconColor: Colors.grey,
    iconBg: const Color(0xFFEEEEEE),
    label: l10n.statusCancelled,
  ),
};

// ---------------------------------------------------------------------------
// Build message text from event_type + metadata
// ---------------------------------------------------------------------------

List<InlineSpan> _buildBoldSpans(String full, List<String> boldParts) {
  final spans = <InlineSpan>[];
  String remaining = full;
  for (final part in boldParts) {
    final idx = remaining.indexOf(part);
    if (idx < 0) {
      spans.add(TextSpan(text: remaining));
      return spans;
    }
    if (idx > 0) spans.add(TextSpan(text: remaining.substring(0, idx)));
    spans.add(TextSpan(text: part, style: const TextStyle(fontWeight: FontWeight.bold)));
    remaining = remaining.substring(idx + part.length);
  }
  if (remaining.isNotEmpty) spans.add(TextSpan(text: remaining));
  return spans;
}

(String, List<InlineSpan>?) _buildConsultationMessage(
  String eventType,
  Map<String, dynamic> metadata,
  AppLocalizations l10n,
) {
  switch (eventType) {
    case 'confirmed':
      final dateRaw = metadata['selected_date'] as String? ?? '';
      final timeRaw = metadata['selected_time'] as String? ?? '';
      final serviceCenter = metadata['selected_service_center'] as String? ?? '';
      String datePart = '';
      if (dateRaw.isNotEmpty) {
        try {
          final d = DateTime.parse(dateRaw);
          datePart = '${d.day} ${l10n.monthsShort[d.month - 1]} ${d.year + 543}';
        } catch (_) {}
      }
      final timePart = timeRaw.length >= 5 ? timeRaw.substring(0, 5) : timeRaw;
      final dateTimeLabel = '$datePart ${l10n.timeLabel} $timePart ${l10n.timeWithUnit}';
      final full = l10n.msgConsultationConfirmed(serviceCenter, dateTimeLabel);
      return (full, _buildBoldSpans(full, [serviceCenter, dateTimeLabel]));
    case 'completed':
      return (l10n.msgConsultationCompleted, null);
    case 'cancelled_by_user':
      return (l10n.msgConsultationCancelledByUser, null);
    case 'cancelled_by_staff':
      final path = l10n.msgConsultationCancelledByStaffPath;
      final full = l10n.msgConsultationCancelledByStaff(path);
      return (full, _buildBoldSpans(full, [path]));
    default: // pending
      return (l10n.msgConsultationPending, null);
  }
}

(String, List<InlineSpan>?) buildMessage(
  String sourceType,
  String eventType,
  Map<String, dynamic> metadata,
  AppLocalizations l10n,
) {
  if (sourceType == 'consultation') {
    return _buildConsultationMessage(eventType, metadata, l10n);
  }
  switch (eventType) {
    case 'preparing':
      return (l10n.msgCondomPreparing, null);

    case 'ready':
      final dateRaw = metadata['selected_date'] as String? ?? '';
      final timeRaw = metadata['selected_time'] as String? ?? '';
      final serviceCenter = metadata['selected_service_center'] as String? ?? '';
      String datePart = '';
      if (dateRaw.isNotEmpty) {
        try {
          final d = DateTime.parse(dateRaw);
          datePart = '${d.day} ${l10n.monthsShort[d.month - 1]} ${d.year + 543}';
        } catch (_) {}
      }
      final timePart = timeRaw.length >= 5 ? timeRaw.substring(0, 5) : timeRaw;
      final dateTimeLabel = '$datePart ${l10n.timeLabel} $timePart ${l10n.timeWithUnit}';
      final full = l10n.msgCondomReady(serviceCenter, dateTimeLabel);
      return (full, _buildBoldSpans(full, [serviceCenter, dateTimeLabel]));

    case 'completed':
      return (l10n.msgCondomReceived, null);

    case 'cancelled_by_staff':
      final path = l10n.msgCondomCancelledByStaffPath;
      final full = l10n.msgCondomCancelledByStaff(path);
      return (full, _buildBoldSpans(full, [path]));

    case 'cancelled_by_user':
      return (l10n.msgCondomCancelledByUser, null);

    default: // pending
      return (l10n.msgCondomPending, null);
  }
}
