+++
title = "Adding Open Graph Social Preview Images to a Hugo Site"
description = "How to add Open Graph meta tags and a social preview image to a Hugo site so links look great when shared on LinkedIn, Twitter/X, and Slack"
date = "2026-04-14T10:00:00+02:00"
author = "Krzysztof Filar"
categories = ["Hugo"]
tags = ["hugo", "seo", "open-graph", "social", "blog"]
+++

When you share a URL on LinkedIn, Twitter/X, or Slack, the platform fetches metadata from the page to generate a preview card — title, description, and an image. Without Open Graph tags, you just get a plain link. Here's how I added proper OG support to my Hugo site.

## What is Open Graph?

Open Graph is a protocol originally created by Facebook that has become the standard for social media link previews. It uses `<meta>` tags in the HTML `<head>` to define how a page should be represented when shared:

```html
<meta property="og:title" content="My Post Title" />
<meta property="og:description" content="A description of the post" />
<meta property="og:image" content="https://example.com/images/og-image.png" />
<meta property="og:url" content="https://example.com/my-post/" />
```

Twitter/X has its own similar system called Twitter Cards, but it falls back to OG tags if Twitter-specific tags are missing.

## Overriding the Meta Partial

The Minimal Black theme has a `meta.html` partial but it only includes basic description and author tags — no Open Graph at all. Override it:

```bash
mkdir -p layouts/partials
cp themes/hugo-minimal-black/layouts/partials/meta.html layouts/partials/meta.html
```

Then replace the content with a full OG implementation:

```html
{{- with .Description -}}
<meta name="description" content="{{ . }}" />
{{- else -}}
<meta name="description" content="{{ .Site.Params.description }}" />
{{- end }}

{{- with .Site.Params.author }}
<meta name="author" content="{{ . }}" />
{{- end }}

{{- /* Open Graph */}}
<meta property="og:site_name" content="{{ .Site.Title }}" />
<meta property="og:title" content="{{ if .IsHome }}{{ .Site.Title }}{{ else }}{{ .Title }} — {{ .Site.Title }}{{ end }}" />
<meta property="og:type" content="{{ if .IsPage }}article{{ else }}website{{ end }}" />
<meta property="og:url" content="{{ .Permalink }}" />

{{- with .Description }}
<meta property="og:description" content="{{ . }}" />
{{- else }}
<meta property="og:description" content="{{ .Site.Params.description }}" />
{{- end }}

{{- $ogImage := "" }}
{{- with .Params.image }}
  {{- $ogImage = . | absURL }}
{{- else }}
  {{- $ogImage = "images/og-image.png" | absURL }}
{{- end }}
<meta property="og:image" content="{{ $ogImage }}" />
<meta property="og:image:width" content="1200" />
<meta property="og:image:height" content="630" />

{{- /* Twitter Card */}}
<meta name="twitter:card" content="summary_large_image" />
<meta name="twitter:title" content="{{ if .IsHome }}{{ .Site.Title }}{{ else }}{{ .Title }} — {{ .Site.Title }}{{ end }}" />
{{- with .Description }}
<meta name="twitter:description" content="{{ . }}" />
{{- else }}
<meta name="twitter:description" content="{{ .Site.Params.description }}" />
{{- end }}
<meta name="twitter:image" content="{{ $ogImage }}" />

{{- /* Article specific tags */}}
{{- if .IsPage }}
<meta property="article:published_time" content="{{ .Date.Format "2006-01-02T15:04:05Z07:00" }}" />
<meta property="article:modified_time" content="{{ .Lastmod.Format "2006-01-02T15:04:05Z07:00" }}" />
{{- range .Params.tags }}
<meta property="article:tag" content="{{ . }}" />
{{- end }}
{{- end }}
```

## The OG Image

The OG image should be **1200×630px PNG** — this is the standard size supported by all platforms. A few important notes:

- **No transparent background** — social platforms render OG images on their own backgrounds. A transparent image will look broken.
- **Keep it simple** — the image is displayed small in previews, so avoid small text
- **PNG format** — SVG is not supported by most platforms for OG images

I created mine as an SVG (easier to design) and then converted it to PNG. The image includes the site logo, name, tagline, and domain.

Place the final PNG at:

```
static/images/og-image.png
```

## Per-Post Images

You can override the OG image on a per-post basis by adding an `image` field to the post frontmatter:

```toml
+++
title = "My Post"
image = "my-post-cover.png"
+++
```

If the image is in the same directory as the post (page bundle), reference it with the full path:

```toml
image = "/blog/my-post/cover.png"
```

If no `image` is specified, the default `og-image.png` is used automatically.

## Verifying the Results

After deploying, use [opengraph.xyz](https://www.opengraph.xyz) to check how your site looks when shared. Enter your URL and it shows previews for Facebook, Twitter, LinkedIn, and Slack.

Common issues to watch for:
- **Title too short** — aim for 50-60 characters
- **Description too short** — aim for 110-160 characters
- **Image wrong size** — must be at least 1200×630px

## Result

Every page on the site now has proper Open Graph and Twitter Card meta tags. The homepage uses the default OG image and the site description. Individual blog posts use their own `description` frontmatter field, making each post shareable with a meaningful preview.