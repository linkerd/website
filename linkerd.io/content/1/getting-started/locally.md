+++
aliases = ["/getting-started/requirements", "/getting-started/locally"]
description = "How to run Linkerd as a standalone process."
title = "Running locally"
weight = 2
[menu.docs]
parent = "getting-started"
weight = 32

+++
This guide will walk you through the steps necessary to download and run
Linkerd locally.

In order to run Linkerd locally, you must have Java 8 installed. You can
check your Java version by running:

```bash
$ java -version
java version "1.8.0_66"
```

Linkerd works with both Oracle and OpenJDK. If you need to install Java 8, you
can download either one.

<!-- markdownlint-disable MD013 MD033 -->

<p class="text-center">
{{% button "Download Oracle Java 8" "http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html" %}} or
{{% button "Download OpenJDK 8" "http://openjdk.java.net/install/" %}}
</p>

## Downloading & installing

First, download the latest binary release of Linkerd.

<p class="text-center">
{{% button "Download Linkerd" "https://github.com/linkerd/linkerd/releases" %}}
</p>

<!-- markdownlint-enable MD013 MD033 -->

Once you've downloaded the release, extract it:

```bash
tar -xzf linkerd-{{% latestversion %}}.tgz
cd linkerd-{{% latestversion %}}
```

The release will contain these files:

* `config/linkerd.yaml` --- config file defining routers, servers, protocols,
  and ports
* `disco/` --- file-based service discovery config
* `docs/` --- documentation
* `linkerd-{{% latestversion %}}-exec` --- Linkerd executable
* `logs/` --- default location where Linkerd logs are written

## Running

Once you have extracted the release, you can start and stop Linkerd by using
`linkerd-{{% latestversion %}}-exec`.

To start Linkerd, run:

```bash
./linkerd-{{% latestversion %}}-exec config/linkerd.yaml
```

## Making sure it works

You can validate that Linkerd works by sending some HTTP traffic through it.
Out of the box, Linkerd is configured to listen on port 4140, and to route any
HTTP calls with a `Host` header set to "web" to a service listening on port
9999.

You can test this by running a simple service on port 9999:

```bash
echo 'It works!' > index.html
python -m SimpleHTTPServer 9999
```

This will be our destination server, and will respond to any HTTP request
with a friendly response. We can send traffic to this destination by
connecting to Linkerd and specifying the appropriate host header:

```bash
$ curl -H "Host: web" http://localhost:4140/
It works!
```

Because we've asked Linkerd to proxy the "web" host, our request is routed to
the server on port 9999, and the response is proxied to the client. It
works!

Note that if you don't provide a Host header that matches the name of one of
the routable services, Linkerd will fail the request:

```bash
$ curl -I -H "Host: foo" http://localhost:4140/
HTTP/1.1 502 Bad Gateway
```

Of course, there's a lot more to naming services than this! In the next
section, we'll see where the service information used above is specified.

## File-based service discovery

Under the configuration shipped with Linkerd, the first place it looks when it
needs to resolve a service endpoints is the `disco/` directory.
(See the configuration guide for more on how this simple [file-based service
discovery]({{% linkerdconfig "file-based-service-discovery" %}}) system works.)
With this configuration, Linkerd looks for files with names corresponding to
the *concrete name* of a destination, and it expects these files to contain
a newline-delimited list of addresses in `host port` form.

The default configuration looks like this:

```bash
$ head disco/*
==> disco/thrift-buffered <==
127.0.0.1 9997

==> disco/thrift-framed <==
127.0.0.1 9998

==> disco/web <==
127.0.0.1 9999
```

As you can see, there is a destination called "web" that is backed by a single
address, `127.0.0.1 9999`, as well as a thrift framed destination that is backed
by `127.0.0.1 9998`, and a thrift buffered destination that is backed by
`127.0.0.1 9997`. Note that, just as it does with all service discovery
endpoints, Linkerd monitors this directory for changes, so feel free to add,
remove, and edit files at any point---no restarting required.

The routing configuration that is shipped with Linkerd is very simple, and
routes directly to the concrete names specified in this directory. In other
words, asking Linkerd for the "web" service, as we did above, will result in it
connecting to one of the endpoints in the `disco/web` file.

This routing configuration is good for demonstrating basic functionality, but
Linkerd is capable of a lot more, including multiple service discovery
endpoints, per-request routing rules, debug proxy injection, service failover,
and more. See the Routing page for details on [Linkerd's routing
capabilities]({{% ref "/1/advanced/routing.md" %}}).
