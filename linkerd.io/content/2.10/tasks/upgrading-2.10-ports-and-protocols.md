---
title: 'Upgrading to Linkerd 2.10: ports and protocols'
description: Upgrading to Linkerd 2.10 and handling skip-ports, server-speaks-first
  protocols, and more.
---

Linkerd 2.10 introduced some significant changes to the way that certain types
of traffic are handled. These changes may require new or different
configuration on your part.

## What were the changes?

The majority of traffic "just works" in Linkerd. However, there are certain
types of traffic that Linkerd cannot handle without additional configuration.
This includes "server-speaks-first" protocols such as MySQL and SMTP, as well
(in some Linkerd versions) protocols such as Postgres and Memcache. Linkerd's
protocol detection logic is unable to efficiently handle these protocols.

In Linkerd 2.9 and earlier, these protocols were handled by simply bypassing
them. Users could mark specific ports as "skip ports" and ensure that traffic
to these ports would not transit Linkerd's data plane proxy. To make this easy,
Linkerd 2.9 and earlier shipped with a default set of skip ports which included
25 (SMTP), 443 (client-initiated TLS), 587 (SMTP), 3306 (MySQL), 5432
(Postgres), and 11211 (Memcache).

In the 2.10 release, Linkerd introduced three changes to the way that protocols
are detected and handled:

1. It added an _opaque ports_ feature, which disables protocol detection on
   specific ports. This means Linkerd 2.10 can now handle these protocols and
   provide TCP-level metrics, mTLS, etc.
2. It replaced the default list of skip ports with a default list of opaque
   ports, covering the same ports. This means that the default behavior for
   these protocols is to transit the proxy rather than bypass it.
3. It changed the handling of connections to continue even if protocol
   detection times out. This means that attempting e.g. server-speaks-first
   protocols through the proxy _without_ skip ports or opaque ports
   configuration has a better behavior: instead of failing, the proxy will
   forward the connection (with service discovery, TCP load balancing, and
   mTLS) after a 10-second connect delay.

## What does this mean for me?

In short, it means that there are several types of traffic that, in Linkerd 2.9
and earlier, simply bypassed the proxy by default, but that in Linkerd 2.10 now
transit the proxy. This is a good thing!—you are using Linkerd for a reason,
after all—but it has some implications in certain situations.

## What do I need to change?

As part of Linkerd 2.10, you may need to update your configuration in certain
situations.

### SMTP, MySQL, Postgres, or Memcache traffic to an off-cluster destination

If you have existing SMTP, MySQL, Postgres, or Memcache traffic to an
off-cluster destination, *on the default port for that protocol*, then you will
need to update your configuration.

**Behavior in 2.9:** Traffic automatically *skips* the proxy.  
**Behavior in 2.10:** Traffic automatically *transits* the proxy, and will incur
a 10-second connect delay.  
**Steps to upgrade:** Use `skip-outbound-ports` to mark the port so as to
bypass the proxy. (There is currently no ability to use opaque ports in this
situation.)

### Client-initiated TLS calls at startup

If you have client-initiated TLS calls to any destination, on- or off-cluster,
you may have to update your configuration if these connections are made at
application startup and not retried.

**Behavior in 2.9:** Traffic automatically *skips* the proxy.  
**Behavior in 2.10:** Traffic automatically *transits* the proxy.  
**Steps to upgrade:** See "Connecting at startup" below.

### An existing skip-ports configuration

If you have an existing configuration involving `skip-inbound-ports` or
`skip-outbound-ports` annotations, everything should continue working as is.
However, you may choose to convert this configuration to opaque ports.

**Behavior in 2.9:** Traffic skips the proxy.  
**Behavior in 2.10:** Traffic skips the proxy.  
**Steps to upgrade:** Optionally, change this configuration to opaque ports to
take advantage of metrics, mTLS (for meshed destinations), etc. See "Connecting
at startup" below if any of these connections happen at application startup and
are not retried.

## Note: Connecting at startup

There is one additional consideration for traffic that previously skipped the
proxy but now transits the proxy. If your application makes connections at
_startup time_, those connections will now require the proxy to be active
before they succeed. Unfortunately, Kubernetes currently provides no container
ordering constraints, so the proxy may not be active before the application
container starts. Thus, if your application does not retry with sufficient
leeway to allow the proxy to start up, it may fail. (This typically manifests
as container restarts.)

To handle this situation, you have four options:

1. Ignore the container restarts. (It's "eventually consistent".)
2. Use [linkerd-await](https://github.com/olix0r/linkerd-await) to make the
   application container wait for the proxy to be ready before starting.
3. Set a `skip-outbound-ports` annotation to bypass the proxy for that port.
   (You will lose Linkerd's features for that connection.)
4. Add retry logic to the application to make it resilient to transient network
   failures.

The last option is arguably the "rightest" approach, but not always the most
practical.

In the future, Kubernetes may provide mechanisms for specifying container
startup ordering, at which point this will no longer be an issue.

## How do I set an opaque port or skip port?

Ports can be marked as opaque ports or as skip ports via Kubernetes
annotations. These annotations can be set at the namespace, workload, or
service level. The `linkerd inject` CLI command provides flags to set these
annotations; they are also settable as defaults in the Helm config.
