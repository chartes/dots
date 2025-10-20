document.addEventListener("DOMContentLoaded", () => {

  /* Body */
  const bodyElement = document.body;

  /* DOM root */
  const docRootElement = document.documentElement;

  /* Doc root */
  const $docRoot = document.getElementById("js-docs");

  /* Doc content */
  const docContentElement = document.querySelector(".bd-docs-content");

  // Levels and articles
  const levels = document.querySelectorAll('[class*="level"], article');

  // Levels and articles presents in TOC
  const anchors = [];
  levels.forEach(element => {
    const tocElement = document.querySelector(".bd-menu-link[href$=" + element.id + "]");
    if (tocElement) {
      anchors.push(element);
    }
  });

  // Recherche de l'ancre la plus proche du haut de l'écran
  const getCurrentSection = function() {

    // Position du haut de l'écran :
    const documentScrollTop = docRootElement.scrollTop;

    let nearestTopBefore = Number.POSITIVE_INFINITY;
    let nearestTopAfter = Number.POSITIVE_INFINITY;
    let nearestElement = anchors[0]; // Par défaut, la première ancre

    anchors.forEach(element => {
      const deltaTop = Math.floor(element.offsetTop - documentScrollTop);
      if (deltaTop < -100) {
        // On stocke le plus proche au-dessus de la fenêtre : sera l'ancre par défaut si aucune ancre n'est visible à l'écran
        const absDeltaTop = Math.abs(deltaTop);
        if (absDeltaTop < nearestTopBefore) {
          nearestTopBefore = absDeltaTop;
          nearestElement = element;
        }
      } else if (deltaTop < window.innerHeight) {
        // Si une ancre apparaît à l'écran, elle est prise en compte
        // Si aucune ancre n'apparaît, on conserve celle qui a été enregistrée au-dessus de la fenêtre
        if (deltaTop < nearestTopAfter) {
          nearestTopAfter = deltaTop;
          nearestElement = element;
        }
      }
    });

    return nearestElement;
  }

  const hiliteCurrentSection = function(e) {

    document.querySelectorAll(".bd-menu-link").forEach(e => {
      e.classList.remove("active");
    });

    // Récupération de l'ancre la plus proche du haut de l'écran
    const nearestElement = getCurrentSection();

    const breadcrumbs = [];

    // TOC : On cherche l'item du menu associé à l'ancre :
    let tocElement = document.querySelector(".bd-menu-link[href$=" + nearestElement.id + "]");
    let activeTocElement = tocElement;

    // TOC : Activation du menu correspondant à l'élément du texte
    tocElement.classList.add("active");

    // On ajoute ce lien au fil d'Ariane (qui est donc constitué à l'envers)
    breadcrumbs.push(tocElement);

    // On ne rafraichit pas la TOC si elle est fermée
    // pour ne pas ouvrir tous les items lorsqu'on scrolle avec le menu fermé
    const tocMenuIsOPened = $docRoot.classList.contains("has-menu-opened");

    // TOC : Ouverture des menu-parents
    while (tocElement)
    {
      tocElement = tocElement.parentElement;
      if (tocElement && ( tocElement.classList.contains("bd-menu-sublist") || tocElement.classList.contains("chapter-list"))) {

        if (tocMenuIsOPened) {
          tocElement.classList.add("is-open")
        }

        // Toggle <a> qui permet de fermer le sous-menu <ul> :
        const sibling = tocElement.parentElement.querySelector(".bd-menu-link");
        if (sibling)
        {
          if (tocMenuIsOPened) {
            sibling.classList.add("is-open");
          }

          // On ajoute ce lien au fil d'Ariane
          breadcrumbs.push(sibling);
        }
      }
    }

    if (activeTocElement) {
      activeTocElement.scrollIntoView({ behavior: "smooth", block: "center" });
    }

    return {
      element: nearestElement,
      tocElement: activeTocElement,
      breadcrumbs: breadcrumbs.reverse(),
    }
  }

  // TOC : Reset
  const resetMenu = function() {

    document.querySelectorAll(".bd-menu-link").forEach(e => {
      e.classList.remove("active");
      e.classList.remove("is-open");
      e.classList.remove("is-clicked");
    });

    document.querySelectorAll(".bd-menu-sublist").forEach(e => e.classList.remove("is-open"));
    document.querySelectorAll(".chapter-list").forEach(e => e.classList.remove("is-open"));
  }

  const resetMenuAutoOpenedItems = function() {
    document.querySelectorAll(".bd-menu-link").forEach(e => {
      if (! (e.classList.contains("is-clicked") && e.classList.contains("is-open"))) {
        e.classList.remove("active");
        e.classList.remove("is-open");
        e.parentElement.querySelectorAll(".bd-menu-sublist, .chapter-list").forEach(e => e.classList.remove("is-open"));
      }
    });
  }

  // TOC LINKS
  const $links = document.querySelectorAll(".js-sublist-link, .js-toggle-sublist");
  $links.forEach((el) => {
    el.addEventListener("click", (e) => {
      if (e.target.classList.contains('icon')) {
        e.preventDefault();
        el.classList.toggle("is-open");
        el.nextElementSibling.classList.remove("is-open");
        if (el.classList.contains("is-open")) {
          el.nextElementSibling.classList.add("is-open");
        }
      }
      el.classList.add("is-clicked");
    }, true);
  });

  // TOGGLE TOC Button
  const $menuToggle = document.getElementById("js-menu-toggle");

  // TOGGLE TOC Button and overlay
  const $menuToggles = document.querySelectorAll(".js-toggle");
  $menuToggles.forEach((toggleElement) => {
    toggleElement.addEventListener("click", (e) => {
        e.preventDefault();

        const target = toggleElement.dataset.target;
        const $target = document.getElementById(target);

        // Paragraphe courant avant d'ouvrir/fermer le menu
        const currentSection = getCurrentSection();
        const currentSectionOffsetTop = currentSection.offsetTop;
        const documentScrollTop = docRootElement.scrollTop;

        $menuToggle.classList.toggle("is-active");
        $target.classList.toggle("has-menu-opened");

        // Si la TOC est fermée, on ferme les items ouverts sans click (= ouverts lors du scroll)
        if ($menuToggle.classList.contains("is-active")) {
          resetMenuAutoOpenedItems();
          bodyElement.classList.remove('has-menu-opened');
        } else {
          // Si on ouvre la TOC, on doit afficher le lien actif :
          hiliteCurrentSection();
          bodyElement.classList.add('has-menu-opened');
        }

        updatePaddingBottom();

        // Repositionnement du paragraphe courant après avoir ouvert/fermé le menu
        docRootElement.scrollTop = currentSection.offsetTop - (currentSectionOffsetTop - documentScrollTop);
    });
  });

  // RESET TOC Button
  const $menuResetButton = document.getElementById("js-menu-reset");
  $menuResetButton.addEventListener("click", (e) => {
    e.preventDefault();
    resetMenu();
    hiliteCurrentSection();
  });

  const updatePaddingBottom = function() {
    // On récupère le dernier élément du menu
    const tocElements = document.querySelectorAll(".bd-menu-link");
    if (tocElements && tocElements.length) {
      let lastTocElement;
      let anchorIdMax = 0;
      tocElements.forEach(element => {
        if (element.attributes.href) {
          const elementAnchorId = element.attributes.href.nodeValue.replace(/^\D+/g, '');
          const elementAnchorIdInt = parseInt(elementAnchorId);
          if (! isNaN(elementAnchorIdInt)) {
            if (parseInt(elementAnchorId) > anchorIdMax) {
              anchorIdMax = elementAnchorIdInt;
              lastTocElement = element;
            }
          }
        }
      })
      if (lastTocElement) {
        // Id du dernier élément du menu
        const lastTocElementId = lastTocElement.attributes.href.nodeValue.substring(1);
        // On récupère l'élément correspondant au dernier élément du menu
        const docElement = docContentElement.querySelector("[id=" + lastTocElementId + "]");
        if (docElement) {
          if (docContentElement) {

            // On remet le padding à zéro pour ne pas fausser le calcul de la taille du document
            docContentElement.style.paddingBottom = 0;

            // On calcule la distance entre le haut de l'écran et cet élément
            // Le padding à ajouter est la différence entre ces deux valeurs et la hauteur de la fenêtre
            // pour qu'on puisse scroller l'élément jusqu'en haut de l'écran
            const paddingBottom = window.innerHeight - (docRootElement.scrollHeight - docElement.offsetTop);

            // On ajoute un padding bottom équivalent
            docContentElement.style.paddingBottom = paddingBottom + "px";
          }
        }
      }
    }
  }

  const updateBreadCrumbs = function(breadcrumbs) {
    let breadcrumbsHTML = [];
    breadcrumbs.forEach(element => {
      breadcrumbsHTML += element.outerHTML;
    });
    const $breadcrumbs = document.getElementById("breadcrumbs");
    $breadcrumbs.innerHTML = breadcrumbsHTML;
  }

  // Displays side-note after clicking on a noteback in the footer
  const $footnotesParent = document.querySelector(".footnotes");
  if ($footnotesParent) {
    $footnotesParent.addEventListener("click", (e) => {
      if (e.target.classList.contains('noteback')) {
        updateSideNotes();
      }
    });
  }

  const updateSideNotes = function() {
    document.querySelectorAll(".aside-noteref").forEach(e => e.remove());
    const windowHeight = window.outerHeight;
    const documentTop = docRootElement.scrollTop;
    const documentContentTop = docContentElement.offsetTop;

    const notesInView = [];
    document.querySelectorAll(".noteref").forEach(noteRefElement => {
      const noteTop = noteRefElement.offsetTop;
      if ((noteTop > documentTop) && (noteTop < documentTop + windowHeight )) {
        const noteId = noteRefElement.attributes.href.nodeValue.substring(1);
        const noteElement = document.querySelector(".note[id=" + noteId + "]");
        if (noteElement) {
          notesInView.push({ noteId, noteElement, top: noteTop + documentContentTop });
        }
      }
    });
    if (notesInView.length) {
      // Parent : on le crée s'il nexiste pas
      let $asideNotesParent = document.querySelector(".aside-noteref-parent");
      if (! $asideNotesParent) {
        $asideNotesParent = document.createElement("aside");
        $asideNotesParent.classList.add("aside-noteref-parent");
        $docRoot.prepend($asideNotesParent);
      }
      // Enfants : notes
      let minTop = 0;
      notesInView.forEach(noteElementDetails => {
        const asideNodeTop = Math.max(noteElementDetails.top, minTop);
        const $asideNoteRef = document.createElement("a");
        $asideNotesParent.append($asideNoteRef);
        $asideNoteRef.classList.add("aside-noteref");
        $asideNoteRef.innerHTML = noteElementDetails.noteElement.innerHTML;
        $asideNoteRef.style.top = asideNodeTop + "px";
        $asideNoteRef.setAttribute("href", "#" + noteElementDetails.noteId);
        $asideNoteRef.querySelector(".noteback")?.remove();


        minTop = asideNodeTop + $asideNoteRef.offsetHeight + 10;
      });
    }
  }

  const updateNavigation = function() {
    const sectionDetails = hiliteCurrentSection();
    updateBreadCrumbs(sectionDetails.breadcrumbs);
    updateSideNotes();
  }

  // Listeners
  window.addEventListener('scroll', updateNavigation);
  window.addEventListener('resize', updateNavigation);
  window.addEventListener('resize', updatePaddingBottom);

  updatePaddingBottom();
  updateNavigation();
});
