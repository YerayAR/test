(() => {
  "use strict";

  const state = {
    gigs: [],
    mixes: [],
  };

  const filters = {
    country: "",
    month: "",
  };

  const ui = {
    gigsPreview: () => document.getElementById("gigs-preview"),
    mixesPreview: () => document.getElementById("mixes-preview"),
    gigsList: () => document.getElementById("gigs-list"),
    mixesGrid: () => document.getElementById("mixes-grid"),
    countryFilter: () => document.getElementById("country-filter"),
    monthFilter: () => document.getElementById("month-filter"),
    hero: () => document.querySelector(".hero"),
    galleryTrack: () => document.querySelector(".gallery-track"),
  };

  const prefersReducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)");

  const fetchJSON = async (path) => {
    const response = await fetch(path, { cache: "no-store" });
    if (!response.ok) {
      throw new Error(`No se pudo cargar ${path}`);
    }
    return response.json();
  };

  const formatDate = (value) => {
    const date = new Date(value);
    return new Intl.DateTimeFormat("es-ES", {
      weekday: "short",
      day: "2-digit",
      month: "short",
      year: "numeric",
    }).format(date);
  };

  const gigsByDate = () =>
    [...state.gigs].sort(
      (a, b) => new Date(a.date).getTime() - new Date(b.date).getTime()
    );

  const createGigCard = (gig) => `
    <article class="card card-gig" role="listitem">
      <p class="eyebrow">${formatDate(gig.date)}</p>
      <h3>${gig.city}, ${gig.country}</h3>
      <p>${gig.venue}</p>
      <div class="badge">${gig.country}</div>
      <a class="btn-link" href="${gig.ticketsUrl}" target="_blank" rel="noopener noreferrer" aria-label="Entradas para ${gig.city} ${gig.venue}">
        Entradas ↗
      </a>
    </article>
  `;

  const createMixCard = (mix, index) => `
    <article class="card mix-card" role="listitem" id="mix-${index}">
      <div>
        <p class="eyebrow">${mix.platform.toUpperCase()}</p>
        <h3>${mix.title}</h3>
        <p class="muted">Duración · ${mix.duration}</p>
      </div>
      <footer>
        <button class="btn btn-outline" data-play-mix="${index}" aria-controls="mix-player">
          Escuchar mix
        </button>
        <button class="btn btn-outline" data-tracklist="${index}">
          Ver tracklist
        </button>
      </footer>
    </article>
  `;

  const renderHomeGigs = () => {
    const container = ui.gigsPreview();
    if (!container || !state.gigs.length) return;
    const template = gigsByDate()
      .slice(0, 3)
      .map(createGigCard)
      .join("");
    container.innerHTML = template;
  };

  const renderHomeMixes = () => {
    const container = ui.mixesPreview();
    if (!container || !state.mixes.length) return;
    const template = [...state.mixes]
      .slice(0, 3)
      .map((mix, index) => `
        <article class="card mix-card" role="listitem">
          <p class="eyebrow">${mix.platform.toUpperCase()}</p>
          <h3>${mix.title}</h3>
          <p>${mix.duration}</p>
          <a class="btn-link" href="mixes.html#mix-${index}">Ver detalles ↗</a>
        </article>
      `)
      .join("");
    container.innerHTML = template;
  };

  const populateCountryFilter = () => {
    const select = ui.countryFilter();
    if (!select || !state.gigs.length) return;
    const countries = Array.from(new Set(state.gigs.map((gig) => gig.country))).sort();
    select.innerHTML = `<option value="">Todos los países</option>` +
      countries.map((country) => `<option value="${country}">${country}</option>`).join("");
  };

  const applyGigFilters = () => {
    let filtered = gigsByDate();
    if (filters.country) {
      filtered = filtered.filter((gig) => gig.country === filters.country);
    }
    if (filters.month) {
      filtered = filtered.filter((gig) => gig.date.startsWith(filters.month));
    }
    return filtered;
  };

  const renderGigsList = () => {
    const container = ui.gigsList();
    if (!container) return;
    const gigs = applyGigFilters();
    if (!gigs.length) {
      container.innerHTML = `<p class="status-message" role="status">No hay fechas que coincidan con el filtro.</p>`;
      return;
    }
    container.innerHTML = gigs.map(createGigCard).join("");
  };

  const renderMixesGrid = () => {
    const container = ui.mixesGrid();
    if (!container || !state.mixes.length) return;
    container.innerHTML = state.mixes
      .map((mix, index) => createMixCard(mix, index))
      .join("");
  };

  const bindFilters = () => {
    const countrySelect = ui.countryFilter();
    const monthInput = ui.monthFilter();
    if (countrySelect) {
      countrySelect.addEventListener("change", (event) => {
        filters.country = event.target.value;
        renderGigsList();
      });
    }
    if (monthInput) {
      monthInput.addEventListener("input", (event) => {
        filters.month = event.target.value;
        renderGigsList();
      });
    }
  };

  const initParallax = () => {
    const hero = ui.hero();
    if (!hero || prefersReducedMotion.matches) return;
    let ticking = false;
    const update = () => {
      const offset = window.scrollY * 0.2;
      hero.style.setProperty("--parallax-y", `${offset}px`);
      ticking = false;
    };
    window.addEventListener("scroll", () => {
      if (!ticking) {
        window.requestAnimationFrame(update);
        ticking = true;
      }
    });
  };

  const initGalleryAutoplay = () => {
    const track = ui.galleryTrack();
    if (!track || prefersReducedMotion.matches) return;
    let direction = 1;
    setInterval(() => {
      const maxScroll = track.scrollWidth - track.clientWidth;
      if (track.scrollLeft >= maxScroll - 5) {
        direction = -1;
      } else if (track.scrollLeft <= 5) {
        direction = 1;
      }
      track.scrollBy({ left: 220 * direction, behavior: "smooth" });
    }, 5000);
  };

  const showError = (message) => {
    [ui.gigsPreview(), ui.mixesPreview(), ui.gigsList(), ui.mixesGrid()].forEach((container) => {
      if (container && !container.innerHTML.trim()) {
        container.innerHTML = `<p class="status-message" role="status">${message}</p>`;
      }
    });
    console.error(message);
  };

  const updateFooterYear = () => {
    const target = document.getElementById("year");
    if (target) {
      target.textContent = new Date().getFullYear();
    }
  };

  const init = async () => {
    updateFooterYear();
    try {
      const [gigs, mixes] = await Promise.all([
        fetchJSON("data/gigs.json"),
        fetchJSON("data/mixes.json"),
      ]);
  state.gigs = gigs;
  state.mixes = mixes;
  window.djKukiState = state;
  window.dispatchEvent(
    new CustomEvent("djKuki:data-ready", { detail: { ...state } })
  );
      renderHomeGigs();
      renderHomeMixes();
      populateCountryFilter();
      bindFilters();
      renderGigsList();
      renderMixesGrid();
      initGalleryAutoplay();
    } catch (error) {
      showError("No se pudo cargar el contenido. Intenta nuevamente más tarde.");
    }
    initParallax();
  };

  document.addEventListener("DOMContentLoaded", init);
})();
