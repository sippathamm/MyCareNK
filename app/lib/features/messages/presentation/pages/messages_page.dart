import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/constants/app_colors.dart';

// ---------------------------------------------------------------------------
// Local data models
// ---------------------------------------------------------------------------

enum _MsgType { submitted, preparing, ready, completed, cancelled }

_MsgType _parseMsgType(String? type) {
  switch (type) {
    case 'preparing':        return _MsgType.preparing;
    case 'ready':            return _MsgType.ready;
    case 'completed':        return _MsgType.completed;
    case 'cancelled_by_staff':
    case 'cancelled_by_user': return _MsgType.cancelled;
    default:                 return _MsgType.submitted;
  }
}

class _MsgItem {
  final String id;
  final _MsgType type;
  final String text;
  final List<InlineSpan>? textSpans;
  final DateTime createdAt;
  bool isNew;

  _MsgItem({
    required this.id,
    required this.type,
    required this.text,
    this.textSpans,
    required this.createdAt,
    required this.isNew,
  });
}

class _RequestGroup {
  final String requestId;
  final String referenceNumber;
  final String serviceCenter;
  final List<_MsgItem> messages; // newest first

  _RequestGroup({
    required this.requestId,
    required this.referenceNumber,
    required this.serviceCenter,
    required this.messages,
  });

  int get unreadCount => messages.where((m) => m.isNew).length;
  _MsgItem get latestMessage => messages.first;
  DateTime get latestDate => latestMessage.createdAt;
}

// ---------------------------------------------------------------------------
// Thai date helpers
// ---------------------------------------------------------------------------

const _thaiMonths = [
  'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
  'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
];

String _formatThaiDate(DateTime utc) {
  final dt = utc.add(const Duration(hours: 7));
  return '${dt.day} ${_thaiMonths[dt.month - 1]} ${dt.year + 543}';
}

