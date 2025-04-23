# linkerd.io

## General development instructions

### Run the linter and checker

```bash
docker run \
  --mount type=bind,source="$(pwd)",target=/website --workdir=/website \
  ghcr.io/linkerd/dev:v44 sh -c ".devcontainer/on-create.sh && make lint check"
```

### Install Hugo to develop locally

For Mac users:

```bash
brew install hugo@0.136.5
```

Or download the **extended** release of Hugo from the GitHub
[release page](https://github.com/gohugoio/hugo/releases/tag/v0.136.5).

### Run Hugo locally

From the root `/website` directory, build site and run Hugo in development mode:

```bash
hugo server -s linkerd.io
```

You should see the site on localhost:1313, and it should reload automatically
upon file write.

## Hugo version requirements

When linkerd.io is deployed to production, we use Hugo `v0.136.5`.

## Website images

Please do not put files in the `static` directory that are referenced on
linkerd.io. This directory is reserved for assets that are used as external
resources. If you need to add images for a page, please add them in the
[page bundle](https://gohugo.io/content-management/page-bundles/).

## Tasks

### Creating a blog post

To create a blog post, start by creating a blog post folder in the `blog`
directory using the following format: `/blog/YYYY/MMDD-title/`. For example:
`/blog/2024/0102-my-blog-post`.

Next, create an `index.md` file in the folder with the following frontmatter:

```yaml
title: # The title of your blog post
description: # The description of your blog post
date: # The date of your post in the format: `2024-01-01T00:00:00Z`
slug: # The URL slug for the page. Only set this param if you want to use a different slug than the title.
keywords: [] # An array of keywords are used to relate blog posts
params:
  author: # The author of the blog post
```

#### Assigning an author

There are 2 ways to assign an author to a blog post.

1. If the author has more than one blog post, the author data should be defined
   in `data/authors.yaml`, then the author id can be set in the frontmatter
   params. For example:

```yaml
params:
  author: william
```

2. If the author is only going to have a single blog post, the author data can
   be set inline if desired. For example:

```yaml
params:
  author:
    name: Author name
    avatar: avatar.png
```

For inline author data, the avatar image can either be a page resource or a
remote image. To use a remote image, simply provide the full url to the image,
and Hugo will download and resize it when the site is published. For example:

```yaml
params:
  author:
    name: John Smith
    avatar: https://example.com/avatars/john-smith.png
```

**Note:** If an author only has a single blog post, but there's a chance they
will have more in the future, please not use the inline method.

#### Cover, thumbnail, and feature images

To associate a cover, thumbnail, or feature image to a blog post, you do not
have to specify them in the frontmatter. You can simply name them `cover`,
`thumbnail` or `feature`, place them in the blog post folder, and they will
automattically be used. For example:

```text
blog/
└── 2024/
    └── 0102-my-blog-post
        ├── cover.jpg
        ├── index.md
        └── thumbnail.jpg
```

If a blog post is featured, by default, the cover image will be used on the blog
list page. If a cover image is not present, or you would like to use a different
image than the cover image, you can name it `feature` and place it in the blog
post folder.

If a thumbnail image is not present in the blog post folder, then the cover
image will be used. By default, the thumbnail image will be cropped into a
square. If you would like to maintaining the original aspect ratio, you can set
the `thumbnailRatio` frontmatter param to `fit`. For example:

```yaml
params:
  thumbnailRatio: fit
```

You can automattically show the cover image at the top of the blog post by
adding the `showCover` frontmatter param. For example:

```yaml
params:
  showCover: true
```

If you need to name your images another way, you can reference the image names
in the frontmatter:

```yaml
params:
  thumbnail: square.png
  cover: hero.png
  feature: hero-cropped.png
```

#### Open graph images

By default, the first 6 images from the `images` array are used when the blog
post is shared on social media. For example:

```yaml
images: [social.png]
```

If the images array is empty, images with names matching `feature`, `cover`, or
`thumbnail` will be used in that order.

#### Markdown images

All images that you want to include in your markdown content should also be
placed in the blog post folder and referenced using a markdown image syntax. For
example:

```markdown
![Alt text](my-image.jpg)
```

To display a caption below the image, provide an image title. For example:

```markdown
![Alt text](my-image.jpg 'My image caption')
```

To center the image, use a Markdown attribute:

```markdown
![Alt text](my-image.jpg) {.center}
```

### Hiding pages in the docs sidenav

_(docs page only)_

A page can be prevented from showing in the sidenav by setting the `unlisted`
frontmatter parameter. The page will be hidden in the sidenav, but can be linked
to externally or from some other page.

```yaml
---
params:
  unlisted: true
---
```

**Note:** Setting this parameter **does not** prevent the page from being shown
on the search results page, or search engines from indexing the page.

### Hiding page from search engines

A page can be prevented from being shown on the search results page, and indexed
by search engines by setting the `noIndex` frontmatter parameter.

```yaml
---
params:
  noIndex: true
---
```

**Note:** Adding this param will cause `<meta name="robots" content="noindex">`
to be added to the `<head>` of the page. It **does not** add the URL of the page
to the robots.txt file.

### Disabling the copy button in codeblocks

Highlighting in code fences is enabled by default. A Copy button will
automatically be added to every highlighted codeblock. If you wish to disable
the copy button for a single codeblock, you can do so by adding the
`disable-copy` class attribute after the language identifier.

```
bash {class=disable-copy}
```

### Creating a new major version

To create a new major version for the Linkerd docs, follow the steps below. As
an example we suppose the latest major is `2.18` and we'd like to create docs
for the upcoming `2.19` version, that will appear at `https://linkerd.io/2.19`.

- Clone the `https://github.com/linkerd/website` repo
- Create a new branch `yourusername/2.19`
- Update the latest version in `linkerd.io/config/_default/params.yaml`:
  `latestMajorVersion: "2.19"`
- Update the `docs` menu in `linkerd.io/config/_default/menu.yaml` to include a
  menu item for `2.19`.
- Make sure all the links in the edge version (`2-edge`) are relative and don't
  have the version hard-coded. E.g. `(/../cli/install/#)` instead of
  `(/2-edge/reference/cli/install/#)`.
- Add a row to the Supported Kubernetes Versions table for `2.19` in
  `linkerd.io/content/2-edge/reference/k8s-versions.md`.
- Create an entire new directory, copying the edge docs:
  `cp -r linkerd.io/content/2-edge linkerd.io/content/2.19`. Any upcoming doc
  changes pertaining to `2.19` should be pushed against that new directory and
  the `2-edge` directory.
- Generate the CLI docs with `linkerd doc > linkerd.io/data/cli/2-19.yaml`. Just
  to make sure the edge data is up to date, copy the contents from this newly
  genereated file to `linkerd.io/data/cli/2-edge.yaml`.
- Push, and hold the merge till after `2.19` is out.
- After merging, update the Cloudflare redirection rule so `/2` points to
  `/2.19`:
  - Click on the `linkerd.io` site
  - Click on the `Rules`section
  - Update the rule `https://linkerd.io/2/*` so that it points to
    `https://linkerd.io/2.19/$1`
