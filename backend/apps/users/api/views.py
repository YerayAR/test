from django.utils import timezone
from rest_framework import generics, permissions, response, status
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView

from apps.rewards.models import Notification, Redemption
from apps.users.api.serializers import (
    AuthTokenObtainPairSerializer,
    RegisterSerializer,
    UserSerializer,
)


class AuthTokenObtainPairView(TokenObtainPairView):
    permission_classes = (permissions.AllowAny,)
    serializer_class = AuthTokenObtainPairSerializer


class RegisterView(generics.CreateAPIView):
    serializer_class = RegisterSerializer
    permission_classes = (permissions.AllowAny,)


class MeView(generics.RetrieveAPIView):
    serializer_class = UserSerializer

    def get_object(self):
        return self.request.user


class DashboardSummaryView(APIView):
    """Provide aggregated data for the user's dashboard."""

    def get(self, request):
        user = request.user
        latest_redemptions = Redemption.objects.filter(user=user).order_by("-created_at")[
            :3
        ]
        data = {
            "points": user.points,
            "redemptions_count": Redemption.objects.filter(user=user).count(),
            "latest_redemptions": [
                {
                    "id": redemption.id,
                    "product": redemption.product.name,
                    "points_spent": redemption.points_spent,
                    "created_at": redemption.created_at,
                }
                for redemption in latest_redemptions
            ],
            "notifications_unread": Notification.objects.filter(
                user=user, is_read=False
            ).count(),
            "server_time": timezone.now(),
        }
        return response.Response(data, status=status.HTTP_200_OK)
