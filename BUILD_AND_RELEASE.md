# كيف تبني وترفع تطبيق Ejack على Google Play

## المشروع باختصار

- **Flutter 3.47+** — تطبيق واحد يشتغل على Android و iOS
- **Riverpod** لإدارة الحالة
- **Dio** للاتصال بـ Django REST API (SimpleJWT مع refresh token تلقائي)
- **RTL كامل** — اللغة الافتراضية عربي
- **دور المستخدم يقرر الشاشة الرئيسية** — Driver / Customer / Manager / Admin كلها في نفس التطبيق

المشروع بيقرأ الدور من حقل `role` أو `user_type` في `GET /auth/me/`، ثم يعرض واجهة الدور المناسب. لو Django عندك يستخدم اسم مختلف، عدّل `lib/features/auth/domain/user.dart`.

---

## 1) اربط التطبيق بلوحة تحكمك (ml.eijack.com)

كل نقاط الـ API في مكان واحد: `lib/core/constants/api_constants.dart`.
اضبط `API_BASE_URL` عند البناء:

```bash
flutter run --dart-define=API_BASE_URL=https://ml.eijack.com/api
```

**Django-side checklist:**
1. `pip install djangorestframework djangorestframework-simplejwt django-cors-headers`
2. أضف endpoints:
   - `POST /api/auth/token/` — يرجع `{access, refresh}`
   - `POST /api/auth/token/refresh/` — يرجع `access` جديد
   - `GET /api/auth/me/` — يرجع بيانات المستخدم + الحقل `role`
3. فعّل CORS لدومين التطبيق (وبالنسبة للـ mobile، `ALLOWED_HOSTS = ['*']` في development).

---

## 2) بناء الـ .aab للرفع على Google Play — 3 طرق

### الطريقة أ — GitHub Actions (موصى بها، بدون تنصيب أي شي محلياً)

المشروع فيه بالفعل `.github/workflows/build-android.yml`.

**الخطوات (مرة وحدة):**

1. **حوّل الـ keystore إلى base64** (على جهازك، بعد ما يعطيك الـ keystore):
   ```bash
   base64 -w 0 android/app/ejack-release.keystore > keystore.b64
   ```

2. **ضيف الأسرار في GitHub:**
   Settings → Secrets and variables → Actions → New repository secret

   | Name | Value |
   |------|-------|
   | `ANDROID_KEYSTORE_BASE64` | محتوى `keystore.b64` |
   | `ANDROID_STORE_PASSWORD` | كلمة مرور الـ keystore |
   | `ANDROID_KEY_PASSWORD` | كلمة مرور المفتاح |
   | `ANDROID_KEY_ALIAS` | `ejack-key` (أو اسم الـ alias) |

3. **شغّل الـ workflow:**
   - Actions → "Build Android AAB" → Run workflow

4. **حمّل الـ AAB:**
   بعد ما يخلص، Artifacts → `ejack-release-aab` → يفك ملف `app-release.aab`.

5. **ارفعه على Play Console** في نفس الشاشة اللي عندك بالصورة.

---

### الطريقة ب — البناء المحلي (Mac / Linux / Windows)

