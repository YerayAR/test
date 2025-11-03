from decimal import Decimal

from django.conf import settings
from django.db import models

from apps.catalog.models import Product


class Redemption(models.Model):
    """Model that stores the redemption history of users."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, related_name="redemptions", on_delete=models.CASCADE
    )
    product = models.ForeignKey(
        Product, related_name="redemptions", on_delete=models.PROTECT
    )
    points_spent = models.PositiveIntegerField(default=0)
    money_spent = models.DecimalField(
        max_digits=12, decimal_places=2, default=Decimal("0.00")
    )
    currency = models.CharField(max_length=3, default="EUR")
    created_at = models.DateTimeField(auto_now_add=True)
    status = models.CharField(
        max_length=20,
        choices=(
            ("completed", "Completado"),
            ("pending", "Pendiente"),
            ("cancelled", "Cancelado"),
        ),
        default="completed",
    )
    notes = models.TextField(blank=True)

    class Meta:
        verbose_name = "Canje"
        verbose_name_plural = "Canjes"
        ordering = ("-created_at",)

    def __str__(self) -> str:
        parts: list[str] = []
        if self.points_spent:
            parts.append(f"{self.points_spent} pts")
        if self.money_spent and self.money_spent > 0:
            parts.append(f"{self.money_spent} {self.currency}")
        display = ", ".join(parts) if parts else "sin costo"
        return f"{self.user} -> {self.product} ({display})"


class Notification(models.Model):
    """Simple visual notification for users."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        related_name="notifications",
        on_delete=models.CASCADE,
    )
    message = models.CharField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True)
    is_read = models.BooleanField(default=False)

    class Meta:
        verbose_name = "Notificacion"
        verbose_name_plural = "Notificaciones"
        ordering = ("-created_at",)

    def __str__(self) -> str:
        return f"{self.user}: {self.message[:30]}"