String _formatTime(DateTime utc) {
  final dt = utc.add(const Duration(hours: 7));
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

// ---------------------------------------------------------------------------
// Type config — ตรงกับ request_history_page
// ---------------------------------------------------------------------------

class _TypeConfig {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;

  const _TypeConfig({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
  });
}

final _typeConfigs = <_MsgType, _TypeConfig>{
  _MsgType.submitted: _TypeConfig(
    icon: Icons.assignment_outlined,
    iconColor: AppColors.primary,
    iconBg: AppColors.statusPendingLight,
    label: 'รอดำเนินการ',
  ),
  _MsgType.preparing: _TypeConfig(
    icon: Icons.inventory_2_outlined,
    iconColor: AppColors.statusPreparing,
    iconBg: AppColors.statusPreparingLight,
    label: 'กำลังเตรียม',
  ),
  _MsgType.ready: _TypeConfig(
    icon: Icons.local_shipping_outlined,
    iconColor: AppColors.statusReady,
    iconBg: AppColors.statusReadyLight,
    label: 'พร้อมรับ',
  ),
  _MsgType.completed: _TypeConfig(
    icon: Icons.check_circle_outline,
    iconColor: AppColors.statusCompleted,
    iconBg: AppColors.statusCompletedLight,
    label: 'สำเร็จ',
  ),
  _MsgType.cancelled: _TypeConfig(
    icon: Icons.cancel_outlined,
    iconColor: Colors.grey,
    iconBg: Color(0xFFEEEEEE),
    label: 'ยกเลิก',
  ),
};

// ---------------------------------------------------------------------------
// Build message text from event_type + metadata
// ---------------------------------------------------------------------------

(String, List<InlineSpan>?) _buildMessage(
  String eventType,
  Map<String, dynamic> metadata,
) {
  switch (eventType) {
    case 'preparing':
      return ('เจ้าหน้าที่กำลังเตรียมถุงยางอนามัยให้คุณ', null);

    case 'ready':
      final dateRaw = metadata['selected_date'] as String? ?? '';
      final timeRaw = metadata['selected_time'] as String? ?? '';
      String datePart = '';
      if (dateRaw.isNotEmpty) {
        try {
          final d = DateTime.parse(dateRaw);
          datePart = '${d.day} ${_thaiMonths[d.month - 1]} ${d.year + 543}';
        } catch (_) {}
      }
      final timePart = timeRaw.length >= 5 ? timeRaw.substring(0, 5) : timeRaw;
      final dateTimeLabel = '($datePart เวลา $timePart น.)';
      return (
        'ถุงยางอนามัยของคุณพร้อมรับแล้ว กรุณามารับภายในวันที่กำหนด $dateTimeLabel',
        <InlineSpan>[
          const TextSpan(
            text: 'ถุงยางอนามัยของคุณพร้อมรับแล้ว กรุณามารับภายในวันที่กำหนด ',
          ),
          TextSpan(
            text: dateTimeLabel,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      );

    case 'completed':
      return ('คุณได้รับถุงยางอนามัยเรียบร้อยแล้ว', null);

    case 'cancelled_by_staff':
      return (
        'คำขอนี้ถูกยกเลิกโดยเจ้าหน้าที่ คุณสามารถดูรายละเอียดได้ที่ ประวัติคำขอ › รายละเอียด › เหตุผล',
        <InlineSpan>[
          const TextSpan(
            text: 'คำขอนี้ถูกยกเลิกโดยเจ้าหน้าที่ คุณสามารถดูรายละเอียดได้ที่ ',
          ),
          const TextSpan(
            text: 'ประวัติคำขอ › รายละเอียด › เหตุผล',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      );

    case 'cancelled_by_user':
      return ('คุณได้ยกเลิกคำขอนี้เรียบร้อยแล้ว', null);

    default: // pending
      return ('ระบบได้รับคำขอของคุณเรียบร้อย รอเจ้าหน้าที่ดำเนินการ', null);
  }
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class MessagesPage extends StatefulWidget {
  final ValueNotifier<int>? unreadNotifier;

  const MessagesPage({super.key, this.unreadNotifier});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  List<_RequestGroup> _groups = [];
  bool _isLoading = true;
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _setupRealtime();
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }

  void _notifyUnread() {
    if (mounted) widget.unreadNotifier?.value = _totalUnread;
  }

  void _setupRealtime() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    _subscription = Supabase.instance.client
        .channel('user_notifs:${session.user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'user_notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: session.user.id,
          ),
          callback: (_) {
            if (mounted) _fetchData();
          },
        )
        .subscribe();
  }

  Future<void> _fetchData() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final userId = session.user.id;

    try {
      final [rawNotifs, rawReads] = await Future.wait([
        Supabase.instance.client
            .from('user_notifications')
            .select(
              'id, source_type, source_id, reference_number, event_type, metadata, created_at',
            )
            .eq('user_id', userId)
            .eq('source_type', 'condom_request')
            .order('created_at', ascending: false),
        Supabase.instance.client
            .from('user_notification_reads')
            .select('notification_id')
            .eq('user_id', userId),
      ]);

      final readIds = Set<String>.from(
        (rawReads as List).map((r) => r['notification_id'] as String),
      );

      final groupMap = <String, _RequestGroup>{};
      for (final n in rawNotifs as List) {
        final sourceId = n['source_id'] as String? ?? '';
        final refNum = n['reference_number'] as String? ?? sourceId;
        final eventType = n['event_type'] as String? ?? '';
        final metadata = (n['metadata'] as Map<String, dynamic>?) ?? {};
        final (text, textSpans) = _buildMessage(eventType, metadata);

        final item = _MsgItem(
          id: n['id'] as String,
          type: _parseMsgType(eventType),
          text: text,
          textSpans: textSpans,
          createdAt: DateTime.parse(n['created_at'] as String),
          isNew: !readIds.contains(n['id'] as String),
        );

        if (groupMap.containsKey(sourceId)) {
          groupMap[sourceId]!.messages.add(item);
        } else {
          groupMap[sourceId] = _RequestGroup(
            requestId: sourceId,
            referenceNumber: refNum,
            serviceCenter: '',
            messages: [item],
          );
        }
      }

      final groups = groupMap.values.toList()
        ..sort((a, b) => b.latestDate.compareTo(a.latestDate));

      if (mounted) {
        setState(() {
          _groups = groups;
          _isLoading = false;
        });
        _notifyUnread();
      }
    } catch (e) {
      debugPrint('MessagesPage fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;
    final userId = session.user.id;
    final unreadIds = _groups
        .expand((g) => g.messages)
        .where((m) => m.isNew)
        .map((m) => m.id)
        .toList();
    if (unreadIds.isEmpty) return;
    await Supabase.instance.client.from('user_notification_reads').upsert(
      unreadIds
          .map((id) => {'notification_id': id, 'user_id': userId})
          .toList(),
      onConflict: 'notification_id,user_id',
    );
    if (mounted) {
      setState(() {
        for (final g in _groups) {
          for (final m in g.messages) {
            m.isNew = false;
          }
        }
      });
      _notifyUnread();
    }
  }

  Future<void> _markGroupRead(_RequestGroup group) async {
    if (group.messages.every((m) => !m.isNew)) return;
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;
    final userId = session.user.id;
    final unreadIds =
        group.messages.where((m) => m.isNew).map((m) => m.id).toList();
    await Supabase.instance.client.from('user_notification_reads').upsert(
      unreadIds
          .map((id) => {'notification_id': id, 'user_id': userId})
          .toList(),
      onConflict: 'notification_id,user_id',
    );
    if (mounted) {
      setState(() {
        for (final m in group.messages) {
          m.isNew = false;
        }
      });
      _notifyUnread();
    }
  }

  int get _totalUnread =>
      _groups.fold(0, (sum, g) => sum + g.unreadCount);

  @override
  Widget build(BuildContext context) {
    final unread = _totalUnread;
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 24,
        title: Row(
          children: [
            const Text(
              'ข้อความ',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (unread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unread ใหม่',
                  style: GoogleFonts.googleSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unread > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton(
                onPressed: _markAllRead,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'อ่านทั้งหมด',
                  style: GoogleFonts.googleSans(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _groups.isEmpty
              ? _buildEmpty()
              : _buildList(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'ยังไม่มีข้อความ',
            style: GoogleFonts.googleSans(fontSize: 16, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        itemCount: _groups.length,
        itemBuilder: (context, i) => _RequestGroupTile(
          group: _groups[i],
          defaultOpen: i == 0,
          onExpand: _markGroupRead,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Request group tile (collapsible)
// ---------------------------------------------------------------------------

class _RequestGroupTile extends StatefulWidget {
  final _RequestGroup group;
  final bool defaultOpen;
  final Future<void> Function(_RequestGroup) onExpand;

  const _RequestGroupTile({
    required this.group,
    required this.defaultOpen,
    required this.onExpand,
  });

  @override
  State<_RequestGroupTile> createState() => _RequestGroupTileState();
}

class _RequestGroupTileState extends State<_RequestGroupTile>
    with SingleTickerProviderStateMixin {
  late bool _open;
  late AnimationController _ctrl;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _open = widget.defaultOpen;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: _open ? 1.0 : 0.0,
    );
    _rotateAnim = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (_open && widget.group.unreadCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onExpand(widget.group);
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      _ctrl.forward();
      if (widget.group.unreadCount > 0) widget.onExpand(widget.group);
    } else {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    final latestCfg =
        _typeConfigs[g.latestMessage.type] ?? _typeConfigs[_MsgType.submitted]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            InkWell(
              onTap: _toggle,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Status icon (latest message)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: latestCfg.iconBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(latestCfg.icon, color: latestCfg.iconColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    // Ref + location row
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                g.referenceNumber,
                                style: GoogleFonts.googleSans(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (g.unreadCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${g.unreadCount}',
                                    style: GoogleFonts.googleSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (g.serviceCenter.isNotEmpty) ...[
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 13,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  g.serviceCenter,
                                  style: GoogleFonts.googleSans(
                                    fontSize: 13,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: latestCfg.iconBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  latestCfg.label,
                                  style: GoogleFonts.googleSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: latestCfg.iconColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Date + chevron
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatThaiDate(g.latestDate),
                          style: GoogleFonts.googleSans(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 6),
                        RotationTransition(
                          turns: _rotateAnim,
                          child: Icon(
                            Icons.expand_more_rounded,
                            size: 20,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // ── Expanded messages ──
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _open
                  ? Column(
                      children: [
                        Divider(height: 1, color: Colors.grey.shade200),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          child: Column(
                            children: [
                              Text(
                                _formatThaiDate(g.latestDate),
                                style: GoogleFonts.googleSans(
                                  fontSize: 11,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 14),
                              ...List.generate(g.messages.length, (i) {
                                return _MessageBubble(
                                  msg: g.messages[i],
                                  isLast: i == g.messages.length - 1,
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Message bubble — IntrinsicHeight ทำให้เส้น timeline ต่อเนื่อง
// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  final _MsgItem msg;
  final bool isLast;

  const _MessageBubble({required this.msg, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final cfg = _typeConfigs[msg.type] ?? _typeConfigs[_MsgType.submitted]!;
    final bodyStyle = GoogleFonts.googleSans(
      fontSize: 14,
      color: AppColors.textPrimary,
      height: 1.5,
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Icon + เส้น timeline ──
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cfg.iconBg,
                  shape: BoxShape.circle,
                  border: msg.isNew
                      ? Border.all(color: cfg.iconColor, width: 1.5)
                      : null,
                ),
                child: Icon(cfg.icon, size: 18, color: cfg.iconColor),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: Colors.grey.shade200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          // ── Bubble ──
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: msg.isNew ? AppColors.white : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: msg.isNew
                        ? cfg.iconColor.withAlpha(40)
                        : Colors.grey.shade200,
                  ),
                  boxShadow: msg.isNew
                      ? const [
                          BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cfg.label,
                          style: GoogleFonts.googleSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: cfg.iconColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: EdgeInsets.only(right: msg.isNew ? 14 : 0),
                          child: msg.textSpans != null
                              ? RichText(
                                  text: TextSpan(
                                    style: bodyStyle,
                                    children: msg.textSpans,
                                  ),
                                )
                              : Text(msg.text, style: bodyStyle),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_formatTime(msg.createdAt)} น.',
                          style: GoogleFonts.googleSans(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    if (msg.isNew)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: cfg.iconColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
