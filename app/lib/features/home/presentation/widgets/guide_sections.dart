import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/app_colors.dart';
import 'guide_widgets.dart';

/// Builds the ten content sections of [GuidePage] in order, wiring each one to
/// the matching [GlobalKey] so the table-of-contents can scroll to it. The
/// content is static Thai copy with no runtime state, so it lives here rather
/// than inflating the page's State class.
List<Widget> buildGuideSections(List<GlobalKey> keys) => [
      _section1(keys[0]),
      _section2(keys[1]),
      _section3(keys[2]),
      _section4(keys[3]),
      _section5(keys[4]),
      _section6(keys[5]),
      _section7(keys[6]),
      _section8(keys[7]),
      _section9(keys[8]),
      _section10(keys[9]),
    ];

// ─── Shared content cells ───────────────────────────────────────────────────

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
          color: AppColors.textPrimary,
          height: 1.6,
        ),
      ),
    );

Widget _div() => const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Divider(height: 1, color: Color(0xFFF0F0F0)),
    );

Widget _iconCell(IconData icon, {Color color = AppColors.textSecondary}) =>
    Align(
      alignment: Alignment.centerLeft,
      child: Icon(icon, size: 20, color: color),
    );

Widget _iconCircleCell(IconData icon, Color iconColor, Color bg) => Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );

Widget _statusCell(GuideStatusType status, String label) =>
    GuideStatusBadge(status: status, label: label);

Widget _textCell(String text) => Text(
      text,
      style: GoogleFonts.googleSans(
        fontSize: 13,
        color: AppColors.textPrimary,
        height: 1.4,
      ),
    );

// ─── Sections ─────────────────────────────────────────────────────────────────

