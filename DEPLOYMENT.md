# 🚀 Deployment Guide

## ✅ Deployed URLs

### Frontend
- **Production**: https://test-ibujf5xky-yerays-projects-0617076e.vercel.app
- **Platform**: Vercel

### Backend
- **API**: https://determined-exploration-production-41ef.up.railway.app
- **Docs**: https://determined-exploration-production-41ef.up.railway.app/api/docs/
- **Admin**: https://determined-exploration-production-41ef.up.railway.app/admin/
- **Platform**: Railway

## ⚙️ Railway Configuration

Configure estas variables de entorno en Railway dashboard:

```bash
# Django Core
DJANGO_SECRET_KEY=<generate-a-secret-key>
DJANGO_DEBUG=False
DJANGO_ALLOWED_HOSTS=determined-exploration-production-41ef.up.railway.app

# CORS
CORS_ALLOWED_ORIGINS=https://test-ibujf5xky-yerays-projects-0617076e.vercel.app
DJANGO_CSRF_TRUSTED_ORIGINS=https://determined-exploration-production-41ef.up.railway.app,https://test-ibujf5xky-yerays-projects-0617076e.vercel.app

# JWT
JWT_ACCESS_TTL=60
JWT_REFRESH_TTL=7

# Stripe (usar test keys)
STRIPE_SECRET_KEY=sk_test_xxx
STRIPE_PUBLISHABLE_KEY=pk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
STRIPE_DEFAULT_CURRENCY=EUR

# Database (Railway lo proporciona automáticamente)
# No necesitas configurar POSTGRES_* manualmente si usas Railway PostgreSQL
```

## 🔧 Comandos útiles

### Backend (Railway)
```bash
cd backend
railway login
railway link
railway up                    # Deploy
railway logs                  # Ver logs
railway open                  # Abrir dashboard
railway variables             # Ver variables
```

### Frontend (Vercel)
```bash
cd frontend
vercel login
vercel link
vercel --prod                 # Deploy
vercel logs                   # Ver logs
vercel env add API_BASE_URL   # Añadir variable
```

## 📝 Crear superusuario en Railway

```bash
cd backend
railway run python manage.py createsuperuser
```

## 🔄 Actualizar deployment

```bash
# Hacer cambios en el código
git add -A
git commit -m "descripción"
git push

# Backend se redeploya automáticamente en Railway si está conectado a GitHub
# Frontend se redeploya automáticamente en Vercel si está conectado a GitHub

# O manualmente:
cd backend && railway up
cd frontend && vercel --prod
```

## 🌐 Configurar dominio personalizado

### En Vercel
1. Ve al dashboard del proyecto
2. Settings > Domains
3. Añade tu dominio

### En Railway
1. Ve al dashboard del proyecto
2. Settings > Domains
3. Añade tu dominio

## 🔐 Configurar Stripe Webhook

1. Ve a Stripe Dashboard > Developers > Webhooks
2. Añade endpoint: `https://determined-exploration-production-41ef.up.railway.app/api/wallet/webhook/stripe/`
3. Selecciona eventos: `checkout.session.completed`
4. Copia el webhook secret y añádelo a Railway variables: `STRIPE_WEBHOOK_SECRET`

## 📊 Monitoreo

- **Railway Logs**: `railway logs --follow`
- **Vercel Logs**: `vercel logs --follow`
- **Railway Dashboard**: https://railway.app/dashboard
- **Vercel Dashboard**: https://vercel.com/dashboard

## 🐛 Troubleshooting

### Error 502 en Railway
```bash
railway logs
# Verifica que todas las variables están configuradas
railway variables
```

### Error CORS
- Verifica que el dominio de Vercel está en `CORS_ALLOWED_ORIGINS`
- Verifica que el dominio está en `DJANGO_CSRF_TRUSTED_ORIGINS`

### Stripe webhook no funciona
- Verifica que `STRIPE_WEBHOOK_SECRET` está configurado
- Verifica que el endpoint está configurado en Stripe Dashboard
- Usa Railway logs para ver errores: `railway logs | grep stripe`

## 📱 Testing Local

```bash
# Backend
cd backend
python manage.py runserver

# Frontend (si tienes Flutter instalado)
cd frontend
flutter run -d chrome
```
