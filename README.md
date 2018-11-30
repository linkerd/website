
## [linkerd.io](linkerd.io)

Source code for the linkerd.io website.

### General development instructions

1. Install Hugo:

    ```bash
    go get -v github.com/spf13/hugo
    ```

    or possibly:

    ```bash
    brew install hugo
    ```

1. Build site:

    ```bash
    ./build
    ```

1. Run Hugo in development mode:

    ```bash
    hugo server
    ```

1. If you would like to modify the CSS, [install SASS](http://sass-lang.com/install)

    ```bash
    sass --watch static/scss/index.scss:static/css/gen/index.css --style compressed
    ```

You should have see the site on localhost:1313, and it should reload
automatically upon file write.

### To change the way the site looks

#### CSS/HTML

The files in static/ are the CSS (SCSS), Javascript, and images for the site.
These files are served as is, except for the files in `css/gen/`, which are
processed from the files in `scss/`. If you want to change the styles, ensure
you have [SASS installed](http://sass-lang.com/install), and run:

```bash
sass --watch static/scss/index.scss:static/css/gen/index.css --style compressed
```

The files in layouts/ are the HTML for the site (including layout/index.html
for the front page.) These files are Go templates with a couple extra Hugo
goodies thrown in. See [the hugo
documentation](http://gohugo.io/templates/overview/) for details.

If you're running `hugo server` (see above) then updates should be reflected in
your browser window via some fancy javascript magic.

## [run.linkerd.io](run.linkerd.io)

Install scripts for linkerd as well as demo applications such as
[emojivoto][emojivoto].

## [versioncheck.linkerd.io](versioncheck.linkerd.io)

Location for existing installations to check and see if they're up to date or
not.

To build and serve against the latest Linkerd2 release:

```bash
make serve-versioncheck.linkerd.io
```

## [api.linkerd.io](api.linkerd.io)

API docs for linkerd1.

Note: this does not deploy by default as part of `make publish`. It needs to be
released separately.

### Updating docs from Linkerd

See [slate documentation](slate-linkerd) `./build` will grab whatever's on
master from slate-linkerd and add it to the public dir.

### Creating a new release

1. From the [linkerd.io](linkerd.io) directory, run:

    ```bash
    ./release-next-version <new version>
    ```

1. Run `./release-next-version <release-tag> <new version>` in
   [slate-linkerd](https://github.com/BuoyantIO/slate-linkerd)

1. Then check locally

    ```bash
    make serve-api.linkerd.io
    ```

1. Finally push to production

    ```bash
    make deploy-api.linkerd.io
    ```

## Publishing

1. Make sure your gcloud tooling is up to date:

    ```bash
    gcloud components update
    gcloud auth login
    ```

1. Do a dry run and make sure everything works:

    ```bash
    make publish DRY_RUN=true
    ```

1. Update the website:

    ```bash
    make publish
    ```

### Notes

- This does not update api.linkerd.io, see the section for that specifically to
  update it.

- There is no caching in front of run.linkerd.io and versioncheck.linkerd.io.
  You should see updates there immediately.

- There is caching for non-html pages in front of linkerd.io. If you're updating
  a non-html page for linkerd.io, it might be worth flushing the cache
  (cloudflare) and waiting awhile.

## If you have to create a new bucket

You probably won't have to do this, but if you do, don't forget to do this
stuff too to set up the bucket for public serving:

```bash
gsutil defacl ch -u AllUsers:R gs://bucketname
gsutil web set -m index.html -e 404.html gs://bucketname
```

## Verifying cache updates

Turn off all caching on all files:

```bash
gsutil -m setmeta -r -h "Cache-Control: no-cache, no-store, must-revalidate" gs://linkerd.io/
```

Turn caching back on:

```bash
gsutil -m setmeta -r -h "Cache-Control:" gs://linkerd.io/
```

## Enable access logs (should only need to be run once)

```bash
gsutil logging set on -b gs://linkerd2-access-logs -o AccessLog gs://linkerd.io
```

## Get access logs

```bash
# note: this will download ALL logs. probably not what you want.
gsutil -m rsync gs://linkerd2-access-logs logs/
```

## Set CORS policy (should only need to be run once)

```bash
gsutil cors set versioncheck.linkerd.io.cors.json gs://versioncheck.linkerd.io
```

[emojivoto]: https://github.com/BuoyantIO/emojivoto
[slate-linkerd]: https://github.com/BuoyantIO/slate-linkerd/blob/master/BUOYANT-README.md
