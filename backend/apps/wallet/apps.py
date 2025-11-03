from django.apps import AppConfig


class WalletConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.wallet"
    verbose_name = "Wallet"

    def ready(self) -> None:
        from apps.wallet import signals  # noqa: F401
        return super().ready()
