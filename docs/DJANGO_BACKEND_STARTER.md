# Django backend starter for the Ejack app

The Flutter app expects a **Django 4.x + DRF + SimpleJWT** backend. If your current
`ml.eijack.com` project doesn't already expose these endpoints, this file is a drop-in
blueprint that gets you from zero to "the app works" in about 20 minutes.

---

## 1) Install

```bash
pip install \
  "django>=5.0" djangorestframework \
  djangorestframework-simplejwt \
  django-cors-headers \
  django-filter
```

## 2) `settings.py` additions

```python
INSTALLED_APPS = [
    # ...
    "rest_framework",
    "rest_framework_simplejwt",
    "corsheaders",
    "django_filters",
    "accounts",   # the app that holds AppUser + role
    "orders",
    "trips",
    "drivers",
    "customers",
]

MIDDLEWARE = [
    "corsheaders.middleware.CorsMiddleware",   # must be high up
    # ...
]

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ],
    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.IsAuthenticated",
    ],
    "DEFAULT_PAGINATION_CLASS":
        "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 20,
    "DEFAULT_FILTER_BACKENDS": [
        "django_filters.rest_framework.DjangoFilterBackend",
    ],
}

from datetime import timedelta
SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(hours=1),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=14),
    "ROTATE_REFRESH_TOKENS": True,
    "BLACKLIST_AFTER_ROTATION": True,
}

CORS_ALLOWED_ORIGINS = [
    "https://ml.eijack.com",
]
CORS_ALLOW_ALL_ORIGINS = False  # True only during local dev
```

## 3) `accounts/models.py` — user with role

```python
from django.contrib.auth.models import AbstractUser
from django.db import models

class AppUser(AbstractUser):
    class Role(models.TextChoices):
        DRIVER = "driver"
        CUSTOMER = "customer"
        MANAGER = "manager"
        ADMIN = "admin"

    role = models.CharField(
        max_length=16,
        choices=Role.choices,
        default=Role.CUSTOMER,
    )
    phone = models.CharField(max_length=20, blank=True)
    full_name = models.CharField(max_length=120, blank=True)
    avatar = models.URLField(blank=True)
```

Then in `settings.py`: `AUTH_USER_MODEL = "accounts.AppUser"`.

## 4) `accounts/views.py` — the `/auth/me/` endpoint

```python
from rest_framework import serializers, viewsets, mixins, decorators, response
from .models import AppUser

class MeSerializer(serializers.ModelSerializer):
    class Meta:
        model = AppUser
        fields = ["id", "username", "email", "full_name",
                  "phone", "avatar", "role"]
        read_only_fields = ["id", "username", "role"]


class MeViewSet(mixins.RetrieveModelMixin,
                mixins.UpdateModelMixin,
                viewsets.GenericViewSet):
    serializer_class = MeSerializer

    def get_object(self):
        return self.request.user
```

## 5) `trips/views.py` — status-change actions

```python
from rest_framework import viewsets, decorators, response, status
from .models import Trip
from .serializers import TripSerializer

class TripViewSet(viewsets.ModelViewSet):
    serializer_class = TripSerializer
    queryset = Trip.objects.all()
    filterset_fields = ["status"]

    def get_queryset(self):
        qs = super().get_queryset()
        if self.request.query_params.get("assigned_to_me") == "true":
            qs = qs.filter(driver=self.request.user)
        return qs

    def _transition(self, request, pk, new_status):
        trip = self.get_object()
        trip.status = new_status
        trip.save(update_fields=["status"])
        return response.Response(TripSerializer(trip).data)

    @decorators.action(detail=True, methods=["post"])
    def start(self, request, pk=None):
        return self._transition(request, pk, "in_progress")

    @decorators.action(detail=True, methods=["post"], url_path="on_the_way")
    def on_the_way(self, request, pk=None):
        return self._transition(request, pk, "on_the_way")

    @decorators.action(detail=True, methods=["post"])
    def complete(self, request, pk=None):
        return self._transition(request, pk, "completed")
```

The Flutter app POSTs to:

| Action key in app | DRF URL generated |
|---|---|
| `start` | `/trips/{id}/start/` |
| `on_the_way` | `/trips/{id}/on_the_way/` |
| `complete` | `/trips/{id}/complete/` |

Mirror this pattern for `orders` (`accept`, `reject`, `assign`, `cancel`)
and `drivers` (`activate`, `suspend`).

## 6) Driver location endpoint

```python
# drivers/views.py
from rest_framework import decorators, response, viewsets
from .models import Driver, LocationPing

class DriverViewSet(viewsets.ModelViewSet):
    serializer_class = DriverSerializer
    queryset = Driver.objects.all()

    @decorators.action(detail=False, methods=["get", "post"],
                       url_path="me/location")
    def my_location(self, request):
        if request.method == "POST":
            LocationPing.objects.create(
                driver=request.user.driver,
                lat=request.data["lat"],
                lng=request.data["lng"],
                speed=request.data.get("speed", 0),
                heading=request.data.get("heading", 0),
            )
            return response.Response(status=204)
        last = LocationPing.objects.filter(
            driver=request.user.driver
        ).order_by("-created_at").first()
        return response.Response({
            "lat": last.lat, "lng": last.lng, "ts": last.created_at,
        } if last else {})
```

## 7) `urls.py`

```python
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import (
    TokenObtainPairView, TokenRefreshView,
)
from accounts.views import MeViewSet
from trips.views import TripViewSet
from orders.views import OrderViewSet
from drivers.views import DriverViewSet
from customers.views import CustomerViewSet

router = DefaultRouter()
router.register("trips", TripViewSet)
router.register("orders", OrderViewSet)
router.register("drivers", DriverViewSet)
router.register("customers", CustomerViewSet)
router.register("auth/me", MeViewSet, basename="me")

urlpatterns = [
    path("api/auth/token/", TokenObtainPairView.as_view()),
    path("api/auth/token/refresh/", TokenRefreshView.as_view()),
    path("api/", include(router.urls)),
]
```

With this URL conf, `lib/core/constants/api_constants.dart` requires zero changes.

## 8) Smoke test

```bash
# obtain a token
curl -X POST https://ml.eijack.com/api/auth/token/ \
     -d 'username=driver1&password=xxx' | jq .

# use it
TOKEN="eyJ..."
curl -H "Authorization: Bearer $TOKEN" \
     https://ml.eijack.com/api/auth/me/
```

If both calls succeed, the app will log in and route to the right role screen.
