+++
title = "Adding Comments to Hugo Blog Posts with Giscus"
description = "How to add a free, GitHub-powered comments system to a Hugo static site using Giscus"
date = "2026-04-07T10:00:00+02:00"
author = "Krzysztof Filar"
categories = ["Hugo"]
tags = ["hugo", "giscus", "github", "comments", "blog"]
+++

Static sites don't have a backend, so adding comments requires an external service. Most options are either paid, privacy-invasive, or require managing a separate database. Giscus solves all of these problems — it stores comments as GitHub Discussions in your repository, it's completely free, and it has no ads or tracking.

## What is Giscus?

Giscus is an open-source comments widget powered by GitHub Discussions. When a visitor leaves a comment on your blog post, it creates a Discussion thread in your GitHub repository. You get notified via GitHub and can reply either on the site or directly in the Discussions tab.

Requirements for visitors to comment:
- A GitHub account
- Authorization of the Giscus app

For a DevOps/tech blog this is a perfect fit — your audience almost certainly has GitHub accounts.

## Step 1 — Enable GitHub Discussions

Go to your repository on GitHub:

1. Click **Settings**
2. Scroll to the **Features** section
3. Check **Discussions**
4. Click **Set up discussions** to create the initial welcome thread

## Step 2 — Install the Giscus GitHub App

Go to [github.com/apps/giscus](https://github.com/apps/giscus) and install it:

1. Click **Install**
2. Select your account
3. Under **Repository access**, select **Only select repositories**
4. Choose your site repository
5. Click **Install**

## Step 3 — Generate Your Configuration

Go to [giscus.app](https://giscus.app) and fill in the form:

- **Repository** — your GitHub repo, e.g. `krzyhon/flairops`
- **Page ↔ Discussions Mapping** — `pathname` (each post URL maps to a unique Discussion)
- **Discussion Category** — `Announcements` (prevents visitors from creating new Discussion categories)
- **Theme** — `transparent_dark` (matches the Minimal Black theme)

The page generates a `<script>` tag automatically:

```html
<script src="https://giscus.app/client.js"
  data-repo="your-username/your-repo"
  data-repo-id="R_xxxxxxxxxx"
  data-category="Announcements"
  data-category-id="DIC_xxxxxxxxxx"
  data-mapping="pathname"
  data-strict="0"
  data-reactions-enabled="1"
  data-emit-metadata="0"
  data-input-position="bottom"
  data-theme="transparent_dark"
  data-lang="en"
  crossorigin="anonymous"
  async>
</script>
```

## Step 4 — Add to the Post Template

Override the single post template if you haven't already:

```bash
mkdir -p layouts/_default
cp themes/hugo-minimal-black/layouts/_default/single.html layouts/_default/single.html
```

Find the closing `</article>` tag and add the Giscus script inside the `article-main` section, after the post content div:

```html
<div class="card card-pad">
  <script src="https://giscus.app/client.js"
    data-repo="your-username/your-repo"
    data-repo-id="R_xxxxxxxxxx"
    data-category="Announcements"
    data-category-id="DIC_xxxxxxxxxx"
    data-mapping="pathname"
    data-strict="0"
    data-reactions-enabled="1"
    data-emit-metadata="0"
    data-input-position="bottom"
    data-theme="transparent_dark"
    data-lang="en"
    crossorigin="anonymous"
    async>
  </script>
</div>
```

Wrapping it in `card card-pad` gives it the same card styling as the post content, keeping the visual consistency of the theme.

## Important: Placement in the Template

The `article-layout` in this theme uses a CSS grid with two columns — the Table of Contents on the left (narrower) and the main article on the right (wider). If you place the Giscus script outside the `<article class="article-main">` element, it will end up below the Table of Contents in the left column, appearing very narrow and misplaced.

Make sure the Giscus div is **inside** `<article class="article-main">`, after the post content but before the closing `</article>` tag.

## Testing

Giscus does not work on `localhost` — it only works on the live site. This is by design, as GitHub OAuth requires a real domain. After deploying, scroll to the bottom of any post and you should see the comment box.

## Result

Every blog post now has a comment section powered by GitHub Discussions. Comments are stored in your repository, you own the data, and there are no third-party trackers involved.