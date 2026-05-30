import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../widgets/guide_widgets.dart';

class GuidePage extends StatefulWidget {
  const GuidePage({super.key});

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  final List<GlobalKey> _sectionKeys = List.generate(10, (_) => GlobalKey());
  final ScrollController _scrollController = ScrollController();
  bool _showGoToTop = false;

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
    final show = _scrollController.offset > 300;
    if (show != _showGoToTop) {
      setState(() => _showGoToTop = show);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToSection(int index) {
    final ctx = _sectionKeys[index].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
          l10n.guide,
          style: GoogleFonts.googleSans(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: _showGoToTop
          ? FloatingActionButton.small(
              onPressed: _scrollToTop,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              child: const Icon(Icons.keyboard_arrow_up),
            )
          : null,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTOC(),
                    ..._buildSections().expand(
                      (s) => [const SizedBox(height: 20), s],
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildTOC() {
    final tocTitles = [
      'เริ่มต้นใช้งาน',
      'หน้าหลักและการนำทาง',
      'การรับถุงยางอนามัยและเจลหล่อลื่น',
      'การสแกน QR Code เพื่อรับถุงยางอนามัย',
      'แบบประเมินความเสี่ยงการติดเชื้อ HIV',
      'การนัดพบแพทย์',
      'บทความ',
      'สถานบริการ',
      'แจ้งเตือน',
      'ตั้งค่า',
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadowMedium,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'สารบัญ',
            style: GoogleFonts.googleSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...tocTitles.asMap().entries.map((entry) {
            final i = entry.key;
            final title = entry.value;
            return InkWell(
              onTap: () => _scrollToSection(i),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i + 1}.',
                      style: GoogleFonts.googleSans(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.googleSans(
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  List<Widget> _buildSections() {
    return [
      _buildSection1(),
      _buildSection2(),
      _buildSection3(),
      _buildSection4(),
      _buildSection5(),
      _buildSection6(),
      _buildSection7(),
      _buildSection8(),
      _buildSection9(),
      _buildSection10(),
    ];
  }

  Widget _h(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: GoogleFonts.googleSans(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
      );

  Widget _p(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: GoogleFonts.googleSans(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
      );

  Widget _div() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Divider(height: 1, color: Color(0xFFF0F0F0)),
      );

  Widget _statusFlow(List<(GuideStatusType, String)> statuses) {
    final items = <Widget>[];
    for (var i = 0; i < statuses.length; i++) {
      final (status, label) = statuses[i];
      items.add(GuideStatusBadge(status: status, label: label));
      if (i < statuses.length - 1) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '→',
              style: GoogleFonts.googleSans(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        );
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 4,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: items,
      ),
    );
  }

  Widget _buildStatusRows(List<(GuideStatusType, String, String)> rows) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final i = entry.key;
          final (status, label, description) = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: i < rows.length - 1 ? 10 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GuideStatusBadge(status: status, label: label),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      description,
                      style: GoogleFonts.googleSans(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSection1() {
    return GuideSection(
      key: _sectionKeys[0],
      number: 1,
      title: 'เริ่มต้นใช้งาน',
      children: [
        _h('1.1 การสร้างบัญชีใหม่'),
        _p('การสร้างบัญชีใหม่แบ่งออกเป็น 5 ขั้นตอน ทำตามลำดับจนครบ'),
        const GuideStepList(steps: [
          'ชื่อผู้ใช้งานและรหัสผ่าน — กรอกชื่อผู้ใช้ที่ต้องการ (ภาษาอังกฤษหรือตัวเลข) และตั้งรหัสผ่านอย่างน้อย 8 ตัวอักษร จากนั้นยืนยันรหัสผ่านอีกครั้ง',
          'ข้อมูลส่วนตัว — เลือกเพศ วันเดือนปีเกิด สัญชาติ และประเภทสิทธิ์การรักษา',
          'ข้อมูลติดต่อ (ไม่บังคับ) — กรอกเบอร์โทรศัพท์และชื่อเล่นที่ต้องการให้เจ้าหน้าที่เรียก หรือกด "ข้าม" เพื่อเว้นไว้ก่อน',
          'นโยบายความเป็นส่วนตัว — อ่านจนจบแล้วทำเครื่องหมายยืนยัน จากนั้นกด "สร้างบัญชี"',
          'รหัสกู้คืนบัญชี — หน้าสุดท้ายจะแสดงรหัสกู้คืนบัญชี 6 รหัส บันทึกหรือถ่ายภาพเก็บไว้ทันที ใช้สำหรับตั้งรหัสผ่านใหม่หากลืมรหัสผ่าน',
        ]),
        const SizedBox(height: 4),
        const GuideInfoBox(
          type: GuideInfoBoxType.important,
          text: 'รหัสกู้คืนบัญชีจะแสดงเพียงครั้งเดียวตอนสร้างบัญชีใหม่ หากหายแล้วต้องสร้างชุดใหม่ในเมนูตั้งค่า',
        ),
        _div(),
        _h('1.2 การเข้าสู่ระบบ'),
        _p('กรอกชื่อผู้ใช้และรหัสผ่านที่ตั้งไว้ตอนสร้างบัญชี แล้วกด "เข้าสู่ระบบ"'),
        const GuideInfoBox(
          type: GuideInfoBoxType.tip,
          text: 'กดไอคอนตาเพื่อสลับแสดง/ซ่อนรหัสผ่านขณะพิมพ์',
        ),
        _div(),
        _h('1.3 ลืมรหัสผ่าน'),
        _p('กดลิงก์ "ลืมรหัสผ่าน?" ในหน้าเข้าสู่ระบบ แล้วกรอกชื่อผู้ใช้ของคุณ จากนั้นระบุรหัสกู้คืนบัญชี 1 ใน 6 รหัสที่บันทึกไว้ตอนสร้างบัญชี ระบบจะให้ตั้งรหัสผ่านใหม่ได้ทันที'),
        const GuideInfoBox(
          type: GuideInfoBoxType.important,
          text: 'รหัสกู้คืนบัญชีแต่ละรหัสใช้ได้ครั้งเดียวเท่านั้น เมื่อใช้แล้วจะหมดอายุทันที',
        ),
      ],
    );
  }

  Widget _buildSection2() {
    return GuideSection(
      key: _sectionKeys[1],
      number: 2,
      title: 'หน้าหลักและการนำทาง',
      children: [
        _h('2.1 เมนูด้านล่าง'),
        _p('แถบเมนูด้านล่างมี 5 แท็บ กดเพื่อสลับระหว่างส่วนต่าง ๆ ของแอป'),
        _buildTabsVisual(),
        const SizedBox(height: 12),
        const GuideTable(
          headers: ['แท็บ', 'ใช้ทำอะไร'],
          rows: [
            ['หน้าหลัก', 'ดูโควตารายเดือน ข่าวสารและประกาศ และเมนูลัด'],
            ['บริการ', 'รับถุงยางอนามัย ประเมินความเสี่ยงการติดเชื้อ HIV นัดพบแพทย์'],
            ['สแกน', 'สแกน QR Code เพื่อยืนยันการรับถุงยางอนามัยที่สถานบริการ'],
            ['แจ้งเตือน', 'ดูการแจ้งเตือนและอัปเดตสถานะคำขอ'],
            ['ตั้งค่า', 'แก้ไขข้อมูลส่วนตัว เปลี่ยนรหัสผ่าน และอื่น ๆ'],
          ],
        ),
        _div(),
        _h('2.2 เมนูลัดบนหน้าหลัก'),
        _p('ด้านล่างโควตารายเดือนมีปุ่มลัด 3 ปุ่ม'),
        const GuideTable(
          headers: ['ปุ่ม', 'พาไปที่'],
          rows: [
            ['สถานบริการ', 'รายชื่อและรายละเอียดสถานบริการทั้งหมด'],
            ['คู่มือการใช้', 'คู่มือฉบับนี้'],
            ['ประวัติคำขอ', 'รายการการรับถุงยางอนามัยที่ผ่านมา'],
          ],
        ),
        _div(),
        _h('2.3 การ์ดโควตารายเดือน'),
        _p('การ์ดบนหน้าหลักแสดงจำนวนที่ใช้ไปแล้วเทียบกับสิทธิ์ทั้งหมดในเดือนนี้'),
        const GuideTable(
          headers: ['รายการ', 'สิทธิ์ต่อเดือน'],
          rows: [
            ['ถุงยางอนามัย', 'สูงสุด 60 ชิ้น'],
            ['เจลหล่อลื่น', 'สูงสุด 30 ชิ้น'],
          ],
        ),
        const GuideInfoBox(
          type: GuideInfoBoxType.note,
          text: 'โควตาจะเริ่มนับใหม่ทุกต้นเดือน',
        ),
      ],
    );
  }

  Widget _buildTabsVisual() {
    final tabs = [
      (Icons.home_outlined, 'หน้าหลัก', true),
      (Icons.medical_services_outlined, 'บริการ', false),
      (Icons.qr_code_scanner, 'สแกน', false),
      (Icons.notifications_outlined, 'แจ้งเตือน', false),
      (Icons.settings_outlined, 'ตั้งค่า', false),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tabs.map((tab) {
        final (icon, label, isActive) = tab;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: isActive ? null : AppColors.primaryBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: isActive ? AppColors.white : AppColors.primaryDark,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.googleSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppColors.white : AppColors.primaryDark,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSection3() {
    return GuideSection(
      key: _sectionKeys[2],
      number: 3,
      title: 'การรับถุงยางอนามัยและเจลหล่อลื่น',
      children: [
        _h('3.1 วิธีส่งคำขอ'),
        _p('ไปที่แท็บ "บริการ" แล้วกด "รับถุงยางอนามัย"'),
        const GuideStepList(steps: [
          'ถุงยางอนามัย — มีให้เลือก 4 ขนาด (49 / 52 / 54 / 56 มม.) กดปุ่ม + / − เพื่อเพิ่มหรือลดจำนวนในแต่ละขนาด',
          'เพิ่มเติม (ไม่บังคับ) — กดปุ่ม + / − เพื่อเพิ่มหรือลดจำนวนเจลหล่อลื่นที่ต้องการ',
          'สถานบริการ — เลือกสถานบริการที่ต้องการไปรับ',
          'วันที่รับ — เลือกวันที่ต้องการ (ระบบจะแสดง 7 วันทำการข้างหน้า ไม่รวมเสาร์–อาทิตย์)',
          'เวลารับ — เลือกช่วงเวลาที่สถานบริการกำหนด',
          'ฝากข้อความ (ไม่ระบุได้) — พิมพ์ข้อความเพิ่มเติมถึงเจ้าหน้าที่ หากมี',
          'กด "ถัดไป" เพื่อดูหน้ายืนยัน ตรวจสอบให้ถูกต้องแล้วกด "ยืนยัน"',
        ]),
        const SizedBox(height: 4),
        const GuideInfoBox(
          type: GuideInfoBoxType.tip,
          text: 'จำนวนที่ขอจะหักจากโควตาเดือนนี้ทันทีที่ยืนยัน ระบบจะแจ้งเตือนหากเกินสิทธิ์',
        ),
        _div(),
        _h('3.2 การติดตามสถานะคำขอ'),
        _p('หลังส่งคำขอแล้ว เจ้าหน้าที่จะดำเนินการตามขั้นตอนดังนี้'),
        _statusFlow([
          (GuideStatusType.pending, 'รอดำเนินการ'),
          (GuideStatusType.preparing, 'กำลังเตรียม'),
          (GuideStatusType.ready, 'พร้อมรับ'),
          (GuideStatusType.completed, 'เสร็จสิ้น'),
        ]),
        _buildStatusRows([
          (GuideStatusType.pending, 'รอดำเนินการ', 'เจ้าหน้าที่ได้รับคำขอแล้ว กำลังตรวจสอบ'),
          (GuideStatusType.preparing, 'กำลังเตรียม', 'เจ้าหน้าที่กำลังจัดเตรียมถุงยางอนามัยและเจลหล่อลื่น'),
          (GuideStatusType.ready, 'พร้อมรับ', 'ถุงยางอนามัยพร้อมให้รับแล้ว สามารถมารับได้เลย'),
          (GuideStatusType.completed, 'เสร็จสิ้น', 'ยืนยันการรับถุงยางอนามัยเรียบร้อยแล้ว'),
          (GuideStatusType.cancelled, 'ยกเลิก', 'คำขอถูกยกเลิก (โดยคุณหรือเจ้าหน้าที่)'),
        ]),
        const GuideInfoBox(
          type: GuideInfoBoxType.note,
          text: 'แอปจะแจ้งเตือนในแท็บ "แจ้งเตือน" ทุกครั้งที่สถานะเปลี่ยน',
        ),
        _div(),
        _h('3.3 ประวัติคำขอ'),
        _p('ดูคำขอทั้งหมดได้ที่เมนูลัด "ประวัติคำขอ" บนหน้าหลัก หรือกดไอคอนประวัติที่มุมขวาบนในหน้ารับถุงยางอนามัย'),
        _p('กดแต่ละรายการเพื่อดูรายละเอียด เช่น สถานะปัจจุบัน จำนวนถุงยางอนามัยแต่ละขนาด จำนวนเจลหล่อลื่น สถานบริการ วันที่และเวลารับ และข้อความที่ฝาก'),
      ],
    );
  }

  Widget _buildSection4() {
    return GuideSection(
      key: _sectionKeys[3],
      number: 4,
      title: 'การสแกน QR Code เพื่อรับถุงยางอนามัย',
      children: [
        _h('4.1 วิธีสแกน'),
        _p('เมื่อคำขอมีสถานะ "พร้อมรับ" ให้ไปที่สถานบริการและทำตามขั้นตอน'),
        const GuideStepList(steps: [
          'กดแท็บ "สแกน"',
          'หันกล้องไปที่ QR Code ที่เจ้าหน้าที่แสดงให้ รอสักครู่จนแอปจับได้อัตโนมัติ',
          'หน้าต่างแสดงรายละเอียดคำขอจะปรากฏขึ้น ตรวจสอบข้อมูลให้ถูกต้อง',
          'กด "ยืนยันการรับ" เพื่อเสร็จสิ้น',
        ]),
        _div(),
        _h('4.2 ตัวเลือกเพิ่มเติม'),
        const GuideTable(
          headers: ['ตัวเลือก', 'วิธีใช้'],
          rows: [
            ['ไฟฉาย', 'กดไอคอนไฟฉายมุมขวาบน เพื่อเปิด/ปิดแสงในที่มืด'],
            ['เลือกจากรูปภาพ', 'กดปุ่ม "เลือกจากรูปภาพ" ด้านล่าง หากมีภาพ QR อยู่ในโทรศัพท์'],
          ],
        ),
        _div(),
        _h('4.3 ข้อความที่อาจพบ'),
        const GuideTable(
          headers: ['ข้อความ', 'สาเหตุ'],
          rows: [
            ['รับไปแล้ว', 'QR นี้ถูกสแกนยืนยันไปแล้วก่อนหน้า'],
            ['ยังไม่พร้อมรับ', 'คำขอยังอยู่ในสถานะกำลังเตรียม ต้องรอจนเป็น "พร้อมรับ"'],
            ['QR ไม่ถูกต้อง', 'รหัสไม่ใช่ของแอปนี้ หรือไฟล์ภาพอ่านไม่ได้'],
            ['QR ไม่ใช่ของคุณ', 'รหัสนี้เป็นของผู้ใช้คนอื่น ไม่สามารถยืนยันแทนกันได้'],
          ],
        ),
      ],
    );
  }

  Widget _buildSection5() {
    return GuideSection(
      key: _sectionKeys[4],
      number: 5,
      title: 'แบบประเมินความเสี่ยงการติดเชื้อ HIV',
      children: [
        _h('5.1 วิธีทำแบบประเมิน'),
        _p('ไปที่แท็บ "บริการ" แล้วกด "ประเมินความเสี่ยงการติดเชื้อ HIV"'),
        _p('ตอบคำถามตามความเป็นจริงทีละข้อ คำถามแบ่งออกเป็น 2 หมวด ได้แก่ พฤติกรรมทางเพศ และพฤติกรรมสุขภาพและโรคติดต่อ'),
        _p('เมื่อตอบครบ ระบบจะแสดงผลระดับความเสี่ยงพร้อมคำแนะนำ'),
        const GuideInfoBox(
          type: GuideInfoBoxType.note,
          text: 'ผลประเมินนี้เป็นแนวทางเบื้องต้นเท่านั้น ไม่ใช่การวินิจฉัยทางการแพทย์',
        ),
        _div(),
        _h('5.2 นัดพบแพทย์ต่อจากผลประเมิน'),
        _p('หากต้องการปรึกษาแพทย์เพิ่มเติม กดปุ่ม "นัดพบแพทย์" ที่แสดงบนหน้าผลประเมิน ระบบจะพาไปยังหน้านัดหมายโดยตรง'),
      ],
    );
  }

  Widget _buildSection6() {
    return GuideSection(
      key: _sectionKeys[5],
      number: 6,
      title: 'การนัดพบแพทย์',
      children: [
        _h('6.1 วิธีส่งคำนัดหมาย'),
        _p('ไปที่แท็บ "บริการ" แล้วกด "นัดพบแพทย์"'),
        const GuideStepList(steps: [
          'เรื่องที่ต้องการพบแพทย์ — เช่น รับยา PEP (ฉุกเฉิน), รับยา PrEP, ตรวจ HIV หรือปรึกษาทั่วไป',
          'สถานบริการ — เลือกสถานบริการที่ต้องการไปพบแพทย์',
          'วันที่นัด — เลือกวันที่ต้องการ (ระบบจะแสดง 7 วันทำการข้างหน้า ไม่รวมเสาร์–อาทิตย์)',
          'เวลานัด — เลือกช่วงเวลาที่สถานบริการกำหนด',
          'บันทึกเพิ่มเติม (ไม่ระบุได้) — ระบุรายละเอียดเพิ่มเติมหากต้องการ',
          'กด "ถัดไป" เพื่อดูหน้ายืนยัน ตรวจสอบให้ถูกต้องแล้วกด "ยืนยัน"',
        ]),
        _div(),
        _h('6.2 การติดตามสถานะการนัดหมาย'),
        _p('หลังส่งคำนัดหมายแล้ว เจ้าหน้าที่จะดำเนินการตามขั้นตอนดังนี้'),
        _statusFlow([
          (GuideStatusType.pending, 'รอยืนยัน'),
          (GuideStatusType.ready, 'ยืนยันแล้ว'),
          (GuideStatusType.completed, 'เสร็จสิ้น'),
        ]),
        _buildStatusRows([
          (GuideStatusType.pending, 'รอยืนยัน', 'ส่งคำนัดหมายแล้ว รอเจ้าหน้าที่ยืนยัน'),
          (GuideStatusType.ready, 'ยืนยันแล้ว', 'เจ้าหน้าที่ยืนยันการนัดเรียบร้อยแล้ว พร้อมไปพบแพทย์ตามวันเวลาที่นัด'),
          (GuideStatusType.completed, 'เสร็จสิ้น', 'พบแพทย์เรียบร้อยแล้ว'),
          (GuideStatusType.cancelled, 'ยกเลิก', 'การนัดถูกยกเลิก (โดยคุณหรือเจ้าหน้าที่)'),
        ]),
        const GuideInfoBox(
          type: GuideInfoBoxType.note,
          text: 'แอปจะแจ้งเตือนในแท็บ "แจ้งเตือน" ทุกครั้งที่สถานะการนัดหมายเปลี่ยน',
        ),
        _div(),
        _h('6.3 ประวัติการนัดหมาย'),
        _p('ดูการนัดหมายทั้งหมดได้ที่ "บริการ → นัดพบแพทย์ → ประวัติการนัด"'),
        _p('กดแต่ละรายการเพื่อดูรายละเอียด เช่น สถานะปัจจุบัน เรื่องที่นัด สถานบริการ วันที่และเวลานัด และบันทึกเพิ่มเติม'),
      ],
    );
  }

  Widget _buildSection7() {
    return GuideSection(
      key: _sectionKeys[6],
      number: 7,
      title: 'บทความ',
      children: [
        _h('7.1 การอ่านบทความสุขภาพ'),
        _p('บทความความรู้ด้านสุขภาพแสดงอยู่ที่ส่วนล่างของหน้าหลัก ภายใต้หัวข้อ "บทความ"'),
        const GuideStepList(steps: [
          'กดการ์ดบทความที่สนใจเพื่ออ่านเนื้อหาเต็ม',
          'กด "ดูทั้งหมด" เพื่อเปิดรายการบทความทั้งหมด',
        ]),
        const SizedBox(height: 4),
        const GuideInfoBox(
          type: GuideInfoBoxType.tip,
          text: 'ต้องเข้าสู่ระบบก่อนจึงจะอ่านบทความได้',
        ),
      ],
    );
  }

  Widget _buildSection8() {
    return GuideSection(
      key: _sectionKeys[7],
      number: 8,
      title: 'สถานบริการ',
      children: [
        _h('8.1 การดูรายการสถานบริการ'),
        _p('กดปุ่ม "สถานบริการ" จากเมนูลัดบนหน้าหลัก จะแสดงรายชื่อสถานบริการทั้งหมดที่เปิดให้บริการ'),
        _p('กดที่สถานบริการใดก็ได้เพื่อดูรายละเอียด'),
        _div(),
        _h('8.2 รายละเอียดสถานบริการ'),
        _p('หน้ารายละเอียดแสดงข้อมูลดังนี้'),
        const GuideTable(
          headers: ['ข้อมูล', 'รายละเอียด'],
          rows: [
            ['เวลาทำการ', 'วันและเวลาเปิด-ปิด'],
            ['เกี่ยวกับ', 'คำอธิบายสถานบริการ'],
            ['ที่อยู่', 'ที่ตั้ง'],
            ['เวลารับถุงยางอนามัย', 'ช่วงเวลาที่รับถุงยางอนามัยได้ (ถ้ามี)'],
            ['เวลานัดแพทย์', 'ช่วงเวลาที่นัดได้ (ถ้ามี)'],
            ['ข้อมูลติดต่อ', 'ช่องทางติดต่อ'],
            ['ตำแหน่งที่ตั้ง', 'แผนที่แสดงจุดที่ตั้ง'],
          ],
        ),
      ],
    );
  }

  Widget _buildSection9() {
    return GuideSection(
      key: _sectionKeys[8],
      number: 9,
      title: 'แจ้งเตือน',
      children: [
        _h('9.1 การดูการแจ้งเตือน'),
        _p('กดแท็บ "แจ้งเตือน" เพื่อดูการแจ้งเตือนทั้งหมด'),
        _p('ระบบจะแจ้งเตือนให้อัตโนมัติเมื่อมีการเปลี่ยนแปลงสถานะที่เกี่ยวข้องกับคุณ เช่น'),
        const GuideTable(
          headers: ['เหตุการณ์', 'ตัวอย่างการแจ้งเตือน'],
          rows: [
            ['คำขอถุงยางอนามัย', 'เจ้าหน้าที่เริ่มจัดเตรียม, ถุงยางอนามัยพร้อมรับแล้ว'],
            ['การนัดพบแพทย์', 'เจ้าหน้าที่ยืนยันการนัด, การนัดถูกยกเลิก'],
          ],
        ),
        const GuideInfoBox(
          type: GuideInfoBoxType.tip,
          text: 'ไอคอนแท็บแจ้งเตือนจะแสดงตัวเลขสีแดงหากมีการแจ้งเตือนที่ยังไม่ได้อ่าน',
        ),
      ],
    );
  }

  Widget _buildSection10() {
    return GuideSection(
      key: _sectionKeys[9],
      number: 10,
      title: 'ตั้งค่า',
      children: [
        _h('10.1 การแก้ไขข้อมูลส่วนตัว'),
        _p('ไปที่แท็บ "ตั้งค่า" แล้วกด "ข้อมูลส่วนตัว"'),
        _p('ข้อมูลที่แก้ไขได้ ได้แก่ เพศ สัญชาติ ประเภทสิทธิ์การรักษา หมายเลขโทรศัพท์ และชื่อที่ใช้เรียก'),
        const GuideInfoBox(
          type: GuideInfoBoxType.note,
          text: 'ชื่อผู้ใช้งานและวันเดือนปีเกิดไม่สามารถแก้ไขได้หลังจากสร้างบัญชีแล้ว',
        ),
        _div(),
        _h('10.2 การเปลี่ยนรหัสผ่าน'),
        _p('ไปที่แท็บ "ตั้งค่า" แล้วกด "เปลี่ยนรหัสผ่าน"'),
        const GuideStepList(steps: [
          'กรอกรหัสผ่านปัจจุบัน',
          'กรอกรหัสผ่านใหม่ (อย่างน้อย 8 ตัวอักษร และต้องไม่ซ้ำกับรหัสเดิม)',
          'ยืนยันรหัสผ่านใหม่อีกครั้ง แล้วกด "เปลี่ยนรหัสผ่าน"',
        ]),
        _div(),
        _h('10.3 รหัสกู้คืนบัญชี'),
        _p('รหัสกู้คืนบัญชีคือรหัสฉุกเฉิน 6 รหัสสำหรับตั้งรหัสผ่านใหม่เมื่อลืมรหัสผ่าน'),
        const GuideInfoBox(
          type: GuideInfoBoxType.important,
          text: 'รหัสกู้คืนบัญชีแต่ละรหัสใช้ได้ครั้งเดียว เมื่อใช้แล้วจะหมดอายุทันที',
        ),
        _p('ไปที่แท็บ "ตั้งค่า" แล้วกด "รหัสกู้คืนบัญชี"'),
        const GuideStepList(steps: [
          'กด "สร้างรหัสใหม่" และยืนยัน',
          'บันทึกรหัสชุดใหม่ทั้ง 6 รหัสทันที (รหัสชุดเก่าจะใช้ไม่ได้อีก)',
        ]),
        const SizedBox(height: 4),
        const GuideInfoBox(
          type: GuideInfoBoxType.tip,
          text: 'กดปุ่ม "คัดลอกรหัสทั้งหมด" เพื่อบันทึกรหัสไว้ในโน้ตหรือที่ปลอดภัยอื่น ๆ',
        ),
        _div(),
        _h('10.4 การเปลี่ยนภาษา'),
        _p('ไปที่แท็บ "ตั้งค่า" แล้วกด "ภาษา" เลือกภาษาที่ต้องการ'),
        _buildLanguageBadges(),
        _div(),
        _h('10.5 การลบบัญชี'),
        _p('ไปที่แท็บ "ตั้งค่า" แล้วกด "ลบบัญชี"'),
        const GuideInfoBox(
          type: GuideInfoBoxType.important,
          text: 'ข้อมูลทั้งหมดจะถูกลบถาวร ไม่สามารถกู้คืนได้ กรุณาตรวจสอบให้แน่ใจก่อนดำเนินการ',
        ),
        const SizedBox(height: 4),
        const GuideStepList(steps: [
          'กรอกรหัสผ่านปัจจุบันเพื่อยืนยันตัวตน',
          'ทำเครื่องหมาย "ฉันเข้าใจว่าข้อมูลทั้งหมดจะถูกลบถาวร"',
          'กดปุ่ม "ลบบัญชี"',
        ]),
      ],
    );
  }

  Widget _buildLanguageBadges() {
    final langs = [
      ('ภาษาไทย', AppColors.primaryBackground, AppColors.primaryDark),
      ('ພາສາລາວ', AppColors.statusPreparingLight, AppColors.lubricantDark),
      ('မြန်မာဘာသာ', AppColors.statusReadyLight, AppColors.statusReady),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: langs.map((lang) {
          final (label, bg, textColor) = lang;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: GoogleFonts.googleSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
