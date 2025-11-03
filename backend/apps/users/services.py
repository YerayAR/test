from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError

from apps.rewards.services import generate_welcome_notification

User = get_user_model()


class UserRegistrationError(Exception):
    """Raised when a user cannot be registered."""


def register_user(*, username: str, email: str, password: str) -> User:
    if User.objects.filter(username=username).exists():
        raise UserRegistrationError("El nombre de usuario ya existe.")
    if User.objects.filter(email=email).exists():
        raise UserRegistrationError("Ya existe un usuario con este email.")

    try:
        validate_password(password)
    except ValidationError as exc:
        raise UserRegistrationError("; ".join(exc.messages)) from exc

    user = User.objects.create_user(
        username=username,
        email=email,
        password=password,
    )
    generate_welcome_notification(user)
    return user
