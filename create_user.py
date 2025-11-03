import requests

API_URL = "https://determined-exploration-production-41ef.up.railway.app/api"

# Crear usuario de prueba
data = {
    "username": "testuser",
    "email": "test@test.com",
    "password": "Test1234!",
    "first_name": "Test",
    "last_name": "User"
}

response = requests.post(f"{API_URL}/auth/register/", json=data)
print(f"Status: {response.status_code}")
print(f"Response: {response.json()}")

if response.status_code in [200, 201]:
    print("\n✅ Usuario creado exitosamente!")
    print(f"Username: {data['username']}")
    print(f"Password: {data['password']}")
