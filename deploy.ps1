# Script para desplegar Flutter a Vercel
Write-Host "Building Flutter web..." -ForegroundColor Cyan

# Verificar si existe build previo
if (Test-Path "frontend\build\web") {
    Write-Host "Using existing build folder" -ForegroundColor Yellow
} else {
    Write-Host "ERROR: No build folder found at frontend\build\web" -ForegroundColor Red
    Write-Host "You need to build Flutter web first or install Flutter" -ForegroundColor Red
    exit 1
}

# Desplegar a Vercel
Write-Host "`nDeploying to Vercel..." -ForegroundColor Cyan
Set-Location frontend\build\web
vercel --prod
Set-Location ..\..\..

Write-Host "`nDeployment complete!" -ForegroundColor Green
