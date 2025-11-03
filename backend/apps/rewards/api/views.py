from rest_framework import mixins, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from apps.rewards.api.serializers import (
    NotificationSerializer,
    RedemptionRequestSerializer,
    RedemptionSerializer,
)
from apps.rewards.models import Notification, Redemption


class RedemptionViewSet(mixins.ListModelMixin, viewsets.GenericViewSet):
    serializer_class = RedemptionSerializer

    def get_queryset(self):
        return (
            Redemption.objects.filter(user=self.request.user)
            .select_related("product", "product__category")
            .order_by("-created_at")
        )

    @action(detail=False, methods=["post"], url_path="redeem")
    def redeem(self, request):
        serializer = RedemptionRequestSerializer(
            data=request.data, context={"request": request}
        )
        serializer.is_valid(raise_exception=True)
        redemption = serializer.save()
        output = RedemptionSerializer(
            redemption, context={"request": request}
        ).data
        return Response(output, status=status.HTTP_201_CREATED)


class NotificationViewSet(mixins.ListModelMixin, viewsets.GenericViewSet):
    serializer_class = NotificationSerializer

    def get_queryset(self):
        queryset = Notification.objects.filter(user=self.request.user).order_by(
            "-created_at"
        )
        mark_read = self.request.query_params.get("markAsRead")
        if mark_read in {"1", "true", "yes"}:
            queryset.filter(is_read=False).update(is_read=True)
        return queryset
