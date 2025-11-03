from django.contrib import admin

from apps.catalog.models import Product, ProductCategory


@admin.register(ProductCategory)
class ProductCategoryAdmin(admin.ModelAdmin):
    prepopulated_fields = {"slug": ("name",)}
    search_fields = ("name",)


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    prepopulated_fields = {"slug": ("name",)}
    list_display = (
        "name",
        "category",
        "price_type",
        "points_cost",
        "price_amount",
        "inventory",
        "is_active",
    )
    list_filter = ("is_active", "category", "price_type")
    search_fields = ("name", "description")
    fieldsets = (
        (
            None,
            {
                "fields": (
                    "name",
                    "slug",
                    "category",
                    "description",
                    "image",
                    "is_active",
                )
            },
        ),
        (
            "Precio",
            {
                "fields": (
                    "price_type",
                    "points_cost",
                    "price_amount",
                    "inventory",
                )
            },
        ),
        ("Metadatos", {"fields": ("created_at", "updated_at"), "classes": ("collapse",)}),
    )
    readonly_fields = ("created_at", "updated_at")
