from rest_framework import serializers

from apps.catalog.api.serializers import ProductSerializer
from apps.catalog.models import Product
from apps.rewards.models import Notification, Redemption
from apps.rewards.services import RedemptionServiceError, RedeemProductService


class RedemptionSerializer(serializers.ModelSerializer):
    product = ProductSerializer(read_only=True)

    class Meta:
        model = Redemption
        fields = (
            "id",
            "product",
            "points_spent",
            "money_spent",
            "currency",
            "status",
            "notes",
            "created_at",
        )


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ("id", "message", "is_read", "created_at")


class RedemptionRequestSerializer(serializers.Serializer):
    product_id = serializers.PrimaryKeyRelatedField(
        queryset=Product.objects.filter(is_active=True),
        source="product",
    )
    notes = serializers.CharField(required=False, allow_blank=True)

    def save(self, **kwargs):
        user = self.context["request"].user
        product = self.validated_data["product"]
        notes = self.validated_data.get("notes")

        service = RedeemProductService(user=user, product=product)
        try:
            redemption = service.execute(notes=notes)
        except RedemptionServiceError as exc:
            raise serializers.ValidationError({"detail": str(exc)}) from exc
        return redemption