**المتطلبات:**
- Flutter 3.47+ (https://docs.flutter.dev/get-started/install)
- Android Studio (لتحميل Android SDK + platform-34)
- JDK 17

**الأوامر:**
```bash
git clone https://github.com/ejack-app/ejack.app.git
cd ejack.app
git checkout claude/server-project-review-yh2odv

flutter pub get
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://ml.eijack.com/api
```

الملف يطلع في: `build/app/outputs/bundle/release/app-release.aab`

---

### الطريقة ج — Docker (نظيف، بدون تلويث الجهاز)

```bash
docker run --rm -it -v $PWD:/app -w /app \
  ghcr.io/cirruslabs/flutter:3.47.5 \
  bash -c "flutter pub get && flutter build appbundle --release"
```

---

## 3) إصلاح أخطاء Google Play اللي عندك حالياً

الرسائل الثلاث اللي طالعة في صورتك كلها بسبب واحد:

> **"يجب تحميل ملف APK أو تنسيق Android App Bundle لهذا التطبيق"**

**الحل بعد ما يجهز الـ AAB:**

1. افتح Play Console → Ejack Driver → الاختبار (اللي في القائمة الجانبية)
2. اختر مسار الاختبار الصحيح (داخلي / مغلق / مفتوح / الإنتاج)
3. **إنشاء إصدار جديد**
4. اسحب ملف `app-release.aab` في منطقة الرفع
5. املأ ملاحظات الإصدار (نص عربي مختصر عن التحديث)
6. **حفظ → مراجعة الإصدار → بدء الطرح**

**تنبيه مهم — Version Code:**
لو رفعت إصدار قبل بنفس `versionCode`، Play Console بيرفضه. عدّل الرقم في `pubspec.yaml`:
```yaml
version: 1.0.1+2   # الرقم بعد الـ + هو versionCode
```
كل بناء جديد يزيد الرقم اللي بعد `+` بواحد.

---

## 4) إعداد التوقيع (Signing Key) — المهم جداً

الـ keystore اللي بيولّده Flutter لأول مرة **ما ترجعه أبداً**. لو ضاع، ما تقدر تحدّث تطبيقك على Play Store — لازم تنشر تطبيق جديد بـ package name مختلف.

**احفظه في 3 أماكن على الأقل:**
- خارج git (تم — موجود في `.gitignore`)
- على Google Drive / iCloud خاصة
- عند مطور تثق فيه احتياطياً

**استرجاع بيانات المفتاح الحالي:**
```bash
keytool -list -v -keystore android/app/ejack-release.keystore
```

---

## 5) الـ iOS

المشروع مهيّأ لـ iOS تلقائياً، لكن البناء يحتاج Mac + Xcode + شهادة Apple Developer ($99/سنة).

**من جهاز Mac:**
```bash
cd ios && pod install && cd ..
flutter build ipa --release \
  --dart-define=API_BASE_URL=https://ml.eijack.com/api
```

الملف يطلع في: `build/ios/ipa/*.ipa`
ارفعه على TestFlight أو App Store عبر Xcode أو Transporter.

**بديل بدون Mac:** استخدم [Codemagic](https://codemagic.io) أو [Bitrise](https://bitrise.io) — يبنون iOS في الـ cloud.

---

## 6) هيكل الملفات

```
lib/
├── main.dart                          # نقطة البداية
├── core/
│   ├── api/api_client.dart           # Dio + JWT interceptor
│   ├── constants/api_constants.dart  # كل الـ endpoints هنا
│   ├── storage/secure_storage.dart   # حفظ التوكن بأمان
│   └── theme/app_theme.dart          # M3 theme (light/dark)
├── features/
│   ├── auth/                         # تسجيل دخول + جلب بيانات المستخدم
│   ├── common/dashboard_shell.dart   # يوجّه لكل دور
│   ├── driver/                       # واجهة السائق
│   ├── customer/                     # واجهة العميل
│   └── manager/                      # لوحة الإدارة
└── widgets/
    ├── role_scaffold.dart            # Bottom nav مشترك
    └── endpoint_list_view.dart       # يعرض أي DRF endpoint كقائمة
```

---

## 7) إضافة شاشة/ميزة جديدة

كل شاشة إدارية جديدة = سطرين. مثال — أضف تبويب "المدفوعات" للـ Manager:

```dart
// lib/features/manager/presentation/manager_home.dart
RoleTab(
  icon: Icons.payments_outlined,
  label: 'المدفوعات',
  endpoint: '/payments/',
),
```

`EndpointListView` يعرف يعرض شكل الرد تلقائياً (سواء `{results:[...]}` أو list عادي).

---

## 8) الخطوة التالية (لو تبي)

- ✅ **مشروع Flutter كامل جاهز** — تم
- ✅ **workflow يبني الـ AAB** — تم، محتاج منك تضيف secrets فقط
- ⏳ **ربط الأسرار في GitHub + أول build** — دقيقتين
- ⏳ **رفع الـ AAB على Play Console** — كذا خطوة كما موضح فوق

عندك أي endpoint في Django مختلف عن الافتراضي؟ عدّل `api_constants.dart` وقول لي وأنا أزوّد باقي الشاشات.