Widget _section1(GlobalKey key) {
  return GuideSection(
    key: key,
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

Widget _section2(GlobalKey key) {
  return GuideSection(
    key: key,
    number: 2,
    title: 'หน้าหลักและการนำทาง',
    children: [
      _h('2.1 เมนูด้านล่าง'),
      _p('แถบเมนูด้านล่างมี 5 แท็บ กดเพื่อสลับระหว่างส่วนต่าง ๆ ของแอป'),
      GuideWidgetTable(
        headers: const ['ไอคอน', 'แท็บ', 'ใช้ทำอะไร'],
        columnFlex: const [2, 2, 4],
        rows: [
          [
            _iconCell(Icons.home_outlined, color: AppColors.primary),
            _textCell('หน้าหลัก'),
            _textCell('ดูโควตารายเดือน ข่าวสารและประกาศ และเมนูลัด'),
          ],
          [
            _iconCell(Icons.grid_view, color: AppColors.primary),
            _textCell('บริการ'),
            _textCell('รับถุงยางอนามัย/เจลหล่อลื่น ประเมินความเสี่ยง HIV นัดรับคำปรึกษา'),
          ],
          [
            _iconCell(Icons.camera_alt_outlined, color: AppColors.primary),
            _textCell('สแกน'),
            _textCell('สแกน QR Code เพื่อยืนยันการรับถุงยางอนามัยที่สถานบริการ'),
          ],
          [
            _iconCell(Icons.chat_bubble_outline, color: AppColors.primary),
            _textCell('แจ้งเตือน'),
            _textCell('ดูการแจ้งเตือนและอัปเดตสถานะคำขอ'),
          ],
          [
            _iconCell(Icons.settings_outlined, color: AppColors.primary),
            _textCell('ตั้งค่า'),
            _textCell('แก้ไขข้อมูลส่วนตัว เปลี่ยนรหัสผ่าน และอื่น ๆ'),
          ],
        ],
      ),
      _div(),
      _h('2.2 เมนูลัดบนหน้าหลัก'),
      _p('ด้านล่างโควตารายเดือนมีปุ่มลัด 3 ปุ่ม'),
      GuideWidgetTable(
        headers: const ['ไอคอน', 'ปุ่ม', 'พาไปที่'],
        columnFlex: const [2, 2, 3],
        rows: [
          [
            _iconCircleCell(Icons.location_on_outlined, AppColors.statusReady, AppColors.statusReadyLight),
            _textCell('สถานบริการ'),
            _textCell('รายชื่อและรายละเอียดสถานบริการทั้งหมด'),
          ],
          [
            _iconCircleCell(Icons.menu_book_outlined, AppColors.lubricant, AppColors.statusPreparingLight),
            _textCell('คู่มือการใช้'),
            _textCell('คู่มือฉบับนี้'),
          ],
          [
            _iconCircleCell(Icons.receipt_long_outlined, AppColors.statusCompleted, AppColors.statusCompletedLight),
            _textCell('ประวัติคำขอ'),
            _textCell('รายการการรับถุงยางอนามัยที่ผ่านมา'),
          ],
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

Widget _section3(GlobalKey key) {
  return GuideSection(
    key: key,
    number: 3,
    title: 'การรับถุงยางอนามัยและเจลหล่อลื่น',
    children: [
      _h('3.1 วิธีส่งคำขอ'),
      _p('ไปที่แท็บ "บริการ" แล้วกด "รับถุงยางอนามัย/เจลหล่อลื่น"'),
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
      GuideWidgetTable(
        headers: const ['สถานะ', 'คำอธิบาย'],
        columnFlex: const [2, 3],
        rows: [
          [_statusCell(GuideStatusType.pending, 'รอดำเนินการ'), _textCell('เจ้าหน้าที่ได้รับคำขอแล้ว กำลังตรวจสอบ')],
          [_statusCell(GuideStatusType.preparing, 'กำลังเตรียม'), _textCell('เจ้าหน้าที่กำลังจัดเตรียมถุงยางอนามัยและเจลหล่อลื่น')],
          [_statusCell(GuideStatusType.ready, 'พร้อมรับ'), _textCell('ถุงยางอนามัยพร้อมให้รับแล้ว สามารถมารับได้เลย')],
          [_statusCell(GuideStatusType.completed, 'เสร็จสิ้น'), _textCell('ยืนยันการรับถุงยางอนามัยเรียบร้อยแล้ว')],
          [_statusCell(GuideStatusType.cancelled, 'ยกเลิก'), _textCell('คำขอถูกยกเลิก (โดยคุณหรือเจ้าหน้าที่)')],
        ],
      ),
      const GuideInfoBox(
        type: GuideInfoBoxType.note,
        text: 'แอปจะแจ้งเตือนในแท็บ "แจ้งเตือน" ทุกครั้งที่สถานะเปลี่ยน',
      ),
      _div(),
      _h('3.3 ประวัติคำขอ'),
      _p('ดูคำขอทั้งหมดได้ที่เมนูลัด "ประวัติคำขอ" บนหน้าหลัก หรือกดไอคอนประวัติที่มุมขวาบนในหน้ารับถุงยางอนามัย/เจลหล่อลื่น'),
      _p('กดแต่ละรายการเพื่อดูรายละเอียด เช่น สถานะปัจจุบัน จำนวนถุงยางอนามัยแต่ละขนาด จำนวนเจลหล่อลื่น สถานบริการ วันที่และเวลารับ และข้อความที่ฝาก'),
    ],
  );
}

Widget _section4(GlobalKey key) {
  return GuideSection(
    key: key,
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
      GuideWidgetTable(
        headers: const ['ไอคอน', 'ตัวเลือก', 'วิธีใช้'],
        columnFlex: const [2, 2, 3],
        rows: [
          [
            _iconCell(Icons.flashlight_on),
            _textCell('ไฟฉาย'),
            _textCell('กดไอคอนไฟฉายมุมขวาบน เพื่อเปิด/ปิดแสงในที่มืด'),
          ],
          [
            _iconCell(Icons.photo_library_outlined),
            _textCell('เลือกจากรูปภาพ'),
            _textCell('กดปุ่ม "เลือกจากรูปภาพ" ด้านล่าง หากมีภาพ QR อยู่ในโทรศัพท์'),
          ],
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

Widget _section5(GlobalKey key) {
  return GuideSection(
    key: key,
    number: 5,
    title: 'แบบประเมินความเสี่ยงการติดเชื้อ HIV',
    children: [
      _h('5.1 วิธีทำแบบประเมิน'),
      _p('ไปที่แท็บ "บริการ" แล้วกด "ประเมินความเสี่ยงการติดเชื้อ HIV"'),
      _p('ตอบคำถามตามความเป็นจริงทีละข้อ คำถามแบ่งออกเป็น 2 หมวด ได้แก่ พฤติกรรมทางเพศ และพฤติกรรมสุขภาพและโรคติดต่อ'),
      _p('เมื่อตอบครบ ระบบจะแสดงผลระดับความเสี่ยงพร้อมคำแนะนำ'),
      const GuideInfoBox(
        type: GuideInfoBoxType.note,
        text: 'ผลประเมินนี้เป็นแนวทางเบื้องต้นเท่านั้น ไม่ใช่การวินิจฉัยโรค',
      ),
      _div(),
      _h('5.2 นัดรับคำปรึกษาต่อจากผลประเมิน'),
      _p('หากต้องการปรึกษาเพิ่มเติม กดปุ่ม "นัดรับคำปรึกษา" ที่แสดงบนหน้าผลประเมิน ระบบจะพาไปยังหน้านัดหมายโดยตรง'),
    ],
  );
}

Widget _section6(GlobalKey key) {
  return GuideSection(
    key: key,
    number: 6,
    title: 'การนัดรับคำปรึกษา',
    children: [
      _h('6.1 วิธีส่งคำนัดหมาย'),
      _p('ไปที่แท็บ "บริการ" แล้วกด "นัดรับคำปรึกษา"'),
      const GuideStepList(steps: [
        'เรื่องที่ต้องการรับคำปรึกษา — เช่น รับยา PEP (ฉุกเฉิน), รับยา PrEP, ตรวจเลือด หรือปรึกษาทั่วไป',
        'สถานบริการ — เลือกสถานบริการที่ต้องการไปพบเจ้าหน้าที่',
        'วันที่นัด — เลือกวันที่ต้องการ (ระบบจะแสดง 7 วันทำการข้างหน้า ไม่รวมเสาร์–อาทิตย์)',
        'เวลานัด — เลือกช่วงเวลาที่สถานบริการกำหนด',
        'บันทึกเพิ่มเติม (ไม่ระบุได้) — ระบุรายละเอียดเพิ่มเติมหากต้องการ',
        'กด "ถัดไป" เพื่อดูหน้ายืนยัน ตรวจสอบให้ถูกต้องแล้วกด "ยืนยัน"',
      ]),
      _div(),
      _h('6.2 การติดตามสถานะการนัดหมาย'),
      _p('หลังส่งคำนัดหมายแล้ว เจ้าหน้าที่จะดำเนินการตามขั้นตอนดังนี้'),
      GuideWidgetTable(
        headers: const ['สถานะ', 'คำอธิบาย'],
        columnFlex: const [2, 3],
        rows: [
          [_statusCell(GuideStatusType.pending, 'รอยืนยัน'), _textCell('ส่งคำนัดหมายแล้ว รอเจ้าหน้าที่ยืนยัน')],
          [_statusCell(GuideStatusType.ready, 'ยืนยันแล้ว'), _textCell('เจ้าหน้าที่ยืนยันการนัดเรียบร้อยแล้ว พร้อมไปพบเจ้าหน้าที่ตามวันเวลาที่นัด')],
          [_statusCell(GuideStatusType.completed, 'เสร็จสิ้น'), _textCell('พบเจ้าหน้าที่เรียบร้อยแล้ว')],
          [_statusCell(GuideStatusType.cancelled, 'ยกเลิก'), _textCell('การนัดถูกยกเลิก (โดยคุณหรือเจ้าหน้าที่)')],
        ],
      ),
      const GuideInfoBox(
        type: GuideInfoBoxType.note,
        text: 'แอปจะแจ้งเตือนในแท็บ "แจ้งเตือน" ทุกครั้งที่สถานะการนัดหมายเปลี่ยน',
      ),
      _div(),
      _h('6.3 ประวัติการนัดหมาย'),
      _p('ดูการนัดหมายทั้งหมดได้ที่ "บริการ → นัดรับคำปรึกษา → ประวัติการนัด"'),
      _p('กดแต่ละรายการเพื่อดูรายละเอียด เช่น สถานะปัจจุบัน เรื่องที่นัด สถานบริการ วันที่และเวลานัด และบันทึกเพิ่มเติม'),
    ],
  );
}

Widget _section7(GlobalKey key) {
  return GuideSection(
    key: key,
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

Widget _section8(GlobalKey key) {
  return GuideSection(
    key: key,
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
          ['เวลารับถุงยางอนามัย/เจลหล่อลื่น', 'ช่วงเวลาที่รับถุงยางอนามัย/เจลหล่อลื่นได้ (ถ้ามี)'],
          ['เวลานัดรับคำปรึกษา', 'ช่วงเวลาที่นัดได้ (ถ้ามี)'],
          ['ข้อมูลติดต่อ', 'ช่องทางติดต่อ'],
          ['ตำแหน่งที่ตั้ง', 'แผนที่แสดงจุดที่ตั้ง'],
        ],
      ),
    ],
  );
}

Widget _section9(GlobalKey key) {
  return GuideSection(
    key: key,
    number: 9,
    title: 'แจ้งเตือน',
    children: [
      _h('9.1 การดูการแจ้งเตือน'),
      _p('กดแท็บ "แจ้งเตือน" เพื่อดูการแจ้งเตือนทั้งหมด'),
      _p('ระบบจะแจ้งเตือนอัตโนมัติทุกครั้งที่มีการเปลี่ยนแปลงสถานะที่เกี่ยวข้องกับคุณ'),
      const GuideInfoBox(
        type: GuideInfoBoxType.tip,
        text: 'ไอคอนแท็บแจ้งเตือนจะแสดงตัวเลขสีแดงหากมีการแจ้งเตือนที่ยังไม่ได้อ่าน',
      ),
      _div(),
      _h('การแจ้งเตือนเกี่ยวกับคำขอถุงยางอนามัย'),
      GuideWidgetTable(
        headers: const ['สถานะ', 'ข้อความแจ้งเตือน'],
        columnFlex: const [2, 3],
        rows: [
          [
            _statusCell(GuideStatusType.pending, 'รอดำเนินการ'),
            _textCell('ระบบได้รับคำขอของคุณเรียบร้อย รอเจ้าหน้าที่ดำเนินการ'),
          ],
          [
            _statusCell(GuideStatusType.preparing, 'กำลังเตรียม'),
            _textCell('เจ้าหน้าที่กำลังเตรียมถุงยางอนามัยให้คุณ'),
          ],
          [
            _statusCell(GuideStatusType.ready, 'พร้อมรับ'),
            _textCell('ถุงยางอนามัยของคุณพร้อมรับแล้ว กรุณามารับที่ [สถานบริการ] ภายในวันที่ [วันที่ เวลา น.]'),
          ],
          [
            _statusCell(GuideStatusType.completed, 'เสร็จสิ้น'),
            _textCell('คุณได้รับถุงยางอนามัยเรียบร้อยแล้ว'),
          ],
          [
            _statusCell(GuideStatusType.cancelled, 'ยกเลิก (คุณ)'),
            _textCell('คุณได้ยกเลิกคำขอนี้เรียบร้อยแล้ว'),
          ],
          [
            _statusCell(GuideStatusType.cancelled, 'ยกเลิก (เจ้าหน้าที่)'),
            _textCell('คำขอนี้ถูกยกเลิกโดยเจ้าหน้าที่ คุณสามารถดูรายละเอียดได้ที่ บริการ > รับถุงยางอนามัย/เจลหล่อลื่น > ประวัติคำขอ > รายละเอียด > เหตุผล'),
          ],
        ],
      ),
      _div(),
      _h('การแจ้งเตือนเกี่ยวกับการนัดรับคำปรึกษา'),
      GuideWidgetTable(
        headers: const ['สถานะ', 'ข้อความแจ้งเตือน'],
        columnFlex: const [2, 3],
        rows: [
          [
            _statusCell(GuideStatusType.pending, 'รอยืนยัน'),
            _textCell('ระบบได้รับการนัดหมายของคุณเรียบร้อย รอเจ้าหน้าที่ยืนยัน'),
          ],
          [
            _statusCell(GuideStatusType.ready, 'ยืนยันแล้ว'),
            _textCell('การนัดหมายของคุณได้รับการยืนยันแล้ว กรุณามาที่ [สถานบริการ] ภายในวันที่ [วันที่ เวลา น.]'),
          ],
          [
            _statusCell(GuideStatusType.completed, 'เสร็จสิ้น'),
            _textCell('การนัดหมายของคุณเสร็จสิ้นแล้ว'),
          ],
          [
            _statusCell(GuideStatusType.cancelled, 'ยกเลิก (คุณ)'),
            _textCell('คุณได้ยกเลิกการนัดหมายนี้แล้ว'),
          ],
          [
            _statusCell(GuideStatusType.cancelled, 'ยกเลิก (เจ้าหน้าที่)'),
            _textCell('การนัดหมายนี้ถูกยกเลิกโดยเจ้าหน้าที่ คุณสามารถดูรายละเอียดได้ที่ บริการ > นัดรับคำปรึกษา > ประวัติการนัด > รายละเอียด > เหตุผล'),
          ],
        ],
      ),
    ],
  );
}

Widget _section10(GlobalKey key) {
  return GuideSection(
    key: key,
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
      _languageBadges(),
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

Widget _languageBadges() {
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
