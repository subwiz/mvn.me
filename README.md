# mvn.me

Personal site hosted on GitHub Pages. The homepage and writings
use GitHub Pages' built-in Jekyll support. The homepage automatically links the
three newest published articles, with a link to all writings. No custom plugins or project package
installation are needed for publishing.

## Write an article

Create `writings/<slug>/index.md`. Put images, videos, and captions in that folder
(or an `assets/` subfolder), so everything for an article stays together.

```markdown
---
title: "My article"
description: "A short summary used in the writings index and sharing previews."
date: 2026-10-11
cover: /writings/my-article/cover.png
cover_alt: "A description of the cover for readers using screen readers."
tags: [poetry, YouTube]
published: false
---

Write the article in **Markdown**.
```

Use a unique folder slug. Set `date` to the publication date in `YYYY-MM-DD`
format. `title`, `description`, and `date` should always be present. Cover and
tags are optional; supply `cover_alt` whenever you use a cover. The author
and article layout come from `_config.yml` and can be overridden in metadata.
For covers, use a site-root path as shown above (or a complete HTTPS URL).

When ready, set `published: true` and push to the publishing branch (`master`).
GitHub Pages rebuilds `/writings/index.html` from the metadata of all writing
pages, newest first. There is no list to maintain. Removing an article removes
it from the next build. `published: false` excludes both the article and its
index entry from production. Future dates do not schedule publication; keep
`published: false` until you are ready.

`writings/index.html` is a Liquid template; the built `_site/writings/index.html`
is the generated HTML. Do not edit the generated files. Source HTML containing
Liquid needs a Jekyll build before it can be previewed.

## Inline images and videos

Use as many images or videos as you like, anywhere in the Markdown body.
Relative media paths resolve from the article's URL:

```markdown
![A recording setup](./assets/recording.jpg)

![A page from the poetry book](./assets/book.jpg)
```

For an image caption, use HTML:

```html
<figure>
  <img src="./assets/book.jpg" alt="A page from the poetry book" loading="lazy">
  <figcaption>The poem that inspired this reading.</figcaption>
</figure>
```

YouTube embeds use the video's ID from `youtube.com/watch?v=VIDEO_ID` or
`youtu.be/VIDEO_ID`, not a channel handle:

```liquid
{% include youtube.html id="VIDEO_ID" title="Name of the poem" caption="A reading from my channel." %}
```

The embed uses YouTube's privacy-enhanced `youtube-nocookie.com` domain,
lazy loading, a descriptive title, and a responsive frame.

For a local video:

```liquid
{% include video.html src="./assets/reading.mp4" poster="./assets/recording.jpg" title="A poetry reading" caption="Recorded at home." captions="./assets/reading.vtt" %}
```

`poster`, `caption`, and `captions` are optional. Captions are WebVTT files.
For WebM, add `type="video/webm"`. You can also write standard HTML `<video>`
or `<iframe>` elements directly. Only include trusted HTML in articles.

## Preview and verify

If Jekyll is already available locally:

```sh
jekyll serve
# Include unpublished articles while writing:
jekyll serve --unpublished
```

Open `http://localhost:4000/writings/` or
`http://localhost:4000/writings/classical-poems-yt/` in the draft preview.
The Classical Poems article is marked published. New articles can use
`published: false` while you write and review them in the draft preview.

For build regression checks:

```sh
ruby tests/writings_test.rb
```

These tests build isolated copies of the site to check index discovery/order,
metadata, cover assets, draft visibility, multiple images, and both video types. For a clean deployment, keep GitHub Pages set
to **Deploy from a branch**, `master`, `/ (root)`; it runs Jekyll automatically.
