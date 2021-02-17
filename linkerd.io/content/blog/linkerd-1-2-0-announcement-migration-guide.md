---
slug: 'linkerd-1-2-0-announcement-migration-guide'
title: 'Linkerd 1.2.0 is here! Features, bugfixes, and migration'
aliases:
  - /2017/09/08/linkerd-1-2-0-announcement-migration-guide/
author: 'eliza'
date: Fri, 08 Sep 2017 20:23:01 +0000
thumbnail: /uploads/linkerd_version_12_featured.png
draft: false
featured: false
tags: [Linkerd, linkerd, News]
---

We're very excited to announce [Linkerd](https://github.com/linkerd/linkerd/releases/tag/1.2.0) [version 1.2.0](https://github.com/linkerd/linkerd/releases/tag/1.2.0)! This is a huge release with a lot of new features, fixes, and performance improvements, especially for our users running Linkerd with Kubernetes, HTTP/2, or gRPC. There are also a handful of breaking changes in 1.2.0 , so we've included a migration guide below to help make the transition as easy as possible.

As usual, release artifacts are available [on GitHub](https://github.com/linkerd/linkerd/releases/tag/1.2.0), and Docker images are available [on Docker Hub](https://hub.docker.com/r/buoyantio/linkerd/).

## Community Contributors

We'd like to take a moment to highlight contributions from the Linkerd community members in this release.

- Christopher Taylor ([@ccmtaylor](https://github.com/ccmtaylor)): added DNS SRV record support
- Andrew Wright (@blacktoe): improved Consul health checks
- Cyril Ponomaryov ([@cponomaryov](https://github.com/cponomaryov)): fixed an issue in the `config.json` admin endpoint, and made some performance improvements in logging
- Marcin Mejran ([@mejran](https://github.com/mejran)): fixed a memory leak in `JsonStreamParser`

In addition to contributions from the community, this release also contains the first contributions from [Phil Calçado](http://philcalcado.com/2017/08/09/buoyant.html), the newest member of the Linkerd engineering team.

## New Features in 1.2.0

### New DNS SRV Record support

Thanks to Christopher Taylor ([@ccmtaylor](https://github.com/ccmtaylor)) at SoundCloud, Linkerd 1.2.0 features a new `io.l5d.dnssrv` namer that allows Linkerd to use DNS SRV records for service discovery.

An example configuration for the DNS SRV namer might look like this:

```yml
namers:
  - kind: io.l5d.dnssrv
    experimental: true
    refreshIntervalSeconds: 5
    dnsHosts:
      - ns0.example.org
      - ns1.example.org
```

The `dnsHosts` configuration key specifies a list of DNS servers against which to perform SRV lookups, while the `refreshIntervalSeconds` key specifies the frequency of lookups. Please note that this namer is still considered experimental, so `experimental: true` is required. Once the DNS SRV namer is configured, it can be referenced in the dtab to use it:

```yml
dtab: |
  /dnssrv => /#/io.l5d.dnssrv
  /svc/myservice =>
    /dnssrv/myservice.srv.example.org &
    /dnssrv/myservice2.srv.example.org;
  /svc/other =>
    /dnssrv/other.srv.example.org;
```

Please see the DNS SRV namer [documentation](https://linkerd.io/config/head/linkerd/index.html#dns-srv-records) for more information.

### Improved Consul health filtering

Another new feature added by an open-source contributor is support for filtering by Consul health states, added by Linkerd user Andrew Wright (@blacktoe). Consul has a concept of `passing`, `warning` and `critical` health statuses, but the Consul namer previously only supported filtering nodes by a binary health status. To use this feature, add the following to the Consul namer configuration:

```yml
useHealthCheck: true
healthStatuses:
  - 'passing'
  - 'warning'
```

Where `healthStatuses` is a list of statuses to filter on. Refer to the [documentation](https://linkerd.io/config/1.2.0/linkerd/index.html#consul-configuration) for the Consul namer for more information. In addition, we've made the Consul namer more robust: Consul errors will now cause the namer to fall back to the last good state observed from Consul, and the log messages on these errors have been made more informative.

### New Kubernetes ConfigMap Interpreter

Users running Linkerd on Kubernetes may be interested in the new `io.l5d.k8s.configMap` interpreter (marked experimental for now, until it sees more production use). This interpreter will interpret names using a dtab stored in a Kubernetes ConfigMap, and update the dtab if the ConfigMap changes, allowing users on Kubernetes to implement dynamic routing rule changes without running Namerd.

An example configuration is as follows:

```yml
routers:
- ...
  interpreter:
    kind: io.l5d.k8s.configMap
    experimental: true
    namespace: ns
    name: dtabs
    filename: my-dtab
```

The `namespace` configuration key refers to the name of the Kubernetes namespace where the ConfigMap is stored, while the `name` key refers to the name of the ConfigMap object, and the `filename` key refers to the name of the dtab within the ConfigMap. As this interpreter is still experimental, `experimental: true` must be set for it to be used.

See the [ConfigMap namer documentation](https://linkerd.io/config/1.2.0/linkerd/index.html#kubernetes-configmap) for more information.

### Improved Ingress Identifier Configurability (istio)

For users running Linkerd-powered Istio deployments, Linkerd 1.2.0 allows multiple simultaneous Ingress controllers by [configuring which annotation class each Ingress controller uses](https://github.com/linkerd/linkerd/blob/master/linkerd/docs/protocol-http.md).

## Bug Fixes and Performance Improvements

### Improved Kubernetes watches, BUGFIXES, and performance

This release features [a major refactoring](https://github.com/linkerd/linkerd/pull/1603) of the `io.l5d.k8s` and `io.l5d.k8s.ns` namers. We've rewritten how these namers watch Kubernetes API objects. New code should be much more efficient, leading to major performance improvements. We've also fixed issues where Linkerd would continue routing to Kubernetes services that had been deleted, and some minor routing problems in the ingress controller. Finally, we'd like to thank community member Marcin Mejran ([@mejran](https://github.com/mejran)), who fixed a memory leak in JSON stream parsing which could impact Kubernetes performance.

### HTTP/2 and gRPC fixes

For users of the HTTP/2 protocol, we've solved an issue where long-running streams would eventually stop receiving new frames, and we've fixed a memory leak in long-running streams.

## Breaking Changes and Migration

### Removed Support for PKCS#1 Keys

Linkerd 1.2.0 [removes support](https://github.com/linkerd/linkerd/pull/1590) for Public Key Cryptography Standard #1 SSL private keys, which were previously deprecated. If you still have keys in PKCS#1 format, you will need to convert your private keys to PKCS#8. Private keys can be converted with the following command:

```bash
openssl pkcs8 -topk8 -nocrypt -in $PKCS1.pem -out $PKCS8.pk8
```

Where `$PKCS1` and `$PKCS8` are the file names of the old PKCS#1 key and the new key to output, respectively. If you see errors with messages containing “file does not contain valid private key”, you'll know you need to do this step. For example, the message:

```txt
WARN 0908 14:03:38.201 CDT finagle/netty4-6: Failed to initialize a channel. Closing: [id: 0xdd6c26dd]
java.lang.IllegalArgumentException: File does not contain valid private key: finagle/h2/src/e2e/resources/linkerd-tls-e2e-key-pkcs1.pem
```

Indicates that the key `linkerd-tls-e2e-key-pkcs1.pem` needs to be updated to PKCS#8 format.

#### Client TLS Configuration

Linkerd now rejects client TLS configurations which contain both `disableValidation: true` and a `clientAuth` configuration, as disabling validation will cause Linkerd to use the JDK SSL provider, which does not support client authorization. These configurations have always been incompatible, and including both would have previously caused errors at runtime.

#### Admin and Interpreter Server Configuration

For improved security, by default Linkerd and Namerd 1.2.0 now serve the admin page, metrics,  `io.l5d.mesh` , and `io.l5d.thriftNameInterpreter` only on 127.0.0.1. (Previously, it bound to every available network interface.) This means that accessing the admin and metrics interfaces from an external IP address will no longer work. If you need to access the admin or metrics pages from an external IP address, you will need to add

```txt
admin:
  ip: 0.0.0.0
  port: 9990
```

To your configuration file.

#### StatsD Telemeter Deprecation

The StatsD telemeter (`io.l5d.statsd`) [is now deprecated](https://discourse.linkerd.io/t/deprecating-the-statsd-telemeter/268/1), and will log a warning on use. We've been considering deprecating this telemeter for some time, as it doesn't work the way most users expect and can lead to loss of data and/or greatly increased Linkerd latency. We recommend that users of this telemeter migrate to the InfluxDB telemeter in conjunction with Telegraf.

In future releases, we will remove this telemeter.

### Further Information

The complete changelog for this release is available [on GitHub](https://github.com/linkerd/linkerd/blob/master/CHANGES.md#120-2017-09-07), and updated documentation can be found on [docs.linkerd.io](https://linkerd.io/config/1.2.0/linkerd/index.html). And, as always, if you have any questions or just want to chat about Linkerd, join [the Linkerd Slack](http://slack.linkerd.io/) or browse [the Discourse community forum](https://discourse.linkerd.io) for more in-depth discussion.
