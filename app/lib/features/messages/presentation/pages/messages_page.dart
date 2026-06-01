import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../data/models/message_models.dart';

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class MessagesPage extends StatefulWidget {
  final ValueNotifier<int>? unreadNotifier;
  final int refreshKey;

  const MessagesPage({super.key, this.unreadNotifier, this.refreshKey = 0});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  List<RequestGroup> _groups = [];
  bool _isLoading = true;
  bool _isLoggedIn = true;
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _setupRealtime();
  }

  @override
  void didUpdateWidget(MessagesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey) {
      _setupRealtime();
      _fetchData();
    }
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
    _subscription?.unsubscribe();
    _subscription = null;
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
      if (mounted) {
        setState(() { _groups = []; _isLoggedIn = false; _isLoading = false; });
        _notifyUnread();
      }
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
            .order('created_at', ascending: false),
        Supabase.instance.client
            .from('user_notification_reads')
            .select('notification_id')
            .eq('user_id', userId),
      ]);

      final readIds = Set<String>.from(
        (rawReads as List).map((r) => r['notification_id'] as String),
      );

      final groupMap = <String, RequestGroup>{};
      for (final n in rawNotifs as List) {
        final sourceId = n['source_id'] as String? ?? '';
        final sourceType = n['source_type'] as String? ?? '';
        final refNum = n['reference_number'] as String? ?? sourceId;
        final eventType = n['event_type'] as String? ?? '';
        final metadata = (n['metadata'] as Map<String, dynamic>?) ?? {};
        final (text, textSpans) = buildMessage(sourceType, eventType, metadata, AppLocalizations.current);

        final item = MsgItem(
          id: n['id'] as String,
          type: parseMsgType(sourceType, eventType),
          text: text,
          textSpans: textSpans,
          createdAt: DateTime.parse(n['created_at'] as String),
          isNew: !readIds.contains(n['id'] as String),
        );

        if (groupMap.containsKey(sourceId)) {
          groupMap[sourceId]!.messages.add(item);
        } else {
          groupMap[sourceId] = RequestGroup(
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
          _isLoggedIn = true;
          _isLoading = false;
        });
        _notifyUnread();
      }
    } catch (_) {
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

  Future<void> _markGroupRead(RequestGroup group) async {
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
            Text(
              AppLocalizations.of(context).messagesTitle,
              style: const TextStyle(
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
                  AppLocalizations.of(context).unreadCount(unread),
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
                  AppLocalizations.of(context).readAll,
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
          ? _buildSkeleton()
          : !_isLoggedIn
              ? _buildNotLoggedIn()
              : _groups.isEmpty
                  ? _buildEmpty()
                  : _buildList(),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      itemCount: 4,
      itemBuilder: (_, _) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 16, width: 140, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 6),
                  Container(height: 12, width: 100, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
            Container(height: 24, width: 60, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12))),
          ],
        ),
      ),
    );
  }

  Widget _buildNotLoggedIn() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).pleaseLogin,
            style: GoogleFonts.googleSans(fontSize: 16, color: Colors.grey[400]),
          ),
        ],
      ),
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
            AppLocalizations.of(context).noMessages,
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
          defaultOpen: false,
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
  final RequestGroup group;
  final bool defaultOpen;
  final Future<void> Function(RequestGroup) onExpand;

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
    final l10n = AppLocalizations.of(context);
    final g = widget.group;
    final typeConfigs = buildTypeConfigs(l10n);
    final latestCfg =
        typeConfigs[g.latestMessage.type] ?? typeConfigs[MsgType.submitted]!;

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
                          formatThaiDate(g.latestDate),
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
                                formatThaiDate(g.latestDate),
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
  final MsgItem msg;
  final bool isLast;

  const _MessageBubble({required this.msg, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final typeConfigs = buildTypeConfigs(AppLocalizations.of(context));
    final cfg = typeConfigs[msg.type] ?? typeConfigs[MsgType.submitted]!;
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
                          '${formatTime(msg.createdAt)} ${AppLocalizations.of(context).timeWithUnit}',
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
