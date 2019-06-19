+++
aliases = ["/getting-started/docker"]
description = "How to run Linkerd through a Docker container."
title = "Running with Docker"
weight = 3
[menu.docs]
parent = "getting-started"
weight = 33

+++
If you're using Docker to run Linkerd, there is no need to pull the release
binary from GitHub, as described in the previous section. Instead, Buoyant
provides the following public Docker images for you:

{{% dockerbuttons %}}

## Tags

Both repositories have tags for all stable released versions of each image. To
see a list of releases with associated changes, visit the [Linkerd GitHub
releases](https://github.com/linkerd/linkerd/releases) page.

In addition to the versioned tags, the "latest" tag always points to the most
recent stable release. This can be useful for environments that want to pick up
new code without manually bumping the dependency version, but note that the
latest tag may pull an image with breaking changes from a previous version,
depending on the nature of the Linkerd release.

Furthermore, the "nightly" tag is used to provide nightly builds of both Linkerd
and namerd from the most recent commit on the master branch in the [Linkerd
GitHub repository](https://github.com/linkerd/linkerd). This image is
unstable, but can be used for testing recently added features and fixes.

## Running

The default entrypoint for the Linkerd image runs the Linkerd executable, which
requires that a [Linkerd config file]({{% linkerdconfig %}}) be passed to it
on the command line. The easiest way to accomplish this is by mounting a config
file into the container at startup.

For instance, given the following config that simply forwards http requests
received on port 8080 to the Linkerd admin service running on port 9990:

```yaml
admin:
  port: 9990
  ip: 0.0.0.0

routers:
- protocol: http
  dtab: /svc => /$/inet/127.1/9990;
  servers:
  - port: 8080
    ip: 0.0.0.0
```

We can start the Linkerd container with:

```bash
$ docker run --name linkerd -p 9990:9990 -v `pwd`/config.yaml:/config.yaml buoyantio/linkerd:{{% latestversion %}} /config.yaml
...
I 0922 02:01:12.862 THREAD1: serving http admin on /0.0.0.0:9990
I 0922 02:01:12.875 THREAD1: serving http on localhost/127.0.0.1:8080
I 0922 02:01:12.890 THREAD1: linkerd initialized.
```

## Making sure it works

To verify that it's working correctly, we can exec into the running container
and curl Linkerd's admin ping endpoint via the http router's configured port:

```bash
$ docker exec linkerd curl -s 127.1:8080/admin/ping
pong
```

Success!

You can also visit Linkerd's admin UI directly in a web browser by navigating to
port 9990 on your Docker host (typically `localhost`).

For more information about Linkerd's admin capabilities, see the
[Administration](/1/administration/) page.
