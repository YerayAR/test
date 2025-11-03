from __future__ import annotations

import json
import logging

import stripe
from django.conf import settings
from django.contrib.auth import get_user_model
from django.http import HttpResponse
from rest_framework import generics, permissions, response, status
from rest_framework.exceptions import ValidationError
from rest_framework.views import APIView

from apps.wallet.api.serializers import (
    TransactionSerializer,
    WalletDepositSerializer,
    WalletSummarySerializer,
)
from apps.wallet.models import Transaction
from apps.wallet.services import (
    WalletService,
    WalletServiceError,
)

logger = logging.getLogger(__name__)


class WalletSummaryView(APIView):
    """Return the current wallet balance for the authenticated user."""

    def get(self, request, *args, **kwargs):
        service = WalletService(request.user)
        wallet = service.get_wallet()
        serializer = WalletSummarySerializer.from_wallet(wallet)
        return response.Response(serializer.data, status=status.HTTP_200_OK)


class WalletTransactionListView(generics.ListAPIView):
    """List the wallet transactions for the authenticated user."""

    serializer_class = TransactionSerializer

    def get_queryset(self):
        service = WalletService(self.request.user)
        wallet = service.get_wallet()
        queryset = wallet.transactions.order_by("-created_at")

        tx_type = self.request.query_params.get("type")
        if tx_type:
            queryset = queryset.filter(type=tx_type)
        status_filter = self.request.query_params.get("status")
        if status_filter:
            queryset = queryset.filter(status=status_filter)

        return queryset


class WalletDepositView(APIView):
    """Create a Stripe Checkout session to top up the wallet."""

    def post(self, request, *args, **kwargs):
        serializer = WalletDepositSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        service = WalletService(request.user)
        try:
            checkout = service.create_stripe_checkout_session(
                amount=data["amount"],
                success_url=data["success_url"],
                cancel_url=data["cancel_url"],
                metadata={"origin": "wallet_deposit"},
            )
        except WalletServiceError as exc:
            raise ValidationError({"detail": str(exc)})

        return response.Response(
            {"checkout_url": checkout.url, "session_id": checkout.session_id},
            status=status.HTTP_201_CREATED,
        )


class StripeWebhookView(APIView):
    """Handle Stripe webhook events to confirm deposits."""

    authentication_classes: list = []
    permission_classes = [permissions.AllowAny]

    def post(self, request, *args, **kwargs):
        payload = request.body
        sig_header = request.META.get("HTTP_STRIPE_SIGNATURE")
        webhook_secret = settings.STRIPE_WEBHOOK_SECRET

        if not webhook_secret:
            logger.error("Stripe webhook secret is not configured.")
            return HttpResponse(status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        try:
            event = stripe.Webhook.construct_event(
                payload=payload,
                sig_header=sig_header,
                secret=webhook_secret,
            )
        except ValueError as exc:
            logger.warning("Stripe webhook payload error: %s", exc)
            return HttpResponse(status=status.HTTP_400_BAD_REQUEST)
        except stripe.error.SignatureVerificationError as exc:
            logger.warning("Stripe webhook signature verification failed: %s", exc)
            return HttpResponse(status=status.HTTP_400_BAD_REQUEST)

        if event["type"] == "checkout.session.completed":
            self._handle_checkout_session_completed(event["data"]["object"])

        return HttpResponse(status=status.HTTP_200_OK)

    def _handle_checkout_session_completed(self, session: dict):
        metadata = session.get("metadata", {}) or {}
        user_id = metadata.get("user_id")
        session_id = session.get("id")
        payment_intent = session.get("payment_intent")

        if not user_id or not session_id:
            logger.warning("Stripe session without user metadata: %s", json.dumps(metadata))
            return

        user_model = get_user_model()
        try:
            user = user_model.objects.get(pk=user_id)
        except user_model.DoesNotExist:
            logger.error("User %s not found for Stripe session %s", user_id, session_id)
            return

        try:
            WalletService(user).complete_deposit(
                session_id=session_id,
                payment_intent=payment_intent,
            )
        except WalletServiceError as exc:
            logger.error("Error completing deposit for session %s: %s", session_id, exc)
        except Transaction.DoesNotExist:
            logger.error(
                "No pending transaction found for Stripe session %s", session_id
            )
