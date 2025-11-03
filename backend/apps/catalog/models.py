from decimal import Decimal

from django.core.exceptions import ValidationError
from django.db import models
from django.utils.text import slugify


class ProductCategory(models.Model):
    name = models.CharField(max_length=120, unique=True)
    description = models.TextField(blank=True)
    slug = models.SlugField(max_length=150, unique=True, blank=True)

    class Meta:
        verbose_name = "Categoria de producto"
        verbose_name_plural = "Categorias de producto"
        ordering = ("name",)

    def __str__(self) -> str:
        return self.name

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.name)
        super().save(*args, **kwargs)


class Product(models.Model):
    class PriceType(models.TextChoices):
        POINTS = "points", "Puntos"
        MONEY = "money", "Dinero"

    name = models.CharField(max_length=160)
    slug = models.SlugField(max_length=180, unique=True, blank=True)
    description = models.TextField()
    price_type = models.CharField(
        max_length=10,
        choices=PriceType.choices,
        default=PriceType.POINTS,
    )
    points_cost = models.PositiveIntegerField(null=True, blank=True)
    price_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        null=True,
        blank=True,
        help_text="Precio en dinero cuando price_type es 'money'.",
    )
    inventory = models.PositiveIntegerField(default=0)
    image = models.ImageField(upload_to="products/", blank=True, null=True)
    category = models.ForeignKey(
        ProductCategory, related_name="products", on_delete=models.CASCADE
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Producto"
        verbose_name_plural = "Productos"
        ordering = ("name",)

    def __str__(self) -> str:
        return self.name

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.name)
        self.full_clean()
        super().save(*args, **kwargs)

    def clean(self):
        if self.price_type == self.PriceType.POINTS:
            if not self.points_cost:
                raise ValidationError(
                    {"points_cost": "Debes indicar el costo en puntos para este producto."}
                )
            self.price_amount = None
        elif self.price_type == self.PriceType.MONEY:
            if self.price_amount is None:
                raise ValidationError(
                    {"price_amount": "Debes indicar el precio en dinero para este producto."}
                )
            if self.price_amount <= Decimal("0.00"):
                raise ValidationError(
                    {"price_amount": "El precio debe ser mayor a cero."}
                )
            self.points_cost = None

    @property
    def requires_points(self) -> bool:
        return self.price_type == self.PriceType.POINTS

    @property
    def requires_money(self) -> bool:
        return self.price_type == self.PriceType.MONEY
