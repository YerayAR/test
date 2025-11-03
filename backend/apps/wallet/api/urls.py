from django.urls import path

from apps.wallet.api.views import (
    StripeWebhookView,
    WalletDepositView,
    WalletSummaryView,
    WalletTransactionListView,
)

app_name = "wallet-api"

urlpatterns = [
    path("", WalletSummaryView.as_view(), name="summary"),
    path("deposit/", WalletDepositView.as_view(), name="deposit"),
    path("history/", WalletTransactionListView.as_view(), name="history"),
    path("webhook/stripe/", StripeWebhookView.as_view(), name="stripe-webhook"),
]
