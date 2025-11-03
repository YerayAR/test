from decimal import Decimal

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand

from apps.catalog.models import Product, ProductCategory
from apps.rewards.models import Notification, Redemption
from apps.wallet.services import WalletService


class Command(BaseCommand):
    help = "Load initial demo data for the rewards platform."

    def handle(self, *args, **options):
        user_model = get_user_model()

        admin, _ = user_model.objects.get_or_create(
            username="admin",
            defaults={
                "email": "admin@example.com",
                "is_staff": True,
                "is_superuser": True,
            },
        )
        if not admin.has_usable_password():
            admin.set_password("admin123")
            admin.save()
        self.stdout.write(self.style.SUCCESS("Admin user ready (admin/admin123)."))

        demo_user, created = user_model.objects.get_or_create(
            username="demo",
            defaults={
                "email": "demo@example.com",
                "points": 1200,
            },
        )
        if created:
            demo_user.set_password("demo12345")
            demo_user.save()
        else:
            demo_user.points = 1200
            demo_user.save(update_fields=["points"])
        self.stdout.write(self.style.SUCCESS("Demo user ready (demo/demo12345)."))

        tech, _ = ProductCategory.objects.get_or_create(
            name="Tecnologia",
            defaults={"description": "Dispositivos y gadgets"},
        )
        travel, _ = ProductCategory.objects.get_or_create(
            name="Viajes",
            defaults={"description": "Experiencias y viajes"},
        )
        wellness, _ = ProductCategory.objects.get_or_create(
            name="Bienestar",
            defaults={"description": "Productos para el bienestar"},
        )

        products = [
            {
                "name": "Auriculares Inalambricos",
                "description": "Auriculares Bluetooth con cancelacion de ruido.",
                "price_type": Product.PriceType.POINTS,
                "points_cost": 350,
                "inventory": 10,
                "category": tech,
            },
            {
                "name": "Smartwatch Fitness",
                "description": "Reloj inteligente con seguimiento de actividad.",
                "price_type": Product.PriceType.POINTS,
                "points_cost": 500,
                "inventory": 5,
                "category": tech,
            },
            {
                "name": "Voucher Spa",
                "description": "Dia completo en un spa urbano.",
                "price_type": Product.PriceType.POINTS,
                "points_cost": 450,
                "inventory": 7,
                "category": wellness,
            },
            {
                "name": "Escapada de Fin de Semana",
                "description": "Estadia en hotel boutique con desayuno.",
                "price_type": Product.PriceType.POINTS,
                "points_cost": 900,
                "inventory": 3,
                "category": travel,
            },
            {
                "name": "Tarjeta Regalo 25 EUR",
                "description": "Tarjeta de regalo digital canjeable en comercios asociados.",
                "price_type": Product.PriceType.MONEY,
                "price_amount": Decimal("25.00"),
                "inventory": 15,
                "category": tech,
            },
        ]

        for data in products:
            product, created = Product.objects.get_or_create(
                name=data["name"], defaults=data
            )
            if not created:
                for field, value in data.items():
                    setattr(product, field, value)
                product.save()

        self.stdout.write(self.style.SUCCESS("Productos semilla creados."))

        redemption_product = Product.objects.get(name="Auriculares Inalambricos")
        Redemption.objects.get_or_create(
            user=demo_user,
            product=redemption_product,
            defaults={
                "points_spent": redemption_product.points_cost or 0,
                "money_spent": Decimal("0.00"),
                "currency": WalletService(demo_user).default_currency,
            },
        )

        wallet_service = WalletService(demo_user)
        wallet_service.refund(
            Decimal("150.00"),
            description="Saldo inicial de demostración",
            metadata={"source": "seed"},
        )

        Notification.objects.get_or_create(
            user=demo_user,
            message="Tienes 1200 puntos disponibles para canjear.",
        )

        self.stdout.write(self.style.SUCCESS("Datos de recompensas iniciales listos."))
