from rest_framework.routers import DefaultRouter

from apps.catalog.api.views import ProductCategoryViewSet, ProductViewSet


app_name = "catalog-api"

router = DefaultRouter()
router.register(r"categories", ProductCategoryViewSet, basename="category")
router.register(r"products", ProductViewSet, basename="product")

urlpatterns = router.urls
