# DJ KUKI — Static Site

Sitio estático cyberpunk para DJ KUKI con enfoque en Breakbeat, Hardcore Breaks y Drum & Bass. Código 100% HTML + CSS + JS listo para desplegar en Vercel.

## Estructura

```
.
├── index.html             # Home, hero, gigs/mixes destacados y galería
├── about.html             # Bio / press kit
├── gigs.html              # Agenda dinámica con filtros
├── mixes.html             # Player embebido + tracklists
├── contact.html           # Redes y formulario estático
├── assets/
│   ├── css/
│   │   ├── vendor-normalize.css
│   │   └── styles.css
│   ├── js/
│   │   ├── app.js         # Fetch de JSON, render y UX global
│   │   └── player.js      # Reproductor + modal accesible de tracklists
│   ├── img/               # Hero, galería, logo y social share
│   └── fonts/             # Orbitron / Inter locales en .woff2
├── data/
│   ├── gigs.json          # Próximas fechas (editar aquí)
│   └── mixes.json         # Mixes con embeds y tracklists
├── favicon.ico
├── site.webmanifest
├── robots.txt
├── sitemap.xml
└── vercel.json
```

## Despliegue en Vercel

```
npm i -g vercel
vercel          # primer deploy (elige proyecto estático)
vercel --prod   # despliegue a producción
```

El repo no requiere build step ni dependencias; basta servirlo como static hosting.

## Edición de datos

- **Gigs:** `data/gigs.json` soporta tantos objetos como necesites (`date`, `city`, `venue`, `country`, `ticketsUrl`).
- **Mixes:** `data/mixes.json` define cada mix con `platform` (`soundcloud`, `mixcloud`, `youtube`), `embedUrl`, `duration` y `tracklist` (array). Cambia los enlaces de SoundCloud/Mixcloud/YouTube por tus embeds reales.
- Tras editar los JSON no necesitas recompilar; el fetch se hace en runtime.

## Player y tracklists

`mixes.html` incluye un reproductor centralizado y un modal accesible:
- El botón **Escuchar mix** monta el iframe correcto según la plataforma.
- **Ver tracklist** abre un modal con foco gestionado (ESC o click fuera lo cierran).
- `player.js` gestiona estos comportamientos sin dependencias externas.

## Assets y branding

- Sustituye las imágenes en `assets/img/` por tus visuales manteniendo los nombres de archivo para conservar las referencias.
- Los estilos definen la paleta neon (`--bg`, `--accent-*`) y efectos como glitch, scanlines y parallax. Ajusta `assets/css/styles.css` si quieres retocar gradientes o animaciones.
- Las fuentes Orbitron / Inter se cargan localmente desde `assets/fonts/` mediante `@font-face`.

## SEO / Accesibilidad

- Metadatos compartidos (OpenGraph/Twitter) apuntan a `assets/img/social-og.jpg`.
- `sitemap.xml` y `robots.txt` permiten indexación completa.
- Se respetan `prefers-reduced-motion`, etiquetas ARIA y contrastes WCAG AA.

## Formularios

`contact.html` usa un formulario HTML estándar. Reemplaza la acción por tu endpoint favorito (`Formspree`, `Basin`, etc.).

¡Listo para publicar y actualizar desde tu editor favorito!
