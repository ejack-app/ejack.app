# Push Notifications — دليل التفعيل

التطبيق فيه بالفعل `NotificationService` (مغلّف `flutter_local_notifications`)
جاهز يعرض إشعارات نظام محلية. البنية المتبقية لـ Push من السيرفر:

## الخيار A: Firebase Cloud Messaging (الموصى به)

### 1. أنشئ مشروع Firebase
- اذهب إلى https://console.firebase.google.com → **Add project** → سمِّه `Ejack`
- فعّل Cloud Messaging

### 2. أضف تطبيقَي Android و iOS
- **Android:** package name = `com.ejack.ejack`
  - حمّل `google-services.json` → ضعه في `android/app/`
- **iOS:** bundle id = `com.ejack.ejack`
  - حمّل `GoogleService-Info.plist` → ضعه في `ios/Runner/`

### 3. أضف الحزم
```bash
flutter pub add firebase_core firebase_messaging
```

### 4. حدّث `android/build.gradle.kts` (مستوى المشروع)
```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
}
```

### 5. حدّث `android/app/build.gradle.kts`
```kotlin
plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // ← أضف هذا
}
```

### 6. أضف ملف `lib/core/notifications/fcm_service.dart`

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import '../api/api_client.dart';
import 'notification_service.dart';

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  Future<void> init() async {
    final fcm = FirebaseMessaging.instance;

    // 1) اطلب الإذن (iOS + Android 13+)
    await fcm.requestPermission(alert: true, badge: true, sound: true);

    // 2) احصل على التوكن وأرسله لـ Django
    final token = await fcm.getToken();
    if (token != null) {
      await ApiClient.instance.dio.post(
        '/devices/register/',
        data: {'fcm_token': token, 'platform': 'android'},
      );
    }

    // 3) حدِّث التوكن عند تجديده تلقائياً
    fcm.onTokenRefresh.listen((t) async {
      await ApiClient.instance.dio.post(
        '/devices/register/',
        data: {'fcm_token': t},
      );
    });

    // 4) اعرض إشعاراً محلياً لما يصل Push و التطبيق مفتوح (foreground)
    FirebaseMessaging.onMessage.listen((msg) {
      NotificationService.instance.show(
        title: msg.notification?.title ?? 'Ejack',
        body: msg.notification?.body ?? '',
        payload: msg.data['order_id']?.toString(),
      );
    });
  }
}
```

### 7. ناديها من `main.dart`
```dart
await Firebase.initializeApp();
unawaited(FcmService.instance.init());
```

### 8. على السيرفر (Django)

```python
# devices/models.py
class Device(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    fcm_token = models.CharField(max_length=255, unique=True)
    platform = models.CharField(max_length=10, default='android')
```

```python
# devices/views.py
@decorators.action(detail=False, methods=['post'])
def register(self, request):
    Device.objects.update_or_create(
        fcm_token=request.data['fcm_token'],
        defaults={'user': request.user, 'platform': request.data.get('platform','android')}
    )
    return Response(status=204)
```

```python
# notifications/sender.py
import requests
from google.oauth2 import service_account
from google.auth.transport.requests import Request

def send_fcm(user, title, body, data=None):
    creds = service_account.Credentials.from_service_account_file(
        '/path/to/firebase-admin-sa.json',
        scopes=['https://www.googleapis.com/auth/firebase.messaging']
    )
    creds.refresh(Request())
    url = f'https://fcm.googleapis.com/v1/projects/{PROJECT_ID}/messages:send'

    for dev in user.device_set.all():
        requests.post(url,
            headers={'Authorization': f'Bearer {creds.token}'},
            json={'message': {
                'token': dev.fcm_token,
                'notification': {'title': title, 'body': body},
                'data': data or {},
            }}
        )
```

### 9. استدعِ `send_fcm()` من إشارة Django (signal)
```python
# orders/signals.py
from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Order

@receiver(post_save, sender=Order)
def notify_order_change(sender, instance, created, **kwargs):
    if not created:
        send_fcm(
            instance.customer,
            title='تحديث طلبك',
            body=f'حالة طلبك #{instance.id}: {instance.get_status_display()}',
            data={'order_id': str(instance.id)}
        )
```

---

## الخيار B: Apple Push Notification Service فقط (iOS)

لو ما تحتاج Android الآن، استخدم `flutter_apns` مباشرة ضد APNs بدون Firebase.
لكن FCM يكفل الاثنين بتكلفة ضئيلة، فنادراً تختار هذا.

---

## الخيار C: Polling (بدون أي إعداد)

التطبيق يقدر يستفسر كل N ثانية. أضفت فيه بالفعل `EndpointListView` اللي
يسحب-للتحديث. لإضافة polling تلقائي:

```dart
// lib/widgets/endpoint_list_view.dart
Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
```

**عيوب هذا الخيار:** يستهلك البطارية، يرفع تحميل السيرفر، التأخير 30 ثانية.
استخدمه فقط للـ MVP السريع قبل إعداد FCM.

---

## اختبار محلي بدون سيرفر

لتجربة الإشعارات المحلية الآن:
```dart
await NotificationService.instance.show(
  title: 'طلب جديد',
  body: 'طلب رقم #42 بانتظار قبولك',
);
```

يظهر إشعار نظام حقيقي على الجهاز.
