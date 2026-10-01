# تسليم مفتاح التوقيع (keystore)

## القاعدة الذهبية
**مفتاح توقيع الإنتاج لا يُرسَل أبداً في محادثة أو ملف مُستضاف.**
لو ضاع هذا المفتاح، لا يمكن تحديث التطبيق على Google Play ولا على TestFlight.
لو تسرّب، أي شخص يقدر ينشر نسخ مُلغّمة بإمضائك.

## الوضع الحالي
الكيستور تم توليده داخل بيئة Claude Code المعزولة أثناء الجلسة:
```
المسار:   android/app/ejack-release.keystore
التنسيق:  JKS, RSA 2048, صالح 10,000 يوم
الـ Alias: ejack-key
```

النظام الآلي للحماية في Claude Code **رفض** تحويل الملف إلى base64 أو إرساله
عبر المحادثة (تصنيف "Credential Leakage") — وهذا سلوك صحيح.

البيئة مؤقتة. عند إنتهاء الجلسة، الملف يُحذف. لذلك عملياً:
**الحل الوحيد الصحيح هو أن تُولّد الكيستور بنفسك على جهازك.**

---

## توليد الكيستور الآن (3 دقائق على جهازك)

على macOS / Linux / Windows (مع Java JDK):

```bash
# انتقل إلى مجلد مشروع التطبيق على جهازك
cd ejack.app

# اختر كلمة مرور قوية واحفظها في مدير كلمات مرور
KEYSTORE_PASS="ضع-كلمة-مرور-قوية-هنا"

keytool -genkeypair -v \
  -keystore android/app/ejack-release.keystore \
  -storetype JKS \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias ejack-key \
  -storepass "$KEYSTORE_PASS" \
  -keypass "$KEYSTORE_PASS" \
  -dname "CN=Ejack, OU=Mobile, O=Ejack, L=Riyadh, ST=Riyadh, C=SA"
```

ثم أنشئ `android/key.properties` (الملف مُستبعد من git بالفعل):

```properties
storePassword=كلمة-المرور-نفسها
keyPassword=كلمة-المرور-نفسها
keyAlias=ejack-key
storeFile=ejack-release.keystore
```

### احفظ الملف في 3 أماكن:
1. على جهازك (المصدر)
2. مجلد مشفّر على سحابة شخصية (مثلاً iCloud Drive أو Google Drive الخاص)
3. USB محمول في مكان آمن

### لا تضعه في:
- git (مُستبعد تلقائياً عبر `.gitignore`)
- بريد
- Slack / Discord / Telegram
- أي خدمة تخزين عامة

---

## رفع المفتاح إلى الـ CI (مرة واحدة)

### على Codemagic
`Teams → Integrations → Environment variables → ejack_android_signing`:

| اسم المتغير | القيمة | نوع |
|---|---|---|
| `CM_KEYSTORE` | ارفع الملف نفسه (ليس base64 — Codemagic يحوّل تلقائياً) | **Secure file** |
| `CM_KEYSTORE_PASSWORD` | كلمة مرور الـ keystore | Secret |
| `CM_KEY_PASSWORD` | نفسها (أو كلمة مرور المفتاح لو مختلفة) | Secret |
| `CM_KEY_ALIAS` | `ejack-key` | Plain |

### على GitHub Actions
Settings → Secrets and variables → Actions → New repository secret:

```bash
# على جهازك
base64 -w0 android/app/ejack-release.keystore | pbcopy    # macOS
base64 -w0 android/app/ejack-release.keystore | xclip -selection clipboard  # Linux
```

| اسم السر | القيمة |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | الناتج من الأمر أعلاه |
| `ANDROID_STORE_PASSWORD` | كلمة المرور |
| `ANDROID_KEY_PASSWORD` | نفسها |
| `ANDROID_KEY_ALIAS` | `ejack-key` |

---

## التحقق من المفتاح
بعد التوليد، اطبع البصمات:

```bash
keytool -list -v -keystore android/app/ejack-release.keystore \
        -storepass "$KEYSTORE_PASS" | grep -E "SHA1|SHA256|Alias"
```

لازم ترى `Alias name: ejack-key` + سطرَي SHA1 و SHA256.
احتفظ بـ SHA256 إذا كنت ستفعّل App Links / Firebase.

---

## استعادة من كيستور قديم
لو كان عندك كيستور للتطبيق مسبقاً من مطور سابق:
1. احصل على الملف منه مباشرة بوسيلة آمنة (USB / تسليم يدوي)
2. ضعه في `android/app/ejack-release.keystore`
3. أنشئ `key.properties` بنفس كلمات المرور الأصلية
4. **لا تحاول توليد كيستور جديد** — سيكون package name مختلف من منظور Play Store ولن يُقبل كتحديث.
