import { Controller } from "@hotwired/stimulus";

const colorMapping = {
  yellow: "#FFCC02",
  purple: "#D783FF",
  orange: "#FF9500",
  green: "#77C344",
  blue: "#017AFF",
  skyblue: "#5AC7FA",
  salmon: "#FDAF8A",
  red: "#FF3B2F",
  black: "#000000",
  white: "#FFFFFF",
};

function bgColor(circuit_color) {
  return colorMapping[circuit_color] || "rgb(80% 80% 80%)";
}

function textColor(circuit_color) {
  return circuit_color === "white" ? "#333" : "#FFF";
}

// Unicode NFD decompose, strip combining marks, strip non-alphanumeric, lowercase
function normalize(str) {
  if (!str) return "";
  return str.normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/[^a-zA-Z0-9]/g, "").toLowerCase();
}

function problemSlug(problem) {
  const name = (problem.name || "").toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/-$/, "");
  return `${problem.id}-${name}`;
}

export default class extends Controller {
  static targets = [
    "searchInput",
    "searchDropdown",
    "searchResults",
    "searchIcon",
    "spinnerIcon",
    "cancelButton",
    "clearButton",
    "searchModal"
  ];

  static values = {
    locale: String,
    debug: Boolean,
    placeholder: String,
    clear: String,
    cancel: String,
    submit: String,
    showUnpublished: { type: Boolean, default: false }
  };

  connect() {
    this.searchInputTarget.value = "";
    this.locale = this.hasLocaleValue ? this.localeValue : "en";
    this._activeDescendant = '';
    this.index = null;

    // Lazy-load the search index
    fetch("/assets/search-index.json")
      .then(res => res.json())
      .then(data => { this.index = data; })
      .catch(() => { /* silently fail */ });
  }

  get activeDescendant() {
    return this._activeDescendant;
  }

  set activeDescendant(value) {
    if (this._activeDescendant) {
      const prevElement = document.getElementById(this._activeDescendant);
      if (prevElement) {
        prevElement.classList.remove('bg-emerald-600/10');
        prevElement.setAttribute('aria-selected', 'false');
      }
    }

    this._activeDescendant = value;

    if (this._activeDescendant) {
      const newElement = document.getElementById(this._activeDescendant);
      if (newElement) {
        newElement.classList.add('bg-emerald-600/10');
        newElement.setAttribute('aria-selected', 'true');
      }
    }
  }

  performSearch() {
    const query = this.searchInputTarget.value.trim();

    if (query.length === 0) {
      this.clearResults();
      return;
    }

    if (!this.index) return;

    this.clearButtonTarget.classList.remove("hidden");

    const normalizedQuery = normalize(query);

    // Search areas
    const areaResults = this.index.areas
      .filter(a => a.normalized_name.includes(normalizedQuery))
      .map(a => ({ ...a, type: "Area", url: `/en/fontainebleau/${a.slug}` }));

    // Search problems (limit to 20)
    const problemResults = this.index.problems
      .filter(p => p.normalized_name && p.normalized_name.includes(normalizedQuery))
      .sort((a, b) => (b.popularity || 0) - (a.popularity || 0))
      .slice(0, 20)
      .map(p => {
        // Look up area slug for URL
        const area = this.index.areas.find(a => a.id === p.area_id);
        const areaSlug = area ? area.slug : "";
        return {
          ...p,
          type: "Problem",
          area_name: area ? area.name : "",
          url: `/en/fontainebleau/${areaSlug}/${problemSlug(p)}`
        };
      });

    const results = [...areaResults, ...problemResults];
    this.updateResults(results);
  }

  updateResults(results) {
    this.searchResultsTarget.innerHTML = "";
    this.disableMouseEvents = true;

    results.forEach((item) => {
      const li = document.createElement("li");
      li.className = "select-none px-4 py-2";
      li.id = `option-${item.type}-${item.id}`;
      li.role = "option";
      li.tabIndex = "-1";
      li.setAttribute('aria-selected', 'false');

      li.innerHTML = this.renderItem(item);

      li.addEventListener("click", () => this.handleResultClick(item));
      li.addEventListener("mouseenter", () => this.handleMouseEnter(li));
      li.addEventListener("mouseleave", () => this.handleMouseLeave());

      this.searchResultsTarget.appendChild(li);
    });

    setTimeout(() => {
      this.disableMouseEvents = false;
    }, 100);

    if (results.length > 0) {
      this.searchDropdownTarget.classList.remove("hidden");
      this.searchInputTarget.setAttribute("aria-expanded", "true");
      this.searchInputTarget.setAttribute("aria-activedescendant", this.activeDescendant);
    } else {
      this.searchDropdownTarget.classList.add("hidden");
      this.searchInputTarget.setAttribute("aria-expanded", "false");
      this.searchInputTarget.setAttribute("aria-activedescendant", '');
    }
  }

