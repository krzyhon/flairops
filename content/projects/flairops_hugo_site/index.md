+++
title = "FlairOps — Personal DevOps Site Built with Hugo"
description = "How I built my personal DevOps site using Hugo, Minimal Black theme, GitHub Actions, and GitHub Pages with a custom domain"
date = "2026-04-28T10:00:00+02:00"
author = "Krzysztof Filar"
categories = ["Hugo"]
tags = ["hugo", "github-actions", "github-pages", "devops", "terraform"]
featured = true
repo = "https://github.com/krzyhon/flairops"
website = "https://flairops.cloud"
websiteLabel = "Visit Site"
subtitle = "Personal site and blog built with Hugo, deployed via GitHub Actions"
+++

FlairOps is my personal DevOps site and blog — a place to document what I build, share technical knowledge, and serve as an online CV. It's built with Hugo, a fast static site generator written in Go, using the Minimal Black theme as a base.

## Stack

- **Hugo** — static site generator
- **Minimal Black theme** — dark-mode first theme from GitLab
- **GitHub Actions** — automatic build and deployment on every push
- **GitHub Pages** — free hosting
- **flairops.cloud** — custom domain with HTTPS

## Why Hugo?

I wanted a site that is fast, free to host, easy to maintain, and doesn't require a backend or database. Hugo fits perfectly:

- Builds in milliseconds
- Outputs plain HTML/CSS/JS — no server required
- Content written in Markdown
- Version controlled in Git
- Free hosting on GitHub Pages

## Project Structure

```
flairops/
├── .github/
│   └── workflows/
│       └── deploy.yml        # GitHub Actions workflow
├── content/
│   ├── blog/                 # Blog posts (page bundles)
│   ├── projects/             # Project pages
│   └── about/
│       └── _index.md         # CV / About page
├── layouts/                  # Theme overrides
│   ├── _default/
│   │   └── single.html       # Post template with Giscus, related posts, progress bar
│   ├── blog/
│   │   └── list.html         # Blog list with tag/category filtering
│   ├── projects/
│   │   └── list.html         # Projects list with tag/category filtering
│   └── partials/
│       ├── components/
│       │   ├── post-card.html
│       │   └── project-card.html
│       ├── home/
│       │   └── hero.html
│       ├── header.html       # Header with search button
│       └── meta.html         # Open Graph meta tags
├── static/
│   ├── images/
│   │   ├── logo.svg
│   │   ├── avatar.svg
│   │   └── og-image.png
│   ├── icons/
│   │   └── favicon.svg
│   └── CNAME                 # Custom domain for GitHub Pages
└── hugo.toml                 # Site configuration
```

## GitHub Actions Deployment

Every push to the `main` branch triggers an automatic build and deployment:

```yaml
name: Build and deploy
on:
  push:
    branches:
      - main
  workflow_dispatch:
permissions:
  contents: read
  pages: write
  id-token: write
concurrency:
  group: pages
  cancel-in-progress: false
defaults:
  run:
    shell: bash
jobs:
  build:
    runs-on: ubuntu-latest
    env:
      DART_SASS_VERSION: 1.99.0
      GO_VERSION: 1.26.1
      HUGO_VERSION: 0.160.0
      NODE_VERSION: 24.14.1
      TZ: Europe/Oslo
    steps:
      - name: Checkout
        uses: actions/checkout@v6
        with:
          submodules: recursive
          fetch-depth: 0
      - name: Setup Go
        uses: actions/setup-go@v6
        with:
          go-version: ${{ env.GO_VERSION }}
          cache: false
      - name: Setup Node.js
        uses: actions/setup-node@v6
        with:
          node-version: ${{ env.NODE_VERSION }}
      - name: Setup Pages
        id: pages
        uses: actions/configure-pages@v6
      - name: Create directory for user-specific executable files
        run: |
          mkdir -p "${HOME}/.local"
      - name: Install Dart Sass
        run: |
          curl -sLJO "https://github.com/sass/dart-sass/releases/download/${DART_SASS_VERSION}/dart-sass-${DART_SASS_VERSION}-linux-x64.tar.gz"
          tar -C "${HOME}/.local" -xf "dart-sass-${DART_SASS_VERSION}-linux-x64.tar.gz"
          rm "dart-sass-${DART_SASS_VERSION}-linux-x64.tar.gz"
          echo "${HOME}/.local/dart-sass" >> "${GITHUB_PATH}"
      - name: Install Hugo
        run: |
          curl -sLJO "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz"
          mkdir "${HOME}/.local/hugo"
          tar -C "${HOME}/.local/hugo" -xf "hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz"
          rm "hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz"
          echo "${HOME}/.local/hugo" >> "${GITHUB_PATH}"
      - name: Verify installations
        run: |
          echo "Dart Sass: $(sass --version)"
          echo "Go: $(go version)"
          echo "Hugo: $(hugo version)"
          echo "Node.js: $(node --version)"
      - name: Install Node.js dependencies
        run: |
          [[ -f package-lock.json || -f npm-shrinkwrap.json ]] && npm ci || true
      - name: Configure Git
        run: |
          git config core.quotepath false
      - name: Cache restore
        id: cache-restore
        uses: actions/cache/restore@v5
        with:
          path: ${{ runner.temp }}/hugo_cache
          key: hugo-${{ github.run_id }}
          restore-keys:
            hugo-
      - name: Build the site
        run: |
          hugo build \
            --gc \
            --minify \
            --baseURL "${{ steps.pages.outputs.base_url }}/" \
            --cacheDir "${{ runner.temp }}/hugo_cache"
      - name: Cache save
        id: cache-save
        uses: actions/cache/save@v5
        with:
          path: ${{ runner.temp }}/hugo_cache
          key: ${{ steps.cache-restore.outputs.cache-primary-key }}
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v5
        with:
          path: ./public
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v5
```

