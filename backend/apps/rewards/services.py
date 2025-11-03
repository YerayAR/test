from decimal import Decimal

from django.db import transaction
from django.utils import timezone

from apps.catalog.models import Product
from apps.rewards.models import Notification, Redemption
from apps.users.models import User
from apps.wallet.services import (
    WalletInsufficientBalanceError,
    WalletService,
)


class RedemptionServiceError(Exception):
    """Raised when a redemption operation cannot be completed."""


class RedeemProductService:
    """Domain service that encapsulates the product redemption workflow."""

    def __init__(self, user: User, product: Product):
        self.user = user
        self.product = product

    def execute(self, *, notes: str | None = None) -> Redemption:
        if not self.product.is_active:
            raise RedemptionServiceError("El producto no esta disponible.")
        if self.product.inventory <= 0:
            raise RedemptionServiceError("El producto no cuenta con inventario.")
        wallet_service = WalletService(self.user)

        with transaction.atomic():
            product = Product.objects.select_for_update().get(pk=self.product.pk)
            if product.inventory <= 0:
                raise RedemptionServiceError("El producto no cuenta con inventario.")

            if product.requires_points:
                if self.user.points < (product.points_cost or 0):
                    raise RedemptionServiceError("No cuentas con puntos suficientes.")
                self.user.deduct_points(product.points_cost or 0)
                points_spent = product.points_cost or 0
                money_spent = Decimal("0.00")
                currency = wallet_service.default_currency
            else:
                try:
                    tx = wallet_service.debit(
                        product.price_amount,
                        description=f"Canje de {product.name}",
                        metadata={"product_id": product.id},
                    )
                except WalletInsufficientBalanceError as exc:
                    raise RedemptionServiceError("No cuentas con saldo suficiente.") from exc

                points_spent = 0
                money_spent = abs(tx.amount) if tx.amount < 0 else product.price_amount
                currency = tx.currency

            product.inventory = product.inventory - 1
            product.save(update_fields=["inventory"])

            redemption = Redemption.objects.create(
                user=self.user,
                product=product,
                points_spent=points_spent,
                money_spent=money_spent,
                currency=currency,
                notes=notes or "",
                status="completed",
            )

        Notification.objects.create(
            user=self.user,
            message=self._build_notification_message(points_spent, money_spent, currency),
        )
        return redemption

    def _build_notification_message(
        self, points_spent: int, money_spent: Decimal, currency: str
    ) -> str:
        if points_spent:
            return (
                f"Has canjeado {self.product.name} por {points_spent} puntos."
            )
        return (
            f"Has canjeado {self.product.name} por {money_spent} {currency}."
        )


def generate_welcome_notification(user: User) -> None:
    """Create a default notification when a user joins the platform."""
    Notification.objects.create(
        user=user,
        message="Bienvenido. Empieza a realizar acciones para ganar puntos.",
        created_at=timezone.now(),
    )
