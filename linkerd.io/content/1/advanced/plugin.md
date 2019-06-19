+++
aliases = ["/doc/0.7.0/plugin", "/doc/0.7.1/plugin", "/doc/0.7.2/plugin", "/doc/0.7.3/plugin", "/doc/0.7.4/plugin", "/doc/0.7.5/plugin", "/doc/0.8.0/plugin", "/doc/head/plugin", "/doc/latest/plugin", "/doc/plugin", "/in-depth/plugin", "/advanced/plugin"]
description = "Sheds light on Linkerd's modular plugin system, and provides a detailed walkthrough for writing your own plugins."
title = "Plugins"
weight = 50
[menu.docs]
parent = "advanced"
weight = 29

+++
Linkerd is built on a modular plugin system so that individual components may
be swapped out without needing to recompile.  This also allows anyone to build
custom plugins that implement functionality specific to their needs.  This guide
will show you how to write your own custom Linkerd plugin, how to package it,
and how to install it in Linkerd.

In this guide we will write a custom [HTTP response classifier]({{%
linkerdconfig "http-response-classifiers" %}}).  However, the ideas in this
guide apply just as well for writing custom [identifiers]({{% linkerdconfig
"http-1-1-identifiers" %}}), [namers]({{% linkerdconfig "namers" %}}), [name
interpreters]({{% linkerdconfig "interpreter" %}}), [protocols]({{%
linkerdconfig "routers" %}}), or any other Linkerd plugin.

