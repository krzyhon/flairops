+++
title = "Adding Tag and Category Filters to Hugo Blog"
description = "How to add interactive tag and category filtering to a Hugo blog page without any JavaScript framework"
date = "2026-03-17T10:00:00+02:00"
author = "Krzysztof Filar"
categories = ["Hugo"]
tags = ["hugo", "javascript", "frontend", "blog"]
+++

When I set up my Hugo blog using the Minimal Black theme, I noticed that blog posts supported tags and categories in frontmatter — but there was no way to filter posts by them on the blog listing page. I wanted a simple, interactive filter that didn't require any external JavaScript framework. Here's how I built it.

## The Problem

Hugo generates a static site, so filtering has to happen either:
- At build time — generating separate pages per tag (Hugo's built-in taxonomy pages)
- At runtime — using JavaScript to show/hide posts in the browser

Hugo's taxonomy pages at `/tags/kubernetes/` work fine, but I wanted something more interactive — a tag cloud at the top of the blog page where you can click a tag and instantly see only matching posts, without a page reload.

## Overriding the Blog List Template

The golden rule in Hugo is: **never edit theme files directly**. Instead, copy the file to the same relative path in your project's `layouts/` folder. Hugo always checks your project first.

```bash
mkdir -p layouts/blog
cp themes/hugo-minimal-black/layouts/blog/list.html layouts/blog/list.html
```

## Collecting Unique Tags and Categories

Inside the template, Hugo's templating language makes it easy to collect all tags and categories from all posts:

```html
{{ $allTags := slice }}
{{ $allCats := slice }}
{{ range .Pages }}
  {{ range .Params.tags }}
    {{ $allTags = $allTags | append . }}
  {{ end }}
  {{ range .Params.categories }}
    {{ $allCats = $allCats | append . }}
  {{ end }}
{{ end }}
{{ $uniqueTags := $allTags | uniq }}
{{ $uniqueCats := $allCats | uniq }}
```

The `uniq` function removes duplicates, so each tag and category appears only once in the filter cloud.

## Rendering the Filter Buttons

Once we have the unique tags and categories, we render them as buttons:

```html
{{ if $uniqueCats }}
  <div class="space-y-1">
    <p class="text-xs text-muted uppercase tracking-widest">Category</p>
    <div class="flex flex-wrap gap-2">
      <button class="card-tag-pill tag-filter-cat active" data-cat="all">All</button>
      {{ range $uniqueCats }}
        <button class="card-tag-pill tag-filter-cat" data-cat="{{ . | urlize }}">{{ . }}</button>
      {{ end }}
    </div>
  </div>
{{ end }}
```

Note the `| urlize` pipe — this converts tag names like "GitHub Actions" to `github-actions` which is safe to use as a `data-` attribute value.

## Wrapping Each Post with Data Attributes

Each post card needs to know its own tags and categories so JavaScript can show or hide it:

```html
{{ range $paginator.Pages.ByDate.Reverse }}
  <div class="post-item"
       data-tags="{{ range .Params.tags }}{{ . | urlize }} {{ end }}"
       data-cats="{{ range .Params.categories }}{{ . | urlize }} {{ end }}">
    {{ partial "components/post-card.html" (dict "Page" . "Root" $) }}
  </div>
{{ end }}
```

This produces something like:

```html
<div class="post-item" 
     data-tags="hugo javascript frontend " 
     data-cats="hugo ">
```

## The Filtering JavaScript

The JavaScript is intentionally simple — no frameworks, no dependencies:

```javascript
function filterPosts() {
  const activeTag = document.querySelector('.tag-filter-tag.active')?.dataset.tag || 'all';
  const activeCat = document.querySelector('.tag-filter-cat.active')?.dataset.cat || 'all';

  document.querySelectorAll('.post-item').forEach(post => {
    const tags = post.dataset.tags.trim().split(' ').filter(Boolean);
    const cats = post.dataset.cats.trim().split(' ').filter(Boolean);
    const tagMatch = activeTag === 'all' || tags.includes(activeTag);
    const catMatch = activeCat === 'all' || cats.includes(activeCat);
    post.classList.toggle('hidden', !(tagMatch && catMatch));
  });
}

document.querySelectorAll('.tag-filter-tag').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.tag-filter-tag').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    filterPosts();
  });
});

document.querySelectorAll('.tag-filter-cat').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.tag-filter-cat').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    filterPosts();
  });
});
```

The tag and category filters work **together** — selecting a category AND a tag will show only posts that match both conditions simultaneously.

## One Gotcha: Frontmatter Field Names

The Minimal Black theme's `post-card.html` reads `category` (singular) as a plain param, but Hugo's taxonomy system uses `categories` (plural, array). To fix this, I overrode the post card partial:

```bash
mkdir -p layouts/partials/components
cp themes/hugo-minimal-black/layouts/partials/components/post-card.html layouts/partials/components/post-card.html
```

Then changed:
```html
{{- $category := $p.Params.category | default "Article" -}}
```

To:
```html
{{- $category := index $p.Params.categories 0 | default "Article" -}}
```

This reads the first item from the `categories` array, which is the proper Hugo taxonomy format.

## Result

The blog page now has two filter rows — one for categories and one for tags. Clicking any combination instantly filters the post grid without a page reload, keeping everything fast and simple.