  handleMouseEnter(li) {
    if (!this.disableMouseEvents) {
      this.activeDescendant = li.id;
    }
  }

  handleMouseLeave() {
    if (!this.disableMouseEvents) {
      this.activeDescendant = '';
    }
  }

  renderItem(item) {
    if (item.type === "Problem") {
      return `
        <div class="flex justify-between items-center">
          <div class="flex items-center">
            <span style="background: ${bgColor(item.circuit_color)}; color: ${textColor(item.circuit_color)}" class="rounded-full h-6 w-6 leading-6 inline-flex justify-center flex-shrink-0">
              ${item.circuit_number || "&nbsp;"}
            </span>
            <span class="ml-2">${item.name}</span>
            <span class="ml-2 text-gray-400">${item.grade}</span>
          </div>
          <span class="ml-2 text-gray-400 flex-shrink-0">${item.area_name || ""}</span>
        </div>
      `;
    } else {
      return item.name;
    }
  }

  handleResultClick(item) {
    if (item.url) {
      window.location = item.url;
    }
    this.closeModal();
  }

  handleKeydown(event) {
    const { key } = event;

    if (key === "ArrowDown" || key === "ArrowUp") {
      this.moveFocus(key === "ArrowDown");
      event.preventDefault();
    } else if (key === "Enter" && this.activeDescendant) {
      const selectedElement = document.getElementById(this.activeDescendant);
      selectedElement.click();
    } else if (key === "Escape") {
      this.closeModal();
    }
  }

  moveFocus(down) {
    const options = Array.from(this.searchResultsTarget.children);
    let currentIndex = options.findIndex(option => option.id === this.activeDescendant);

    if (down) {
      currentIndex = (currentIndex + 1) % options.length;
    } else {
      currentIndex = (currentIndex - 1 + options.length) % options.length;
    }

    this.activeDescendant = options[currentIndex].id;
    this.searchInputTarget.setAttribute("aria-activedescendant", this.activeDescendant);
  }

  openModal(event) {
    event.stopPropagation();
    if (!this.hasSearchModalTarget) {
      // Static layout: modal is not a Stimulus target, find by ID
      const modal = document.getElementById("searchModal");
      if (modal) modal.classList.remove("hidden");
    } else {
      this.searchModalTarget.classList.remove("hidden");
    }
    document.body.style.overflow = "hidden";
    this.searchInputTarget.focus();
    document.addEventListener("click", this.closeModal.bind(this));
    this.searchInputTarget.setAttribute("aria-expanded", "true");
  }

  closeModal(event) {
    const modal = this.hasSearchModalTarget
      ? this.searchModalTarget
      : document.getElementById("searchModal");

    if (!event || (!this.searchInputTarget.contains(event.target) && !this.searchDropdownTarget.contains(event.target))) {
      if (modal) modal.classList.add("hidden");
      document.body.style.overflow = "";
      document.removeEventListener("click", this.closeModal.bind(this));
      this.searchInputTarget.setAttribute("aria-expanded", "false");
    }
  }

  clearSearch(event) {
    event.stopPropagation();
    this.searchInputTarget.value = "";
    this.searchInputTarget.focus();
    this.searchDropdownTarget.classList.add("hidden");
    this.clearButtonTarget.classList.add("hidden");
    this.searchInputTarget.setAttribute("aria-expanded", "false");
  }

  clearResults() {
    this.searchResultsTarget.innerHTML = "";
    this.searchDropdownTarget.classList.add("hidden");
    if (this.hasSpinnerIconTarget) this.spinnerIconTarget.classList.add("hidden");
    this.clearButtonTarget.classList.add("hidden");
    if (this.hasSearchIconTarget) this.searchIconTarget.classList.remove("hidden");
    this.activeDescendant = '';
    this.searchInputTarget.setAttribute("aria-expanded", "false");
    this.searchInputTarget.setAttribute("aria-activedescendant", '');
  }
}
