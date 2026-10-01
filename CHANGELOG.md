# Changelog

كل تغيير على المشروع. التنسيق: [Keep a Changelog](https://keepachangelog.com/)،
و[الإصدار الدلالي](https://semver.org/lang/ar/).

## [Unreleased]

### Added
- حوار تأكيد عند تسجيل الخروج داخل Settings.
- Status chips بألوان Material 3 وترجمة عربية (قيد الانتظار، مُسنَد، في الطريق،
  مكتمل، ملغي).
- DetailSheet لعرض السجل الكامل مع أزرار إجراء POST على
  `/<resource>/<id>/<action>/`.
- LiveTrackingPage: خريطة OpenStreetMap بدون API key، تتبع لحظي لكل 10 ثوانٍ.

### Fixed
- CI: مجلدا الأصول الفارغان ما كانوا يُتتبعون من git → أضيف `.gitkeep`.
- CI: تفعيل Core Library Desugaring لـ `flutter_local_notifications`.

## [1.0.0+1] — 2026-10-01

### Added
- **المشروع الأساسي:** Flutter 3.47.5 بـ Riverpod + Dio + Material 3 + RTL.
- **المصادقة:** تسجيل دخول SimpleJWT مع تجديد access token تلقائي عند 401.
- **التخزين الآمن:** EncryptedSharedPreferences (Android) و Keychain (iOS).
- **بنية الأدوار:** تطبيق واحد يعرض واجهة السائق / العميل / المدير حسب حقل
  `role` من `/auth/me/`.
- **السائق:**
  - تبويبات: رحلاتي، الطلبات، الأرباح، حسابي.
  - أزرار الحالة: ابدأ / في الطريق / تم التسليم / قبول / رفض.
  - `LocationService`: بث GPS كل 25 متر إلى `/drivers/me/location/`.
  - `DriverStatusBar`: زر متصل/غير متصل أعلى الواجهة.
- **العميل:**
  - تبويبات: طلباتي، الفواتير، التتبّع، حسابي.
  - `CreateOrderPage`: نموذج طلب جديد مع تحقق + ترجمة أخطاء DRF.
  - FAB لفتح خريطة التتبّع.
- **المدير:**
  - تبويبات: ملخص، الطلبات، السائقون، العملاء، حسابي.
  - أزرار: إسناد / إلغاء الطلب / تفعيل / إيقاف السائق.
- **الإعدادات:**
  - صفحة حساب للتعديل (`PATCH /auth/me/`).
  - عرض نسخة التطبيق من `package_info_plus`.
- **البنية التحتية:**
  - `Dockerfile` + `docker-compose.yml` + `nginx.conf` للنشر على الـ web preview.
  - GitHub Actions workflow `.github/workflows/build-android.yml` يبني AAB + APK
    وينشر Artifacts.
  - `codemagic.yaml` بـ workflows لـ Android (Linux) و iOS (mac_mini_m2) مع رفع
    تلقائي لـ TestFlight.
- **التوثيق:**
  - `README.md`, `BUILD_AND_RELEASE.md`, `DEPLOYMENT.md`, `DEVELOPMENT.md`,
    `API_DOCUMENTATION.md`.
  - `docs/DJANGO_BACKEND_STARTER.md`: مخطط Django 5 + DRF كامل.
  - `docs/KEYSTORE_HANDOVER.md`: دليل توليد وحفظ مفتاح التوقيع.
  - `docs/PLAY_STORE_LISTING.md`: نصوص وأصول القائمة في Play Store بالعربي.
- **اختبارات:** 7 unit tests لـ `AppUser.fromJson` — كلها خضراء.
