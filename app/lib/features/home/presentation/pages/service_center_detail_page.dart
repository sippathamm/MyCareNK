import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/models/service_center_model.dart';

class ServiceCenterDetailPage extends StatefulWidget {
  final ServiceCenterModel center;

  const ServiceCenterDetailPage({super.key, required this.center});

  @override
  State<ServiceCenterDetailPage> createState() =>
      _ServiceCenterDetailPageState();
}

class _ServiceCenterDetailPageState extends State<ServiceCenterDetailPage> {
  static const double _expandedHeight = 220;
  final _scrollController = ScrollController();
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final threshold = _expandedHeight - kToolbarHeight;
    final scrolled = _scrollController.offset >= threshold;
    if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
  }

  @override
  Widget build(BuildContext context) {
    final center = widget.center;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: _expandedHeight,
            pinned: true,
            backgroundColor: AppColors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: _BackButton(scrolled: _scrolled),
            flexibleSpace: FlexibleSpaceBar(
              background: center.imageUrl != null
                  ? Image.network(
                      center.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildImagePlaceholder(),
                    )
                  : _buildImagePlaceholder(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    center.name,
                    style: GoogleFonts.googleSans(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (center.operatingHours != null) ...[
                    _buildSection(
                      icon: Icons.access_time_outlined,
                      title: 'เวลาทำการ',
                      content: center.operatingHours!,
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (center.description != null &&
                      center.description!.isNotEmpty) ...[
                    _buildSection(
                      icon: Icons.info_outline,
                      title: 'เกี่ยวกับ',
                      content: center.description!,
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (center.address != null && center.address!.isNotEmpty) ...[
                    _buildSection(
                      icon: Icons.location_on_outlined,
                      title: 'ที่อยู่',
                      content: center.address!,
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (center.contacts.isNotEmpty) ...[
                    _buildContactsSection(center.contacts),
                    const SizedBox(height: 20),
                  ],
                  if (center.latitude != null && center.longitude != null) ...[
                    _buildMapsButton(center.latitude!, center.longitude!),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.googleSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: GoogleFonts.googleSans(
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildContactsSection(List<Map<String, String>> contacts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.phone_outlined, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'ข้อมูลติดต่อ',
              style: GoogleFonts.googleSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...contacts.map(
          (contact) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _ContactRow(contact: contact),
          ),
        ),
      ],
    );
  }

  Widget _buildMapsButton(double lat, double lng) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () async {
          final url = Uri.parse('https://maps.google.com/?q=$lat,$lng');
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        },
        icon: const Icon(Icons.map_outlined),
        label: Text(
          'ดูบน Google Maps',
          style: GoogleFonts.googleSans(fontWeight: FontWeight.w500),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.primaryBackground,
      child: const Center(
        child:
            Icon(Icons.storefront_outlined, size: 64, color: AppColors.primary),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final bool scrolled;

  const _BackButton({required this.scrolled});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dark circle — fades out when scrolled
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: scrolled ? 0 : 1,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0x4D000000),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // White icon — fades out when scrolled
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: scrolled ? 0 : 1,
            child: const Icon(Icons.arrow_back,
                color: AppColors.white, size: 20),
          ),
          // Primary icon — fades in when scrolled
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: scrolled ? 1 : 0,
            child: const Icon(Icons.arrow_back,
                color: AppColors.primary, size: 20),
          ),
          // Full-size tap target
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(18),
              child: const SizedBox(width: 36, height: 36),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final Map<String, String> contact;

  const _ContactRow({required this.contact});

  @override
  Widget build(BuildContext context) {
    final label = contact['label'] ?? '';
    final value = contact['value'] ?? '';
    final isPhone = RegExp(r'^[\d\s\+\-\(\)]+$').hasMatch(value.trim()) &&
        value.trim().length >= 9;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Text(
            '$label: ',
            style: GoogleFonts.googleSans(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        Expanded(
          child: GestureDetector(
            onTap: isPhone
                ? () async {
                    final digits = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
                    final url = Uri(scheme: 'tel', path: digits);
                    if (await canLaunchUrl(url)) await launchUrl(url);
                  }
                : null,
            child: Text(
              value,
              style: GoogleFonts.googleSans(
                fontSize: 14,
                color: isPhone ? AppColors.primary : AppColors.textPrimary,
                decoration: isPhone ? TextDecoration.underline : null,
                decorationColor: isPhone ? AppColors.primary : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
