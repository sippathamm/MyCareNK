import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations? _current;
  static AppLocalizations get current => _current!;

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('th'),
    Locale('lo'),
    Locale('my'),
    Locale('en'),
  ];

  String _t(String th, String lo, String my, [String? en]) {
    switch (locale.languageCode) {
      case 'lo':
        return lo;
      case 'my':
        return my;
      case 'en':
        return en ?? th;
      default:
        return th;
    }
  }

  // ─── Navigation ───────────────────────────────────────────────────────────
  String get navHome => _t('หน้าหลัก', 'ໜ້າຫຼັກ', 'ပင်မ', 'Home');
  String get navService => _t('บริการ', 'ບໍລິການ', 'ဝန်ဆောင်မှု', 'Services');
  String get navScan => _t('สแกน', 'ສະແກນ', 'စကင်', 'Scan');
  String get navMessages =>
      _t('แจ้งเตือน', 'ແຈ້ງເຕືອນ', 'အကြောင်းကြား', 'Notifications');
  String get navSettings => _t('ตั้งค่า', 'ຕັ້ງຄ່າ', 'ဆက်တင်', 'Settings');

  // ─── Common ───────────────────────────────────────────────────────────────
  String get ok => _t('ตกลง', 'ຕົກລົງ', 'ကောင်းပြီ', 'OK');
  String get cancel => _t('ยกเลิก', 'ຍົກເລີກ', 'မလုပ်တော့', 'Cancel');
  String get confirm => _t('ยืนยัน', 'ຢືນຢັນ', 'အတည်ပြု', 'Confirm');
  String get next => _t('ถัดไป', 'ຕໍ່ໄປ', 'ဆက်လုပ်', 'Next');
  String get edit => _t('แก้ไข', 'ແກ້ໄຂ', 'ပြင်ဆင်', 'Edit');
  String get retry =>
      _t('ลองอีกครั้ง', 'ລອງໃໝ່ອີກ', 'ထပ်ကြိုးစား', 'Try Again');
  String get tryAgain => _t('ลองใหม่', 'ລອງໃໝ່', 'ထပ်ကြိုးစား', 'Try Again');
  String get errorOccurred => _t(
    'เกิดข้อผิดพลาด',
    'ເກີດຂໍ້ຜິດພາດ',
    'အမှားဖြစ်ပေါ်သည်',
    'An error occurred',
  );
  String get errorOccurredTitle => _t(
    'เกิดข้อผิดพลาด',
    'ເກີດຂໍ້ຜິດພາດ',
    'အမှားဖြစ်ပေါ်သည်',
    'An error occurred',
  );
  String get pleaseLogin => _t(
    'กรุณาเข้าสู่ระบบ',
    'ກະລຸນາເຂົ້າສູ່ລະບົບ',
    'ကျေးဇူးပြု၍ ဝင်ရောက်ပါ',
    'Please Log In',
  );
  String get loginBtn =>
      _t('เข้าสู่ระบบ', 'ເຂົ້າສູ່ລະບົບ', 'ဝင်ရောက်ရန်', 'Log In');
  String get logout => _t('ออกจากระบบ', 'ອອກຈາກລະບົບ', 'ထွက်ရန်', 'Log Out');
  String get loggedIn => _t(
    'เข้าสู่ระบบแล้ว',
    'ເຂົ້າສູ່ລະບົບແລ້ວ',
    'ဝင်ရောက်ပြီးပါပြီ',
    'Logged in',
  );
  String get loggedOut =>
      _t('ออกจากระบบแล้ว', 'ອອກຈາກລະບົບແລ້ວ', 'ထွက်ပြီးပါပြီ', 'Logged out');
  String get viewAll =>
      _t('ดูทั้งหมด', 'ເບິ່ງທັງໝົດ', 'အားလုံးကြည့်', 'View All');
  String get all => _t('ทั้งหมด', 'ທັງໝົດ', 'အားလုံး', 'All');
  String get noData =>
      _t('ไม่มีข้อมูล', 'ບໍ່ມີຂໍ້ມູນ', 'အချက်အလက်မရှိ', 'No data');
  String get details => _t('รายละเอียด', 'ລາຍລະອຽດ', 'အသေးစိတ်', 'Details');
  String get referenceNumber =>
      _t('รหัสอ้างอิง', 'ລະຫັດອ້າງອີງ', 'ကိုးကားနံပါတ်', 'Reference Number');
  String get pieces => _t('ชิ้น', 'ອັນ', 'ခု', 'pcs');
  String get backLabel => _t('กลับ', 'ກັບ', 'နောက်သို့', 'Back');
  String get changeLanguage =>
      _t('เปลี่ยนภาษา', 'ປ່ຽນພາສາ', 'ဘာသာစကားပြောင်း', 'Change Language');
  String get copied => _t('คัดลอกแล้ว', 'ຄັດລອກແລ້ວ', 'ကူးယူပြီး', 'Copied');
  String get cannotLoadData => _t(
    'ไม่สามารถโหลดข้อมูลได้ กดเพื่อลองใหม่',
    'ບໍ່ສາມາດໂຫຼດຂໍ້ມູນໄດ້ ກົດເພື່ອລອງໃໝ່',
    'ဒေတာမဖွင့်နိုင်ပါ နှိပ်၍ ထပ်ကြိုးစားပါ',
    'Cannot load data. Tap to retry',
  );
  String get generalErrorRetry => _t(
    'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง',
    'ເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່ອີກຄັ້ງ',
    'အမှားဖြစ်သည် ထပ်ကြိုးစားပါ',
    'An error occurred. Please try again',
  );

  // ─── Months (index 0 = empty string, 1..12 = months) ────────────────────
  List<String> get monthsFull => locale.languageCode == 'lo'
      ? [
          '',
          'ມັງກອນ',
          'ກຸມພາ',
          'ມີນາ',
          'ເມສາ',
          'ພຶດສະພາ',
          'ມິຖຸນາ',
          'ກໍລະກົດ',
          'ສິງຫາ',
          'ກັນຍາ',
          'ຕຸລາ',
          'ພະຈິກ',
          'ທັນວາ',
        ]
      : locale.languageCode == 'my'
      ? [
          '',
          'ဇန်နဝါရီ',
          'ဖေဖော်ဝါရီ',
          'မတ်',
          'ဧပြီ',
          'မေ',
          'ဇွန်',
          'ဇူလိုင်',
          'ဩဂုတ်',
          'စက်တင်ဘာ',
          'အောက်တိုဘာ',
          'နိုဝင်ဘာ',
          'ဒီဇင်ဘာ',
        ]
      : locale.languageCode == 'en'
      ? [
          '',
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ]
      : [
          '',
          'มกราคม',
          'กุมภาพันธ์',
          'มีนาคม',
          'เมษายน',
          'พฤษภาคม',
          'มิถุนายน',
          'กรกฎาคม',
          'สิงหาคม',
          'กันยายน',
          'ตุลาคม',
          'พฤศจิกายน',
          'ธันวาคม',
        ];

  List<String> get monthsShort => locale.languageCode == 'lo'
      ? [
          '',
          'ມ.ກ.',
          'ກ.ພ.',
          'ມີ.ນ.',
          'ເມ.ສ.',
          'ພ.ພ.',
          'ມິ.ຖ.',
          'ກ.ລ.',
          'ສ.ຫ.',
          'ກ.ຍ.',
          'ຕ.ລ.',
          'ພ.ຈ.',
          'ທ.ວ.',
        ]
      : locale.languageCode == 'my'
      ? [
          '',
          'ဇန်',
          'ဖေ',
          'မတ်',
          'ဧ',
          'မေ',
          'ဇွန်',
          'ဇူ',
          'ဩ',
          'စက်',
          'အောက်',
          'နို',
          'ဒီ',
        ]
      : locale.languageCode == 'en'
      ? [
          '',
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ]
      : [
          '',
          'ม.ค.',
          'ก.พ.',
          'มี.ค.',
          'เม.ย.',
          'พ.ค.',
          'มิ.ย.',
          'ก.ค.',
          'ส.ค.',
          'ก.ย.',
          'ต.ค.',
          'พ.ย.',
          'ธ.ค.',
        ];

  List<String> get daysShort => locale.languageCode == 'lo'
      ? ['ອາ', 'ຈ', 'ອ', 'ພ', 'ພຫ', 'ສ', 'ເສ']
      : locale.languageCode == 'my'
      ? ['နွေ', 'လာ', 'ဂါ', 'ဟူ', 'ကြာ', 'သော', 'နေ']
      : locale.languageCode == 'en'
      ? ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
      : ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส'];

  // ─── Status ───────────────────────────────────────────────────────────────
  String get statusPending =>
      _t('รอดำเนินการ', 'ລໍຖ້າດຳເນີນການ', 'စောင့်ဆိုင်းနေသည်', 'Pending');
  String get statusPreparing =>
      _t('กำลังเตรียม', 'ກຳລັງກຽມ', 'ပြင်ဆင်နေသည်', 'Preparing');
  String get statusReady =>
      _t('พร้อมรับ', 'ພ້ອມຮັບ', 'ယူရန်အသင့်ဖြစ်ပြီ', 'Ready');
  String get statusCompleted =>
      _t('เสร็จสิ้น', 'ສຳເລັດ', 'ပြီးစီး', 'Completed');
  String get statusSuccess => _t('สำเร็จ', 'ສຳເລັດ', 'အောင်မြင်သည်', 'Success');
  String get statusCancelled =>
      _t('ยกเลิก', 'ຍົກເລີກ', 'ပယ်ဖျက်ပြီ', 'Cancelled');
  String get statusCancelledByStaff => _t(
    'ยกเลิกโดยเจ้าหน้าที่',
    'ຍົກເລີກໂດຍເຈົ້າໜ້າທີ່',
    'ဝန်ထမ်းမှ ပယ်ဖျက်',
    'Cancelled by Staff',
  );
  String get statusCancelledByUser =>
      _t('ยกเลิกโดยคุณ', 'ຍົກເລີກໂດຍທ່ານ', 'သင်မှ ပယ်ဖျက်', 'Cancelled by You');
  String get statusPendingAppt => _t(
    'รอยืนยัน',
    'ລໍຖ້າການຢືນຢັນ',
    'အတည်ပြုရန်စောင့်',
    'Pending Confirmation',
  );
  String get statusConfirmedAppt =>
      _t('ยืนยันแล้ว', 'ຢືນຢັນແລ້ວ', 'အတည်ပြုပြီး', 'Confirmed');

  // ─── Auth – Login ─────────────────────────────────────────────────────────
  String get loginTitle =>
      _t('เข้าสู่ระบบ', 'ເຂົ້າສູ່ລະບົບ', 'ဝင်ရောက်ရန်', 'Log In');
  String get loginWelcome =>
      _t('ยินดีต้อนรับ', 'ຍິນດີຕ້ອນຮັບ', 'ကြိုဆိုပါသည်', 'Welcome');
  String get loginSubtitle => _t(
    'เข้าสู่ระบบเพื่อใช้บริการ MyCareNK',
    'ເຂົ້າສູ່ລະບົບເພື່ອໃຊ້ບໍລິການ MyCareNK',
    'MyCareNK ဝန်ဆောင်မှုသုံးရန် ဝင်ရောက်ပါ',
    'Log in to use MyCareNK services',
  );
  String get usernameHint =>
      _t('ชื่อผู้ใช้งาน', 'ຊື່ຜູ້ໃຊ້', 'အသုံးပြုသူနာမည်', 'Username');
  String get usernameRequired => _t(
    'กรุณากรอกชื่อผู้ใช้งาน',
    'ກະລຸນາໃສ່ຊື່ຜູ້ໃຊ້',
    'အသုံးပြုသူနာမည် ထည့်သွင်းပါ',
    'Please enter your username',
  );
  String get usernameTooShort => _t(
    'ชื่อผู้ใช้งานต้องมีความยาวอย่างน้อย 4 ตัวอักษร',
    'ຊື່ຜູ້ໃຊ້ຕ້ອງມີຢ່າງໜ້ອຍ 4 ຕົວອັກສອນ',
    'အသုံးပြုသူနာမည် အနည်းဆုံး ၄ လုံးရှိရမည်',
    'Username must be at least 4 characters',
  );
  String get usernameInvalidChars => _t(
    'ชื่อผู้ใช้งานต้องเป็นตัวอักษรภาษาอังกฤษหรือตัวเลขเท่านั้น',
    'ຊື່ຜູ້ໃຊ້ຕ້ອງເປັນຕົວອັກສອນ ຫຼື ຕົວເລກ ພາສາອັງກິດເທົ່ານັ້ນ',
    'အင်္ဂလိပ်စာလုံးများနှင့် ဂဏန်းများသာ ခွင့်ပြုသည်',
    'Username must contain only English letters or numbers',
  );
  String get passwordHint =>
      _t('รหัสผ่าน', 'ລະຫັດຜ່ານ', 'စကားဝှက်', 'Password');
  String get passwordRequired => _t(
    'กรุณากรอกรหัสผ่าน',
    'ກະລຸນາໃສ່ລະຫັດຜ່ານ',
    'စကားဝှက် ထည့်သွင်းပါ',
    'Please enter your password',
  );
  String get forgotPassword => _t(
    'ลืมรหัสผ่าน?',
    'ລືມລະຫັດຜ່ານ?',
    'စကားဝှက်မေ့သွားပါသလား?',
    'Forgot password?',
  );
  String get createNewAccount => _t(
    'สร้างบัญชีใหม่',
    'ສ້າງບັນຊີໃໝ່',
    'အကောင့်အသစ်ဖွင့်',
    'Create Account',
  );
  String get incorrectCredentials => _t(
    'ชื่อผู้ใช้งานหรือรหัสผ่านไม่ถูกต้อง',
    'ຊື່ຜູ້ໃຊ້ ຫຼື ລະຫັດຜ່ານບໍ່ຖືກຕ້ອງ',
    'အသုံးပြုသူနာမည် သို့မဟုတ် စကားဝှက် မှားသည်',
    'Username or password is incorrect',
  );
  String get loginErrorMsg => _t(
    'เกิดข้อผิดพลาดในการเข้าสู่ระบบ',
    'ເກີດຂໍ້ຜິດພາດໃນການເຂົ້າສູ່ລະບົບ',
    'ဝင်ရောက်ရာတွင် အမှားဖြစ်ပေါ်သည်',
    'An error occurred while logging in',
  );

  // ─── Auth – Register ──────────────────────────────────────────────────────
  String get registerTitle => _t(
    'สร้างบัญชีใหม่',
    'ສ້າງບັນຊີໃໝ່',
    'အကောင့်အသစ်ဖွင့်',
    'Create Account',
  );
  String get usernameLength => _t(
    'ตัวอักษรภาษาอังกฤษอย่างน้อย 4 ตัว ผสมตัวเลขได้ (4–20 ตัว)',
    'ຕົວອັກສອນພາສາອັງກິດຢ່າງໜ້ອຍ 4 ຕົວ ຜສົມຕົວເລກໄດ້ (4–20 ຕົວ)',
    'အင်္ဂလိပ်စာ အနည်းဆုံး ၄ လုံးပါရှိရမည် ဂဏန်းပါနိုင် (၄–၂၀ လုံး)',
    'At least 4 English letters, numbers allowed (4–20 chars)',
  );
  String get usernameLetterRequired => _t(
    'ชื่อผู้ใช้งานต้องมีตัวอักษรภาษาอังกฤษอย่างน้อย 4 ตัว',
    'ຊື່ຜູ້ໃຊ້ຕ້ອງມີຕົວອັກສອນພາສາອັງກິດຢ່າງໜ້ອຍ 4 ຕົວ',
    'အသုံးပြုသူနာမည်တွင် အင်္ဂလိပ်စာလုံး အနည်းဆုံး ၄ လုံးပါရှိရမည်',
    'Username must contain at least 4 English letters',
  );
  String get usernameRange => _t(
    'ชื่อผู้ใช้งานต้องมีความยาว 4-20 ตัวอักษร',
    'ຊື່ຜູ້ໃຊ້ຕ້ອງມີ 4-20 ຕົວອັກສອນ',
    'အသုံးပြုသူနာမည် ၄-၂၀ လုံးရှိရမည်',
    'Username must be 4–20 characters',
  );
  String get passwordTooShort => _t(
    'รหัสผ่านต้องมีความยาวอย่างน้อย 8 ตัวอักษร',
    'ລະຫັດຜ່ານຕ້ອງມີຢ່າງໜ້ອຍ 8 ຕົວອັກສອນ',
    'စကားဝှက် အနည်းဆုံး ၈ လုံးရှိရမည်',
    'Password must be at least 8 characters',
  );
  String get passwordStrength => _t(
    'รหัสผ่านต้องมีทั้งตัวอักษรและตัวเลข',
    'ລະຫັດຜ່ານຕ້ອງມີທັງຕົວອັກສອນ ແລະ ຕົວເລກ',
    'စကားဝှက်တွင် စာလုံးနှင့် ဂဏန်းပါရှိရမည်',
    'Password must contain both letters and numbers',
  );
  String get passwordStrengthHint => _t(
    'ต้องมีทั้งตัวอักษรและตัวเลข อย่างน้อย 8 ตัว',
    'ຕ້ອງມີທັງຕົວອັກສອນ ແລະ ຕົວເລກ ຢ່າງໜ້ອຍ 8 ຕົວ',
    'စာလုံးနှင့် ဂဏန်း ပါဝင်ရမည် (အနည်းဆုံး ၈ လုံး)',
    'Must contain both letters and numbers, at least 8 chars',
  );
  String get confirmPasswordHint => _t(
    'ยืนยันรหัสผ่าน',
    'ຢືນຢັນລະຫັດຜ່ານ',
    'စကားဝှက် အတည်ပြု',
    'Confirm Password',
  );
  String get confirmPasswordRequired => _t(
    'กรุณายืนยันรหัสผ่าน',
    'ກະລຸນາຢືນຢັນລະຫັດຜ່ານ',
    'စကားဝှက် အတည်ပြုပါ',
    'Please confirm your password',
  );
  String get passwordMismatch => _t(
    'รหัสผ่านไม่ตรงกัน',
    'ລະຫັດຜ່ານບໍ່ກົງກັນ',
    'စကားဝှက် မတူညီပါ',
    'Passwords do not match',
  );
  String get gender => _t('เพศ', 'ເພດ', 'ကျားမ', 'Gender');
  String get male => _t('ชาย', 'ຊາຍ', 'ကျား', 'Male');
  String get female => _t('หญิง', 'ຍິງ', 'မ', 'Female');
  String get dateOfBirth => _t(
    'วัน/เดือน/ปีเกิด',
    'ວັນ/ເດືອນ/ປີເກີດ',
    'မွေးနေ့/လ/ခုနှစ်',
    'Date/Month/Year of Birth',
  );
  String get nationality =>
      _t('สัญชาติ', 'ສັນຊາດ', 'နိုင်ငံသား', 'Nationality');
  String get nationalityThai => _t('ไทย', 'ໄທ', 'ထိုင်း', 'Thai');
  String get nationalityLao => _t('ลาว', 'ລາວ', 'လာအို', 'Lao');
  String get nationalityMyanmar => _t('พม่า', 'ພະມ່າ', 'မြန်မာ', 'Myanmar');
  String get nationalityOther => _t('อื่นๆ', 'ອື່ນໆ', 'အခြား', 'Other');
  String get specifyNationality => _t(
    'ระบุสัญชาติ',
    'ລະບຸສັນຊາດ',
    'နိုင်ငံသားဖော်ပြပါ',
    'Specify Nationality',
  );
  String get selectGender => _t(
    'กรุณาเลือกเพศ',
    'ກະລຸນາເລືອກເພດ',
    'ကျားမ ရွေးချယ်ပါ',
    'Please select gender',
  );
  String get selectBirthDate => _t(
    'กรุณาเลือกวันเกิด',
    'ກະລຸນາເລືອກວັນເກີດ',
    'မွေးနေ့ ရွေးချယ်ပါ',
    'Please select date of birth',
  );
  String get nationalityRequired => _t(
    'กรุณาระบุสัญชาติ',
    'ກະລຸນາລະບຸສັນຊາດ',
    'နိုင်ငံသား ဖော်ပြပါ',
    'Please specify nationality',
  );
  String get skip => _t('ข้าม', 'ຂ້າມ', 'ကျော်', 'Skip');
  String get healthCoverage => _t(
    'สิทธิ์การรักษา',
    'ສິດທິການຮັກສາ',
    'ကျန်းမာရေးထောက်ပံ့မှု',
    'Health Coverage',
  );
  String get healthCoverageHelper => _t(
    'สิทธิ์ที่คุณใช้รับบริการทางการแพทย์',
    'ສິດທິທີ່ທ່ານໃຊ້ຮັບບໍລິການທາງການແພດ',
    'သင်ဆေးကုသမှုဝန်ဆောင်မှုရရှိရာတွင် အသုံးပြုသော အခွင့်အရေး',
    'The coverage you use for medical services',
  );
  String get selectHealthCoverage => _t(
    'กรุณาเลือกสิทธิ์การรักษา',
    'ກະລຸນາເລືອກສິດທິການຮັກສາ',
    'ကျန်းမာရေးထောက်ပံ့မှု ရွေးချယ်ပါ',
    'Please select health coverage',
  );
  String get hcSelfPay =>
      _t('จ่ายเงินเอง', 'ຈ່າຍເງິນເອງ', 'ကိုယ်တိုင်ပေးချေ', 'Self-pay');
  String get hcForeignInsurance => _t(
    'บัตรประกันสุขภาพต่างด้าว',
    'ບັດປະກັນສຸຂະພາບຕ່າງດ້າວ',
    'နိုင်ငံခြားသား ကျန်းမာရေးအာမခံကတ်',
    'Foreign Health Insurance Card',
  );
  String get hcNone =>
      _t('ไม่มี/ไม่ทราบ', 'ບໍ່ມີ/ບໍ່ຮູ້', 'မရှိ/မသိ', 'None/Unknown');
  String get phoneNumberHint =>
      _t('หมายเลขโทรศัพท์', 'ໝາຍເລກໂທລະສັບ', 'ဖုန်းနံပါတ်', 'Phone Number');
  String get phoneNumberHelper => _t(
    'หมายเลขโทรศัพท์ 10 หลัก สำหรับการติดต่อกลับ',
    'ໝາຍເລກໂທລະສັບ 10 ຕົວ ສຳລັບການຕິດຕໍ່ກັບ',
    'ဆက်သွယ်ရန် ဂဏန်း ၁၀ လုံး ဖုန်းနံပါတ်',
    '10-digit phone number for contact',
  );
  String get phoneNumberRequired => _t(
    'กรุณากรอกหมายเลขโทรศัพท์',
    'ກະລຸນາໃສ່ໝາຍເລກໂທລະສັບ',
    'ဖုန်းနံပါတ် ထည့်ပါ',
    'Please enter your phone number',
  );
  String get phoneNumberInvalid => _t(
    'หมายเลขโทรศัพท์ต้อง 10 หลัก และขึ้นต้นด้วย 0',
    'ໝາຍເລກໂທລະສັບຕ້ອງ 10 ຕົວ ແລະ ຂຶ້ນຕົ້ນດ້ວຍ 0',
    'ဖုန်းနံပါတ် ၁၀ လုံးဖြစ်ရမည်၊ ၀ ဖြင့်စရမည်',
    'Phone number must be 10 digits and start with 0',
  );
  String get nicknameHint =>
      _t('ชื่อที่ใช้เรียก', 'ຊື່ທີ່ໃຊ້ເອີ້ນ', 'ခေါ်ဆိုသောနာမည်', 'Nickname');
  String get nicknameHelper => _t(
    'ชื่อที่เจ้าหน้าที่ใช้เรียกคุณ ชื่อเล่นหรือชื่อสมมุติก็ได้',
    'ຊື່ທີ່ເຈົ້າໜ້າທີ່ໃຊ້ເອີ້ນທ່ານ ຊື່ຫຼິ້ນ ຫຼື ຊື່ສົມມຸດກໍ່ໄດ້',
    'ဝန်ထမ်းများ ခေါ်ဆိုမည့်နာမည် အမည်ပြောင် သို့မဟုတ် ကင်းနာမည်ဖြစ်နိုင်',
    'The name staff will use to address you. Can be a nickname or alias',
  );
  String get nicknameRequired => _t(
    'กรุณากรอกชื่อที่ใช้เรียก',
    'ກະລຸນາໃສ່ຊື່ທີ່ໃຊ້ເອີ້ນ',
    'ခေါ်ဆိုသောနာမည် ထည့်ပါ',
    'Please enter a nickname',
  );
  String get nicknameTooLong => _t(
    'ชื่อที่ใช้เรียกต้องไม่เกิน 50 ตัวอักษร',
    'ຊື່ທີ່ໃຊ້ເອີ້ນຕ້ອງບໍ່ເກີນ 50 ຕົວອັກສອນ',
    'ခေါ်ဆိုသောနာမည် ၅၀ လုံးမကျော်ရ',
    'Nickname must not exceed 50 characters',
  );
  String get privacyFrameTitle => _t(
    'ข้อมูลของคุณเป็นความลับ',
    'ຂໍ້ມູນຂອງທ່ານເປັນຄວາມລັບ',
    'သင်၏ ဒေတာကို လျှို့ဝှက်ထားသည်',
    'Your data is confidential',
  );
  String get privacyFrameBody => _t(
    'MyCareNK ปกปิดข้อมูลส่วนตัวของคุณตามมาตรฐาน PDPA และจะไม่เปิดเผยให้บุคคลภายนอก',
    'MyCareNK ປົກປິດຂໍ້ມູນສ່ວນຕົວຂອງທ່ານຕາມມາດຕະຖານ PDPA ແລະ ຈະບໍ່ເປີດເຜີຍໃຫ້ບຸກຄົນພາຍນອກ',
    'MyCareNK သည် သင်၏ ကိုယ်ရေးကိုယ်တာ အချက်အလက်ကို PDPA စံနှုန်းအတိုင်း ကာကွယ်ထားပြီး ပြင်ပသို့ မဖော်ပြပါ',
    'MyCareNK protects your personal data under PDPA standards and will not disclose it to third parties',
  );
  String get usernameExists => _t(
    'ชื่อผู้ใช้งานนี้มีอยู่ในระบบแล้ว',
    'ຊື່ຜູ້ໃຊ້ນີ້ມີໃນລະບົບແລ້ວ',
    'ဤအသုံးပြုသူနာမည် ရှိပြီးသားဖြစ်သည်',
    'This username already exists',
  );
  String get createAccountError => _t(
    'เกิดข้อผิดพลาดในการสร้างบัญชี',
    'ເກີດຂໍ້ຜິດພາດໃນການສ້າງບັນຊີ',
    'အကောင့်ဖန်တီးရာတွင် အမှားဖြစ်ပေါ်သည်',
    'An error occurred while creating account',
  );
  String get passwordLeaked => _t(
    'รหัสผ่านนี้เคยรั่วไหลในอินเทอร์เน็ต กรุณากลับไปตั้งรหัสผ่านใหม่',
    'ລະຫັດຜ່ານນີ້ເຄີຍຮົ່ວໄຫລໃນອິນເຕີເນັດ ກະລຸນາຕັ້ງໃໝ່',
    'ဤစကားဝှက်သည် အင်တာနက်တွင် ယိုစိမ့်ဖူးသည် ကျေးဇူးပြု၍ အသစ်သတ်မှတ်ပါ',
    'This password has been compromised online. Please set a new password',
  );
  String get passwordWeak => _t(
    'รหัสผ่านนี้คาดเดาง่ายเกินไป กรุณาตั้งรหัสผ่านใหม่ที่ปลอดภัยกว่านี้',
    'ລະຫັດຜ່ານນີ້ຄາດເດົາງ່າຍເກີນໄປ ກະລຸນາຕັ້ງລະຫັດຜ່ານໃໝ່ທີ່ປອດໄພກວ່ານີ້',
    'ဤစကားဝှက်သည် ခန့်မှန်းရန် လွယ်ကူလွန်းသည် ကျေးဇူးပြု၍ ပိုမိုလုံခြုံသော စကားဝှက်အသစ်ကို သတ်မှတ်ပါ',
    'This password is too easy to guess. Please set a more secure password',
  );
  String get recoveryCodesSaveFailed => _t(
    'สร้างบัญชีสำเร็จ แต่บันทึกรหัสกู้คืนไม่สำเร็จ คุณสามารถสร้างรหัสกู้คืนใหม่ได้ที่เมนูตั้งค่า',
    'ສ້າງບັນຊີສຳເລັດ ແຕ່ບັນທຶກລະຫັດກູ້ຄືນບໍ່ສຳເລັດ ທ່ານສາມາດສ້າງລະຫັດກູ້ຄືນໃໝ່ໄດ້ທີ່ເມນູຕັ້ງຄ່າ',
    'အကောင့်ဖွင့်ပြီးပါပြီ သို့သော် ကယ်တင်ကုဒ်များ သိမ်းဆည်းခြင်း မအောင်မြင်ပါ ဆက်တင်တွင် ကယ်တင်ကုဒ်အသစ် ထုတ်ယူနိုင်ပါသည်',
    'Account created, but recovery codes could not be saved. You can generate new ones in Settings',
  );

  // ─── Privacy Policy ───────────────────────────────────────────────────────
  String get privacyPolicyTitle => _t(
    'นโยบายความเป็นส่วนตัว',
    'ນະໂຍບາຍຄວາມເປັນສ່ວນຕົວ',
    'ကိုယ်ရေးကိုယ်တာ မူဝါဒ',
    'Privacy Policy',
  );
  String get privacyPolicyCheckbox => _t(
    'ฉันอ่านและเข้าใจนโยบายความเป็นส่วนตัวแล้ว',
    'ຂ້ອຍໄດ້ອ່ານ ແລະ ເຂົ້າໃຈນະໂຍບາຍຄວາມເປັນສ່ວນຕົວແລ້ວ',
    'ကျွန်ုပ် ကိုယ်ရေးကိုယ်တာ မူဝါဒကို ဖတ်ရှုနားလည်ပြီးပါပြီ',
    'I have read and understood the privacy policy',
  );
  String get privacyPolicyScrollHint => _t(
    'เลื่อนลงเพื่ออ่านนโยบายจนครบ',
    'ເລື່ອນລົງເພື່ອອ່ານນະໂຍບາຍຈົນຄົບ',
    'မူဝါဒ အပြည့်ဖတ်ရန် ဆင်းကြည့်ပါ',
    'Scroll down to read the full policy',
  );

  // ─── Registration Success ─────────────────────────────────────────────────
  String get registrationSuccessTitle => _t(
    'สร้างบัญชีใหม่สำเร็จ!',
    'ສ້າງບັນຊີໃໝ່ສຳເລັດ!',
    'အကောင့်ဖွင့်ပြီးပါပြီ!',
    'Account Created!',
  );
  String get welcomeTo => _t(
    'ยินดีต้อนรับสู่ MyCareNK',
    'ຍິນດີຕ້ອນຮັບສູ່ MyCareNK',
    'MyCareNK မှ ကြိုဆိုပါသည်',
    'Welcome to MyCareNK',
  );
  String get saveCodesHint => _t(
    'กรุณาบันทึกรหัสกู้คืนทั้ง 6 ตัวไว้ในที่ปลอดภัย\nใช้สำหรับกู้คืนบัญชีหากลืมรหัสผ่าน',
    'ກະລຸນາບັນທຶກລະຫັດກູ້ຄືນທັງ 6 ຕົວໄວ້ໃນທີ່ປອດໄພ\nໃຊ້ສຳລັບກູ້ຄືນບັນຊີຫາກລືມລະຫັດຜ່ານ',
    'ကယ်တင်ကုဒ် ၆ ခုလုံးကို လုံခြုံသောနေရာတွင် မှတ်သားထားပါ\nစကားဝှက်မေ့ပါက အကောင့်ပြန်ယူနိုင်မည်',
    'Please save all 6 recovery codes in a safe place\nUse them to recover your account if you forget your password',
  );
  String get recoveryCodesTitle => _t(
    'รหัสกู้คืนบัญชี',
    'ລະຫັດກູ້ຄືນບັນຊີ',
    'အကောင့် ကယ်တင်ကုဒ်',
    'Account Recovery Codes',
  );
  String get recoveryCodesHint => _t(
    'หากต้องการกู้คืนบัญชี ให้ใช้หนึ่งในรหัส 6 ตัวนี้',
    'ຫາກຕ້ອງການກູ້ຄືນບັນຊີ ໃຫ້ໃຊ້ໜຶ່ງໃນລະຫັດ 6 ຕົວນີ້',
    'အကောင့်ပြန်ယူလိုပါက ဤကုဒ် ၆ ခုထဲမှ တစ်ခုကို သုံးပါ',
    'To recover your account, use one of these 6 codes',
  );
  String get startUsing =>
      _t('เริ่มใช้งาน', 'ເລີ່ມໃຊ້ງານ', 'စတင်သုံးရန်', 'Get Started');
  String get copyAll => _t(
    'คัดลอกรหัสทั้งหมด',
    'ຄັດລອກລະຫັດທັງໝົດ',
    'ကုဒ်အားလုံး ကူးယူ',
    'Copy All Codes',
  );
  String get allCopied => _t(
    'คัดลอกรหัสทั้งหมดแล้ว',
    'ຄັດລອກລະຫັດທັງໝົດແລ້ວ',
    'ကုဒ်အားလုံး ကူးယူပြီး',
    'All codes copied',
  );

  // ─── Forgot Password ──────────────────────────────────────────────────────
  String get forgotPasswordTitle =>
      _t('ลืมรหัสผ่าน', 'ລືມລະຫັດຜ່ານ', 'စကားဝှက်မေ့', 'Forgot Password');
  String get enterYourUsername => _t(
    'กรอกชื่อผู้ใช้งานของคุณ',
    'ໃສ່ຊື່ຜູ້ໃຊ້ຂອງທ່ານ',
    'သင်၏ အသုံးပြုသူနာမည် ထည့်ပါ',
    'Enter your username',
  );
  String get verifyWithRecoveryCode => _t(
    'ยืนยันตัวตนด้วยรหัสกู้ยืน',
    'ຢືນຢັນຕົວຕົນດ້ວຍລະຫັດກູ້ຄືນ',
    'ကယ်တင်ကုဒ်ဖြင့် အထောက်အထားပြပါ',
    'Verify identity with recovery code',
  );
  String get enterRecoveryCode => _t(
    'กรอกรหัสกู้คืนบัญชี',
    'ໃສ່ລະຫັດກູ້ຄືນບັນຊີ',
    'အကောင့် ကယ်တင်ကုဒ် ထည့်ပါ',
    'Enter recovery code',
  );
  String get enterSixDigitCode => _t(
    'กรอกรหัส 6 หลักที่บันทึกไว้',
    'ໃສ່ລະຫັດ 6 ຕົວທີ່ບັນທຶກໄວ້',
    'မှတ်သားထားသော ၆ လုံး ကုဒ် ထည့်ပါ',
    'Enter the saved 6-digit code',
  );
  String get incompleteSixDigit => _t(
    'กรุณากรอกรหัสกู้คืนให้ครบ 6 หลัก',
    'ກະລຸນາໃສ່ລະຫັດກູ້ຄືນໃຫ້ຄົບ 6 ຕົວ',
    'ကယ်တင်ကုဒ် ၆ လုံးပြည့်အောင် ထည့်ပါ',
    'Please enter all 6 digits of the recovery code',
  );
  String get incorrectUsernameOrCode => _t(
    'ชื่อผู้ใช้งานหรือรหัสกู้คืนไม่ถูกต้อง',
    'ຊື່ຜູ້ໃຊ້ ຫຼື ລະຫັດກູ້ຄືນບໍ່ຖືກຕ້ອງ',
    'အသုံးပြုသူနာမည် သို့မဟုတ် ကယ်တင်ကုဒ် မှားသည်',
    'Username or recovery code is incorrect',
  );

  // ─── Set New Password ─────────────────────────────────────────────────────
  String get setNewPassword => _t(
    'ตั้งรหัสผ่านใหม่',
    'ຕັ້ງລະຫັດຜ່ານໃໝ່',
    'စကားဝှက်အသစ် သတ်မှတ်',
    'Set New Password',
  );
  String get newPasswordHint =>
      _t('รหัสผ่านใหม่', 'ລະຫັດຜ່ານໃໝ່', 'စကားဝှက်အသစ်', 'New Password');
  String get newPasswordRequired => _t(
    'กรุณากรอกรหัสผ่านใหม่',
    'ກະລຸນາໃສ່ລະຫັດຜ່ານໃໝ່',
    'စကားဝှက်အသစ် ထည့်ပါ',
    'Please enter new password',
  );
  String get confirmNewPasswordHint => _t(
    'ยืนยันรหัสผ่านใหม่',
    'ຢືນຢັນລະຫັດຜ່ານໃໝ່',
    'စကားဝှက်အသစ် အတည်ပြု',
    'Confirm New Password',
  );
  String get confirmNewPasswordRequired => _t(
    'กรุณายืนยันรหัสผ่านใหม่',
    'ກະລຸນາຢືນຢັນລະຫັດຜ່ານໃໝ່',
    'စကားဝှက်အသစ် အတည်ပြုပါ',
    'Please confirm new password',
  );
  String get passwordDifferentFromOld => _t(
    'รหัสผ่านใหม่ต้องต่างจากรหัสผ่านเดิม',
    'ລະຫັດຜ່ານໃໝ່ຕ້ອງຕ່າງຈາກລະຫັດຜ່ານເກົ່າ',
    'စကားဝှက်အသစ်သည် ဟောင်းနှင့် မတူရမည်',
    'New password must be different from old password',
  );

  // ─── Recovery Codes Display (after password change) ───────────────────────
  String get changePasswordTitle => _t(
    'เปลี่ยนรหัสผ่าน',
    'ປ່ຽນລະຫັດຜ່ານ',
    'စကားဝှက်ပြောင်း',
    'Change Password',
  );
  String get changePasswordSubtitle => _t(
    'กรอกรหัสผ่านปัจจุบันและรหัสผ่านใหม่ของคุณ',
    'ໃສ່ລະຫັດຜ່ານປັດຈຸບັນແລະລະຫັດຜ່ານໃໝ່',
    'လက်ရှိနှင့် စကားဝှက်အသစ် ထည့်ပါ',
    'Enter your current and new password',
  );
  String get passwordChangedSuccess => _t(
    'เปลี่ยนรหัสผ่านสำเร็จ!',
    'ປ່ຽນລະຫັດຜ່ານສຳເລັດ!',
    'စကားဝှက် ပြောင်းပြီးပါပြီ!',
    'Password changed!',
  );
  String get newCodesCreated => _t(
    'รหัสกู้คืนชุดใหม่ถูกสร้างขึ้นแล้ว',
    'ລະຫັດກູ້ຄືນຊຸດໃໝ່ຖືກສ້າງຂຶ້ນແລ້ວ',
    'ကယ်တင်ကုဒ်အသစ် ဖန်တီးပြီးပါပြီ',
    'New recovery codes have been created',
  );
  String get oldCodesExpired => _t(
    'รหัสกู้คืนชุดเก่าใช้ไม่ได้แล้ว\nกรุณาบันทึกรหัสชุดใหม่ทั้ง 6 ตัวไว้ในที่ปลอดภัย',
    'ລະຫັດກູ້ຄືນຊຸດເກົ່າໃຊ້ບໍ່ໄດ້ແລ້ວ\nກະລຸນາບັນທຶກລະຫັດຊຸດໃໝ່ 6 ຕົວ',
    'ကယ်တင်ကုဒ်ဟောင်းများ သုံး၍မရတော့ပါ\nကုဒ်အသစ် ၆ ခုကို မှတ်သားထားပါ',
    'Old recovery codes are no longer valid\nPlease save all 6 new codes in a safe place',
  );
  String get newCodesHint => _t(
    'หากต้องการกู้คืนบัญชี ให้ใช้หนึ่งในรหัสชุดใหม่นี้',
    'ຫາກຕ້ອງການກູ້ຄືນບັນຊີ ໃຫ້ໃຊ້ໜຶ່ງໃນລະຫັດຊຸດໃໝ່ນີ້',
    'အကောင့်ပြန်ယူလိုပါက ဤကုဒ်အသစ်ထဲမှ တစ်ခုကို သုံးပါ',
    'To recover your account, use one of the new codes',
  );
  String get backToLogin => _t(
    'กลับไปเข้าสู่ระบบ',
    'ກັບໄປເຂົ້າສູ່ລະບົບ',
    'ဝင်ရောက်ရာသို့ ပြန်',
    'Back to Login',
  );

  // ─── Home ─────────────────────────────────────────────────────────────────
  String get freeQuotaThisMonth => _t(
    'สิทธิ์รับฟรีเดือนนี้',
    'ສິດທິ໌ຮັບຟຣີເດືອນນີ້',
    'ဤလ အခမဲ့ ကိုတာ',
    'Free Quota This Month',
  );
  String get condoms =>
      _t('ถุงยางอนามัย', 'ຖົງຢາງອະນາໄມ', 'ကွန်ဒုံး', 'Condoms');
  String get lubricant =>
      _t('เจลหล่อลื่น', 'ເຈວຫຼໍ່ລື່ນ', 'လူဘရီကင်', 'Lubricant');
  String get requestHistory => _t(
    'ประวัติคำขอ',
    'ປະຫວັດຄຳຮ້ອງ',
    'တောင်းဆိုမှုမှတ်တမ်း',
    'Request History',
  );
  String get guide =>
      _t('คู่มือการใช้', 'ຄູ່ມືການໃຊ້', 'သုံးစွဲနည်း', 'User Guide');
  String get serviceCenters =>
      _t('สถานบริการ', 'ສູນບໍລິການ', 'ဝန်ဆောင်မှုဌာန', 'Service Centers');
  String get emergencyCall => _t(
    'เจ็บป่วยฉุกเฉิน',
    'ເຈັບເປັນສຸກເສີນ',
    'အရေးပေါ် ဆေးကု',
    'Medical Emergency',
  );
  String get assessRisk => _t(
    'ทำแบบประเมินความเสี่ยง',
    'ທຳແບບປະເມີນຄວາມສ່ຽງ',
    'အန္တရာယ်အကဲဖြတ်',
    'Risk Assessment',
  );
  String get articles => _t('บทความ', 'ບົດຄວາມ', 'ဆောင်းပါး', 'Articles');
  String get accountTooltip =>
      _t('บัญชีผู้ใช้', 'ບັນຊີຜູ້ໃຊ້', 'အသုံးပြုသူအကောင့်', 'User Account');
  String get loginToViewQuota => _t(
    'เข้าสู่ระบบเพื่อดูสิทธิ์ของคุณ',
    'ເຂົ້າສູ່ລະບົບເພື່ອເບິ່ງສິດທິ໌ຂອງທ່ານ',
    'သင်၏ ကိုတာကြည့်ရန် ဝင်ရောက်ပါ',
    'Log in to view your quota',
  );

  String resetInDaysMsg(int days) => _t(
    'จะรีเซ็ตในอีก $days วัน',
    'ຈະປັບໃໝ່ໃນອີກ $days ວັນ',
    '$days ရက်အကြာတွင် ပြန်လည်သတ်မှတ်မည်',
    'Resets in $days days',
  );

  // ─── Settings ────────────────────────────────────────────────────────────
  String get settingsAccountSection =>
      _t('บัญชีของฉัน', 'ບັນຊີຂອງຂ້ອຍ', 'ကျွန်ုပ်အကောင့်', 'My Account');
  String get settingsDisplaySection =>
      _t('การแสดงผล', 'ການສະແດງຜົນ', 'မျက်နှာပြင်', 'Display');
  String get settingsAboutSection =>
      _t('เกี่ยวกับแอป', 'ກ່ຽວກັບແອັບ', 'အက်ပ်အကြောင်း', 'About App');
  String get settingsDangerSection =>
      _t('บัญชี', 'ບັນຊີ', 'အကောင့်', 'Account');
  String get profileTitle => _t(
    'ข้อมูลส่วนตัว',
    'ຂໍ້ມູນສ່ວນຕົວ',
    'ကိုယ်ရေးအချက်အလက်',
    'Personal Information',
  );
  String get profileSaved => _t(
    'บันทึกข้อมูลแล้ว',
    'ບັນທຶກຂໍ້ມູນແລ້ວ',
    'သိမ်းဆည်းပြီးပါပြီ',
    'Information saved',
  );
  String get usernameLabel =>
      _t('ชื่อผู้ใช้งาน', 'ຊື່ຜູ້ໃຊ້', 'အသုံးပြုသူနာမည်', 'Username');
  String get appVersion => _t('เวอร์ชัน', 'ເວີຊັນ', 'ဗားရှင်း', 'Version');
  String get languageLabel => _t('ภาษา', 'ພາສາ', 'ဘာသာစကား', 'Language');
  String get logoutConfirmMessage => _t(
    'คุณต้องการออกจากระบบใช่หรือไม่',
    'ທ່ານຕ້ອງການອອກຈາກລະບົບໃຊ່ຫຼືບໍ່',
    'ထွက်ရန် သေချာပါသလား',
    'Do you want to log out?',
  );
  String get deleteAccountTitle =>
      _t('ลบบัญชี', 'ລຶບບັນຊີ', 'အကောင့်ဖျက်', 'Delete Account');
  String get deleteAccountWarning => _t(
    'ข้อมูลทั้งหมดจะถูกลบถาวร ไม่สามารถกู้คืนได้',
    'ຂໍ້ມູນທັງໝົດຈະຖືກລຶບຖາວອນ ບໍ່ສາມາດກູ້ຄືນໄດ້',
    'ဒေတာအားလုံး ထာဝစဉ် ဖျက်သွားမည်ဖြစ်ပြီး ပြန်ရ၍မရပါ',
    'All data will be permanently deleted and cannot be recovered',
  );
  String get deleteAccountConfirmCheck => _t(
    'ฉันเข้าใจว่าข้อมูลทั้งหมดจะถูกลบถาวร',
    'ຂ້ອຍເຂົ້າໃຈວ່າຂໍ້ມູນທັງໝົດຈະຖືກລຶບຖາວອນ',
    'ဒေတာအားလုံး ထာဝစဉ် ဖျက်မည်ကို နားလည်ပါသည်',
    'I understand that all data will be permanently deleted',
  );
  String get deleteAccountSuccess => _t(
    'ลบบัญชีเรียบร้อยแล้ว',
    'ລຶບບັນຊີສຳເລັດ',
    'အကောင့်ဖျက်ပြီးပါပြီ',
    'Account deleted successfully',
  );
  String get deleteAccountError => _t(
    'ไม่สามารถลบบัญชีได้ กรุณาลองใหม่',
    'ບໍ່ສາມາດລຶບບັນຊີໄດ້ ກະລຸນາລອງໃໝ່',
    'အကောင့်ဖျက်၍မရပါ ထပ်ကြိုးစားပါ',
    'Unable to delete account. Please try again',
  );
  String get deleteAccountBlockedActive => _t(
    'ไม่สามารถลบบัญชีได้ เนื่องจากคุณยังมีคำขอหรือนัดพบแพทย์ที่ยังไม่เสร็จสิ้น กรุณารอให้เสร็จสิ้นหรือยกเลิกก่อน',
    'ບໍ່ສາມາດລຶບບັນຊີໄດ້ ເນື່ອງຈາກທ່ານຍັງມີຄຳຂໍຫຼືນັດພົບແພດທີ່ຍັງບໍ່ສຳເລັດ ກະລຸນາລໍຖ້າໃຫ້ສຳເລັດ ຫຼື ຍົກເລີກກ່ອນ',
    'သင့်တွင် ပြီးဆုံးခြင်းမရှိသေးသော တောင်းဆိုမှု သို့မဟုတ် ဆရာဝန်ချိန်းဆိုမှု ရှိနေသဖြင့် အကောင့်ဖျက်၍မရပါ ပြီးဆုံးအောင် စောင့်ပါ သို့မဟုတ် အရင်ပယ်ဖျက်ပါ',
    'Cannot delete account. You have unfinished requests or appointments. Please wait for them to complete or cancel them first',
  );
  String get recoveryCodesManageTitle => _t(
    'รหัสกู้คืนบัญชี',
    'ລະຫັດກູ້ຄືນບັນຊີ',
    'အကောင့် ကယ်တင်ကုဒ်',
    'Account Recovery Codes',
  );
  String get recoveryCodesCannotRetrieve => _t(
    'รหัสกู้คืนเดิมไม่สามารถแสดงได้เพื่อความปลอดภัย สร้างชุดใหม่เพื่อแทนที่รหัสเดิม',
    'ລະຫັດກູ້ຄືນເກົ່າບໍ່ສາມາດສະແດງໄດ້ເພື່ອຄວາມປອດໄພ',
    'လုံခြုံရေးအတွက် ဟောင်းကုဒ်ကို ပြ၍မရပါ',
    'Previous recovery codes cannot be shown for security. Create a new set to replace them.',
  );
  String get recoveryCodesRegenerateBtn => _t(
    'สร้างรหัสใหม่',
    'ສ້າງລະຫັດໃໝ່',
    'ကုဒ်အသစ်ဖန်တီး',
    'Generate New Codes',
  );
  String get recoveryCodesRegenerateConfirm => _t(
    'รหัสกู้คืนชุดเดิมจะใช้ไม่ได้อีกต่อไป\nต้องการสร้างชุดใหม่ใช่หรือไม่',
    'ລະຫັດກູ້ຄືນຊຸດເກົ່າຈະໃຊ້ບໍ່ໄດ້ອີກ\nຕ້ອງການສ້າງຊຸດໃໝ່ໃຊ່ຫຼືບໍ່',
    'ဟောင်းကုဒ်များ သုံး၍မရတော့ပါ\nအသစ်ဖန်တီးမည်လား',
    'Old recovery codes will be invalidated\nDo you want to create new ones?',
  );
  String get recoveryCodesRegenerateSuccess => _t(
    'สร้างรหัสกู้คืนชุดใหม่แล้ว',
    'ສ້າງລະຫັດກູ້ຄືນຊຸດໃໝ່ແລ້ວ',
    'ကယ်တင်ကုဒ်အသစ် ဖန်တီးပြီးပါပြီ',
    'New recovery codes created',
  );
  String get changePasswordCurrentHint => _t(
    'รหัสผ่านปัจจุบัน',
    'ລະຫັດຜ່ານປັດຈຸບັນ',
    'လက်ရှိ စကားဝှက်',
    'Current Password',
  );
  String get changePasswordCurrentRequired => _t(
    'กรุณากรอกรหัสผ่านปัจจุบัน',
    'ກະລຸນາໃສ່ລະຫັດຜ່ານປັດຈຸບັນ',
    'လက်ရှိ စကားဝှက် ထည့်ပါ',
    'Please enter current password',
  );
  String get changePasswordWrongCurrent => _t(
    'รหัสผ่านปัจจุบันไม่ถูกต้อง',
    'ລະຫັດຜ່ານປັດຈຸບັນບໍ່ຖືກຕ້ອງ',
    'လက်ရှိ စကားဝှက် မှားနေသည်',
    'Current password is incorrect',
  );
  String get changePasswordSuccessMsg => _t(
    'เปลี่ยนรหัสผ่านแล้ว',
    'ປ່ຽນລະຫັດຜ່ານແລ້ວ',
    'စကားဝှက် ပြောင်းပြီးပါပြီ',
    'Password changed',
  );
  String get notLoggedInSettingsBody => _t(
    'เพื่อดูและจัดการข้อมูลบัญชีของคุณ',
    'ເພື່ອເບິ່ງ ແລະ ຈັດການຂໍ້ມູນບັນຊີຂອງທ່ານ',
    'သင်၏ အကောင့်ကို ကြည့်ရှုစီမံရန်',
    'To view and manage your account',
  );
  String get selectLanguage =>
      _t('เลือกภาษา', 'ເລືອກພາສາ', 'ဘာသာစကားရွေးချယ်', 'Select Language');

  // ─── Service Centers ──────────────────────────────────────────────────────
  String get noServiceCenters => _t(
    'ไม่มีสถานบริการ',
    'ບໍ່ມີສູນບໍລິການ',
    'ဝန်ဆောင်မှုဌာနမရှိ',
    'No service centers',
  );
  String get operatingHours =>
      _t('เวลาทำการ', 'ເວລາທຳການ', 'ဆောင်ရွက်ချိန်', 'Operating Hours');
  String get about => _t('เกี่ยวกับ', 'ກ່ຽວກັບ', 'အကြောင်း', 'About');
  String get address => _t('ที่อยู่', 'ທີ່ຢູ່', 'လိပ်စာ', 'Address');
  String get contactInfo => _t(
    'ข้อมูลติดต่อ',
    'ຂໍ້ມູນຕິດຕໍ່',
    'ဆက်သွယ်ရေးအချက်အလက်',
    'Contact Information',
  );
  String get locationLabel =>
      _t('ตำแหน่งที่ตั้ง', 'ສະຖານທີ່ຕັ້ງ', 'တည်နေရာ', 'Location');
  String get viewOnGoogleMaps => _t(
    'ดูบน Google Maps',
    'ເບິ່ງໃນ Google Maps',
    'Google Maps တွင်ကြည့်ရှု',
    'View on Google Maps',
  );
  String get condomPickupTime => _t(
    'เวลารับถุงยางอนามัย',
    'ເວລາຮັບຖົງຢາງອະນາໄມ',
    'ကွန်ဒုံးရယူချိန်',
    'Condom Pickup Hours',
  );
  String get appointmentTimeLabel => _t(
    'เวลานัดพบแพทย์',
    'ເວລານັດພົບໝໍ',
    'ဆရာဝန်ချိန်းချိန်',
    'Doctor Appointment Hours',
  );

  // ─── Service Page ─────────────────────────────────────────────────────────
  String get servicePageTitle =>
      _t('บริการ', 'ບໍລິການ', 'ဝန်ဆောင်မှု', 'Services');
  String get getCondomsTitle =>
      _t('รับถุงยางอนามัย', 'ຮັບຖົງຢາງອະນາໄມ', 'ကွန်ဒုံးရယူ', 'Get Condoms');
  String get getCondomsSubtitle => _t(
    'ค้นหาสถานบริการและรับถุงยางอนามัยฟรี',
    'ຄົ້ນຫາສູນບໍລິການ ແລະ ຮັບຖົງຢາງອະນາໄມຟຣີ',
    'ဝန်ဆောင်မှုဌာနရှာ၍ ကွန်ဒုံးအခမဲ့ ရယူပါ',
    'Find a service center and get free condoms',
  );
  String get assessHIVTitle => _t(
    'ประเมินความเสี่ยงการติดเชื้อ HIV',
    'ປະເມີນຄວາມສ່ຽງການຕິດເຊື້ອ HIV',
    'HIV ကူးစက်ခံရနိုင်ခြေ အကဲဖြတ်',
    'HIV Risk Assessment',
  );
  String get assessHIVSubtitle => _t(
    'ทำแบบทดสอบเพื่อประเมินความเสี่ยงการติดเชื้อ HIV',
    'ທຳແບບທົດສອບເພື່ອປະເມີນຄວາມສ່ຽງ HIV',
    'HIV အန္တရာယ်အကဲဖြတ်ရန် စစ်ဆေးပါ',
    'Take a test to assess your HIV infection risk',
  );
  String get bookDoctorTitle =>
      _t('นัดพบแพทย์', 'ນັດພົບໝໍ', 'ဆရာဝန်ချိန်းဆို', 'Book a Doctor');
  String get bookDoctorSubtitle => _t(
    'จองคิวล่วงหน้าเพื่อรับยา PrEP/PEP ตรวจเลือด หรือปรึกษาสุขภาพ',
    'ຈອງຄິວລ່ວງໜ້າເພື່ອຮັບຢາ PrEP/PEP ກວດເລືອດ ຫຼື ປຶກສາສຸຂະພາບ',
    'PrEP/PEP ဆေးရယူ၊ သွေးစစ် သို့မဟုတ် ကျန်းမာရေးတိုင်ပင်ရန် ကြိုတင်ချိန်းဆို',
    'Book in advance for PrEP/PEP medication, blood test, or health consultation',
  );

  // ─── Condom Request ───────────────────────────────────────────────────────
  String get requestPageTitle =>
      _t('รับถุงยางอนามัย', 'ຮັບຖົງຢາງອະນາໄມ', 'ကွန်ဒုံးရယူ', 'Get Condoms');
  String get selectServiceCenterFirst => _t(
    'กรุณาเลือกสถานบริการก่อน',
    'ກະລຸນາເລືອກສູນບໍລິການກ່ອນ',
    'ဝန်ဆောင်မှုဌာနကို အရင်ရွေးပါ',
    'Please select a service center first',
  );
  String get noCondomService => _t(
    'สถานบริการนี้ไม่เปิดรับถุงยางอนามัย',
    'ສູນບໍລິການນີ້ບໍ່ໄດ້ເປີດຮັບຖົງຢາງອະນາໄມ',
    'ဤဝန်ဆောင်မှုဌာနသည် ကွန်ဒုံး မပေးပါ',
    'This service center does not provide condoms',
  );
  String get selectServiceCenterTitle =>
      _t('สถานบริการ', 'ສູນບໍລິການ', 'ဝန်ဆောင်မှုဌာန', 'Service Center');
  String get selectDateTitle =>
      _t('วันที่รับ', 'ວັນທີ່ຮັບ', 'ရယူမည့်ရက်', 'Pickup Date');
  String get selectTimeTitle =>
      _t('เวลารับ', 'ເວລາຮັບ', 'ရယူမည့်အချိန်', 'Pickup Time');
  String get addMessageTitle => _t(
    'ฝากข้อความ (ไม่ระบุได้)',
    'ຝາກຂໍ້ຄວາມ (ຖ້ຢາກ)',
    'မှာစကား (မဖြစ်မနေ မဟုတ်)',
    'Leave a message (optional)',
  );
  String get addMessageHint => _t(
    'พิมพ์ข้อความที่นี่...',
    'ພິມຂໍ້ຄວາມທີ່ນີ້...',
    'ဤနေရာတွင် စာရိုက်ပါ...',
    'Type your message here...',
  );
  String get selectCondomFirst => _t(
    'กรุณาเลือกถุงยางอนามัยอย่างน้อย 1 ชิ้น',
    'ກະລຸນາເລືອກຖົງຢາງອະນາໄມຢ່າງໜ້ອຍ 1 ອັນ',
    'ကွန်ဒုံး အနည်းဆုံး ၁ ခု ရွေးပါ',
    'Please select at least 1 condom',
  );
  String get stepForm =>
      _t('กรอกข้อมูล', 'ໃສ່ຂໍ້ມູນ', 'ဖောင်ဖြည့်', 'Fill Form');
  String get stepConfirm => _t('ยืนยัน', 'ຢືນຢັນ', 'အတည်ပြု', 'Confirm');
  String get stepSuccess => _t('สำเร็จ', 'ສຳເລັດ', 'အောင်မြင်', 'Success');
  String get morning => _t('ช่วงเช้า', 'ຊ່ວງເຊົ້າ', 'မနက်ပိုင်း', 'Morning');
  String get afternoon =>
      _t('ช่วงบ่าย', 'ຊ່ວງບ່າຍ', 'မွန်းလွဲပိုင်း', 'Afternoon');
  String get quotaThisMonth => _t(
    'สิทธิ์รับฟรีเดือนนี้',
    'ສິດທິ໌ຮັບຟຣີເດືອນນີ້',
    'ဤလ အခမဲ့ ကိုတာ',
    'Free Quota This Month',
  );
  String get total => _t('รวม', 'ລວມ', 'စုစုပေါင်း', 'Total');
  String get extra => _t('เพิ่มเติม', 'ເພີ່ມເຕີມ', 'နောက်ထပ်', 'Extra');
  String get sizeMm => _t('มม.', 'ມມ.', 'မမ', 'mm');
  String get sizeLabel => _t('ขนาด', 'ຂະໜາດ', 'အရွယ်', 'Size');

  // ─── Confirm Page ─────────────────────────────────────────────────────────
  String get checkInfoMessage => _t(
    'กรุณาตรวจสอบข้อมูลให้ถูกต้องก่อนยืนยัน หากต้องการแก้ไขให้กดปุ่ม "แก้ไข"',
    'ກະລຸນາກວດສອບຂໍ້ມູນໃຫ້ຖືກຕ້ອງກ່ອນຢືນຢັນ ຫາກຕ້ອງການແກ້ໄຂໃຫ້ກົດ "ແກ້ໄຂ"',
    'အတည်ပြုမတိုင်မီ အချက်အလက်စစ်ဆေးပါ "ပြင်ဆင်" ခလုတ်နှိပ်၍ ပြင်နိုင်သည်',
    'Please verify information before confirming. Tap "Edit" to make changes',
  );
  String get remainingQuota => _t(
    'สิทธิ์รับฟรีคงเหลือ',
    'ສິດທິ໌ຮັບຟຣີຄົງເຫຼືອ',
    'ကျန်ရှိသော အခမဲ့ ကိုတာ',
    'Remaining Free Quota',
  );
  String get serviceAndDateTime => _t(
    'สถานบริการ วันที่และเวลารับ',
    'ສູນບໍລິການ ວັນທີ ແລະ ເວລາຮັບ',
    'ဝန်ဆောင်မှုဌာနနှင့် ရယူမည့်ရက်/အချိန်',
    'Service Center, Pickup Date and Time',
  );
  String get serviceCenterLabel =>
      _t('สถานบริการ', 'ສູນບໍລິການ', 'ဝန်ဆောင်မှုဌာန', 'Service Center');
  String get dateLabel => _t('วันที่', 'ວັນທີ', 'ရက်စွဲ', 'Date');
  String get timeLabel => _t('เวลา', 'ເວລາ', 'အချိန်', 'Time');
  String get messageLabel =>
      _t('ฝากข้อความ', 'ຝາກຂໍ້ຄວາມ', 'မှာစကား', 'Message');

  // ─── Request Success ──────────────────────────────────────────────────────
  String get requestSuccessTitle => _t(
    'ส่งคำขอสำเร็จ!',
    'ສົ່ງຄຳຮ້ອງສຳເລັດ!',
    'တောင်းဆိုမှု အောင်မြင်!',
    'Request Sent!',
  );
  String get requestSuccessMessage => _t(
    'เราได้รับคำขอถุงยางอนามัยของคุณแล้ว',
    'ພວກເຮົາໄດ້ຮັບຄຳຮ້ອງຂອງທ່ານແລ້ວ',
    'သင်၏ ကွန်ဒုံးတောင်းဆိုမှု လက်ခံပြီးပါပြီ',
    'We have received your condom request',
  );
  String get requestDetails => _t(
    'รายละเอียดคำขอ',
    'ລາຍລະອຽດຄຳຮ້ອງ',
    'တောင်းဆိုမှု အသေးစိတ်',
    'Request Details',
  );
  String get backToService => _t(
    'กลับหน้าบริการ',
    'ກັບໜ້າບໍລິການ',
    'ဝန်ဆောင်မှုစာမျက်နှာ ပြန်',
    'Back to Services',
  );
  String get viewRequestHistory => _t(
    'ดูประวัติคำขอ',
    'ເບິ່ງປະຫວັດຄຳຮ້ອງ',
    'တောင်းဆိုမှုမှတ်တမ်း ကြည့်',
    'View Request History',
  );

  String referencePrefix(String ref) => _t(
    'รหัสอ้างอิง: $ref',
    'ລະຫັດອ້າງອີງ: $ref',
    'ကိုးကားနံပါတ်: $ref',
    'Reference: $ref',
  );

  // ─── Request History ──────────────────────────────────────────────────────
  String get requestHistoryTitle => _t(
    'ประวัติคำขอ',
    'ປະຫວັດຄຳຮ້ອງ',
    'တောင်းဆိုမှုမှတ်တမ်း',
    'Request History',
  );
  String get searchRefCode => _t(
    'ค้นหารหัสอ้างอิง',
    'ຄົ້ນຫາລະຫັດອ້າງອີງ',
    'ကိုးကားနံပါတ် ရှာ',
    'Search reference code',
  );
  String get noRequests =>
      _t('ยังไม่มีรายการ', 'ຍັງບໍ່ມີລາຍການ', 'မှတ်တမ်းမရှိ', 'No requests yet');
  String get noMatchingRequests =>
      _t('ไม่พบรายการ', 'ບໍ່ພົບລາຍການ', 'မှတ်တမ်းမတွေ့ပါ', 'No requests found');
  String get copiedRefCode => _t(
    'คัดลอกรหัสอ้างอิงแล้ว',
    'ຄັດລອກລະຫັດອ້າງອີງແລ້ວ',
    'ကိုးကားနံပါတ် ကူးယူပြီး',
    'Reference code copied',
  );
  String get cancelRequestSectionTitle => _t(
    'ยกเลิกคำขอ',
    'ຍົກເລີກຄຳຮ້ອງ',
    'တောင်းဆိုမှု ပယ်ဖျက်',
    'Cancel Request',
  );
  String get cancelRequestTitle => _t(
    'ยืนยันการยกเลิกคำขอ',
    'ຢືນຢັນການຍົກເລີກຄຳຮ້ອງ',
    'တောင်းဆိုမှုပယ်ဖျက်ခြင်း အတည်ပြု',
    'Confirm Request Cancellation',
  );
  String get cancelRequestMessage => _t(
    'คุณต้องการยกเลิกคำขอนี้ใช่หรือไม่?\nการยกเลิกจะคืนสิทธิ์การรับให้กับคุณทันที',
    'ທ່ານຕ້ອງການຍົກເລີກຄຳຮ້ອງນີ້ໃຊ່ໄຫມ?\nການຍົກເລີກຈະຄືນສິດທິ໌ທັນທີ',
    'ဤတောင်းဆိုမှု ပယ်ဖျက်လိုသလား?\nပယ်ဖျက်ပါက ကိုတာ ချက်ချင်းပြန်ရမည်',
    'Do you want to cancel this request?\nCancelling will immediately restore your quota',
  );
  String get confirmCancel => _t(
    'ยืนยันยกเลิก',
    'ຢືນຢັນຍົກເລີກ',
    'ပယ်ဖျက်ကြောင်းအတည်ပြု',
    'Confirm Cancellation',
  );
  String get keepRequest =>
      _t('ไม่ยกเลิก', 'ບໍ່ຍົກເລີກ', 'မပယ်ဖျက်တော့', 'Keep Request');
  String get cancelSuccess => _t(
    'ยกเลิกคำขอเรียบร้อยแล้ว',
    'ຍົກເລີກຄຳຮ້ອງສຳເລັດ',
    'တောင်းဆိုမှု ပယ်ဖျက်ပြီး',
    'Request cancelled',
  );
  String get cancelError => _t(
    'เกิดข้อผิดพลาดในการยกเลิกคำขอ',
    'ເກີດຂໍ້ຜິດພາດໃນການຍົກເລີກ',
    'ပယ်ဖျက်ရာတွင် အမှားဖြစ်သည်',
    'An error occurred while cancelling the request',
  );
  String get cancelReason => _t(
    'เหตุผลที่ยกเลิก',
    'ເຫດຜົນທີ່ຍົກເລີກ',
    'ပယ်ဖျက်သည့် အကြောင်းပြချက်',
    'Cancellation Reason',
  );

  String sizeAndPieces(int size, int qty) => _t(
    'ขนาด $size มม.',
    'ຂະໜາດ $size ມມ.',
    'အရွယ် $size မမ',
    'Size $size mm',
  );

  // ─── Scan ─────────────────────────────────────────────────────────────────
  String get scanTitle =>
      _t('สแกน QR Code', 'ສະແກນ QR Code', 'QR Code စကင်ဖတ်', 'Scan QR Code');
  String get scanSubtitle => _t(
    'วาง QR Code ไว้ในกรอบ',
    'ວາງ QR Code ໄວ້ໃນກອບ',
    'QR Code ကို ဘောင်ထဲတွင်ထားပါ',
    'Place the QR Code inside the frame',
  );
  String get scanHint => _t(
    'แอปจะสแกนโดยอัตโนมัติ',
    'ແອັບຈະສະແກນໂດຍອັດຕໂນມັດ',
    'အက်ပ်မှ အလိုအလျောက် စကင်ဖတ်မည်',
    'The app will scan automatically',
  );
  String get selectFromGallery => _t(
    'เลือกจากรูปภาพ',
    'ເລືອກຈາກຮູບພາບ',
    'ဓာတ်ပုံမှ ရွေးချယ်',
    'Select from Gallery',
  );
  String get scanChecking => _t(
    'กำลังตรวจสอบ QR Code...',
    'ກຳລັງກວດສອບ QR Code...',
    'QR Code စစ်ဆေးနေသည်...',
    'Checking QR Code...',
  );
  String get confirmReceive => _t(
    'ยืนยันการรับ',
    'ຢືນຢັນການຮັບ',
    'ရယူကြောင်း အတည်ပြု',
    'Confirm Receipt',
  );
  String get receiveSuccess => _t(
    'รับถุงยางอนามัยสำเร็จ',
    'ຮັບຖົງຢາງອະນາໄມສຳເລັດ',
    'ကွန်ဒုံး ရယူပြီး',
    'Condoms received',
  );
  String get cannotReceiveTitle =>
      _t('ไม่สามารถรับได้', 'ບໍ່ສາມາດຮັບໄດ້', 'ရယူ၍မရပါ', 'Cannot Receive');
  String get notReadyTitle =>
      _t('ยังไม่พร้อมรับ', 'ຍັງບໍ່ພ້ອມຮັບ', 'မရယူနိုင်သေးပါ', 'Not Ready Yet');
  String get notReadyMsg1 => _t(
    'คำขอยังอยู่ในสถานะ',
    'ຄຳຮ້ອງຍັງຢູ່ໃນສະຖານະ',
    'တောင်းဆိုမှုသည် အခြေအနေ',
    'The request is currently in status',
  );
  String get notReadyMsg2 => _t(
    'สามารถรับถุงยางอนามัยได้เมื่อสถานะเป็น',
    'ສາມາດຮັບໄດ້ເມື່ອສະຖານະເປັນ',
    'ကွန်ဒုံးရယူနိုင်သည်မှာ အခြေအနေ',
    'You can receive condoms when the status is',
  );
  String get notReadyMsg3 =>
      _t('เท่านั้น', 'ເທົ່ານັ້ນ', 'ဖြစ်သောအခါသာ', 'only');
  String get qrNotFoundInImage => _t(
    'ไม่พบ QR Code ในรูปภาพนี้',
    'ບໍ່ພົບ QR Code ໃນຮູບພາບນີ້',
    'ဤဓာတ်ပုံတွင် QR Code မတွေ့ပါ',
    'No QR Code found in this image',
  );
  String get notYoursMsg => _t(
    'ไม่พบข้อมูลที่ตรงกับ QR Code นี้',
    'ບໍ່ພົບຂໍ້ມູນທີ່ກົງກັບ QR Code ນີ້',
    'ဤ QR Code နှင့် ကိုက်ညီသော ဒေတာ မတွေ့ပါ',
    'No data matching this QR Code',
  );
  String get notLoggedInScan => _t(
    'คุณต้องเข้าสู่ระบบก่อนจึงจะสแกน QR Code ได้',
    'ທ່ານຕ້ອງເຂົ້າສູ່ລະບົບກ່ອນຈຶ່ງຈະສະແກນ QR Code ໄດ້',
    'QR Code စကင်ဖတ်ရန် အရင်ဝင်ရောက်ပါ',
    'You must log in first to scan a QR Code',
  );
  String get qrError => _t(
    'ไม่สามารถตรวจสอบ QR Code ได้ในขณะนี้ กรุณาลองอีกครั้ง',
    'ບໍ່ສາມາດກວດສອບ QR Code ໄດ້ ກະລຸນາລອງໃໝ່',
    'QR Code စစ်ဆေး၍မရပါ ထပ်ကြိုးစားပါ',
    'Cannot verify QR Code at this time. Please try again',
  );
  String get scanAgain =>
      _t('สแกนอีกครั้ง', 'ສະແກນໃໝ່', 'ထပ်စကင်ဖတ်', 'Scan Again');

  String alreadyReceivedMsg(String when) => _t(
    'คุณรับถุงยางอนามัยคำขอนี้ไปแล้ว เมื่อ $when',
    'ທ່ານໄດ້ຮັບຖົງຢາງອະນາໄມນີ້ໄປແລ້ວ ເມື່ອ $when',
    'သင်သည် ဤကွန်ဒုံးကို $when တွင် ရယူပြီးသားဖြစ်သည်',
    'You already received condoms from this request at $when',
  );

  // ─── Messages ─────────────────────────────────────────────────────────────
  String get messagesTitle =>
      _t('แจ้งเตือน', 'ແຈ້ງເຕືອນ', 'အကြောင်းကြားချက်', 'Notifications');
  String get readAll => _t(
    'อ่านทั้งหมด',
    'ອ່ານທັງໝົດ',
    'အားလုံးဖတ်ပြီးအမှတ်ပြု',
    'Mark All as Read',
  );
  String get noMessages => _t(
    'ยังไม่มีการแจ้งเตือน',
    'ຍັງບໍ່ມີການແຈ້ງເຕືອນ',
    'အကြောင်းကြားချက် မရှိသေးပါ',
    'No notifications yet',
  );
  String get msgApptPending => _t(
    'ระบบได้รับการนัดหมายของคุณเรียบร้อย รอเจ้าหน้าที่ยืนยัน',
    'ລະບົບໄດ້ຮັບການນັດໝາຍຂອງທ່ານ ລໍຖ້າເຈົ້າໜ້າທີ່ຢືນຢັນ',
    'သင်၏ ချိန်းဆိုမှု လက်ခံပြီးပါပြီ ဝန်ထမ်းအတည်ပြုရန် စောင့်ဆိုင်း',
    'Your appointment has been received. Waiting for staff confirmation',
  );
  String get msgApptCompleted => _t(
    'การนัดหมายของคุณเสร็จสิ้นแล้ว',
    'ການນັດໝາຍຂອງທ່ານສຳເລັດແລ້ວ',
    'သင်၏ ချိန်းဆိုမှု ပြီးဆုံးပါပြီ',
    'Your appointment has been completed',
  );
  String get msgApptCancelledByUser => _t(
    'คุณได้ยกเลิกการนัดหมายนี้แล้ว',
    'ທ່ານໄດ້ຍົກເລີກການນັດໝາຍນີ້ແລ້ວ',
    'သင် ဤချိန်းဆိုမှုကို ပယ်ဖျက်ပြီးပါပြီ',
    'You have cancelled this appointment',
  );
  String get msgCondomPreparing => _t(
    'เจ้าหน้าที่กำลังเตรียมถุงยางอนามัยให้คุณ',
    'ເຈົ້າໜ້າທີ່ກຳລັງກຽມຖົງຢາງອະນາໄມໃຫ້ທ່ານ',
    'ဝန်ထမ်းမှ သင်အတွက် ကွန်ဒုံး ပြင်ဆင်နေသည်',
    'Staff is preparing your condoms',
  );
  String get msgCondomReceived => _t(
    'คุณได้รับถุงยางอนามัยเรียบร้อยแล้ว',
    'ທ່ານໄດ້ຮັບຖົງຢາງອະນາໄມສຳເລັດ',
    'သင် ကွန်ဒုံး ရယူပြီးပါပြီ',
    'You have received your condoms',
  );
  String get msgCondomCancelledByUser => _t(
    'คุณได้ยกเลิกคำขอนี้เรียบร้อยแล้ว',
    'ທ່ານໄດ້ຍົກເລີກຄຳຮ້ອງນີ້ສຳເລັດ',
    'သင် ဤတောင်းဆိုမှုကို ပယ်ဖျက်ပြီးပါပြီ',
    'You have cancelled this request',
  );
  String get msgCondomPending => _t(
    'ระบบได้รับคำขอของคุณเรียบร้อย รอเจ้าหน้าที่ดำเนินการ',
    'ລະບົບໄດ້ຮັບຄຳຮ້ອງຂອງທ່ານ ລໍຖ້າເຈົ້າໜ້າທີ່',
    'တောင်းဆိုမှု လက်ခံပြီးပါပြီ ဝန်ထမ်း ဆောင်ရွက်ရန် စောင့်ဆိုင်း',
    'Your request has been received. Waiting for staff action',
  );

  String msgApptConfirmed(String serviceCenter, String dateTime) => _t(
    'การนัดหมายของคุณได้รับการยืนยันแล้ว กรุณามาที่ $serviceCenter ภายในวันที่ $dateTime',
    'ການນັດໝາຍຂອງທ່ານໄດ້ຮັບການຢືນຢັນ ກະລຸນາມາທີ່ $serviceCenter ກ່ອນ $dateTime',
    'သင်၏ ချိန်းဆိုမှု အတည်ပြုပြီးပါပြီ $dateTime မတိုင်မီ $serviceCenter သို့ လာပါ',
    'Your appointment is confirmed. Please come to $serviceCenter by $dateTime',
  );

  String msgApptCancelledByStaff(String path) => _t(
    'การนัดหมายนี้ถูกยกเลิกโดยเจ้าหน้าที่ คุณสามารถดูรายละเอียดได้ที่ $path',
    'ການນັດໝາຍນີ້ຖືກຍົກເລີກໂດຍເຈົ້າໜ້າທີ່ ລາຍລະອຽດ: $path',
    'ဝန်ထမ်းမှ ဤချိန်းဆိုမှုကို ပယ်ဖျက်သည် အသေးစိတ်: $path',
    'This appointment was cancelled by staff. Details: $path',
  );

  String msgCondomReady(String serviceCenter, String dateTime) => _t(
    'ถุงยางอนามัยของคุณพร้อมรับแล้ว กรุณามารับที่ $serviceCenter ภายในวันที่ $dateTime',
    'ຖົງຢາງອະນາໄມຂອງທ່ານພ້ອມ ກະລຸນາຮັບທີ່ $serviceCenter ກ່ອນ $dateTime',
    'ကွန်ဒုံး အသင့်ဖြစ်ပြီ $dateTime မတိုင်မီ $serviceCenter တွင် လာယူပါ',
    'Your condoms are ready. Please pick up at $serviceCenter by $dateTime',
  );

  String msgCondomCancelledByStaff(String path) => _t(
    'คำขอนี้ถูกยกเลิกโดยเจ้าหน้าที่ คุณสามารถดูรายละเอียดได้ที่ $path',
    'ຄຳຮ້ອງນີ້ຖືກຍົກເລີກໂດຍເຈົ້າໜ້າທີ່ ລາຍລະອຽດ: $path',
    'ဝန်ထမ်းမှ ဤတောင်းဆိုမှုကို ပယ်ဖျက်သည် အသေးစိတ်: $path',
    'This request was cancelled by staff. Details: $path',
  );

  String get msgApptCancelledByStaffPath => _t(
    'บริการ > นัดพบแพทย์ > ประวัติการนัด > รายละเอียด > เหตุผล',
    'ບໍລິການ > ນັດພົບໝໍ > ປະຫວັດ > ລາຍລະອຽດ > ເຫດຜົນ',
    'ဝန်ဆောင်မှု > ဆရာဝန်ချိန်း > မှတ်တမ်း > အသေးစိတ် > အကြောင်းပြချက်',
    'Services > Book Doctor > History > Details > Reason',
  );

  String get msgCondomCancelledByStaffPath => _t(
    'บริการ > รับถุงยางอนามัย > ประวัติคำขอ > รายละเอียด > เหตุผล',
    'ບໍລິການ > ຮັບຖົງຢາງ > ປະຫວັດ > ລາຍລະອຽດ > ເຫດຜົນ',
    'ဝန်ဆောင်မှု > ကွန်ဒုံးရယူ > မှတ်တမ်း > အသေးစိတ် > အကြောင်းပြချက်',
    'Services > Get Condoms > Request History > Details > Reason',
  );

  // ─── Articles ─────────────────────────────────────────────────────────────
  String get articlesTitle => _t('บทความ', 'ບົດຄວາມ', 'ဆောင်းပါး', 'Articles');
  String get loadArticleError => _t(
    'โหลดบทความไม่สำเร็จ',
    'ໂຫຼດບົດຄວາມບໍ່ສຳເລັດ',
    'ဆောင်းပါး မဖွင့်နိုင်ပါ',
    'Failed to load article',
  );
  String get noArticles => _t(
    'ยังไม่มีบทความ',
    'ຍັງບໍ່ມີບົດຄວາມ',
    'ဆောင်းပါး မရှိသေးပါ',
    'No articles yet',
  );
  String get loginToViewArticles => _t(
    'คุณต้องเข้าสู่ระบบก่อนจึงจะดูบทความได้',
    'ທ່ານຕ້ອງເຂົ້າສູ່ລະບົບກ່ອນຈຶ່ງຈະເບິ່ງບົດຄວາມໄດ້',
    'ဆောင်းပါးကြည့်ရန် အရင်ဝင်ရောက်ပါ',
    'You must be logged in to view articles',
  );
  String get loginToReadArticle => _t(
    'คุณต้องเข้าสู่ระบบก่อนจึงจะอ่านบทความได้',
    'ທ່ານຕ້ອງເຂົ້າສູ່ລະບົບກ່ອນຈຶ່ງຈະອ່ານບົດຄວາມໄດ້',
    'ဆောင်းပါးဖတ်ရန် အရင်ဝင်ရောက်ပါ',
    'You must be logged in to read this article',
  );
  String get openInYouTube => _t(
    'เปิดใน YouTube',
    'ເປີດໃນ YouTube',
    'YouTube တွင်ဖွင့်',
    'Open in YouTube',
  );

  // ─── HIV Assessment ───────────────────────────────────────────────────────
  String get hivAssessmentTitle => _t(
    'ประเมินความเสี่ยงการติดเชื้อ HIV',
    'ປະເມີນຄວາມສ່ຽງ HIV',
    'HIV အန္တရာယ်အကဲဖြတ်',
    'HIV Risk Assessment',
  );
  String get hivAssessmentFullTitle => _t(
    'แบบประเมินความเสี่ยงการติดเชื้อ HIV',
    'ແບບປະເມີນຄວາມສ່ຽງ HIV',
    'HIV ကူးစက်ခံရနိုင်ခြေ စစ်ဆေးပုံစံ',
    'HIV Risk Assessment Form',
  );
  String assessmentSectionLabel(int s) =>
      _t('ส่วนที่ $s', 'ສ່ວນທີ $s', 'အပိုင်း $s', 'Section $s');
  String get sectionBehavior => _t(
    'พฤติกรรมทางเพศ',
    'ພຶດຕິກຳທາງເພດ',
    'လိင်ဆိုင်ရာ အပြုအမူ',
    'Sexual Behavior',
  );
  String get sectionHealthBehavior => _t(
    'พฤติกรรมสุขภาพและโรคติดต่อ',
    'ພຶດຕິກຳສຸຂະພາບ ແລະ ພະຍາດຕິດຕໍ່',
    'ကျန်းမာရေး အပြုအမူနှင့် ကူးစက်ရောဂါ',
    'Health Behavior & Infectious Diseases',
  );
  String get riskLow =>
      _t('ความเสี่ยงต่ำ', 'ຄວາມສ່ຽງຕ່ຳ', 'အန္တရာယ်နည်း', 'Low Risk');
  String get riskMedium =>
      _t('ความเสี่ยงปานกลาง', 'ຄວາມສ່ຽງປານກາງ', 'အန္တရာယ်အလတ်', 'Medium Risk');
  String get riskHigh =>
      _t('ความเสี่ยงสูง', 'ຄວາມສ່ຽງສູງ', 'အန္တရာယ်မြင့်', 'High Risk');
  String get riskLowHeadline => _t(
    'อยู่ในเกณฑ์ดีเยี่ยม',
    'ຢູ່ໃນເກນດີ',
    'အကောင်းဆုံးအဆင့်တွင်ရှိ',
    'Excellent',
  );
  String get riskMediumHeadline =>
      _t('ควรเฝ้าระวัง', 'ຄວນລະວັງ', 'သတိထားရမည်', 'Stay Vigilant');
  String get riskHighHeadline => _t(
    'เร่งด่วน — ควรพบแพทย์ทันที',
    'ຮີບດ່ວນ — ຄວນພົບໝໍທັນທີ',
    'အရေးပေါ် — ဆရာဝန်နှင့် ချက်ချင်းတွေ့ပါ',
    'Urgent — See a Doctor Immediately',
  );
  String get startAssessment => _t(
    'เริ่มทำแบบประเมิน',
    'ເລີ່ມທຳແບບປະເມີນ',
    'စစ်ဆေးပုံစံ စတင်',
    'Start Assessment',
  );
  String get viewAssessmentResult =>
      _t('ดูผลประเมิน', 'ເບິ່ງຜົນປະເມີນ', 'စစ်ဆေးမှု ရလဒ်ကြည့်', 'View Result');
  String get reassess =>
      _t('ทำแบบประเมินใหม่', 'ທຳແບບປະເມີນໃໝ່', 'ပြန်စစ်ဆေး', 'Reassess');
  String get additionalInfo => _t(
    'ข้อมูลเพิ่มเติม',
    'ຂໍ້ມູນເພີ່ມເຕີມ',
    'နောက်ထပ်သတင်းအချက်အလက်',
    'Additional Information',
  );
  String get viewYourAnswers => _t(
    'ดูคำตอบของคุณ',
    'ເບິ່ງຄຳຕອບຂອງທ່ານ',
    'သင်၏ အဖြေများ ကြည့်',
    'View Your Answers',
  );
  String questionNumber(int n) =>
      _t('ข้อที่ $n', 'ຂໍ້ທີ $n', 'မေးခွန်း $n', 'Question $n');
  String get assessmentDisclaimer => _t(
    'ไม่มีการเก็บข้อมูลของคุณ ใช้เพื่อการประเมินความเสี่ยงเท่านั้น',
    'ບໍ່ມີການເກັບຂໍ້ມູນຂອງທ່ານ ໃຊ້ເພື່ອປະເມີນຄວາມສ່ຽງເທົ່ານັ້ນ',
    'သင်၏ ဒေတာ သိမ်းဆည်းမှု မရှိပါ အန္တရာယ်အကဲဖြတ်ရန် သာ သုံးသည်',
    'No data is stored. Used only for risk assessment.',
  );
  String get assessmentContains => _t(
    'แบบประเมินประกอบด้วย',
    'ແບບປະເມີນປະກອບດ້ວຍ',
    'စစ်ဆေးပုံစံတွင် ပါဝင်သည်',
    'The assessment contains',
  );
  String questionCountLabel(int n) =>
      _t('$n ข้อ', '$n ຂໍ້', 'မေးခွန်း $n ခု', '$n questions');

  // ─── Doctor Booking ───────────────────────────────────────────────────────
  String get bookingTitle =>
      _t('นัดพบแพทย์', 'ນັດພົບໝໍ', 'ဆရာဝန်ချိန်းဆို', 'Book a Doctor');
  String get reasonPEP => _t(
    'รับยา PEP (ฉุกเฉิน)',
    'ຮັບຢາ PEP (ສຸກເສີນ)',
    'PEP ဆေးရယူ (အရေးပေါ်)',
    'Get PEP (Emergency)',
  );
  String get reasonPrEP =>
      _t('รับยา PrEP', 'ຮັບຢາ PrEP', 'PrEP ဆေးရယူ', 'Get PrEP');
  String get reasonHIV =>
      _t('ตรวจเลือด', 'ກວດເລືອດ', 'စစ်ဆေးသည်', 'Blood Test');
  String get reasonConsult => _t(
    'ปรึกษาทั่วไป',
    'ປຶກສາທົ່ວໄປ',
    'ကျန်းမာရေး တိုင်ပင်',
    'General Consultation',
  );
  String get bookingSelectService => _t(
    'เลือกบริการ',
    'ເລືອກບໍລິການ',
    'ဝန်ဆောင်မှုရွေးချယ်',
    'Select Service',
  );
  String get bookingServiceReason => _t(
    'เรื่องที่ต้องการพบแพทย์',
    'ສິ່ງທີ່ຕ້ອງການໄດ້ໝໍ',
    'ဆရာဝန်တွေ့ရမည့် အကြောင်း',
    'Reason for Appointment',
  );
  String get bookingAppointmentDate =>
      _t('วันที่นัด', 'ວັນທີ່ນັດ', 'ချိန်းဆိုသည့် ရက်', 'Appointment Date');
  String get bookingAppointmentTime =>
      _t('เวลานัด', 'ເວລານັດ', 'ချိန်းဆိုသည့် အချိန်', 'Appointment Time');
  String get bookingAdditionalNotes => _t(
    'บันทึกเพิ่มเติม (ไม่ระบุได้)',
    'ບັນທຶກເພີ່ມເຕີມ (ຖ້ຢາກ)',
    'မှတ်ချက် (မဖြစ်မနေ မဟုတ်)',
    'Additional Notes (optional)',
  );
  String get bookingAdditionalNotesHint => _t(
    'เช่น อาการที่มี หรือยาที่ใช้อยู่...',
    'ເຊັ່ນ ອາການທີ່ມີ ຫຼື ຢາທີ່ໃຊ້...',
    'ဥပမာ ရောဂါလက္ခဏာ သို့မဟုတ် သောက်နေသောဆေး...',
    'E.g. symptoms or current medications...',
  );
  String get noAppointmentService => _t(
    'สถานบริการนี้ไม่เปิดให้นัดพบแพทย์',
    'ສູນບໍລິການນີ້ບໍ່ໄດ້ເປີດນັດໝໍ',
    'ဤဝန်ဆောင်မှုဌာနသည် ဆရာဝန်ချိန်းဆိုမှု မပေးပါ',
    'This service center does not offer doctor appointments',
  );
  String get bookingAppointmentSummary => _t(
    'สรุปการนัดหมาย',
    'ສະຫຼຸບການນັດໝາຍ',
    'ချိန်းဆိုမှု အကျဉ်းချုပ်',
    'Appointment Summary',
  );
  String get bookingNoteLabel =>
      _t('บันทึกเพิ่มเติม', 'ບັນທຶກເພີ່ມເຕີມ', 'မှတ်ချက်', 'Additional Notes');
  String get bookingCancelNote => _t(
    'หากต้องการยกเลิกหรือเปลี่ยนแปลงนัด โปรดติดต่อสถานบริการล่วงหน้าอย่างน้อย 24 ชม.',
    'ຫາກຕ້ອງການຍົກເລີກ ຫຼື ປ່ຽນນັດ ໂປດຕິດຕໍ່ລ່ວງໜ້າ 24 ຊ.ມ.',
    'ပယ်ဖျက်/ပြောင်းလဲလိုပါက အနည်းဆုံး ၂၄ နာရီ ကြိုတင်အကြောင်းကြားပါ',
    'To cancel or change your appointment, please contact the service center at least 24 hrs in advance.',
  );
  String get confirmAppointment => _t(
    'ยืนยันการนัดหมาย',
    'ຢືນຢັນການນັດໝາຍ',
    'ချိန်းဆိုမှု အတည်ပြု',
    'Confirm Appointment',
  );
  String get loginToBookDoctor => _t(
    'คุณต้องเข้าสู่ระบบก่อนจึงจะนัดพบแพทย์ได้',
    'ທ່ານຕ້ອງເຂົ້າສູ່ລະບົບກ່ອນຈຶ່ງຈະນັດພົບໝໍໄດ້',
    'ဆရာဝန်ချိန်းဆိုရန် အရင်ဝင်ရောက်ပါ',
    'You must be logged in to book a doctor',
  );
  String get bookingSuccess => _t(
    'นัดหมายสำเร็จ!',
    'ນັດໝາຍສຳເລັດ!',
    'ချိန်းဆိုမှု အောင်မြင်!',
    'Appointment Booked!',
  );
  String get bookingSuccessMessage => _t(
    'เราได้รับคำขอนัดหมายของคุณแล้ว',
    'ພວກເຮົາໄດ້ຮັບຄຳຮ້ອງນັດໝາຍຂອງທ່ານ',
    'သင်၏ ချိန်းဆိုမှု လက်ခံပြီးပါပြီ',
    'We have received your appointment request',
  );
  String get appointmentDetailsTitle => _t(
    'รายละเอียดการนัดหมาย',
    'ລາຍລະອຽດການນັດໝາຍ',
    'ချိန်းဆိုမှု အသေးစိတ်',
    'Appointment Details',
  );
  String get preTodoTitle => _t(
    'สิ่งที่ควรทำก่อนวันนัด',
    'ສິ່ງທີ່ຄວນເຮັດກ່ອນວັນນັດ',
    'ချိန်းဆိုသည့်ရက် မတိုင်မီ ပြင်ဆင်ရမည်',
    'Before Your Appointment',
  );
  String get reasonLabel => _t('เรื่อง', 'ສິ່ງ', 'အကြောင်း', 'Reason');
  String get timeWithUnit => _t('น.', 'ໂມງ', 'နာရီ', '');

  // ─── Appointment History ──────────────────────────────────────────────────
  String get appointmentHistoryTitle => _t(
    'ประวัติการนัด',
    'ປະຫວັດການນັດ',
    'ချိန်းဆိုမှုမှတ်တမ်း',
    'Appointment History',
  );
  String get noAppointments => _t(
    'ยังไม่มีการนัดหมาย',
    'ຍັງບໍ່ມີການນັດໝາຍ',
    'ချိန်းဆိုမှု မရှိသေးပါ',
    'No appointments yet',
  );
  String get cancelAppointmentTitle => _t(
    'ยืนยันการยกเลิกนัดหมาย',
    'ຢືນຢັນການຍົກເລີກນັດໝາຍ',
    'ချိန်းဆိုမှုပယ်ဖျက်ခြင်း အတည်ပြု',
    'Confirm Cancellation',
  );
  String get cancelAppointmentMessage => _t(
    'คุณต้องการยกเลิกการนัดหมายนี้ใช่หรือไม่?\nการยกเลิกไม่สามารถเปลี่ยนแปลงได้',
    'ທ່ານຕ້ອງການຍົກເລີກນັດໝາຍນີ້ໃຊ່ໄຫມ?\nການຍົກເລີກບໍ່ສາມາດປ່ຽນໄດ້',
    'ဤချိန်းဆိုမှုကို ပယ်ဖျက်လိုသလား?\nပယ်ဖျက်ပြီးနောက် ပြောင်းလဲ၍မရပါ',
    'Cancel this appointment?\nThis action cannot be undone',
  );
  String get cancelApptSuccess => _t(
    'ยกเลิกนัดหมายเรียบร้อยแล้ว',
    'ຍົກເລີກນັດໝາຍສຳເລັດ',
    'ချိန်းဆိုမှု ပယ်ဖျက်ပြီး',
    'Appointment cancelled',
  );
  String get cancelApptError => _t(
    'เกิดข้อผิดพลาดในการยกเลิกนัดหมาย',
    'ເກີດຂໍ້ຜິດພາດໃນການຍົກເລີກ',
    'ချိန်းဆိုမှုပယ်ဖျက်ရာတွင် အမှားဖြစ်သည်',
    'Failed to cancel appointment',
  );
  String get cancelApptBtn => _t(
    'ยกเลิกนัด',
    'ຍົກເລີກນັດ',
    'ချိန်းဆိုမှု ပယ်ဖျက်',
    'Cancel Appointment',
  );
  String get copiedApptRefCode => _t(
    'คัดลอกรหัสอ้างอิงแล้ว',
    'ຄັດລອກລະຫັດອ້າງອີງແລ້ວ',
    'ကိုးကားနံပါတ် ကူးယူပြီး',
    'Reference code copied',
  );
  String get apptSubjectSection => _t(
    'เรื่องที่ต้องการพบแพทย์',
    'ສິ່ງທີ່ຕ້ອງການໄດ້ໝໍ',
    'ဆရာဝန်တွေ့ရမည့် အကြောင်း',
    'Reason for Appointment',
  );
  String get apptServiceDateTime => _t(
    'สถานบริการ วันที่ และเวลารับ',
    'ສູນບໍລິການ ວັນທີ ແລະ ເວລາ',
    'ဝန်ဆောင်မှုဌာနနှင့် ချိန်းဆိုသည့် ရက်/အချိန်',
    'Service Center, Date and Time',
  );
  String get additionalNotesSection =>
      _t('บันทึกเพิ่มเติม', 'ບັນທຶກເພີ່ມເຕີມ', 'မှတ်ချက်', 'Additional Notes');
  String get cancelReasonSection => _t(
    'เหตุผลที่ยกเลิก',
    'ເຫດຜົນທີ່ຍົກເລີກ',
    'ပယ်ဖျက်သည့် အကြောင်းပြချက်',
    'Cancellation Reason',
  );
  String get searchApptRefCode => _t(
    'ค้นหารหัสอ้างอิง',
    'ຄົ້ນຫາລະຫັດອ້າງອີງ',
    'ကိုးကားနံပါတ် ရှာ',
    'Search reference code',
  );
  String get noMatchingAppts =>
      _t('ไม่พบรายการ', 'ບໍ່ພົບລາຍການ', 'မှတ်တမ်းမတွေ့ပါ', 'No results found');

  // ─── HIV Assessment – Intro ───────────────────────────────────────────────
  String get assessmentIntroPart1 => _t(
    'โปรดพิจารณาพฤติกรรมของคุณในช่วง ',
    'ກະລຸນາພິຈາລະນາພຶດຕິກຳຂອງທ່ານໃນໄລຍະ ',
    'မိမိ၏ အပြုအမူများကို ',
    'Please consider your behavior over the past ',
  );
  String get assessmentIntroHighlight => _t(
    '3–6 เดือนที่ผ่านมา',
    '3–6 ເດືອນຜ່ານມາ',
    'လွန်ခဲ့သော 3–6 လ',
    '3–6 months',
  );
  String get assessmentIntroPart2 => _t(
    ' และเลือกคำตอบที่ตรงกับความเป็นจริงมากที่สุด\nเพื่อให้ได้ผลการประเมินที่แม่นยำ',
    ' ແລະ ເລືອກຄຳຕອບທີ່ກົງຄວາມຈິງທີ່ສຸດ\nເພື່ອໃຫ້ໄດ້ຜົນທີ່ຖືກຕ້ອງ',
    ' ကိုသုံးသပ်ပါ မှန်ကန်ဆုံး အဖြေကို ရွေးချယ်ပါ\nသေချာသောရလဒ်ရရှိရန်',
    ' and choose the most accurate answer\nfor the most precise result',
  );

  // ─── HIV Assessment – Questions ───────────────────────────────────────────
  String get q1Text => _t(
    'คุณใช้ถุงยางอนามัยเมื่อมีเพศสัมพันธ์บ่อยแค่ไหน?',
    'ທ່ານໃຊ້ຖົງຢາງອະນາໄມເວລາມີເພດສຳພັນເລື້ອຍໆ?',
    'ကာမဆက်ဆံသောအခါ ကွန်ဒုံးကို မည်မျှမကြာခဏ သုံးသနည်း?',
    'How often do you use a condom during sex?',
  );
  String get q1OptALabel =>
      _t('ใช้ทุกครั้ง', 'ໃຊ້ທຸກຄັ້ງ', 'အမြဲသုံးသည်', 'Every time');
  String get q1OptASub => _t(
    'ทั้งทางช่องคลอดและทางทวารหนัก',
    'ທັງທາງຊ່ອງຄອດ ແລະ ທາງຮູທວານ',
    'မိန်းကိုယ်နှင့် မြောင်ကြီးလမ်းအပါ',
    'Both vaginal and anal',
  );
  String get q1OptBLabel => _t(
    'ใช้เกือบทุกครั้ง',
    'ໃຊ້ເກືອບທຸກຄັ້ງ',
    'တောတော်များများ သုံးသည်',
    'Almost every time',
  );
  String get q1OptBSub => _t(
    'มีพลาดหรือผิดพลาดบางครั้ง',
    'ມີຄາດຜ່ານ ຫຼື ຜິດພາດບາງຄັ້ງ',
    'တစ်ခါတစ်ရံ မမှန်ကန်ဘဲ ဖြစ်တတ်',
    'Occasionally slipped or broke',
  );
  String get q1OptCLabel => _t(
    'ไม่ได้ใช้เป็นประจำ',
    'ບໍ່ໄດ້ໃຊ້ເປັນປະຈຳ',
    'မပုံမှန်သုံးသည်',
    'Not regularly',
  );
  String get q1OptCSub => _t(
    'ไม่สวมถุงยางอนามัยบ่อยครั้ง',
    'ບໍ່ສວມຖົງຢາງຫຼາຍຄັ້ງ',
    'ကွန်ဒုံးကို မကြာမကြာ မသုံးပါ',
    'Often without a condom',
  );

  String get q2Text => _t(
    'คุณเคยมีถุงยางอนามัยแตกหรือหลุดระหว่างมีเพศสัมพันธ์หรือไม่?',
    'ທ່ານເຄີຍມີຖົງຢາງຂາດ ຫຼື ຫຼຸດລະຫວ່າງມີເພດສຳພັນບໍ?',
    'ကာမဆက်ဆံစဉ် ကွန်ဒုံး ပေါက်ကွဲ သို့မဟုတ် ကျွတ်ထွက်ဖူးသလား?',
    'Has a condom ever broken or slipped off during sex?',
  );
  String get q2OptALabel =>
      _t('ไม่เคยเกิดขึ้น', 'ບໍ່ເຄີຍເກີດຂຶ້ນ', 'မဖြစ်ဖူးပါ', 'Never happened');
  String get q2OptASub => _t(
    'ไม่มีอุบัติเหตุดังกล่าว',
    'ບໍ່ມີອຸບັດຕິເຫດດັ່ງກ່າວ',
    'ထိုသို့သော အဖြစ်အပျက် မရှိပါ',
    'No such incident',
  );
  String get q2OptBLabel => _t(
    'เคยเกิดขึ้น แต่รับยา PEP ทันที',
    'ເຄີຍເກີດ ແຕ່ຮັບຢາ PEP ທັນທີ',
    'ဖြစ်ဖူးသော်လည်း PEP ဆေး ချက်ချင်းသောက်',
    'Happened, but took PEP immediately',
  );
  String get q2OptBSub => _t(
    'ดำเนินการป้องกันเสมอ',
    'ດຳເນີນການປ້ອງກັນສະເໝີ',
    'အမြဲ ကာကွယ်မှု ဆောင်ရွက်ထား',
    'Always took preventive action',
  );
  String get q2OptCLabel => _t(
    'เคยเกิดขึ้นและไม่ได้ป้องกัน',
    'ເຄີຍເກີດ ແລະ ບໍ່ໄດ້ປ້ອງກັນ',
    'ဖြစ်ဖူးသော်လည်း မကာကွယ်ခဲ့',
    'Happened with no follow-up',
  );
  String get q2OptCSub => _t(
    'ไม่ได้รับยาหรือดำเนินการใดๆ',
    'ບໍ່ໄດ້ຮັບຢາ ຫຼື ດຳເນີນການໃດ',
    'ဆေးမသောက်/မည်သည့် ဆောင်ရွက်မှုမျှ မပြုလုပ်ခဲ့',
    'No medication or action taken',
  );

  String get q3Text => _t(
    'คุณเคยทำออรัลเซ็กซ์โดยไม่ป้องกันหรือไม่?',
    'ທ່ານເຄີຍມີເພດສຳພັນທາງປາກໂດຍບໍ່ປ້ອງກັນບໍ?',
    'ကာကွယ်မှု မရှိဘဲ နှုတ်ဖျားလိင်ဆောင်ရွက်ဖူးသလား?',
    'Have you ever had unprotected oral sex?',
  );
  String get q3OptALabel => _t('ไม่เคย', 'ບໍ່ເຄີຍ', 'မဖြစ်ဖူးပါ', 'Never');
  String get q3OptASub => _t(
    'ใช้ถุงยางอนามัยทุกครั้งหรือไม่มีแผลในปาก',
    'ໃຊ້ຖົງຢາງທຸກຄັ້ງ ຫຼື ບໍ່ມີບາດແຜໃນປາກ',
    'အမြဲကွန်ဒုံးသုံး သို့မဟုတ် ပါးစပ်အနာ မရှိ',
    'Always used condom or no mouth sores',
  );
  String get q3OptBLabel => _t(
    'เคย แต่ไม่มีการหลั่งในปาก',
    'ເຄີຍ ແຕ່ບໍ່ມີການໝົດໃນປາກ',
    'ဖြစ်ဖူးသော်လည်း ပါးစပ်ထဲ မဝင်',
    'Yes, but no ejaculation in mouth',
  );
  String get q3OptBSub => _t(
    'ไม่มีการสัมผัสของเหลวโดยตรง',
    'ບໍ່ມີການສຳຜັດຂອງແຫຼວໂດຍກົງ',
    'အရည်နှင့် တိုက်ရိုက် မထိ',
    'No direct fluid contact',
  );
  String get q3OptCLabel => _t(
    'เคย และมีการหลั่งหรือแผลในปาก',
    'ເຄີຍ ແລະ ມີການໝົດ ຫຼື ບາດແຜໃນປາກ',
    'ဖြစ်ဖူးပြီး အရည်/ပါးစပ်အနာ ပါဝင်',
    'Yes, with ejaculation or mouth sores',
  );
  String get q3OptCSub => _t(
    'มีการสัมผัสของเหลวหรือเลือดโดยตรง',
    'ມີການສຳຜັດຂອງແຫຼວ ຫຼື ເລືອດ',
    'အရည် သို့မဟုတ် သွေးနှင့် တိုက်ရိုက်ထိ',
    'Direct fluid or blood contact',
  );

  String get q4Text => _t(
    'คุณเคยมีเพศสัมพันธ์กับคู่นอนที่มีความเสี่ยงหรือไม่?',
    'ທ່ານເຄີຍມີເພດສຳພັນກັບຄູ່ນອນທີ່ມີຄວາມສ່ຽງບໍ?',
    'ကူးစက်နိုင်ခြေရှိသည့် လိင်ဖော်နှင့် ဆက်ဆံဖူးသလား?',
    'Have you had sex with a high-risk partner?',
  );
  String get q4OptALabel => _t('ไม่เคย', 'ບໍ່ເຄີຍ', 'မဖြစ်ဖူးပါ', 'Never');
  String get q4OptASub => _t(
    'คู่นอนผลเลือดเป็นลบหรือป้องกันทุกครั้ง',
    'ຄູ່ນອນຜົນເລືອດລົບ ຫຼື ປ້ອງກັນທຸກຄັ້ງ',
    'လိင်ဖော် HIV negative သို့မဟုတ် အမြဲကာကွယ်',
    'Partner is HIV-negative or always protected',
  );
  String get q4OptBLabel =>
      _t('ไม่ทราบสถานะ', 'ບໍ່ຮູ້ສະຖານະ', 'အခြေအနေ မသိ', 'Unknown status');
  String get q4OptBSub => _t(
    'ไม่ทราบผลตรวจหรือสถานะการติดเชื้อของคู่นอน',
    'ບໍ່ຮູ້ຜົນກວດ ຫຼື ສະຖານະຄູ່ນອນ',
    'လိင်ဖော်၏ စစ်ဆေးရလဒ် သို့မဟုတ် ကူးစက်မှုအခြေအနေ မသိ',
    "Don't know partner's test result or HIV status",
  );
  String get q4OptCLabel => _t(
    'เคย และคู่นอนเสี่ยงสูง',
    'ເຄີຍ ແລະ ຄູ່ນອນສ່ຽງສູງ',
    'ဖြစ်ဖူးပြီး လိင်ဖော်မှာ ဆိုးသည်',
    'Yes, with a known high-risk partner',
  );
  String get q4OptCSub => _t(
    'ทราบว่าติดเชื้อหรือไม่ได้รักษา',
    'ຮູ້ວ່າຕິດເຊື້ອ ຫຼື ບໍ່ໄດ້ຮັກສາ',
    'ကူးစက်ခံထားသည် သို့မဟုတ် မကုသကြောင်း သိ',
    'Known HIV+ or untreated',
  );

  String get q5Text => _t(
    'คุณใช้สารเสพติดหรือไม่?',
    'ທ່ານໃຊ້ສານເສບຕິດບໍ?',
    'မူးယစ်ဆေးဝါး သုံးနေသလား?',
    'Do you use drugs?',
  );
  String get q5OptALabel =>
      _t('ไม่ใช้เลย', 'ບໍ່ໃຊ້ເລີຍ', 'လုံးဝ မသုံးပါ', 'None at all');
  String get q5OptASub => _t(
    'ไม่มีการใช้สารเสพติดใดๆ',
    'ບໍ່ມີການໃຊ້ສານເສບຕິດໃດ',
    'မည်သည့် မူးယစ်ဆေးဝါးမျှ မသုံးပါ',
    'No drug use of any kind',
  );
  String get q5OptBLabel => _t(
    'ใช้ชนิดกิน / สูบ / ดม',
    'ໃຊ້ຊະນິດກິນ / ສູບ / ດົມ',
    'သောက် / ဆေးလိပ် / ရှုနံ့',
    'Oral / Smoked / Inhaled',
  );
  String get q5OptBSub => _t(
    'อาจทำให้ขาดสติหรือละเลยการป้องกัน',
    'ອາດເຮັດໃຫ້ຂາດສະຕິ ຫຼື ລະເລີຍການປ້ອງກັນ',
    'သတိမေ့ခြင်း သို့မဟုတ် ကာကွယ်မှုကို လစ်လျူရှုနိုင်',
    'May impair judgment or neglect protection',
  );
  String get q5OptCLabel =>
      _t('ใช้ชนิดฉีด', 'ໃຊ້ຊະນິດສັກ', 'ထိုးဆေးကြိုး ဖြင့်သုံး', 'Injected');
  String get q5OptCSub => _t(
    'และใช้เข็มร่วมกับผู้อื่น',
    'ແລະ ໃຊ້ເຂັມຮ່ວມກັນກັບຄົນອື່ນ',
    'အပ်ကို အခြားသူနှင့် မျှသုံး',
    'And sharing needles with others',
  );

  String get q6Text => _t(
    'คุณเคยเป็นโรคติดต่อทางเพศสัมพันธ์ (STIs) หรือไม่?',
    'ທ່ານເຄີຍເປັນພະຍາດຕິດຕໍ່ທາງເພດສຳພັນ (STIs) ບໍ?',
    'လိင်မှ ကူးစက်ရောဂါ (STIs) ဖြစ်ဖူးသလား?',
    'Have you ever had a sexually transmitted infection (STI)?',
  );
  String get q6OptALabel => _t('ไม่เคย', 'ບໍ່ເຄີຍ', 'မဖြစ်ဖူးပါ', 'Never');
  String get q6OptASub => _t(
    'ไม่มีอาการผิดปกติใดๆ',
    'ບໍ່ມີອາການຜິດປົກກະຕິ',
    'မည်သည့် ဝေဒနာမျှ မရှိ',
    'No abnormal symptoms',
  );
  String get q6OptBLabel => _t(
    'เคย แต่รักษาหายขาดแล้ว',
    'ເຄີຍ ແຕ່ຮັກສາຫາຍຂາດແລ້ວ',
    'ဖြစ်ဖူးသော်လည်း ပြည့်ဝစွာ ကုသပြီး',
    'Yes, but fully treated',
  );
  String get q6OptBSub => _t(
    'ได้รับการรักษาจนครบถ้วน',
    'ໄດ້ຮັບການຮັກສາຄົບຖ້ວນ',
    'ပြည့်ဝသောကုသမှု ခံယူပြီး',
    'Completed full treatment',
  );
  String get q6OptCLabel => _t(
    'มีอาการอยู่และยังไม่รักษา',
    'ມີອາການຢູ່ ແລະ ຍັງບໍ່ຮັກສາ',
    'လက်ရှိ ဝေဒနာရှိ၍ မကုသသေး',
    'Currently symptomatic, untreated',
  );
  String get q6OptCSub => _t(
    'ปัจจุบันยังมีอาการผิดปกติ',
    'ປັດຈຸບັນຍັງມີອາການຜິດປົກກະຕິ',
    'ယနေ့ ဝေဒနာများ ရှိနေဆဲ',
    'Still experiencing abnormal symptoms',
  );

  // ─── HIV Assessment – Risk Results ───────────────────────────────────────
  String get riskLowAdvice => _t(
    'ควรรักษามาตรฐานการป้องกันอย่างต่อเนื่อง และแนะนำให้ตรวจเลือดทุก 6 เดือนเพื่อสุขภาวะที่ยั่งยืน',
    'ຄວນຮັກສາມາດຕະຖານການປ້ອງກັນ ແລະ ແນະນຳໃຫ້ກວດເລືອດທຸກ 6 ເດືອນ',
    'ကာကွယ်မှုစံနှုန်းကို ဆက်ကာကွယ်ပါ သွေးစစ်ဆေး ၆ လတစ်ကြိမ် ပြုလုပ်ရန် အကြံပြုသည်',
    'Maintain your prevention standards and get a blood test every 6 months for sustained health',
  );
  List<String> get riskLowPills => [
    _t(
      'ตรวจเลือดทุก 6 เดือน',
      'ກວດເລືອດທຸກ 6 ເດືອນ',
      'သွေးစစ် ၆ လတစ်ကြိမ်',
      'Blood test every 6 months',
    ),
    _t(
      'รักษามาตรฐานต่อไป',
      'ຮັກສາມາດຕະຖານ',
      'ကာကွယ်မှုစံနှုန်းထိန်း',
      'Keep up your prevention standards',
    ),
  ];
  String get riskMediumAdvice => _t(
    'เริ่มมีความเสี่ยงในการรับเชื้อ แนะนำให้ปรึกษาแพทย์เพื่อพิจารณาการใช้ยา PrEP และตรวจหาเชื้อทุก 3 เดือน',
    'ເລີ່ມມີຄວາມສ່ຽງ ແນະນຳໃຫ້ປຶກສາໝໍ ພິຈາລະນາ PrEP ແລະ ກວດຫາເຊື້ອທຸກ 3 ເດືອນ',
    'ကူးစက်ခံနိုင်ခြေ စတင်ရှိသည် ဆရာဝန်ပြပြီး PrEP ဆေးစဉ်းစားကာ ၃ လတစ်ကြိမ် စစ်ဆေးပါ',
    'Some infection risk detected. Consult a doctor about PrEP and get tested every 3 months',
  );
  List<String> get riskMediumPills => [
    _t(
      'ปรึกษาแพทย์เรื่อง PrEP',
      'ປຶກສາໝໍ PrEP',
      'ဆရာဝန်ပြ PrEP',
      'Consult doctor about PrEP',
    ),
    _t(
      'ตรวจหาเชื้อทุก 3 เดือน',
      'ກວດຫາເຊື້ອທຸກ 3 ເດືອນ',
      '၃ လတစ်ကြိမ် စစ်ဆေး',
      'Get tested every 3 months',
    ),
  ];
  String get riskHighAdvice => _t(
    'มีความเสี่ยงสูงในการรับเชื้อ ควรพบแพทย์เพื่อตรวจเลือดโดยเร็ว หรือหากเพิ่งเสี่ยงมาไม่เกิน 72 ชั่วโมง ให้ขอรับยา PEP ทันที',
    'ມີຄວາມສ່ຽງສູງ ຄວນພົບໝໍເພື່ອກວດເລືອດ ຫຼື ຮັບຢາ PEP ພາຍໃນ 72 ຊ.ມ.',
    'ကူးစက်ခံနိုင်ခြေ မြင့်မားသည် ဆရာဝန်နှင့် ချက်ချင်းတွေ့ပြီး သွေးစစ်ပါ သို့မဟုတ် ၇၂ နာရီအတွင်း PEP ဆေးတောင်းပါ',
    'High infection risk. See a doctor for a blood test soon, or if exposed within 72 hours, request PEP immediately',
  );
  List<String> get riskHighPills => [
    _t(
      'พบแพทย์เพื่อตรวจเลือด',
      'ພົບໝໍກວດເລືອດ',
      'ဆရာဝန်ပြ သွေးစစ်',
      'See a doctor for blood test',
    ),
    _t(
      'ขอรับยา PEP ภายใน 72 ชม.',
      'ຮັບຢາ PEP ພາຍໃນ 72 ຊ.ມ.',
      'PEP ၇၂ နာရီအတွင်း',
      'Get PEP within 72 hours',
    ),
  ];

  // ─── HIV Assessment – Knowledge Box ──────────────────────────────────────
  String get prepMedDesc => _t(
    'ยาสำหรับรับประทานก่อนสัมผัสความเสี่ยง ช่วยป้องกันการติดเชื้อ HIV ได้เกือบ 100%',
    'ຢາສຳລັບກິນກ່ອນສຳຜັດຄວາມສ່ຽງ ປ້ອງກັນ HIV ໄດ້ເກືອບ 100%',
    'အန္တရာယ်ထိတ်ဆိုင်မတိုင်မီ သောက်ရမည့် ဆေး HIV ကူးစက်မှုကို ၁၀၀% နီးပါး ကာကွယ်',
    'Taken before exposure, PrEP helps prevent HIV infection by nearly 100%',
  );
  String get pepMedDesc => _t(
    'ยาป้องกันฉุกเฉิน ต้องรับประทานให้เร็วที่สุดภายใน 72 ชั่วโมง หลังสัมผัสความเสี่ยง เพื่อยับยั้งการติดเชื้อเข้าสู่ร่างกาย',
    'ຢາປ້ອງກັນສຸກເສີນ ຕ້ອງກິນໄວທີ່ສຸດພາຍໃນ 72 ຊ.ມ. ຫຼັງສຳຜັດຄວາມສ່ຽງ ເພື່ອຢຸດການຕິດເຊື້ອ',
    'အရေးပေါ် ကာကွယ်ဆေး ထိတ်ဆိုင်ပြီး ၇၂ နာရီအတွင်း အမြန်ဆုံးသောက် ကူးစက်မှု တားဆီးရန်',
    'Emergency prevention medication. Must be taken as soon as possible within 72 hours after exposure to stop infection',
  );
  String get hivScreeningNote => _t(
    'นอกจากการตรวจ HIV ควรตรวจคัดกรองมะเร็งปากมดลูกและซิฟิลิสเป็นประจำ เนื่องจากรอยโรคเหล่านี้ส่งผลให้เชื้อ HIV เข้าสู่ร่างกายได้ง่ายขึ้นหากเกิดบาดแผล',
    'ນອກຈາກກວດ HIV ຄວນກວດຄັດກອງມະເຮັງປາກມົດລູກ ແລະ ຊິຟິລິດເປັນປະຈຳ ເພາະຮອຍໂລກເຫຼົ່ານີ້ເຮັດໃຫ້ HIV ເຂົ້າໄດ້ງ່າຍ',
    'HIV စစ်ဆေးရုံမကဘဲ သားအိမ်ဦးကင်ဆာနှင့် ဆစ်ဖိုင်လစ် ကင်းစစ်ရန်လည်း အကြံပြု ကြောင်းပြပြင်ရှိပါက HIV ပိုလွယ်ကူစွာ ဝင်ရောက်နိုင်',
    'In addition to HIV testing, regular screening for cervical cancer and syphilis is recommended, as sores from these conditions make HIV infection easier',
  );

  // ─── Unread badge ─────────────────────────────────────────────────────────
  String unreadCount(int n) => _t('$n ใหม่', '$n ໃໝ່', '$n အသစ်', '$n new');

  // ─── Emergency / Shortcut ────────────────────────────────────────────────
  String get emergencyPressed =>
      _t('"1669" ถูกกด', '"1669" ຖືກກົດ', '"1669" နှိပ်ပြီး', '"1669" tapped');
  String shortcutPressed(String label) => _t(
    '"$label" ถูกกด',
    '"$label" ຖືກກົດ',
    '"$label" နှိပ်ပြီး',
    '"$label" tapped',
  );

  // ─── QR Scan ──────────────────────────────────────────────────────────────
  String get pickupSectionTitle => _t(
    'สถานบริการ วันที่และเวลารับ',
    'ສູນບໍລິການ ວັນທີ ແລະ ເວລາຮັບ',
    'ဝန်ဆောင်မှုစင်တာ ထုတ်ယူမည့်ရက်နှင့်အချိန်',
    'Service Center, Pickup Date and Time',
  );
  String get qrNotYoursTitle => _t(
    'QR Code ไม่ใช่ของคุณ',
    'QR Code ບໍ່ແມ່ນຂອງທ່ານ',
    'QR Code သင်၏ မဟုတ်ပါ',
    'QR Code Not Yours',
  );
  String get qrNotYoursBody => _t(
    'QR Code นี้เป็นของผู้ใช้งานท่านอื่น ไม่สามารถใช้งานได้',
    'QR Code ນີ້ເປັນຂອງຜູ້ໃຊ້ອື່ນ ບໍ່ສາມາດໃຊ້ໄດ້',
    'ဤ QR Code သည် အခြားသုံးစွဲသူ၏ ဖြစ်သည် အသုံးမပြုနိုင်ပါ',
    'This QR Code belongs to another user and cannot be used',
  );
  String get qrInvalidTitle => _t(
    'QR Code ไม่ถูกต้อง',
    'QR Code ບໍ່ຖືກຕ້ອງ',
    'QR Code မမှန်ကန်ပါ',
    'Invalid QR Code',
  );

  // ─── Doctor Booking ───────────────────────────────────────────────────────
  String get bookingInstruction1 => _t(
    'งดอาหาร 4–6 ชม. ก่อนตรวจเลือด (ถ้ามี)',
    'ງົດອາຫານ 4–6 ຊ.ມ. ກ່ອນກວດເລືອດ (ຖ້າມີ)',
    'သွေးစစ်ဆေးမတိုင်မီ ၄–၆ နာရီ ဆာဆာနေပါ (ရှိပါက)',
    'Fast for 4–6 hrs before blood test (if applicable)',
  );
  String get bookingInstruction2 => _t(
    'นำบัตรประชาชนมาด้วย',
    'ນໍາບັດປະຊາຊົນມາດ້ວຍ',
    'နိုင်ငံသားကတ်ယူလာပါ',
    'Bring your ID card',
  );
  String get bookingInstruction3 => _t(
    'มาก่อนเวลานัด 15 นาที',
    'ມາກ່ອນເວລານັດ 15 ນາທີ',
    'ချိန်းဆိုချိန်ထက် မိနစ် ၁၅ စောပါ',
    'Arrive 15 minutes before your appointment',
  );

  // ─── Recovery ─────────────────────────────────────────────────────────────
  String get recoveryCodeInvalid => _t(
    'ชื่อผู้ใช้งานหรือรหัสกู้คืนไม่ถูกต้อง',
    'ຊື່ຜູ້ໃຊ້ ຫຼື ລະຫັດກູ້ຄືນ ບໍ່ຖືກຕ້ອງ',
    'အသုံးပြုသူ အမည် သို့မဟုတ် ပြန်လည်ရယူကုဒ် မှားနေသည်',
    'Username or recovery code is incorrect',
  );

  // ─── Campaign Banner ──────────────────────────────────────────────────────
  String get campaignAssessRisk => _t(
    'ทำแบบประเมินความเสี่ยง',
    'ທຳແບບປະເມີນຄວາມສ່ຽງ',
    'အန္တရာယ်အကဲဖြတ်စစ်ဆေးပါ',
    'Take Risk Assessment',
  );
  String get campaignHIVFree => _t(
    'การติดเชื้อ HIV ฟรี!',
    'ການຕິດເຊື້ອ HIV ຟຣີ!',
    'HIV စစ်ဆေးခ အခမဲ့!',
    'Free HIV Screening!',
  );
  String get campaignRegisterTitle => _t(
    'สร้างบัญชีใหม่ฟรี!',
    'ສ້າງບັນຊີໃໝ່ຟຣີ!',
    'အခမဲ့ အကောင့်အသစ်ဖွင့်ပါ!',
    'Register for Free!',
  );
  String get campaignRegisterSubtitle => _t(
    'เข้าถึงบริการ MyCareNK ได้เลย',
    'ເຂົ້າເຖິງບໍລິການ MyCareNK ໄດ້ທັນທີ',
    'MyCareNK ဝန်ဆောင်မှုများ ချက်ချင်းရရှိသည်',
    'Access MyCareNK services now',
  );

  // ─── Privacy Policy ───────────────────────────────────────────────────────
  String get privacyPolicyIntro => _t(
    'สำนักงานสาธารณสุขจังหวัดหนองคาย ในฐานะผู้ให้บริการแอปพลิเคชัน MyCareNK ตระหนักถึงความสำคัญของความเป็นส่วนตัวและให้คำมั่นว่าจะปกป้องข้อมูลส่วนบุคคลของท่านด้วยความรับผิดชอบสูงสุด ภายใต้พระราชบัญญัติคุ้มครองข้อมูลส่วนบุคคล พ.ศ. 2562',
    'ສໍານັກງານສາທາລະນະສຸກຈັງຫວັດ Nong Khai ໃນຖານະຜູ້ໃຫ້ບໍລິການແອັບ MyCareNK ຕະໜັກຮູ້ເຖິງຄວາມສໍາຄັນຂອງຄວາມເປັນສ່ວນຕົວ ແລະ ໃຫ້ຄໍາໝັ້ນວ່າຈະປົກປ້ອງຂໍ້ມູນສ່ວນຕົວຂອງທ່ານດ້ວຍຄວາມຮັບຜິດຊອບສູງສຸດ',
    'Nong Khai ပြည်နယ်ကျန်းမာရေးဦးစီးဌာနသည် MyCareNK application ၏ ဝန်ဆောင်မှုပေးသူအဖြစ် သင်၏ ကိုယ်ရေးကိုယ်တာ အချက်အလက်များကို အကောင်းဆုံး ကာကွယ်ရန် ကတိပြုပါသည်',
    'Nong Khai Provincial Health Office, as the provider of MyCareNK, recognizes the importance of privacy and commits to protecting your personal information with the highest responsibility under the Personal Data Protection Act B.E. 2562',
  );

  String get privacySection1Title => _t(
    'ข้อมูลที่เราเก็บรวบรวม',
    'ຂໍ້ມູນທີ່ເຮົາເກັບກໍາ',
    'ကျွန်ုပ်တို့ စုဆောင်းသော အချက်အလက်များ',
    'Information We Collect',
  );
  String get privacySection1Body => _t(
    'เมื่อท่านสร้างบัญชีและใช้งาน MyCareNK เราจะเก็บรวบรวมเฉพาะข้อมูลที่จำเป็นต่อการให้บริการเท่านั้น ได้แก่ ชื่อผู้ใช้งาน เพศ วันเกิด และสัญชาติที่ท่านกรอกในขั้นตอนการสมัคร รวมถึงข้อมูลการใช้บริการ เช่น ประวัติคำขอรับอุปกรณ์ป้องกัน สถานที่รับบริการ วันเวลานัดหมาย และข้อความที่ท่านฝากไว้ นอกจากนี้ ท่านอาจให้หมายเลขโทรศัพท์ไว้โดยสมัครใจ เพื่อให้เจ้าหน้าที่สามารถติดต่อนัดรับอุปกรณ์ป้องกัน นัดพบแพทย์ หรือในกรณีที่มีเหตุจำเป็นเร่งด่วน\n\nทั้งนี้ เราไม่เก็บชื่อ-นามสกุลจริง หมายเลขบัตรประชาชน หรือข้อมูลที่สามารถระบุตัวตนของท่านได้โดยตรงแต่อย่างใด',
    'ເມື່ອທ່ານສ້າງບັນຊີ ແລະ ນໍາໃຊ້ MyCareNK ເຮົາຈະເກັບກໍາສະເພາະຂໍ້ມູນທີ່ຈໍາເປັນຕໍ່ການໃຫ້ບໍລິການເທົ່ານັ້ນ ໄດ້ແກ່ ຊື່ຜູ້ໃຊ້ ເພດ ວັນເດືອນປີເກີດ ແລະ ສັນຊາດ ລວມທັງຂໍ້ມູນການໃຊ້ບໍລິການ ເຊັ່ນ ປະຫວັດຄໍາຂໍ ສະຖານທີ່ ວັນທີ ແລະ ເວລານັດໝາຍ ຂໍ້ຄວາມທີ່ທ່ານຝາກໄວ້\n\nທັງນີ້ ເຮົາບໍ່ໄດ້ເກັບຊື່-ນາມສະກຸນຈິງ ເລກບັດປະຊາຊົນ ຫຼື ຂໍ້ມູນທີ່ສາມາດລະບຸຕົວຕົນຂອງທ່ານໄດ້ໂດຍກົງ',
    'သင် MyCareNK တွင် အကောင့်ဖန်တီးပြီး အသုံးပြုသောအခါ ဝန်ဆောင်မှုအတွက် လိုအပ်သော အချက်အလက်များကိုသာ စုဆောင်းပါသည် ၎င်းတို့မှာ အသုံးပြုသူအမည် လိင် မွေးသက္ကရာဇ် နှင့် နိုင်ငံသား ဝန်ဆောင်မှုမှတ်တမ်းများ ဆေးရုံချိန်းဆိုချက်များ နှင့် သင်ချန်ထားသော မက်ဆေ့ချ်များ ဖြစ်သည်\n\nကျွန်ုပ်တို့သည် အမည်၊ နိုင်ငံသားကတ်နံပါတ် သို့မဟုတ် တိုက်ရိုက်သတ်မှတ်နိုင်သော အချက်အလက်များကို မစုဆောင်းပါ',
    'When you create an account and use MyCareNK, we collect only the information necessary to provide the service: username, gender, date of birth, and nationality entered during registration, along with service usage data such as request history, service center, appointment dates and times, and any messages you leave. You may also voluntarily provide a phone number so staff can contact you.\n\nWe do not collect your full name, ID card number, or any information that can directly identify you.',
  );

  String get privacySection2Title => _t(
    'เราใช้ข้อมูลของคุณทำอะไรบ้าง',
    'ເຮົາໃຊ້ຂໍ້ມູນຂອງທ່ານເພື່ອຫຍັງ',
    'သင်၏ အချက်အလက်ကို ဘာအတွက် အသုံးပြုသနည်း',
    'How We Use Your Information',
  );
  String get privacySection2Body => _t(
    'ข้อมูลที่เก็บรวบรวมจะถูกนำไปใช้เพื่อดำเนินการตามคำขอของท่าน ประสานงานกับเจ้าหน้าที่สถานบริการที่ท่านเลือก และติดตามสิทธิ์การรับบริการรายเดือนของท่านให้เป็นไปตามเกณฑ์ที่กำหนด นอกจากนี้ เราอาจนำข้อมูลในภาพรวม ซึ่งไม่สามารถระบุตัวตนของผู้ใช้รายใดได้ ไปใช้ประกอบการวางแผนด้านสาธารณสุขในระดับจังหวัด\n\nเราขอยืนยันว่าจะไม่นำข้อมูลของท่านไปขาย แลกเปลี่ยน หรือเปิดเผยต่อบุคคลหรือองค์กรภายนอกเพื่อวัตถุประสงค์ทางการค้าหรือวัตถุประสงค์อื่นใดที่นอกเหนือจากที่ระบุไว้ในนโยบายฉบับนี้',
    'ຂໍ້ມູນທີ່ເກັບກໍາຈະຖືກນໍາໄປໃຊ້ເພື່ອດໍາເນີນການຕາມຄໍາຂໍຂອງທ່ານ ປະສານງານກັບເຈົ້າໜ້າທີ່ສູນໃຫ້ບໍລິການ ແລະ ຕິດຕາມສິດທິ໌ການຮັບບໍລິການລາຍເດືອນ ນອກຈາກນີ້ ເຮົາອາດຈະນໍາຂໍ້ມູນໃນພາບລວມ ທີ່ບໍ່ສາມາດລະບຸຕົວຕົນ ໄປໃຊ້ວາງແຜນດ້ານສາທາລະນະສຸກ\n\nເຮົາຢືນຢັນວ່າຈະບໍ່ຂາຍ ແລກປ່ຽນ ຫຼື ເປີດເຜີຍຂໍ້ມູນຂອງທ່ານໃຫ້ກັບບຸກຄົນ ຫຼື ອົງກອນພາຍນອກ',
    'စုဆောင်းသော အချက်အလက်များကို သင်၏ တောင်းဆိုချက်များကို ဆောင်ရွက်ရန် ဝန်ဆောင်မှုဌာနနှင့် ညှိနှိုင်းရန် နှင့် လစဉ်ကိုတာ စစ်ဆေးရန် အသုံးပြုပါသည် ကိုယ်ပိုင်မသတ်မှတ်နိုင်သော ပေါင်းစပ်ထားသော အချက်အလက်များကို ကျန်းမာရေး စီမံကိန်းချရာတွင် အသုံးပြုနိုင်သည်\n\nကျွန်ုပ်တို့သည် သင်၏ အချက်အလက်များကို မည်သူ့မှ မရောင်း မဖလှယ် မဖော်ပြပါ',
    'Collected information is used to process your requests, coordinate with the service center you selected, and track your monthly service quota. Aggregated, non-identifiable data may be used for provincial public health planning.\n\nWe will not sell, exchange, or disclose your information to any external party for commercial or any other purpose beyond what is stated in this policy.',
  );

  String get privacySection3Title => _t(
    'การเก็บรักษาความลับ',
    'ການຮັກສາຄວາມລັບ',
    'လျှို့ဝှက်ရေး ထိန်းသိမ်းခြင်း',
    'Confidentiality',
  );
  String get privacySection3Body => _t(
    'เราจำกัดการเข้าถึงข้อมูลของท่านเฉพาะเจ้าหน้าที่ของสถานบริการที่ท่านเลือกและผู้ดูแลระบบที่ได้รับอนุญาตอย่างเป็นทางการเท่านั้น โดยเจ้าหน้าที่จะสามารถมองเห็นได้เพียงข้อมูลที่จำเป็นต่อการจัดเตรียมและส่งมอบบริการให้ท่าน ได้แก่ ชื่อผู้ใช้งาน รายการและจำนวนอุปกรณ์ที่ขอ วันเวลานัดหมาย และสถานะคำขอเท่านั้น\n\nข้อมูลของท่านจะถูกเก็บรักษาตลอดระยะเวลาที่บัญชียังคงเปิดใช้งาน และจะถูกดำเนินการตามที่ท่านร้องขอในกรณีที่ต้องการลบหรือโอนย้ายข้อมูล',
    'ເຮົາຈໍາກັດການເຂົ້າເຖິງຂໍ້ມູນຂອງທ່ານສະເພາະເຈົ້າໜ້າທີ່ທີ່ໄດ້ຮັບອະນຸຍາດເທົ່ານັ້ນ ໂດຍເຈົ້າໜ້າທີ່ຈະເຫັນໄດ້ສະເພາະຂໍ້ມູນທີ່ຈໍາເປັນຕໍ່ການຈັດກຽມ ແລະ ສົ່ງມອບບໍລິການ ໄດ້ແກ່ ຊື່ຜູ້ໃຊ້ ລາຍການ ແລະ ຈໍານວນ ວັນທີ ແລະ ເວລານັດ ແລະ ສະຖານະຄໍາຂໍ\n\nຂໍ້ມູນຂອງທ່ານຈະຖືກເກັບຮັກສາຕະຫຼອດລະຫວ່າງທີ່ບັນຊີຍັງໃຊ້ງານຢູ່ ແລະ ຈະດໍາເນີນການຕາມທີ່ທ່ານຮ້ອງຂໍ',
    'သင်၏ အချက်အလက်များကို ခွင့်ပြုထားသော ဝန်ထမ်းများသာ ဝင်ကြည့်နိုင်သည် ၎င်းတို့သည် ဝန်ဆောင်မှုပေးရန် လိုအပ်သော အချက်အလက်များကိုသာ မြင်နိုင်သည် ၎င်းတို့မှာ အသုံးပြုသူအမည် တောင်းဆိုသော ပစ္စည်းများ ချိန်းဆိုချက် ရက်နှင့်အချိန် နှင့် တောင်းဆိုချက်အခြေအနေ တို့ဖြစ်သည်\n\nသင်၏ အချက်အလက်များကို အကောင့်ဖွင့်ထားသမျှ သိမ်းဆည်းထားပြီး သင်တောင်းဆိုပါက ဖျက်သိမ်းပေးမည် ဖြစ်သည်',
    'We limit access to your information to authorized staff at your chosen service center and system administrators only. Staff can view only the information necessary to prepare and deliver services: username, items requested, appointment date and time, and request status.\n\nYour data is retained while your account is active and will be handled as you request if you wish to delete or transfer it.',
  );

  String get privacySection4Title =>
      _t('ความปลอดภัย', 'ຄວາມປອດໄພ', 'လုံခြုံရေး', 'Security');
  String get privacySection4Body => _t(
    'เราใช้มาตรการรักษาความปลอดภัยในระดับมาตรฐานสากลเพื่อคุ้มครองข้อมูลของท่านจากการเข้าถึง การแก้ไข หรือการเปิดเผยโดยไม่ได้รับอนุญาต ข้อมูลทุกอย่างถูกส่งผ่านช่องทางที่เข้ารหัสอย่างปลอดภัย และรหัสผ่านของท่านจะไม่ถูกจัดเก็บในรูปแบบที่อ่านออกได้ในระบบของเราแต่อย่างใด นอกจากนี้ ระบบยังถูกออกแบบให้แต่ละบัญชีสามารถเข้าถึงได้เฉพาะข้อมูลของตนเองเท่านั้น',
    'ເຮົາໃຊ້ມາດຕະການຮັກສາຄວາມປອດໄພລະດັບສາກົນ ເພື່ອປົກປ້ອງຂໍ້ມູນຂອງທ່ານຈາກການເຂົ້າເຖິງ ການແກ້ໄຂ ຫຼື ການເປີດເຜີຍໂດຍບໍ່ໄດ້ຮັບອະນຸຍາດ ຂໍ້ມູນທຸກຢ່າງຖືກສົ່ງຜ່ານຊ່ອງທາງທີ່ເຂົ້າລະຫັດ ແລະ ລະຫັດຜ່ານຂອງທ່ານຈະບໍ່ຖືກເກັບໃນຮູບແບບທີ່ອ່ານໄດ້ ນອກຈາກນີ້ ລະບົບຍັງຖືກອອກແບບໃຫ້ແຕ່ລະບັນຊີສາມາດເຂົ້າເຖິງໄດ້ສະເພາະຂໍ້ມູນຂອງຕົນເອງ',
    'ကျွန်ုပ်တို့သည် ခွင့်မပြုဘဲ ဝင်ရောက်ခြင်း ပြင်ဆင်ခြင်း သို့မဟုတ် ဖော်ပြခြင်းမှ ကာကွယ်ရန် နိုင်ငံတကာ လုံခြုံရေးစံနှုန်းများ အသုံးပြုပါသည် အချက်အလက်အားလုံးကို ဝှက်ပြီး ပို့ဆောင်ပြီး သင်၏ စကားဝှက်ကို ဖတ်ရနိုင်သောပုံစံဖြင့် မသိမ်းဆည်းပါ ကိုယ်စီကောင့်တိုင်း ကိုယ်ပိုင်အချက်အလက်သာ ဝင်ရောက်ကြည့်ရှုနိုင်သည်',
    'We use international-standard security measures to protect your information from unauthorized access, modification, or disclosure. All data is transmitted through encrypted channels, your password is never stored in readable form, and the system ensures each account can only access its own data.',
  );

  String get privacyContactText => _t(
    'หากท่านมีข้อสงสัยหรือต้องการใช้สิทธิ์ตามกฎหมาย ไม่ว่าจะเป็นการขอเข้าถึง แก้ไข ลบ หรือโอนย้ายข้อมูลส่วนบุคคลของท่าน กรุณาติดต่อ นายสันติ ธรรมวิเศษ สำนักงานสาธารณสุขจังหวัดหนองคาย โทร. 084-686-6406',
    'ຫາກທ່ານມີຂໍ້ສົງໄສ ຫຼື ຕ້ອງການໃຊ້ສິດທິ໌ຕາມກົດໝາຍ ໄດ້ແກ່ ການຂໍເຂົ້າເຖິງ ແກ້ໄຂ ລົບ ຫຼື ໂອນຍ້າຍຂໍ້ມູນ ກະລຸນາຕິດຕໍ່ ທ່ານ ສັນຕິ ທໍາມະວິເສດ ສໍານັກງານສາທາລະນະສຸກຈັງຫວັດ Nong Khai ໂທ. 084-686-6406',
    'သင်မေးစရာရှိပါက သို့မဟုတ် ဥပဒေအရ အချက်အလက် ဝင်ကြည့်ရန် ပြင်ဆင်ရန် ဖျက်ရန် သို့မဟုတ် လွှဲပြောင်းရန် ခွင့်ပြုချက်တောင်းလိုပါက ဆက်သွယ်ပါ — Santi Thammawisut ၊ Nong Khai ပြည်နယ်ကျန်းမာရေးဦးစီးဌာန ဖုန်း 084-686-6406',
    'If you have any questions or wish to exercise your legal rights — including access, correction, deletion, or transfer of your personal data — please contact Santi Thammawisut, Nong Khai Provincial Health Office. Tel. 084-686-6406',
  );

  // ─── Update Dialog / Settings ─────────────────────────────────────────────
  String get downloadingProgress => _t(
    'กำลังดาวน์โหลด',
    'ກຳລັງດາວໂຫລດ',
    'ဒေါင်းလုဒ်လုပ်နေသည်',
    'Downloading',
  );
  String get checkForUpdate => _t(
    'ตรวจสอบอัปเดต',
    'ກວດສອບການອັບເດດ',
    'အပ်ဒိတ်စစ်ဆေး',
    'Check for Updates',
  );
  String get updateCheckFailed => _t(
    'ไม่สามารถตรวจสอบอัปเดตได้',
    'ບໍ່ສາມາດກວດສອບການອັບເດດໄດ້',
    'အပ်ဒိတ်စစ်ဆေး၍ မရပါ',
    'Unable to check for updates',
  );
  String get updateAlreadyLatest => _t(
    'แอปเป็นเวอร์ชันล่าสุดแล้ว',
    'ແອັບເປັນເວີຊັ່ນຫຼ້າສຸດແລ້ວ',
    'အက်ပ် နောက်ဆုံးဗားရှင်း ဖြစ်ပြီးပါပြီ',
    'App is up to date',
  );
  String get updateAvailable => _t(
    'มีเวอร์ชันใหม่!',
    'ມີເວີຊັ່ນໃໝ່!',
    'ဗားရှင်းသစ် ရှိပါသည်!',
    'New Version Available!',
  );
  String get updateDownloadFailed => _t(
    'ดาวน์โหลดล้มเหลว กรุณาลองใหม่',
    'ດາວໂຫລດລົ້ມເຫລວ ລອງໃໝ່',
    'ဒေါင်းလုဒ် မအောင်မြင်ပါ ထပ်ကြိုးစားပါ',
    'Download failed. Please try again',
  );
  String get updateCannotOpenFolder => _t(
    'ไม่สามารถเปิดโฟลเดอร์ดาวน์โหลดได้',
    'ບໍ່ສາມາດເປີດໂຟນເດີດາວໂຫລດໄດ້',
    'ဒေါင်းလုဒ်ဖိုင်တွဲ မဖွင့်နိုင်ပါ',
    'Cannot open downloads folder',
  );
  String get updateDownloadComplete => _t(
    'ดาวน์โหลดเสร็จสิ้น กด "ติดตั้ง" เพื่อเปิดโฟลเดอร์ดาวน์โหลด',
    'ດາວໂຫລດສຳເລັດ ກົດ "ຕິດຕັ້ງ" ເພື່ອເປີດໂຟນເດີ',
    'ဒေါင်းလုဒ်ပြီးပြီ "ติดตั้ง" နှိပ်ပြီး ဒေါင်းလုဒ်ဖိုင်တွဲဖွင့်ပါ',
    'Download complete. Tap "Install" to open downloads folder',
  );
  String get updateInstall => _t('ติดตั้ง', 'ຕິດຕັ້ງ', 'ထည့်သွင်း', 'Install');
  String get updateLater => _t('ภายหลัง', 'ທີ່ຫຼັງ', 'နောက်မှ', 'Later');
  String get updateBtn => _t('อัปเดต', 'ອັບເດດ', 'အပ်ဒိတ်', 'Update');
  String get releaseNotesAdd => _t('เพิ่ม', 'ເພີ່ມ', 'ထည့်သည်', 'Added');
  String get releaseNotesFix => _t('แก้ไข', 'ແກ້ໄຂ', 'ပြင်ဆင်သည်', 'Fixed');
  String get releaseNotesImprove =>
      _t('ปรับปรุง', 'ປັບປຸງ', 'တိုးတက်သည်', 'Improved');
  String get releaseNotesOther => _t('อื่น ๆ', 'ອື່ນໆ', 'အခြား', 'Others');

  // ─── Register Steps ───────────────────────────────────────────────────────
  String get registerStep1 => _t(
    'ชื่อผู้ใช้งานและรหัสผ่าน',
    'ຊື່ຜູ້ໃຊ້ແລະລະຫັດຜ່ານ',
    'အသုံးပြုသူအမည်နှင့်စကားဝှက်',
    'Username & Password',
  );
  String get registerStep2 => _t(
    'ข้อมูลส่วนตัว',
    'ຂໍ້ມູນສ່ວນຕົວ',
    'ကိုယ်ရေးအချက်အလက်',
    'Personal Info',
  );
  String get registerStep3 =>
      _t('ข้อมูลติดต่อ', 'ຂໍ້ມູນຕິດຕໍ່', 'ဆက်သွယ်ရေးအချက်အလက်', 'Contact Info');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['th', 'lo', 'my', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final loc = AppLocalizations(locale);
    AppLocalizations._current = loc;
    return loc;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
