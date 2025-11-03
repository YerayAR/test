from decimal import Decimal

from django.conf import settings
from django.db import models
from django.utils import timezone


class Wallet(models.Model):
    """Represents the real-money balance for a user."""

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL, related_name="wallet", on_delete=models.CASCADE
    )
    balance = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal("0.00"))
    currency = models.CharField(max_length=3, default="EUR")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Wallet"
        verbose_name_plural = "Wallets"

    def __str__(self) -> str:
        return f"Wallet({self.user})"


class Transaction(models.Model):
    """Stores money movements for a wallet: deposits, redemptions, refunds."""

    class Type(models.TextChoices):
        DEPOSIT = "deposit", "Depósito"
        REDEEM = "redeem", "Canje"
        REFUND = "refund", "Reembolso"

    class Status(models.TextChoices):
        PENDING = "pending", "Pendiente"
        COMPLETED = "completed", "Completado"
        FAILED = "failed", "Fallido"

    wallet = models.ForeignKey(
        Wallet, related_name="transactions", on_delete=models.CASCADE
    )
    type = models.CharField(max_length=20, choices=Type.choices)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    currency = models.CharField(max_length=3, default="EUR")
    description = models.CharField(max_length=255, blank=True)
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.PENDING
    )
    external_reference = models.CharField(
        max_length=255, blank=True, help_text="Stripe session ID or similar reference."
    )
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = "Transacción"
        verbose_name_plural = "Transacciones"
        ordering = ("-created_at",)
        indexes = [
            models.Index(fields=("wallet", "created_at")),
            models.Index(fields=("status",)),
            models.Index(fields=("external_reference",)),
        ]

    def __str__(self) -> str:
        sign = "-" if self.amount < 0 else "+"
        return f"{self.wallet.user} {self.get_type_display()} {sign}{abs(self.amount)} {self.currency}"

    def mark_completed(self) -> None:
        if self.status != self.Status.COMPLETED:
            self.status = self.Status.COMPLETED
            self.completed_at = timezone.now()
            self.save(update_fields=["status", "completed_at", "updated_at"])
