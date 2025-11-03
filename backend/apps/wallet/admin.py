from django.contrib import admin

from apps.wallet.models import Transaction, Wallet


@admin.register(Wallet)
class WalletAdmin(admin.ModelAdmin):
    list_display = ("user", "balance", "currency", "updated_at")
    search_fields = ("user__username", "user__email")
    readonly_fields = ("created_at", "updated_at")


@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = (
        "wallet",
        "type",
        "amount",
        "currency",
        "status",
        "external_reference",
        "created_at",
    )
    list_filter = ("type", "status", "currency", "created_at")
    search_fields = ("wallet__user__username", "external_reference")
    readonly_fields = ("created_at", "updated_at", "completed_at")
