import requests

# Simular lo que hace el frontend
API_URL = "https://determined-exploration-production-41ef.up.railway.app/api"
FRONTEND_URL = "https://test-yerays-projects-0617076e.vercel.app"

print("1. Probando CORS desde el frontend...")
headers = {
    "Origin": FRONTEND_URL,
    "Content-Type": "application/json"
}

data = {
    "username": "testuser",
    "password": "Test1234!"
}

response = requests.post(f"{API_URL}/auth/login/", json=data, headers=headers)
print(f"Status: {response.status_code}")
print(f"CORS headers: {response.headers.get('Access-Control-Allow-Origin', 'NOT SET')}")
print(f"Response: {response.text[:200]}")

if response.status_code == 200:
    print("\n✅ Login funciona!")
    print("\nCredenciales válidas:")
    print("Username: testuser")
    print("Password: Test1234!")
else:
    print("\n❌ Login falló")
