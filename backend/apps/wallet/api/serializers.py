from decimal import Decimal

from rest_framework import serializers

from apps.wallet.models import Transaction, Wallet


class WalletSummarySerializer(serializers.Serializer):
    balance = serializers.DecimalField(max_digits=12, decimal_places=2)
    currency = serializers.CharField()
    updated_at = serializers.DateTimeField()

    @classmethod
    def from_wallet(cls, wallet: Wallet) -> "WalletSummarySerializer":
        return cls(
            {
                "balance": wallet.balance,
                "currency": wallet.currency,
                "updated_at": wallet.updated_at,
            }
        )


class WalletDepositSerializer(serializers.Serializer):
    amount = serializers.DecimalField(
        max_digits=12,
        decimal_places=2,
        min_value=Decimal("1.00"),
        help_text="Monto a recargar en la wallet.",
    )
    success_url = serializers.URLField()
    cancel_url = serializers.URLField()


class TransactionSerializer(serializers.ModelSerializer):
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)

    class Meta:
        model = Transaction
        fields = (
            "id",
            "type",
            "amount",
            "currency",
            "status",
            "description",
            "external_reference",
            "metadata",
            "created_at",
            "updated_at",
            "completed_at",
        )
        read_only_fields = fields
