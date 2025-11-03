from django.contrib.auth.models import AbstractUser
from django.db import models
from django.db.models import F


class User(AbstractUser):
    """Custom user model that tracks points balance."""

    points = models.PositiveIntegerField(default=0)

    class Meta:
        verbose_name = "Usuario"
        verbose_name_plural = "Usuarios"

    def add_points(self, amount: int) -> None:
        """Increase user's point balance."""
        if amount < 0:
            raise ValueError("La cantidad de puntos a agregar debe ser positiva.")
        self.points = F("points") + amount
        self.save(update_fields=["points"])
        self.refresh_from_db(fields=["points"])

    def deduct_points(self, amount: int) -> None:
        """Decrease user's point balance ensuring it never goes negative."""
        if amount < 0:
            raise ValueError("La cantidad de puntos a restar debe ser positiva.")
        if self.points < amount:
            raise ValueError("El usuario no cuenta con puntos suficientes.")
        self.points = F("points") - amount
        self.save(update_fields=["points"])
        self.refresh_from_db(fields=["points"])
