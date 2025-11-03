from rest_framework import filters, mixins, permissions, viewsets

from apps.catalog.api.serializers import ProductCategorySerializer, ProductSerializer
from apps.catalog.models import Product, ProductCategory


class ProductCategoryViewSet(mixins.ListModelMixin, viewsets.GenericViewSet):
    queryset = ProductCategory.objects.all()
    serializer_class = ProductCategorySerializer
    permission_classes = [permissions.AllowAny]


class ProductViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Product.objects.filter(is_active=True).select_related("category")
    serializer_class = ProductSerializer
    lookup_field = "slug"
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ("name", "description", "category__name")
    ordering_fields = ("name", "points_cost", "created_at")
    ordering = ("name",)
    permission_classes = [permissions.AllowAny]
