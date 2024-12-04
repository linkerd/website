
## [linkerd.io](linkerd.io)

Source code for the linkerd.io website.

### General development instructions

1. Run the linter and checker:

   ```bash
   docker run \
      --mount type=bind,source="$(pwd)",target=/website --workdir=/website \
      ghcr.io/linkerd/dev:v39 sh -c ".devcontainer/on-create.sh && make lint check"
   ```

1. Install Hugo to run the site locally:

   For Mac users:

   ```bash
   brew install hugo
   ```

   For Linux users, download the **extended** release of Hugo from its GitHub
   [release page](https://github.com/gohugoio/hugo/releases).

   The minimum version of Hugo that is required to build linkerd.io is
   **v0.131.0**.

1. From the root `/website` directory, build site and run Hugo in development mode:

    ```bash
    hugo server -s linkerd.io
    ```

You should see the site on localhost:1313, and it should reload
automatically upon file write.

[Learn more](https://github.com/linkerd/website/blob/main/linkerd.io/README.md/)
about how to add content to linkerd.io.

## [run.linkerd.io](run.linkerd.io)

Install scripts for linkerd as well as demo applications such as
[emojivoto](https://github.com/BuoyantIO/emojivoto).

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

See [slate documentation](slate-linkerd) `./build` will grab whatever's on
main from slate-linkerd and add it to the public dir.

### Creating a new release

1. Run `./release-next-version <release-tag> <new version>` in
   [https://github.com/BuoyantIO/slate-linkerd/blob/master/BUOYANT-README.md](github.com/BuoyantIO/slate-linkerd)

1. Then check locally

    ```bash
    make serve-api.linkerd.io
    ```

1. Finally push to production

    ```bash
    make deploy-api.linkerd.io
    ```

   * NB: If you're running macOS 10.14+ with `ruby` installed by XCode, you
    may have to [set the SDKROOT](https://github.com/castwide/vscode-solargraph/issues/78#issuecomment-552675511)
    in order to install `json 1.8.3` which is a `middleman` dependency.

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
