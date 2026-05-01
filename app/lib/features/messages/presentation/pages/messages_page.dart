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
    case 'preparing':
      return _MsgType.preparing;
    case 'ready':
      return _MsgType.ready;
    case 'completed':
      return _MsgType.completed;
    case 'cancelled_by_staff':
    case 'cancelled_by_user':
      return _MsgType.cancelled;
    default:
      return _MsgType.submitted;
  }
}

class _MsgItem {
  final String id;
  final _MsgType type;
  final String text;
  final DateTime createdAt;
  bool isNew;

  _MsgItem({
    required this.id,
    required this.type,
    required this.text,
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
// Type config
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

const _typeConfigs = <_MsgType, _TypeConfig>{
  _MsgType.submitted: _TypeConfig(
    icon: Icons.send_rounded,
    iconColor: AppColors.lubricant,
    iconBg: AppColors.lubricantCardStart,
    label: 'ส่งคำขอแล้ว',
  ),
  _MsgType.preparing: _TypeConfig(
    icon: Icons.inventory_2_rounded,
    iconColor: AppColors.primary,
    iconBg: AppColors.primaryCardStart,
    label: 'กำลังเตรียม',
  ),
  _MsgType.ready: _TypeConfig(
    icon: Icons.check_circle_rounded,
    iconColor: AppColors.success,
    iconBg: Color(0xFFE8F5E9),
    label: 'พร้อมรับแล้ว',
  ),
  _MsgType.completed: _TypeConfig(
    icon: Icons.done_all_rounded,
    iconColor: AppColors.success,
    iconBg: Color(0xFFE8F5E9),
    label: 'รับแล้ว',
  ),
  _MsgType.cancelled: _TypeConfig(
    icon: Icons.cancel_rounded,
    iconColor: AppColors.error,
    iconBg: Color(0xFFFFEBEE),
    label: 'ถูกยกเลิก',
  ),
};

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

// Set to true to bypass Supabase and show all mock cases
const bool _kUseMock = true;

List<_RequestGroup> _buildMockGroups() {
  final now = DateTime.now().toUtc();
  DateTime d(int daysAgo, int hour, int minute) =>
      now.subtract(Duration(days: daysAgo)).copyWith(hour: hour, minute: minute, second: 0);

  return [
    // 1. กำลังดำเนินการ — มีข้อความใหม่ 2 รายการ (preparing + ready)
    _RequestGroup(
      requestId: 'mock-1',
      referenceNumber: 'NK-2568-00145',
      serviceCenter: 'รพ.โพนพิสัย',
      messages: [
        _MsgItem(
          id: 'm1-3',
          type: _MsgType.ready,
          text: 'ถุงยางอนามัยของคุณพร้อมรับแล้ว กรุณามารับตามวันและเวลาที่นัด',
          createdAt: d(0, 10, 23),
          isNew: true,
        ),
        _MsgItem(
          id: 'm1-2',
          type: _MsgType.preparing,
          text: 'เจ้าหน้าที่กำลังเตรียมถุงยางอนามัยให้คุณ กรุณารอสักครู่',
          createdAt: d(0, 9, 14),
          isNew: true,
        ),
        _MsgItem(
          id: 'm1-1',
          type: _MsgType.submitted,
          text: 'ส่งคำขอแล้ว ระบบได้รับคำขอของคุณเรียบร้อย',
          createdAt: d(0, 8, 50),
          isNew: false,
        ),
      ],
    ),
    // 2. รับของแล้ว — flow สมบูรณ์ทุกขั้นตอน
    _RequestGroup(
      requestId: 'mock-2',
      referenceNumber: 'NK-2568-00141',
      serviceCenter: 'รพ.สต.วัดหลวง',
      messages: [
        _MsgItem(
          id: 'm2-4',
          type: _MsgType.completed,
          text: 'คุณได้รับถุงยางอนามัยเรียบร้อยแล้ว ขอบคุณที่ใช้บริการ MyCareNK',
          createdAt: d(7, 14, 35),
          isNew: false,
        ),
        _MsgItem(
          id: 'm2-3',
          type: _MsgType.ready,
          text: 'ถุงยางอนามัยของคุณพร้อมรับแล้ว กรุณามารับภายในวันที่กำหนด',
          createdAt: d(8, 13, 5),
          isNew: false,
        ),
        _MsgItem(
          id: 'm2-2',
          type: _MsgType.preparing,
          text: 'เจ้าหน้าที่กำลังเตรียมถุงยางอนามัยให้คุณ กรุณารอสักครู่',
          createdAt: d(8, 10, 20),
          isNew: false,
        ),
        _MsgItem(
          id: 'm2-1',
          type: _MsgType.submitted,
          text: 'ส่งคำขอแล้ว ระบบได้รับคำขอของคุณเรียบร้อย',
          createdAt: d(8, 9, 30),
          isNew: false,
        ),
      ],
    ),
    // 3. ยกเลิกโดยเจ้าหน้าที่
    _RequestGroup(
      requestId: 'mock-3',
      referenceNumber: 'NK-2568-00138',
      serviceCenter: 'อบต.วัดหลวง',
      messages: [
        _MsgItem(
          id: 'm3-3',
          type: _MsgType.cancelled,
          text: 'คำขอถูกยกเลิกโดยเจ้าหน้าที่ หากมีข้อสงสัยกรุณาติดต่อเจ้าหน้าที่โดยตรง',
          createdAt: d(14, 11, 45),
          isNew: false,
        ),
        _MsgItem(
          id: 'm3-2',
          type: _MsgType.preparing,
          text: 'เจ้าหน้าที่กำลังเตรียมถุงยางอนามัยให้คุณ กรุณารอสักครู่',
          createdAt: d(14, 9, 0),
          isNew: false,
        ),
        _MsgItem(
          id: 'm3-1',
          type: _MsgType.submitted,
          text: 'ส่งคำขอแล้ว ระบบได้รับคำขอของคุณเรียบร้อย',
          createdAt: d(14, 8, 30),
          isNew: false,
        ),
      ],
    ),
    // 4. ยกเลิกโดยผู้ใช้
    _RequestGroup(
      requestId: 'mock-4',
      referenceNumber: 'NK-2568-00130',
      serviceCenter: 'สสจ.หนองคาย',
      messages: [
        _MsgItem(
          id: 'm4-2',
          type: _MsgType.cancelled,
          text: 'คุณได้ยกเลิกคำขอนี้เรียบร้อยแล้ว สามารถส่งคำขอใหม่ได้เมื่อต้องการ',
          createdAt: d(21, 15, 10),
          isNew: false,
        ),
        _MsgItem(
          id: 'm4-1',
          type: _MsgType.submitted,
          text: 'ส่งคำขอแล้ว ระบบได้รับคำขอของคุณเรียบร้อย',
          createdAt: d(21, 14, 55),
          isNew: false,
        ),
      ],
    ),
    // 5. เพิ่งส่งคำขอ — ยังไม่มีการดำเนินการ (1 ข้อความใหม่)
    _RequestGroup(
      requestId: 'mock-5',
      referenceNumber: 'NK-2568-00125',
      serviceCenter: 'รพ.โพนพิสัย',
      messages: [
        _MsgItem(
          id: 'm5-1',
          type: _MsgType.submitted,
          text: 'ส่งคำขอแล้ว ระบบได้รับคำขอของคุณเรียบร้อย กรุณารอเจ้าหน้าที่ดำเนินการ',
          createdAt: d(30, 16, 5),
          isNew: true,
        ),
      ],
    ),
  ];
}

class _MessagesPageState extends State<MessagesPage> {
  List<_RequestGroup> _groups = [];
  bool _isLoading = true;
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    if (_kUseMock) {
      _groups = _buildMockGroups();
      _isLoading = false;
    } else {
      _fetchData();
      _setupRealtime();
    }
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }

  void _setupRealtime() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    _subscription = Supabase.instance.client
        .channel('messages:notifications:${session.user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
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
            .from('notifications')
            .select(
              'id, type, message, created_at, request_id, '
              'condom_requests!request_id(reference_number, selected_service_center)',
            )
            .eq('user_id', userId)
            .order('created_at', ascending: false),
        Supabase.instance.client
            .from('notification_reads')
            .select('notification_id')
            .eq('user_id', userId),
      ]);

      final readIds = Set<String>.from(
        (rawReads as List).map((r) => r['notification_id'] as String),
      );

      // Group by request_id
      final groupMap = <String, _RequestGroup>{};
      for (final n in rawNotifs as List) {
        final reqId = n['request_id'] as String? ?? '';
        final req = n['condom_requests'] as Map<String, dynamic>? ?? {};
        final refNum = req['reference_number'] as String? ?? reqId;
        final center =
            req['selected_service_center'] as String? ?? '';

        final item = _MsgItem(
          id: n['id'] as String,
          type: _parseMsgType(n['type'] as String?),
          text: n['message'] as String? ?? '',
          createdAt: DateTime.parse(n['created_at'] as String),
          isNew: !readIds.contains(n['id'] as String),
        );

        if (groupMap.containsKey(reqId)) {
          groupMap[reqId]!.messages.add(item);
        } else {
          groupMap[reqId] = _RequestGroup(
            requestId: reqId,
            referenceNumber: refNum,
            serviceCenter: center,
            messages: [item],
          );
        }
      }

      // Sort groups by latest notification date
      final groups = groupMap.values.toList()
        ..sort((a, b) => b.latestDate.compareTo(a.latestDate));

      if (mounted) {
        setState(() {
          _groups = groups;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('MessagesPage fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    if (!_kUseMock) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return;
      final userId = session.user.id;
      final unreadIds = _groups
          .expand((g) => g.messages)
          .where((m) => m.isNew)
          .map((m) => m.id)
          .toList();
      if (unreadIds.isEmpty) return;
      await Supabase.instance.client.from('notification_reads').upsert(
        unreadIds
            .map((id) => {'notification_id': id, 'user_id': userId})
            .toList(),
        onConflict: 'notification_id,user_id',
      );
    }
    if (mounted) {
      setState(() {
        for (final g in _groups) {
          for (final m in g.messages) {
            m.isNew = false;
          }
        }
      });
    }
  }

  Future<void> _markGroupRead(_RequestGroup group) async {
    if (group.messages.every((m) => !m.isNew)) return;
    if (!_kUseMock) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return;
      final userId = session.user.id;
      final unreadIds =
          group.messages.where((m) => m.isNew).map((m) => m.id).toList();
      await Supabase.instance.client.from('notification_reads').upsert(
        unreadIds
            .map((id) => {'notification_id': id, 'user_id': userId})
            .toList(),
        onConflict: 'notification_id,user_id',
      );
    }
    if (mounted) {
      setState(() {
        for (final m in group.messages) {
          m.isNew = false;
        }
      });
    }
  }

  int get _totalUnread =>
      _groups.fold(0, (sum, g) => sum + g.unreadCount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _groups.isEmpty
              ? _buildEmpty()
              : _buildList(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final unread = _totalUnread;
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Container(
        color: AppColors.white,
        child: SafeArea(
          bottom: false,
          child: Container(
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE0E0E0)),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'ข้อความ',
                  style: GoogleFonts.prompt(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (unread > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unread ใหม่',
                      style: GoogleFonts.prompt(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (unread > 0)
                  TextButton(
                    onPressed: _markAllRead,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'อ่านทั้งหมด',
                      style: GoogleFonts.prompt(
                        fontSize: 13,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 48, color: Color(0xFFDDDDDD)),
          const SizedBox(height: 12),
          Text(
            'ยังไม่มีข้อความ',
            style: GoogleFonts.prompt(fontSize: 14, color: AppColors.textHint),
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
    final latestCfg = _typeConfigs[g.latestMessage.type] ?? _typeConfigs[_MsgType.submitted]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          InkWell(
            onTap: _toggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: _open
                    ? const Border(
                        bottom: BorderSide(color: Color(0xFFE0E0E0)),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  // Tag icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryCardStart,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.tag_rounded,
                      size: 22,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title + preview
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              g.referenceNumber,
                              style: GoogleFonts.prompt(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (g.unreadCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${g.unreadCount}',
                                  style: GoogleFonts.prompt(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        RichText(
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${g.serviceCenter}  ·  ',
                                style: GoogleFonts.prompt(
                                  fontSize: 12,
                                  color: AppColors.textHint,
                                ),
                              ),
                              TextSpan(
                                text: latestCfg.label,
                                style: GoogleFonts.prompt(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: latestCfg.iconColor,
                                ),
                              ),
                            ],
                          ),
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
                        style: GoogleFonts.prompt(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RotationTransition(
                        turns: _rotateAnim,
                        child: const Icon(
                          Icons.expand_more_rounded,
                          size: 18,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Expanded messages
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _formatThaiDate(g.latestDate),
                          style: GoogleFonts.prompt(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(g.messages.length, (i) {
                          return _MessageBubble(
                            msg: g.messages[i],
                            isLast: i == g.messages.length - 1,
                          );
                        }),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Message bubble with timeline connector
// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  final _MsgItem msg;
  final bool isLast;

  const _MessageBubble({required this.msg, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final cfg = _typeConfigs[msg.type] ?? _typeConfigs[_MsgType.submitted]!;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + timeline line
          SizedBox(
            width: 36,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                if (!isLast)
                  Positioned(
                    top: 36,
                    bottom: -14,
                    left: 17,
                    child: const SizedBox(
                      width: 2,
                      child: ColoredBox(color: Color(0xFFF0F0F0)),
                    ),
                  ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cfg.iconBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: msg.isNew ? cfg.iconColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Icon(cfg.icon, size: 18, color: cfg.iconColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Bubble
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: msg.isNew ? AppColors.white : const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: msg.isNew
                      ? cfg.iconColor.withAlpha(34)
                      : const Color(0xFFE0E0E0),
                  width: msg.isNew ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: msg.isNew
                        ? const Color(0x14000000)
                        : const Color(0x0A000000),
                    blurRadius: msg.isNew ? 10 : 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cfg.label,
                        style: GoogleFonts.prompt(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: cfg.iconColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: EdgeInsets.only(right: msg.isNew ? 14 : 0),
                        child: Text(
                          msg.text,
                          style: GoogleFonts.prompt(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_formatTime(msg.createdAt)} น.',
                        style: GoogleFonts.prompt(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  if (msg.isNew)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 8,
                        height: 8,
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
        ],
      ),
    );
  }
}
