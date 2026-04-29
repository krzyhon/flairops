+++
title = "Adding a Related Posts Section to Hugo Blog Posts"
description = "How to add an automatic related posts section at the bottom of Hugo blog posts using Hugo's built-in Related Pages feature"
date = "2026-04-21T10:00:00+02:00"
author = "Krzysztof Filar"
categories = ["Hugo"]
tags = ["hugo", "blog", "frontend", "templates"]
+++

A related posts section at the bottom of a blog post helps readers discover more content and keeps them engaged. Hugo has a built-in Related Pages feature that automatically finds similar posts based on shared tags and categories. Here's how I set it up.

## Hugo's Built-in Related Pages

Hugo's `.Related` function compares the current page against all other pages and returns the most similar ones based on configurable criteria. It supports matching by tags, categories, keywords, date proximity, and more.

The function is fast because Hugo pre-computes the similarity index at build time — there's no runtime cost.

## Step 1 — Configure Related Pages in hugo.toml

First, tell Hugo what to use for matching. Add this to `hugo.toml`:

```toml
[related]
  threshold = 80
  includeNewer = true
  toLower = true

  [[related.indices]]
    name = "tags"
    weight = 100

  [[related.indices]]
    name = "categories"
    weight = 80
```

The configuration options:

- `threshold` — minimum similarity score (0-100) for a post to be considered related. Lower values return more results but less relevant ones. Start with 80 and lower to 50 if you don't see results.
- `includeNewer` — whether to include posts published after the current one
- `toLower` — case-insensitive tag matching
- `weight` — how much each index contributes to the similarity score. Tags have higher weight than categories here, meaning shared tags matter more than shared categories.

## Step 2 — Add Related Posts to the Post Template

Override the single post template if you haven't already:

```bash
mkdir -p layouts/_default
cp themes/hugo-minimal-black/layouts/_default/single.html layouts/_default/single.html
```

Then find the post content div and add the related posts section after it, before the comments:

```html
<div class="card card-pad">
  <div class="markdown-body">
    {{ .Content }}
  </div>
</div>

{{/* Related posts */}}
{{ $related := .Site.RegularPages.Related . | first 3 }}
{{ with $related }}
  <div class="space-y-3">
    <p class="text-xs text-muted uppercase tracking-widest">Related Posts</p>
    <div class="grid gap-4 md:grid-cols-3">
      {{ range . }}
        {{ partial "components/post-card.html" (dict "Page" . "Root" $) }}
      {{ end }}
    </div>
  </div>
{{ end }}
```

Key parts of this template:

- `.Site.RegularPages.Related .` — finds all pages related to the current page (`.`)
- `| first 3` — limits to 3 results
- `{{ with $related }}` — only renders the section if there are any related posts, so posts with no matches don't show an empty section
- `partial "components/post-card.html"` — reuses the existing post card component for consistent styling

## How Similarity is Calculated

Hugo calculates a similarity score for each page based on the configured indices. For example, if the current post has tags `["hugo", "terraform", "github-actions"]`:

- A post with tags `["hugo", "terraform"]` scores highly — 2 shared tags
- A post with tags `["hugo"]` scores lower — 1 shared tag
- A post with only a shared category scores even lower — categories have lower weight

Only posts scoring above the `threshold` are returned.

## Troubleshooting

**No related posts showing?**

First check that you have at least two posts with shared tags. Then lower the threshold:

```toml
[related]
  threshold = 50
```

**Wrong posts showing?**

Your tags might be too generic. Using very common tags like `devops` on every post means everything is related to everything. Use more specific tags like `terraform-modules` or `github-actions-workflow` to get more meaningful relationships.

**Related posts pointing to the current post?**

Hugo's `.Related` function automatically excludes the current page, so this shouldn't happen. If it does, check that your pages have unique permalinks.

## Result

Every blog post now shows up to 3 related posts at the bottom, automatically selected based on shared tags and categories. The section only appears when there are actual matches, keeping the layout clean for posts with no related content yet.