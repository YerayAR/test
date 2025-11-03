from django.contrib import admin

from apps.rewards.models import Notification, Redemption


@admin.register(Redemption)
class RedemptionAdmin(admin.ModelAdmin):
    list_display = (
        "user",
        "product",
        "points_spent",
        "money_spent",
        "currency",
        "status",
        "created_at",
    )
    list_filter = ("status", "created_at", "currency")
    search_fields = ("user__username", "product__name")


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ("user", "message", "is_read", "created_at")
    list_filter = ("is_read",)
    search_fields = ("user__username", "message")
