---
slug: 'announcing-linkerd-1-0'
title: 'Announcing Linkerd 1.0'
aliases:
  - /2017/04/25/announcing-linkerd-1-0/
author: 'oliver'
date: Tue, 25 Apr 2017 23:36:00 +0000
draft: false
featured: false
thumbnail: /uploads/linkerd_version_1_featured.png
tags: [Linkerd, linkerd, News]
---

Today, we’re thrilled to announce Linkerd version 1.0. A little more than one year from our initial launch, Linkerd is part of the [Cloud Native Computing Foundation](https://cncf.io/) and has a thriving community of contributors and users. Adopters range from startups like Monzo, which is disrupting the UK banking industry, to high scale Internet companies like [Paypal](https://paypal.com/), [Ticketmaster](https://ticketmaster.com/), and [Credit Karma](https://creditkarma.com/), to companies that have been in business for hundreds of years like Houghton Mifflin Harcourt.

A 1.0 release is a meaningful milestone for any open source project. In our case, it’s a recognition that we’ve hit a stable set of features that our users depend on to handle their most critical production traffic. It also signals a commitment to limiting breaking configuration changes moving forward.

It’s humbling that our little project has amassed such an amazing group of operators and developers. I’m continually stunned by the features and integrations coming out of the Linkerd community; and there’s simply nothing more satisfying than hearing how Linkerd is helping teams do their jobs with a little less fear and uncertainty.

## THE SERVICE MESH

Linkerd is a *service mesh* for cloud native applications. As part of this release, we wanted to define what this actually meant. My cofounder William Morgan has a writeup in another post we released today, [What’s a service mesh? And why do I need one?](/2017/04/25/whats-a-service-mesh-and-why-do-i-need-one/)

## NEW FEATURES

Beyond stability and performance improvements, Linkerd 1.0 has a couple new features worth talking about.

This release includes a substantial change to the way that routers are configured in Linkerd. New plugin interfaces have been introduced to allow for much finer-grained policy control.

### PER-SERVICE CONFIGURATION

There is a new section in the router config called `service` where service-level parameters may be configured. This parallels the `client` sections where client-level parameters are configured. The current parameters that can be specified in the `service` section are:

- `totalTimeoutMs`
- `retries`
- `responseClassifier`

```yml
routers:
  - protocol: http
    service:
      totalTimeoutMs: 200
      retries:
        budget:
          minRetriesPerSec: 5
          percentCanRetry: 0.5
          ttlSecs: 15
        backoff:
          kind: jittered
          minMs: 10
          maxMs: 10000
      responseClassifier:
        kind: io.l5d.http.retryableRead5XX
```

With this change, a router now has three main subsections:

- `servers` — where the router listens for incoming requests
- `service` — the logical destination of the request based on the identifier
- `client` — where the router sends outgoing requests to concrete destinations

### PER-CLIENT CONFIGURATION

Prior to version 1.0 any client configuration such as timeouts or TLS would apply globally to all clients. We now support the ability to configure clients in a more granular way by specifying `kind: io.l5d.static` in the client section and providing a list of configs. For example:

```yml
routers:
  - protocol: http
    client:
      kind: io.l5d.static
      configs:
        - prefix: /
          requestAttemptTimeoutMs: 1000
          failFast: true
        - prefix: /#/io.l5d.k8s/default/http/hello
          requestAttemptTimeoutMs: 300
        - prefix: /#/io.l5d.k8s/default/http/world
          failureAccrual:
            kind: none
            failFast: false
```

Each item in the list of configs must specify a prefix and some parameters. Those parameters will apply to all clients with an id that matches the prefix. In the example above, the first config with prefix `/` applies to all clients. The next two configs apply to the `hello` and `world` clients respectively. If a client matches more than one config, all matching configs will be applied with configs later in the file taking precedence over earlier ones. For example, the `hello` client overrides the `requestAttemptTimeoutMs`property to `300` whereas the `world` client inherits the `1000` value from the first config.

If you don’t specify `kind: io.l5d.static` then `kind: io.l5d.global` will be assumed and you can specify client configuration directly on the client object which will apply globally to all clients.

```yml
routers:
  - protocol: http
    client:
      requestAttemptTimeoutMs: 1000
      failFast: true
```

This same fine-grained level of control applies to the new `service` section as well. In the `service` configs, the `prefix` is compared to the service name i.e. the name produced by the identifier (which typically starts with `/svc`).

```yml
routers:
  - protocol: http
    service:
      kind: io.l5d.static
      configs:
        - prefix: /svc
          totalTimeout: 1000
          responseClassifier:
            kind: io.l5d.http.retryableRead5XX
        - prefix: /svc/hello
          responseClassifier:
            kind: io.l5d.http.nonRetryable5XX
        - prefix: /svc/world
          totalTimeout: 300
```

## UPGRADING GUIDE

There are a couple changes you’ll have to make to your config files to move from pre-1.0 to 1.0.

### IDENTIFIER KINDS

The following identifier kinds have been renamed for consistency:

- The `io.l5d.headerToken` id has been renamed to `io.l5d.header.token`.
- The `io.l5d.headerPath` id has been renamed to `io.l5d.header.path`.
- The `io.l5d.h2.ingress` id has been renamed to `io.l5d.ingress`.
- The `io.l5d.http.ingress` id has been renamed to `io.l5d.ingress`.

### RESPONSE CLASSIFIER KINDS

The following response classifier kinds have been renamed for consistency:

- The `io.l5d.nonRetryable5XX` id has been renamed to `io.l5d.http.nonRetryable5XX`.
- The `io.l5d.retryableRead5XX` id has been renamed to `io.l5d.http.retryableRead5XX`.
- The `io.l5d.retryableIdempotent5XX` id has been renamed to `io.l5d.http.retryableIdempotent5XX`.

### CLIENT AND SERVICE PARAMETERS

The following parameter have moved or been renamed:

- `failFast` moved from router to client
- `responseClassifier` moved from router to service
- `retries` moved from client to service
- `timeoutMs` moved from router to
  - `requestAttemptTimeoutMs` in client
  - `totalTimeoutMs` in service

### TIMEOUTS

The `timeoutMs` property has been split into two properties, `requestAttemptTimeoutMs`which is configured in the `client` section and `totalTimeoutMs` which is configured in the `service` section.

`requestAttemptTimeoutMs` configures the timeout for each individual request or retry. As soon as this timeout is exceeded, the current attempt is canceled. If the request is retryable and the retry budget is not empty, a retry will be attempted with a fresh timeout.

`totalTimeoutMs` configures the total timeout for the request and all retries. A running timer is started when the first request is attempted and continues running if the request is retried. Once this timeout is exceeded, the request is canceled and no more retries may be attempted.

### TLS

The client TLS section no longer has a `kind` parameter and instead can simply be configured with these 3 parameters:

| Key                 | Default Value                              | Description                                                        |
| ------------------- | ------------------------------------------ | ------------------------------------------------------------------ |
| `disableValidation` | false                                      | Enable this to skip hostname validation (unsafe).                  |
| `commonName`        | _required_ unless disableValidation is set | The common name to use for all TLS requests.                       |
| `trustCerts`        | empty list                                 | A list of file paths of CA certs to use for common name validation |

Fine-grained client configuration can be used to only configure TLS for certain clients. Furthermore, segments from the prefix can be captured into variables and used in the `commonName`. For example:

```yml
routers:
  - protocol: http
    client:
      kind: io.l5d.static
      configs:
        - prefix: /#/io.l5d.k8s/default/http/{service}
          tls:
            commonName: '{service}.linkerd.io'
```

### METRICS

The following metrics scopes have changed names. You will need to update any consumers of these metrics such as dashboards or alerts.

- `rt/*/dst/id` has changed to `rt/*/service`
- `rt/*/dst/path` has changed to `rt/*/client`
- `rt/*/dst/id/*/path` has changed to `rt/*/client/*/service`
- `rt/*/srv` has changed to `rt/*/server`

These three metrics scopes (server, service, client) mirror the three main subsections of the router config (servers, service, client).

### TRACE ANNOTATIONS

The following trace annotations have changed names:

- `dst.id` has changed to `client`
- `dst.path` has changed to `residual`
- `namer.path` has changed to `service`

### HTTP HEADERS

The following outgoing request headers have changed names:

- `l5d-dst-logical` has changed to `l5d-dst-service`
- `l5d-dst-concrete` has changed to `l5d-dst-client`

## THANKS

Linkerd is only possible thanks to the community of amazing people around it. I’d like to thank everyone who helps in [the Linkerd Slack](https://slack.linkerd.io/), files issues, and contributes pull requests. The 1.0 release was made possible by contributions from Amédée d’Aboville, Zack Angelo, Ian Macalinao, Alexander Pakulov, Jordan Taylor, and [users like you](https://github.com/linkerd/linkerd/blob/master/CONTRIBUTING.md)!
