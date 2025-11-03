from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from apps.users.models import User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    fieldsets = BaseUserAdmin.fieldsets + (
        ("Recompensas", {"fields": ("points",)}),
    )
    list_display = ("username", "email", "points", "is_staff", "is_active")
    list_filter = ("is_staff", "is_active")
