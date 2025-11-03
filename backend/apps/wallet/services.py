from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal, ROUND_HALF_UP
from typing import Any, Optional

import stripe
from django.conf import settings
from django.db import transaction
from django.db.models import F
from django.utils import timezone

from apps.wallet.models import Transaction, Wallet

TWO_PLACES = Decimal("0.01")


class WalletServiceError(Exception):
    """Base exception for wallet service."""


class WalletInsufficientBalanceError(WalletServiceError):
    """Raised when the wallet balance is not enough to cover a charge."""


@dataclass
class CheckoutSessionData:
    session_id: str
    url: str


class WalletService:
    """Domain service that encapsulates wallet operations."""

    def __init__(self, user):
        self.user = user
        self.default_currency = settings.STRIPE_DEFAULT_CURRENCY or "EUR"

    # ------------------------------------------------------------------ helpers
    def _quantize_amount(self, amount: Decimal | float | int) -> Decimal:
        if not isinstance(amount, Decimal):
            amount = Decimal(str(amount))
        return amount.quantize(TWO_PLACES, rounding=ROUND_HALF_UP)

    def get_wallet(self, *, for_update: bool = False) -> Wallet:
        qs = Wallet.objects.filter(user=self.user)
        if for_update:
            qs = qs.select_for_update()
        wallet = qs.first()
        if wallet is None:
            wallet = Wallet.objects.create(user=self.user, currency=self.default_currency)
        elif for_update and wallet.currency != self.default_currency:
            # Keep existing currency, do not override.
            pass
        return wallet

    # ---------------------------------------------------------------- transactions
    def create_pending_deposit(
        self,
        amount: Decimal | float | int,
        *,
        session_id: str,
        description: str = "",
        metadata: Optional[dict[str, Any]] = None,
    ) -> Transaction:
        amount_decimal = self._quantize_amount(amount)
        wallet = self.get_wallet()
        metadata = metadata or {}
        transaction_obj, _ = Transaction.objects.get_or_create(
            wallet=wallet,
            external_reference=session_id,
            defaults={
                "type": Transaction.Type.DEPOSIT,
                "amount": amount_decimal,
                "currency": wallet.currency,
                "description": description,
                "status": Transaction.Status.PENDING,
                "metadata": metadata,
            },
        )
        return transaction_obj

    def complete_deposit(
        self,
        *,
        session_id: str,
        payment_intent: str | None = None,
    ) -> Transaction:
        with transaction.atomic():
            tx = (
                Transaction.objects.select_for_update()
                .select_related("wallet")
                .filter(
                    external_reference=session_id,
                    type=Transaction.Type.DEPOSIT,
                )
                .first()
            )
            if tx is None:
                raise WalletServiceError(
                    f"No se encontró la transacción para la sesión {session_id}."
                )
            if tx.status == Transaction.Status.COMPLETED:
                return tx

            wallet = Wallet.objects.select_for_update().get(pk=tx.wallet_id)
            wallet.balance = F("balance") + tx.amount
            wallet.save(update_fields=["balance", "updated_at"])

            if payment_intent:
                metadata = tx.metadata or {}
                metadata.setdefault("payment_intent", payment_intent)
                tx.metadata = metadata

            tx.status = Transaction.Status.COMPLETED
            tx.completed_at = timezone.now()
            tx.save(update_fields=["status", "completed_at", "metadata", "updated_at"])
            wallet.refresh_from_db(fields=["balance", "updated_at"])
            return tx

    def debit(
        self,
        amount: Decimal | float | int,
        *,
        description: str = "",
        metadata: Optional[dict[str, Any]] = None,
    ) -> Transaction:
        amount_decimal = self._quantize_amount(amount)
        if amount_decimal <= Decimal("0.00"):
            raise WalletServiceError("El monto debe ser mayor a cero.")

        metadata = metadata or {}
        with transaction.atomic():
            wallet = self.get_wallet(for_update=True)
            current_balance = wallet.balance
            if current_balance < amount_decimal:
                raise WalletInsufficientBalanceError("Saldo insuficiente en la wallet.")

            wallet.balance = F("balance") - amount_decimal
            wallet.save(update_fields=["balance", "updated_at"])

            tx = Transaction.objects.create(
                wallet=wallet,
                type=Transaction.Type.REDEEM,
                amount=-amount_decimal,
                currency=wallet.currency,
                description=description,
                status=Transaction.Status.COMPLETED,
                metadata=metadata,
                completed_at=timezone.now(),
            )
            wallet.refresh_from_db(fields=["balance", "updated_at"])
            return tx

    def refund(
        self,
        amount: Decimal | float | int,
        *,
        description: str = "",
        metadata: Optional[dict[str, Any]] = None,
    ) -> Transaction:
        amount_decimal = self._quantize_amount(amount)
        if amount_decimal <= Decimal("0.00"):
            raise WalletServiceError("El monto debe ser mayor a cero.")

        metadata = metadata or {}
        with transaction.atomic():
            wallet = self.get_wallet(for_update=True)
            wallet.balance = F("balance") + amount_decimal
            wallet.save(update_fields=["balance", "updated_at"])
            tx = Transaction.objects.create(
                wallet=wallet,
                type=Transaction.Type.REFUND,
                amount=amount_decimal,
                currency=wallet.currency,
                description=description,
                status=Transaction.Status.COMPLETED,
                metadata=metadata,
                completed_at=timezone.now(),
            )
            wallet.refresh_from_db(fields=["balance", "updated_at"])
            return tx

    # ------------------------------------------------------------------ Stripe
    def create_stripe_checkout_session(
        self,
        *,
        amount: Decimal | float | int,
        success_url: str,
        cancel_url: str,
        description: str = "Recarga de wallet",
        metadata: Optional[dict[str, Any]] = None,
    ) -> CheckoutSessionData:
        amount_decimal = self._quantize_amount(amount)
        if amount_decimal <= Decimal("0.00"):
            raise WalletServiceError("El monto debe ser mayor a cero.")

        stripe.api_key = settings.STRIPE_SECRET_KEY
        if not stripe.api_key:
            raise WalletServiceError("Stripe no está configurado correctamente.")

        metadata = metadata or {}
        metadata.update({"user_id": str(self.user.id)})
        amount_in_cents = int(amount_decimal * 100)

        session = stripe.checkout.Session.create(
            mode="payment",
            payment_method_types=["card"],
            line_items=[
                {
                    "price_data": {
                        "currency": self.default_currency.lower(),
                        "product_data": {
                            "name": description,
                        },
                        "unit_amount": amount_in_cents,
                    },
                    "quantity": 1,
                }
            ],
            metadata=metadata,
            success_url=success_url,
            cancel_url=cancel_url,
        )

        self.create_pending_deposit(
            amount_decimal,
            session_id=session.id,
            description=description,
            metadata=metadata,
        )
        return CheckoutSessionData(session_id=session.id, url=session.url)
