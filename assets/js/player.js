(() => {
  "use strict";

  const modal = document.getElementById("tracklist-modal");
  if (!modal) {
    return;
  }

  const modalDialog = modal.querySelector("[data-modal-dialog]");
  const modalTitle = modal.querySelector("[data-tracklist-title]");
  const modalList = modal.querySelector("[data-tracklist]");
  const closeButtons = modal.querySelectorAll("[data-modal-close]");
  const playerShell = document.querySelector("[data-player]");
  const clearButton = document.querySelector("[data-player-clear]");
  let lastFocusedElement = null;

  const ensureMixes = () => window.djKukiState?.mixes ?? [];

  const describePlatform = (platform) => {
    const labels = {
      soundcloud: "Reproductor de SoundCloud",
      mixcloud: "Reproductor de Mixcloud",
      youtube: "Reproductor de YouTube",
    };
    return labels[platform] ?? "Reproductor multimedia";
  };

  const renderPlayer = (mix) => {
    if (!playerShell || !mix) return;
    playerShell.innerHTML = `
      <iframe
        src="${mix.embedUrl}"
        title="${mix.title}"
        loading="lazy"
        allow="autoplay; encrypted-media"
        aria-label="${describePlatform(mix.platform)}"
      ></iframe>
    `;
    if (clearButton) {
      clearButton.disabled = false;
      clearButton.setAttribute("aria-disabled", "false");
    }
  };

  const clearPlayer = () => {
    if (!playerShell) return;
    playerShell.innerHTML = `<p>Selecciona un mix para reproducirlo.</p>`;
    if (clearButton) {
      clearButton.disabled = true;
      clearButton.setAttribute("aria-disabled", "true");
    }
  };

  const openModal = (title, tracks) => {
    if (!modalDialog || !modalTitle || !modalList) return;
    lastFocusedElement = document.activeElement;
    modal.hidden = false;
    modal.setAttribute("aria-hidden", "false");
    modalTitle.textContent = title;
    const safeList = Array.isArray(tracks) && tracks.length ? tracks : ["Tracklist no disponible"];
    modalList.innerHTML = safeList.map((item) => `<li>${item}</li>`).join("");
    modalDialog.setAttribute("tabindex", "-1");
    modalDialog.focus();
  };

  const closeModal = () => {
    modal.setAttribute("aria-hidden", "true");
    modal.hidden = true;
    if (lastFocusedElement) {
      lastFocusedElement.focus();
    }
  };

  modal.addEventListener("click", (event) => {
    if (event.target === modal) {
      closeModal();
    }
  });

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && !modal.hidden) {
      closeModal();
    }
  });

  closeButtons.forEach((button) =>
    button.addEventListener("click", () => closeModal())
  );

  if (clearButton) {
    clearButton.addEventListener("click", () => clearPlayer());
    clearPlayer();
  }

  document.addEventListener("click", (event) => {
    const playTrigger = event.target.closest("[data-play-mix]");
    if (playTrigger) {
      const index = Number(playTrigger.getAttribute("data-play-mix"));
      const mix = ensureMixes()[index];
      if (mix) {
        renderPlayer(mix);
      }
    }
    const trackTrigger = event.target.closest("[data-tracklist]");
    if (trackTrigger) {
      const index = Number(trackTrigger.getAttribute("data-tracklist"));
      const mix = ensureMixes()[index];
      if (mix) {
        openModal(mix.title, mix.tracklist);
      }
    }
  });

  window.addEventListener("djKuki:data-ready", () => {
    if (!clearButton?.disabled) return;
    clearPlayer();
  });
})();
