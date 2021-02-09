---
slug: 'upgrading-to-linkerd-0-6-0'
title: 'Upgrading to Linkerd 0.6.0'
aliases:
  - /2016/05/24/upgrading-to-linkerd-0-6-0/
author: 'alex'
date: Tue, 24 May 2016 22:33:14 +0000
draft: false
featured: false
thumbnail: /uploads/linkerd_v_060.png
tags: [Article, Buoyant, Linkerd, linkerd, News]
---

Version 0.6.0 of Linkerd and namerd were released today! We wanted to take the opportunity in this release to bring more consistency and uniformity to our config files. Unfortunately, this means making non-backwards compatible changes. In this post, we describe how to update your config files to work with 0.6.0.

## KIND NAMES

Linkerd and namerd use a plugin system where plugins are identified in config files by the `kind` property. We’ve renamed the `kind`s of our plugins to follow a consistent pattern: `<organization>.<plugin name>`. We use `io.l5d` as the organization for Linkerd’s built-in plugins. For example, the `kind` of the etcd storage plugin changed from`io.buoyant.namerd.storage.experimental.etcd` to `io.l5d.etcd`.

**You will need to update the `kind` properties in your configs to their new values**. A full list of the `kind` name changes is below. You can always find more information about plugins in the [Linkerd config docs](https://linkerd.io/doc/0.6.0/linkerd/config/).

```txt
# Identifiers
default -> io.l5d.methodAndHost

# Response Classifiers
retryableIdempotent5XX -> io.l5d.retryableIdempotent5XX
retryableRead5XX -> io.l5d.retryableRead5XX
nonRetryable5XX -> io.l5d.nonRetryable5XX

# Client TLS Config
io.l5d.clientTls.boundPath -> io.l5d.boundPath
io.l5d.clientTls.noValidation -> io.l5d.noValidation
io.l5d.clientTls.static -> io.l5d.static

# Tracers
io.l5d.zipkin -> io.l5d.zipkin

# Namers
io.l5d.experimental.consul -> io.l5d.consul
io.l5d.fs -> io.l5d.fs
io.l5d.experimental.k8s -> io.l5d.k8s
io.l5d.experimental.marathon -> io.l5d.marathon
io.l5d.serversets -> io.l5d.serversets

# namerd Interfaces
httpController -> io.l5d.httpController
thriftNameInterpreter -> io.l5d.thriftNameInterpreter

# namerd Dtab Storage
io.buoyant.namerd.storage.experimental.etcd -> io.l5d.etcd
io.buoyant.namerd.storage.inMemory -> io.l5d.inMemory
io.buoyant.namerd.storage.experimental.k8s -> io.l5d.k8s
io.buoyant.namerd.storage.experimental.zk -> io.l5d.zk
```

## EXPERIMENTAL PLUGINS

Certain plugins have been marked as experimental. While these plugins definitely work, they have not yet been tested at scale so we can’t be sure how they will perform in production environments. **In order to use these plugins, you’ll need to acknowledge their experimental status by setting the `experimental: true` property on the plugin’s config.** For example:

```yml
kind: io.l5d.k8s
experimental: true # must be set because this plugin is experimental
host: localhost
port: 8001
```

If a plugin is experimental, this will be indicated in the [Linkerd config docs](https://linkerd.io/doc/0.6.0/linkerd/config/). A full list of the currently experimental plugins is below:

```yml
- namers - io.l5d.consul - io.l5d.k8s - io.l5d.marathon
- storage - io.l5d.k8s - io.l5d.zk - io.l5d.etcd
```

## NAMER PATHS

Namers match on concrete names and bind them to physical addresses (for a fuller explanation of this, see: [https://linkerd.io/doc/dtabs/#namers-addresses][namers]). If a path begins with `/$`, that indicates that it is a concrete name and that the classpath should be searched for a namer to use. For example, `/$/inet/127.0.0.1/4140` searches the classpath for a namer called `inet` and uses it to bind this path.

In 0.6.0 we added a similar indicator for concrete names that should be bound by namers specified in the config file. If a path begins with `/#`, that indicates that it is a concrete name and a namer from the config file should be used. The result is that dtabs are more readable because it is more obvious which paths can be handled by namers (those starting with `/$` or `/#`) and which require further processing by the dtab entries.

**This means that all dtab entries that refer to a namer prefix need to be updated to begin with `/#`.** For example, the entry

```txt
/srv => /io.l5d.fs
```

would need to be changed to

```txt
/srv => /#/io.l5d.fs
```

Any path beginning with `/#/io.l5d.fs` means that this is a concrete name and the `io.l5d.fs` namer should be used to bind it.

## ZOOKEEPER ADDRESSES

To make the way that ZooKeeper hosts are addressed more consistent, **the ZooKeeper dtab storage plugin config now requires ZooKeeper addresses be specified as follows**:

```yml
zkAddrs:
- host: zkHost1
    port: 1234
- host: zkHost2
    port: 1234
```

## DC/OS

If you have installed namerd via the [official DC/OS universe packages](https://github.com/mesosphere/universe), and are using the `io.l5d.zk` storage plugin, you will need to update any dtabs referencing `/io.l5d.marathon`. This should be done in conjunction with upgrading Linkerd and namerd DC/OS packages from pre-0.6.0 to 0.6.0 or higher. Specifically, change lines like this:

```txt
/srv => /io.l5d.marathon ;
```

to this:

```txt
/srv => /#/io.l5d.marathon ;
```

To update namerd via [namerctl](https://github.com/linkerd/namerctl), run the following commands:

```bash
export NAMERCTL_BASE_URL=http://namerd.example.com:4180

namerctl dtab get default > default.dtab
DTAB_VERSION=`awk '/# version/{print $NF}' default.dtab`
sed -i -- 's//io.l5d.marathon//#/io.l5d.marathon/g' default.dtab
namerctl dtab update --version=$DTAB_VERSION default default.dtab
```

## ADDITIONAL SUPPORT

If you run into any difficulties with this upgrade, or just want to chat, join us in the [Linkerd Slack channel](http://slack.linkerd.io/)!

[namers]: https://linkerd.io/doc/dtabs/#namers-addresses
