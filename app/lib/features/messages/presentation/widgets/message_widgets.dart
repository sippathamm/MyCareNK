import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../data/models/message_models.dart';

// ---------------------------------------------------------------------------
// Request group tile (collapsible)
// ---------------------------------------------------------------------------

class RequestGroupTile extends StatefulWidget {
  final RequestGroup group;
  final bool defaultOpen;
  final Future<void> Function(RequestGroup) onExpand;

  const RequestGroupTile({
    super.key,
    required this.group,
    required this.defaultOpen,
    required this.onExpand,
  });

  @override
  State<RequestGroupTile> createState() => _RequestGroupTileState();
}

class _RequestGroupTileState extends State<RequestGroupTile>
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
                                return MessageBubble(
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

class MessageBubble extends StatelessWidget {
  final MsgItem msg;
  final bool isLast;

  const MessageBubble({super.key, required this.msg, required this.isLast});

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
