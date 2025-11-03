from rest_framework import serializers

from apps.catalog.models import Product, ProductCategory


class ProductCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductCategory
        fields = ("id", "name", "slug", "description")


class ProductSerializer(serializers.ModelSerializer):
    category = ProductCategorySerializer(read_only=True)
    image_url = serializers.SerializerMethodField()
    price_amount = serializers.DecimalField(
        max_digits=12, decimal_places=2, allow_null=True, required=False, read_only=True
    )

    class Meta:
        model = Product
        fields = (
            "id",
            "name",
            "slug",
            "description",
            "price_type",
            "points_cost",
            "price_amount",
            "inventory",
            "image_url",
            "category",
            "is_active",
        )

    def get_image_url(self, obj: Product) -> str | None:
        request = self.context.get("request")
        if obj.image and request:
            return request.build_absolute_uri(obj.image.url)
        if obj.image:
            return obj.image.url
        return None
