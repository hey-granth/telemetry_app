document.addEventListener('DOMContentLoaded', () => {
    initNavigation();
    initScrollAnimations();
    initSearch();
    initCodeCopy();
});

// Navigation Logic
function initNavigation() {
    const currentPath = window.location.pathname.split('/').pop() || 'index.html';
    const navLinks = document.querySelectorAll('.nav-link');

    navLinks.forEach(link => {
        if (link.getAttribute('href') === currentPath) {
            link.classList.add('active');
        }
    });

    // Mobile Menu Toggle
    const toggle = document.createElement('button');
    toggle.className = 'menu-toggle';
    toggle.innerHTML = '☰';
    toggle.style.display = 'none'; // Hidden by default, shown in CSS media query
    document.body.appendChild(toggle);

    toggle.addEventListener('click', () => {
        document.querySelector('.sidebar').classList.toggle('open');
    });
}

// Scroll Animations
function initScrollAnimations() {
    const observerOptions = {
        root: null,
        rootMargin: '0px',
        threshold: 0.1
    };

    const observer = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
                observer.unobserve(entry.target);
            }
        });
    }, observerOptions);

    const animatedElements = document.querySelectorAll('h1, h2, p, .card, pre');
    animatedElements.forEach(el => {
        el.classList.add('animate-in');
        observer.observe(el);
    });
}

// Search Functionality
async function initSearch() {
    const searchInput = document.getElementById('search-input');
    if (!searchInput) return;

    const pages = [
        'index.html',
        'getting-started.html',
        'architecture.html',
        'api-reference.html',
        'database.html',
        'troubleshooting.html'
    ];

    let searchIndex = [];

    // Pre-fetch pages to build index (naive approach for small sites)
    for (const page of pages) {
        try {
            const response = await fetch(page);
            const text = await response.text();
            const parser = new DOMParser();
            const doc = parser.parseFromString(text, 'text/html');
            const content = doc.querySelector('.main-content')?.innerText || '';
            searchIndex.push({
                url: page,
                title: doc.title,
                content: content.toLowerCase()
            });
        } catch (e) {
            console.warn(`Failed to index ${page}`, e);
        }
    }

    searchInput.addEventListener('input', (e) => {
        const query = e.target.value.toLowerCase();
        const resultsContainer = document.getElementById('search-results') || createResultsContainer(searchInput);

        if (query.length < 2) {
            resultsContainer.innerHTML = '';
            resultsContainer.style.display = 'none';
            return;
        }

        const results = searchIndex.filter(item => item.content.includes(query));
        displayResults(results, resultsContainer);
    });
}

function createResultsContainer(inputElement) {
    const container = document.createElement('div');
    container.id = 'search-results';
    container.style.cssText = `
        position: absolute;
        top: 100%;
        left: 0;
        right: 0;
        background: var(--secondary-bg);
        border: 1px solid var(--accent-color);
        border-radius: 4px;
        max-height: 300px;
        overflow-y: auto;
        z-index: 1000;
        display: none;
    `;
    inputElement.parentElement.appendChild(container);
    return container;
}

function displayResults(results, container) {
    if (results.length === 0) {
        container.innerHTML = '<div style="padding: 10px;">No results found</div>';
    } else {
        container.innerHTML = results.map(result => `
            <a href="${result.url}" style="display: block; padding: 10px; border-bottom: 1px solid var(--border-color); color: var(--text-color);">
                <strong>${result.title}</strong>
            </a>
        `).join('');
    }
    container.style.display = 'block';
}

// Code Copy Functionality
function initCodeCopy() {
    document.querySelectorAll('pre').forEach(pre => {
        const btn = document.createElement('button');
        btn.className = 'copy-btn';
        btn.textContent = 'Copy';

        btn.addEventListener('click', () => {
            const code = pre.querySelector('code')?.innerText || pre.innerText;
            navigator.clipboard.writeText(code);
            btn.textContent = 'Copied!';
            setTimeout(() => btn.textContent = 'Copy', 2000);
        });

        pre.appendChild(btn);
    });
}
