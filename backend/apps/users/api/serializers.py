from django.contrib.auth import get_user_model
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from apps.users.services import UserRegistrationError, register_user

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ("id", "username", "email", "first_name", "last_name", "points")


class RegisterSerializer(serializers.Serializer):
    username = serializers.CharField(min_length=4, max_length=150)
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, min_length=8)

    def create(self, validated_data):
        try:
            return register_user(**validated_data)
        except UserRegistrationError as exc:
            raise serializers.ValidationError({"detail": str(exc)}) from exc


class AuthTokenObtainPairSerializer(TokenObtainPairSerializer):
    """JWT payload that returns user metadata alongside tokens."""

    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token["username"] = user.username
        token["email"] = user.email
        return token

    def validate(self, attrs):
        data = super().validate(attrs)
        data["user"] = UserSerializer(self.user).data
        return data
