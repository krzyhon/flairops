+++
title = "Enabling Search Functionality in Hugo with Minimal Black Theme"
description = "How to enable and expose the built-in search functionality in the Hugo Minimal Black theme"
date = "2026-03-31T10:00:00+02:00"
author = "Krzysztof Filar"
categories = ["Hugo"]
tags = ["hugo", "search", "javascript", "frontend", "blog"]
+++

The Minimal Black theme for Hugo ships with a fully built search overlay — keyboard navigation, highlighted results, ESC to close, and even a `Ctrl+K` shortcut. By default it is accessible via the dock — a small panel in the bottom right corner of the page that expands when clicked and reveals a search icon among other controls. However, the dock is easy to miss and not immediately obvious to visitors. I wanted the search to also be accessible directly from the main navigation header. Here's how I wired it up properly.

## How the Search Works

The search is powered by a JSON index that Hugo generates at build time. Every page is serialized into `/index.json` and the search JavaScript loads this file on demand when the overlay is opened.

The search overlay itself is already included in the theme's `header.html` — it's just hidden. The JavaScript in `static/js/search.js` exposes a global API:

```javascript
window.MinimalSearch = {
  open: openOverlay,
  close: closeOverlay,
};
```

So all we need to do is:
1. Make sure the JSON index is being generated
2. Add a trigger button to the header that calls `window.MinimalSearch.open()`

## Step 1 — Enable JSON Output

The theme requires a JSON output format to be configured in `hugo.toml`. Make sure you have this:

```toml
[outputs]
  home = ["HTML", "RSS", "JSON", "WebAppManifest"]
```

Without this, Hugo won't generate `index.json` and the search will always return empty results.

## Step 2 — Override the Header

Never edit theme files directly. Copy the header partial to your project:

```bash
mkdir -p layouts/partials
cp themes/hugo-minimal-black/layouts/partials/header.html layouts/partials/header.html
```

## Step 3 — Add the Search Button

Open `layouts/partials/header.html` and find the theme toggle button:

```html
{{ partial "dark-toggle.html" . }}
```

Add the search button just before it:

```html
<!-- Search button -->
<button
  type="button"
  class="inline-flex items-center justify-center rounded-full border border-border bg-bg p-2 text-muted shadow-sm hover:text-accent"
  aria-label="Search"
  onclick="window.MinimalSearch && window.MinimalSearch.open()"
>
  <i class="fa-solid fa-magnifying-glass text-[0.75rem]"></i>
</button>
{{ partial "dark-toggle.html" . }}
```

The `window.MinimalSearch &&` guard prevents JavaScript errors if the script hasn't loaded yet.

## Step 4 — Add Search to Mobile Menu

The mobile navigation is a separate block in the same file. Find the mobile nav links loop:

```html
{{ range .Site.Menus.main }}
  <a href="{{ .URL | relURL }}" class="flex items-center gap-2 py-1.5">
```

Add a search button before it:

```html
<button
  type="button"
  class="flex items-center gap-2 py-1.5 text-muted hover:text-accent w-full"
  aria-label="Search"
  onclick="window.MinimalSearch && window.MinimalSearch.open()"
>
  <i class="fa-solid fa-magnifying-glass text-[0.8rem]"></i>
  <span>Search</span>
</button>
{{ range .Site.Menus.main }}
```

## What the Search Supports

Once wired up, the search overlay supports:

- **Full text search** across post titles and summaries
- **Keyboard navigation** — `↑↓` to move between results, `↵` to open
- **`Ctrl+K`** (or `Cmd+K` on Mac) to open from anywhere on the site
- **`ESC`** to close
- **Highlighted matches** — search terms are highlighted in results
- **Section icons** — blog posts and projects show different icons

## Limitations

The search only indexes titles and summaries, not the full content of posts. This is intentional — indexing full content would make `index.json` very large. To make your posts more searchable, write descriptive `description` fields in your frontmatter:

```toml
+++
title = "My Post"
description = "A detailed description that will be searchable and also shown as a subtitle"
+++
```

## Result

The search icon now appears in the header on both desktop and mobile. Clicking it or pressing `Ctrl+K` opens a clean search overlay that searches across all blog posts and projects instantly.