import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'rewards_platform.settings')
django.setup()

from apps.users.models import User
from apps.catalog.models import Product

# Añadir puntos al usuario testuser
user = User.objects.get(username='testuser')
user.points = 10000
user.save()
print(f"✅ Usuario {user.username} ahora tiene {user.points} puntos")

# Crear productos
productos = [
    {
        "name": "iPhone 15 Pro",
        "slug": "iphone-15-pro",
        "description": "Último modelo de iPhone con chip A17 Pro",
        "category": "Electrónica",
        "points_cost": 5000,
        "stock": 10,
        "is_active": True
    },
    {
        "name": "PlayStation 5",
        "slug": "playstation-5",
        "description": "Consola de última generación",
        "category": "Gaming",
        "points_cost": 3500,
        "stock": 15,
        "is_active": True
    },
    {
        "name": "AirPods Pro",
        "slug": "airpods-pro",
        "description": "Auriculares con cancelación de ruido",
        "category": "Electrónica",
        "points_cost": 1200,
        "stock": 25,
        "is_active": True
    },
    {
        "name": "Nintendo Switch",
        "slug": "nintendo-switch",
        "description": "Consola híbrida de Nintendo",
        "category": "Gaming",
        "points_cost": 2000,
        "stock": 20,
        "is_active": True
    },
    {
        "name": "Vale Amazon 50€",
        "slug": "vale-amazon-50",
        "description": "Tarjeta regalo de Amazon",
        "category": "Vales",
        "points_cost": 500,
        "stock": 100,
        "is_active": True
    }
]

print("\nCreando productos...")
for producto_data in productos:
    producto, created = Product.objects.get_or_create(
        slug=producto_data['slug'],
        defaults=producto_data
    )
    if created:
        print(f"✅ {producto.name} creado")
    else:
        print(f"⚠️  {producto.name} ya existía")

print("\n✅ ¡Datos de prueba añadidos!")
print(f"Total productos: {Product.objects.count()}")
print(f"Puntos de testuser: {User.objects.get(username='testuser').points}")
