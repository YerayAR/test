import requests

API_URL = "https://determined-exploration-production-41ef.up.railway.app/api"

# Test login
data = {
    "username": "testuser",
    "password": "Test1234!"
}

print("Testing login...")
response = requests.post(f"{API_URL}/auth/login/", json=data)
print(f"Status: {response.status_code}")
print(f"Response: {response.text}")

if response.status_code == 200:
    print("\n✅ Login exitoso!")
    tokens = response.json()
    print(f"Access token: {tokens.get('access', 'N/A')[:50]}...")
else:
    print("\n❌ Login falló")
    print("Probando endpoints disponibles...")
    
    # Probar token endpoint
    response2 = requests.post(f"{API_URL}/token/", json=data)
    print(f"\nToken endpoint status: {response2.status_code}")
    print(f"Response: {response2.text[:200]}")