All the code for the plugin in this guide is available on
[GitHub](https://github.com/linkerd/linkerd-examples/tree/master/plugins/header-classifier).
I recommend keeping the code open in another window while you read this guide so
that you can follow along.

## Overview

We will write a custom HTTP response classifier that classifies responses based
on a special response header instead of the HTTP response code.  If the header's
value is "success" we will treat the response as a success, if it is "retry"
we will treat it as a retryable failure, and otherwise we will treat it as
a non-retryable failure.

We will describe how to write the plugin, how to build and package it, and how
to install it in Linkerd.

## Writing plugins

While Linkerd itself is written in Scala, its plugins can be written in Scala or
Java.  To demonstrate this, we will write our plugin in Java.  For our plugin
to be functional, we will need 3 things: the response classifier itself, a
config class, and a config initializer.  All plugins follow this pattern of
having the class that implements the business logic, a config class, and a
config initializer.

### Response classifier

[HeaderClassifier.java](https://github.com/linkerd/linkerd-examples/blob/master/plugins/header-classifier/src/main/java/io/buoyant/http/classifiers/HeaderClassifier.java)
is the response classifier itself.  Response classifiers must extend
`PartialFunction[ReqRep, ResponseClass]`.  Each plugin type has a different
interface that it must implement.  For example, namer plugins must implement
[Namer](https://github.com/twitter/finagle/blob/master/finagle-core/src/main/scala/com/twitter/finagle/Namer.scala#L16)
and identifier plugins must implement
[Identifier](https://github.com/linkerd/linkerd/blob/master/router/core/src/main/scala/io/buoyant/router/RoutingFactory.scala#L21).

### Config class

Next we need a class that defines the structure of the config block for this
plugin and constructs the response classifier.  We will call this
[HeaderClassifierConfig.java](https://github.com/linkerd/linkerd-examples/blob/master/plugins/header-classifier/src/main/java/io/buoyant/http/classifiers/HeaderClassifierConfig.java).
Notice that `HeaderClassifierConfig` must implement
[`ResponseClassifierConfig`](https://github.com/linkerd/linkerd/blob/master/linkerd/core/src/main/scala/io/buoyant/linkerd/ResponseClassifierInitializer.scala#L14).
ResponseClassifierConfigs are deserialized from the response classifier section
of the Linkerd config by [Jackson](https://github.com/FasterXML/jackson) and its
public members are populated by the corresponding JSON (or YAML) properties. (In
Scala this would be a case class.)  In our case we have one public member called
`headerName`, which defines the name of the response header to use.

To satisfy `ResponseClassifierConfig` we must also implement a method called
`mk()` which constructs the response classifier.

### Config initializer

A config initializer is a special class that Linkerd loads at startup. It tells
Linkerd about config classes it can use.  We create a config initializer called
[HeaderClassifierInitializer.java](https://github.com/linkerd/linkerd-examples/blob/master/plugins/header-classifier/src/main/java/io/buoyant/http/classifiers/HeaderClassifierInitializer.java).
This class must define a `configId` and a `configClass`.  When Linkerd parses a
config block with a `kind` property, it looks for a config initializer with that
`configId` and attempts to deserialize the block as an instance of the
`configClass`.  `HeaderClassifierInitializer` tells Linkerd that when it finds a
`responseClassifier` block with `kind: io.buoyant.headerClassifier`, it should
deserialize that block as a `HeaderClassifierConfig`.

Finally, in order for Linkerd to be able to dynamically load the config
initializer at startup, we must register it with the service loader.  To do this
simply create a resource file called
[`META-INF/services/io.buoyant.linkerd.ResponseClassifierConfig`](https://github.com/linkerd/linkerd-examples/blob/master/plugins/header-classifier/src/main/resources/META-INF/services/io.buoyant.linkerd.ResponseClassifierInitializer)
and add the fully qualified class name of the config initializer to that file.

## Build & package

We use sbt to build our plugin and the assembly sbt plugin to package it into a
jar.  Here is the
[build.sbt](https://github.com/linkerd/linkerd-examples/blob/master/plugins/build.sbt)
file for the project.  Note that we can mark any Linkerd dependencies as
"provided".  This means that those dependencies will be provided by Linkerd and
do not need to be included in the plugin jar.  Similarly, Linkerd will provide
the Scala standard libraries, so we can exclude those from the jar as well by
setting `includeScala = false`.

Build the plugin jar by running:

```bash
./sbt headerClassifier/assembly
```

## Installing

To install this plugin with Linkerd, simply move the plugin jar into Linkerd's
plugin directory (`$L5D_HOME/plugins`).  Then add a classifier block to the
router in your Linkerd config:

```yaml
routers:
- ...
  responseClassifier:
    kind: io.buoyant.headerClassifier
    headerName: status
```

If you run Linkerd with `-log.level=DEBUG` then you should see a line printed
at startup that indicates the HeaderClassifierInitializer has been loaded:

```bash
LoadService: loaded instance of class io.buoyant.http.classifiers.HeaderClassifierInitializer for requested service io.buoyant.linkerd.ResponseClassifierInitializer
```

## Trying it out

Now that we have our plugin in the plugins directory, let's try it out.  Start
Linkerd with this simple config that sends all requests to `localhost:8888`.

```yaml
routers:
- protocol: http
  dtab: /svc/* => /$/inet/localhost/8888
  responseClassifier:
    kind: io.buoyant.headerClassifier
    headerName: status
  servers:
  - ip: 0.0.0.0
    port: 4140
```

Then we'll start a simple server on port 8888 that responds with the status
header indicating success:

```bash
while true; do echo -e "HTTP/1.1 200 OK\r\nstatus: success\r\n" | nc -i 1 -l 8888; done
```

Now let's issue a request:

```bash
curl -v localhost:4140
```

By checking Linkerd's metrics, we can see that this request was classified as
a success:

```bash
curl -s localhost:9990/admin/metrics.json?pretty=1 | grep -E 'srv.*(success|failure)'
  "rt/http/srv/0.0.0.0/4140/success" : 1,
```

Now let's restart our server and have it set the header to "failure":

```bash
while true; do echo -e "HTTP/1.1 200 OK\r\nstatus: failure\r\n" | nc -i 1 -l 8888; done
```

And issue another request:

```bash
curl -v localhost:4140
```

Now when we check Linkerd's metrics, we'll see that this request was classified
as a failure:

```bash
curl -s localhost:9990/admin/metrics.json?pretty=1 | grep -E 'srv.*(success|failure)'
  "rt/http/srv/0.0.0.0/4140/failures" : 1,
  "rt/http/srv/0.0.0.0/4140/failures/com.twitter.finagle.service.ResponseClassificationSyntheticException" : 1,
  "rt/http/srv/0.0.0.0/4140/success" : 1,
```

## More information

If you have any questions about using or developing Linkerd plugins, or would
like to share what you've created, please drop into [the Linkerd public Slack](
http://slack.linkerd.io).  We hope to see you soon!
