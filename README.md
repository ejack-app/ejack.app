# Ejack — Mobile App (Flutter)

تطبيق موبايل واحد لمنصة **Ejack** يخدم كل الأدوار (سائق، عميل، مدير، أدمن) وموصول مع
لوحة تحكم Django REST API على `ml.eijack.com`.

- **Flutter 3.47+ · Riverpod · Dio + SimpleJWT · Material 3 · RTL**
- **Android + iOS من نفس الكود**
- **Package:** `com.ejack.ejack`

## بدء سريع

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=https://ml.eijack.com/api
```

## بناء نسخة النشر (AAB لـ Google Play)

راجع [`BUILD_AND_RELEASE.md`](./BUILD_AND_RELEASE.md) — فيه ٣ طرق: GitHub Actions
(الموصى بها)، بناء محلي، أو Docker. الملف يشرح إعداد الـ secrets للتوقيع خطوة بخطوة.

## البنية

- `lib/core/` — API client (Dio + JWT refresh)، التخزين الآمن، الثيم
- `lib/features/auth/` — تسجيل الدخول وجلب `/auth/me/`
- `lib/features/{driver,customer,manager}/` — واجهة كل دور
- `lib/widgets/` — مكونات مشتركة (`RoleScaffold`, `EndpointListView`)

كل الـ endpoints في مكان واحد: `lib/core/constants/api_constants.dart`.

## ملاحظات للتطوير

- أي شاشة جديدة لدور معين = سطر `RoleTab` واحد في `xxx_home.dart`.
- `EndpointListView` يعرف يقرأ pagination `{count, next, results}` من DRF
  أو list عادي، ويعرض عناصرها في بطاقات.
- Dio interceptor يجدد الـ access token تلقائياً عند 401 ويعيد الطلب الأصلي.
