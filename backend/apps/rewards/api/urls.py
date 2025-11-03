from rest_framework.routers import DefaultRouter

from apps.rewards.api.views import NotificationViewSet, RedemptionViewSet


app_name = "rewards-api"

router = DefaultRouter()
router.register(r"history", RedemptionViewSet, basename="redemption")
router.register(r"notifications", NotificationViewSet, basename="notification")

urlpatterns = router.urls
