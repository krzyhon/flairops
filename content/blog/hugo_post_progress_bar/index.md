+++
title = "Adding a Reading Progress Bar to Hugo Blog Posts"
description = "How to add a reading progress bar to Hugo blog posts using pure CSS and vanilla JavaScript"
date = "2026-03-24T10:00:00+02:00"
author = "Krzysztof Filar"
categories = ["Hugo"]
tags = ["hugo", "javascript", "css", "frontend", "blog"]
+++

A reading progress bar is a thin bar at the top of the page that fills up as you scroll through an article. It gives readers a visual indication of how far through a post they are. Here's how I added one to my Hugo site with minimal code.

## Approach

There are two common approaches:

1. **Full page scroll** — the bar fills based on how far down the entire page you've scrolled
2. **Article scroll** — the bar fills based on how far through the article content specifically you've scrolled

I went with the second approach since it's more accurate — it ignores the header and footer and only tracks progress through the actual article content.

## Implementation

Since I already had a custom `layouts/_default/single.html` override, I added the progress bar there. If you don't have one yet, create it first:

```bash
mkdir -p layouts/_default
cp themes/hugo-minimal-black/layouts/_default/single.html layouts/_default/single.html
```

### The HTML

Add a fixed `div` at the very top of the template, right after `{{ define "main" }}`:

```html
{{ define "main" }}
<div id="reading-progress"
  style="position:fixed;top:0;left:0;height:3px;width:0%;
         background:linear-gradient(to right, #a855f7, #7c3aed);
         z-index:9999;transition:width 0.1s ease;">
</div>
```

Key CSS properties:
- `position:fixed` — stays at the top as you scroll
- `top:0;left:0` — anchored to the top-left corner
- `height:3px` — thin and unobtrusive
- `width:0%` — starts empty, JavaScript updates this
- `z-index:9999` — sits above everything else
- `transition:width 0.1s ease` — smooth animation as it fills

### The JavaScript

```javascript
window.addEventListener('scroll', function () {
  const article = document.querySelector('.markdown-body');
  if (!article) return;

  const articleTop = article.offsetTop;
  const articleHeight = article.offsetHeight;
  const scrollTop = window.scrollY;
  const windowHeight = window.innerHeight;

  const progress = Math.min(100, Math.max(0,
    ((scrollTop - articleTop + windowHeight) / articleHeight) * 100
  ));

  document.getElementById('reading-progress').style.width = progress + '%';
});
```

The formula calculates progress as a percentage of the article that has passed through the viewport:

- `scrollTop - articleTop` — how far past the article start we've scrolled
- `+ windowHeight` — account for the viewport height (article starts entering view before scrollTop reaches articleTop)
- `/ articleHeight` — normalize to a 0-1 range
- `* 100` — convert to percentage
- `Math.min(100, Math.max(0, ...))` — clamp between 0% and 100%

The `.markdown-body` selector targets the article content div specifically, so the bar only tracks progress through the actual content, not the header or footer.

## Customisation

**Change the color** — update the gradient values:
```css
background:linear-gradient(to right, #a855f7, #7c3aed);
```

**Make it thicker**:
```css
height: 5px;
```

**Add a shadow for depth**:
```css
box-shadow: 0 0 8px rgba(168, 85, 247, 0.5);
```

**Slow down the animation**:
```css
transition: width 0.3s ease;
```

## Result

A thin purple gradient bar now appears at the top of every blog post and fills smoothly as you scroll through the content. It resets to zero when you navigate away. The entire implementation is about 20 lines of code with no dependencies.