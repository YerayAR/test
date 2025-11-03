from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from apps.users.api.views import (
    AuthTokenObtainPairView,
    DashboardSummaryView,
    MeView,
    RegisterView,
)


app_name = "users-api"

urlpatterns = [
    path("auth/register/", RegisterView.as_view(), name="register"),
    path("auth/login/", AuthTokenObtainPairView.as_view(), name="login"),
    path("auth/refresh/", TokenRefreshView.as_view(), name="refresh"),
    path("me/", MeView.as_view(), name="me"),
    path("dashboard/summary/", DashboardSummaryView.as_view(), name="dashboard-summary"),
]