## Custom Domain Setup

GitHub Pages supports custom domains. The setup requires:

1. A `CNAME` file in `static/` with the domain name — this ensures the custom domain is preserved after every deployment
2. Four `A` records in DNS pointing to GitHub's IP addresses
3. A `CNAME` record for `www` pointing to `krzyhon.github.io`
4. Enabling HTTPS in the repository's Pages settings

```
# static/CNAME
flairops.cloud
```

DNS records:
```
A    @    185.199.108.153
A    @    185.199.109.153
A    @    185.199.110.153
A    @    185.199.111.153
CNAME www  krzyhon.github.io
```

## Theme Customisations

All customisations follow Hugo's override pattern — files in `layouts/` take priority over theme files. The theme itself is never modified directly, making updates safe.

### Blog and Project Filtering

Added interactive tag and category filtering to both the blog and projects listing pages. Posts are filtered client-side using vanilla JavaScript and `data-` attributes — no framework required. Read more in [Adding Tag and Category Filters to Hugo Blog](/blog/hugo_category_filtering/).

### Search

The Minimal Black theme ships with a full search overlay powered by a JSON index, but it wasn't exposed in the UI. I added a search button to the header that calls `window.MinimalSearch.open()`, the global API exposed by the theme's search script. Read more in [Enabling Search Functionality in Hugo with Minimal Black Theme](/blog/hugo_search/).

### Comments

Giscus powers the comment section on every blog post. Comments are stored as GitHub Discussions in this repository — no external database, no ads, no tracking. Read more in [Adding Comments to Hugo Blog Posts with Giscus](/blog/hugo_giscus_comment/).

### Reading Progress Bar

A thin purple gradient bar at the top of each blog post fills as you scroll through the content. Implemented with ~15 lines of vanilla JavaScript tracking scroll position relative to the article element. Read more in [Adding a Reading Progress Bar to Hugo Blog Posts](/blog/hugo_post_progress_bar/).

### Related Posts

Hugo's built-in `.Related` function automatically finds posts with matching tags and categories. Up to 3 related posts are displayed at the bottom of each blog post using the existing post card component. Read more in [Adding a Related Posts Section to Hugo Blog Posts](/blog/hugo_related_posts/).

### Open Graph

Added full Open Graph and Twitter Card meta tags to every page. Each blog post uses its `description` frontmatter field for the OG description. A default 1200×630px OG image is used for pages without a specific image. Read more in [Adding Open Graph Social Preview Images to a Hugo Site](/blog/hugo_open_graph/).

## Logo and Branding

The site logo, avatar, and favicon are all built around a Möbius strip SVG. The strip is rendered in a purple gradient matching the theme's accent colour. The SVGs are generated programmatically using Python to extract and re-colour the original paths.

## Content Workflow

Writing a new blog post:

```bash
# Create a new post as a page bundle
hugo new content blog/my-new-post/index.md

# Start local development server with drafts
hugo server -D

# Edit content/blog/my-new-post/index.md
# Add images to content/blog/my-new-post/

# When ready to publish, set draft = false
# Commit and push — GitHub Actions deploys automatically
git add .
git commit -m "Add new blog post"
git push
```

## What's Next

- Google Analytics or Plausible for visitor tracking
- Customised 404 page
- More blog posts documenting DevOps tools and workflows