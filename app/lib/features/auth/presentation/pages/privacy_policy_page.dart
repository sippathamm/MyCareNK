import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../data/recovery_service.dart';
import 'registration_success_page.dart';

class PrivacyPolicyPage extends StatefulWidget {
  final String username;
  final String password;
  final String? gender;
  final DateTime? dateOfBirth;
  final String nationality;

  const PrivacyPolicyPage({
    super.key,
    required this.username,
    required this.password,
    required this.gender,
    required this.dateOfBirth,
    required this.nationality,
  });

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;
  bool _hasAgreed = false;
  bool _isLoading = false;

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
    if (_hasScrolledToBottom) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 32) {
      setState(() => _hasScrolledToBottom = true);
    }
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      final username = widget.username;
      final password = widget.password;
      const domain = '@mycarenk.local';
      final proxyEmail = '$username$domain';

      final response = await Supabase.instance.client.auth.signUp(
        email: proxyEmail,
        password: password,
      );

      await Supabase.instance.client.auth.signInWithPassword(
        email: proxyEmail,
        password: password,
      );

      final userId = response.user?.id;
      if (userId != null) {
        await Supabase.instance.client.from('user_profiles').upsert({
          'user_id': userId,
          'username': username,
          'gender': widget.gender,
          'nationality': widget.nationality,
          'date_of_birth':
              widget.dateOfBirth!.toIso8601String().split('T')[0],
        });
      }

      if (!mounted) return;

      final recoveryService = RecoveryService();
      final recoveryCodes = RecoveryService.generateRecoveryCodes();
      try {
        await recoveryService.saveRecoveryCodes(recoveryCodes);
      } catch (e) {
        debugPrint('เกิดข้อผิดพลาดในการบันทึกรหัสกู้คืน: $e');
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RegistrationSuccessPage(recoveryCodes: recoveryCodes),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      String msg = e.message;
      if (msg.toLowerCase().contains('breach') ||
          msg.toLowerCase().contains('found in a')) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'รหัสผ่านนี้เคยรั่วไหลในอินเทอร์เน็ต กรุณากลับไปตั้งรหัสผ่านใหม่',
            style: GoogleFonts.googleSans(),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.of(context).pop();
        return;
      }
      if (msg.toLowerCase().contains('already registered') ||
          msg.toLowerCase().contains('already exists')) {
        msg = 'ชื่อผู้ใช้งานนี้มีอยู่ในระบบแล้ว';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.googleSans()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('เกิดข้อผิดพลาดในการสร้างบัญชี',
            style: GoogleFonts.googleSans()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'นโยบายความเป็นส่วนตัว',
          style: GoogleFonts.googleSans(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: _buildContent(),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIntro(),
        const SizedBox(height: 28),
        _buildSection(
          number: '1',
          title: 'ข้อมูลที่เราเก็บรวบรวม',
          body:
              'เมื่อท่านสร้างบัญชีและใช้งาน MyCareNK เราจะเก็บรวบรวมเฉพาะข้อมูลที่จำเป็นต่อการให้บริการเท่านั้น ได้แก่ ชื่อผู้ใช้งาน เพศ วันเกิด และสัญชาติที่ท่านกรอกในขั้นตอนการสมัคร รวมถึงข้อมูลการใช้บริการ เช่น ประวัติคำขอรับอุปกรณ์ป้องกัน สถานที่รับบริการ วันเวลานัดหมาย และข้อความที่ท่านฝากไว้ นอกจากนี้ ท่านอาจให้หมายเลขโทรศัพท์ไว้โดยสมัครใจ เพื่อให้เจ้าหน้าที่สามารถติดต่อนัดรับอุปกรณ์ป้องกัน นัดพบแพทย์ หรือในกรณีที่มีเหตุจำเป็นเร่งด่วน\n\nทั้งนี้ เราไม่เก็บชื่อ-นามสกุลจริง หมายเลขบัตรประชาชน หรือข้อมูลที่สามารถระบุตัวตนของท่านได้โดยตรงแต่อย่างใด',
        ),
        const SizedBox(height: 24),
        _buildSection(
          number: '2',
          title: 'เราใช้ข้อมูลของคุณทำอะไรบ้าง',
          body:
              'ข้อมูลที่เก็บรวบรวมจะถูกนำไปใช้เพื่อดำเนินการตามคำขอของท่าน ประสานงานกับเจ้าหน้าที่สถานบริการที่ท่านเลือก และติดตามสิทธิ์การรับบริการรายเดือนของท่านให้เป็นไปตามเกณฑ์ที่กำหนด นอกจากนี้ เราอาจนำข้อมูลในภาพรวม ซึ่งไม่สามารถระบุตัวตนของผู้ใช้รายใดได้ ไปใช้ประกอบการวางแผนด้านสาธารณสุขในระดับจังหวัด\n\nเราขอยืนยันว่าจะไม่นำข้อมูลของท่านไปขาย แลกเปลี่ยน หรือเปิดเผยต่อบุคคลหรือองค์กรภายนอกเพื่อวัตถุประสงค์ทางการค้าหรือวัตถุประสงค์อื่นใดที่นอกเหนือจากที่ระบุไว้ในนโยบายฉบับนี้',
        ),
        const SizedBox(height: 24),
        _buildSection(
          number: '3',
          title: 'การเก็บรักษาความลับ',
          body:
              'เราจำกัดการเข้าถึงข้อมูลของท่านเฉพาะเจ้าหน้าที่ของสถานบริการที่ท่านเลือกและผู้ดูแลระบบที่ได้รับอนุญาตอย่างเป็นทางการเท่านั้น โดยเจ้าหน้าที่จะสามารถมองเห็นได้เพียงข้อมูลที่จำเป็นต่อการจัดเตรียมและส่งมอบบริการให้ท่าน ได้แก่ ชื่อผู้ใช้งาน รายการและจำนวนอุปกรณ์ที่ขอ วันเวลานัดหมาย และสถานะคำขอเท่านั้น\n\nข้อมูลของท่านจะถูกเก็บรักษาตลอดระยะเวลาที่บัญชียังคงเปิดใช้งาน และจะถูกดำเนินการตามที่ท่านร้องขอในกรณีที่ต้องการลบหรือโอนย้ายข้อมูล',
        ),
        const SizedBox(height: 24),
        _buildSection(
          number: '4',
          title: 'ความปลอดภัย',
          body:
              'เราใช้มาตรการรักษาความปลอดภัยในระดับมาตรฐานสากลเพื่อคุ้มครองข้อมูลของท่านจากการเข้าถึง การแก้ไข หรือการเปิดเผยโดยไม่ได้รับอนุญาต ข้อมูลทุกอย่างถูกส่งผ่านช่องทางที่เข้ารหัสอย่างปลอดภัย และรหัสผ่านของท่านจะไม่ถูกจัดเก็บในรูปแบบที่อ่านออกได้ในระบบของเราแต่อย่างใด นอกจากนี้ ระบบยังถูกออกแบบให้แต่ละบัญชีสามารถเข้าถึงได้เฉพาะข้อมูลของตนเองเท่านั้น',
        ),
        const SizedBox(height: 28),
        _buildContact(),
      ],
    );
  }

  Widget _buildIntro() {
    return Text(
      'สำนักงานสาธารณสุขจังหวัดหนองคาย ในฐานะผู้ให้บริการแอปพลิเคชัน MyCareNK ตระหนักถึงความสำคัญของความเป็นส่วนตัวและให้คำมั่นว่าจะปกป้องข้อมูลส่วนบุคคลของท่านด้วยความรับผิดชอบสูงสุด ภายใต้พระราชบัญญัติคุ้มครองข้อมูลส่วนบุคคล พ.ศ. 2562',
      style: GoogleFonts.googleSans(
        fontSize: 14,
        color: AppColors.textSecondary,
        height: 1.7,
      ),
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    required String body,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.primaryCardStart,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: GoogleFonts.googleSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.googleSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Text(
            body,
            style: GoogleFonts.googleSans(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.75,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContact() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryCardStart,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.contact_support_outlined,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'หากท่านมีข้อสงสัยหรือต้องการใช้สิทธิ์ตามกฎหมาย ไม่ว่าจะเป็นการขอเข้าถึง แก้ไข ลบ หรือโอนย้ายข้อมูลส่วนบุคคลของท่าน กรุณาติดต่อ นายสันติ ธรรมวิเศษ สำนักงานสาธารณสุขจังหวัดหนองคาย โทร. 084-686-6406',
              style: GoogleFonts.googleSans(
                fontSize: 13,
                color: AppColors.primary,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _hasScrolledToBottom
                ? () => setState(() => _hasAgreed = !_hasAgreed)
                : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _hasAgreed,
                    onChanged: _hasScrolledToBottom
                        ? (v) => setState(() => _hasAgreed = v ?? false)
                        : null,
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    side: BorderSide(
                      color: _hasScrolledToBottom
                          ? AppColors.primary
                          : const Color(0xFFCCCCCC),
                      width: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ฉันอ่านและเข้าใจนโยบายความเป็นส่วนตัวแล้ว',
                    style: GoogleFonts.googleSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _hasScrolledToBottom
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!_hasScrolledToBottom) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 34),
                const Icon(Icons.arrow_downward,
                    size: 13, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  'เลื่อนลงเพื่ออ่านนโยบายจนครบ',
                  style: GoogleFonts.googleSans(
                      fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          GradientButton(
            onPressed: (_hasAgreed && !_isLoading) ? _register : null,
            label: 'ตกลง',
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}
