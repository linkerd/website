+++
aliases = ["/getting-started/dcos"]
description = "How to run Linkerd in DC/OS, routing requests with Marathon-backed service discovery."
title = "Running in DC/OS"
weight = 5
[menu.docs]
parent = "getting-started"
weight = 30

+++
This guide will walk you through getting Linkerd running in DC/OS, routing
requests to an example web service, and monitoring your cluster.

## Deploy the webapp

We are going to deploy a sample app that responds with "Hello world". We'll use
a
[webapp.json](https://raw.githubusercontent.com/linkerd/linkerd-examples/master/dcos/webapp.json)
config file from the [linkerd-examples](https://github.com/linkerd/linkerd-examples)
repo:

```bash
dcos marathon app add https://raw.githubusercontent.com/linkerd/linkerd-examples/master/dcos/webapp.json
```

## Deploy Linkerd

Install the Linkerd DC/OS Universe package with the following command, note
`instances` should match the total number of nodes in your DC/OS cluster, both
public and private:

```bash
dcos package install --options=<(echo '{"linkerd":{"instances":4}}') linkerd
```

Note that Linkerd boots two servers, `outgoing` on port `4140`, and `incoming`
on `4141`. Your applications make an outgoing request to their local Linkerd on
port 4140, which routes the request to a separate Linkerd process running on a
remote node on port 4141. The Linkerd on the remote node accepts the incoming
request and routes it to your local application instance.

## Making sure it works

The Linkerd DC/OS Universe package comes preconfigured to route traffic as an
HTTP proxy. By default, it accepts all traffic on port 4140 from your
applications. Virtually all http tools and client libraries support this. `curl`
checks for an `http_proxy` environment variable:

```bash
$ http_proxy=$PUBLIC_NODE:4140 curl -s http://webapp/hello
Hello world
```

Finally, to reach the admin service, make a request on port `9990`:

```bash
$ curl $PUBLIC_NODE:9990/admin/ping
pong
```

## Application groups

For applications deployed as part of a group, reverse the group/app name into a
domain. For example, `my-group/webapp` becomes `webapp.my-group`:

```bash
$ http_proxy=$PUBLIC_NODE:4140 curl webapp.my-group/hello
Hello world
```

## Deploying a custom Linkerd

You can also install your own custom version of Linkerd, for example:

```bash
dcos marathon app add https://raw.githubusercontent.com/linkerd/linkerd-examples/master/dcos/linker-to-linker/linkerd-dcos.json
```

This custom version has a Linkerd config file embedded in its command as
string-encoded json, a more human readable version is in the
[linkerd-examples](https://github.com/linkerd/linkerd-examples)
repo as
[linkerd-config.yml](https://raw.githubusercontent.com/linkerd/linkerd-examples/master/dcos/linker-to-linker/linkerd-config.yml).

To modify a Linkerd config, do the following:

1. Edit `linkerd-config.yml`
1. Convert to JSON using something like [http://json2yaml.com](http://json2yaml.com)
1. Remove all line breaks and escape quotes:

    ```bash
    cat linkerd-config.json |tr -d '\n '|sed 's/"/\\\\\\\"/g'
    ```

1. Replace the inner contents of `linkerd-dcos.json`'s `cmd` field with the
output.

## Deploying linkerd-viz

linkerd-viz is a monitoring application for applications routing via Linkerd.
Deploy as a DC/OS Universe package with:

```bash
dcos package install linkerd-viz
```

View the dashboard:

```bash
open $(dcos config show core.dcos_url)/service/linkerd-viz
```

Alternatively, install a custom version with:

```bash
dcos marathon app add https://raw.githubusercontent.com/linkerd/linkerd-viz/master/dcos/linkerd-viz.json
open $PUBLIC_NODE:3000
```

{{< fig src="/images/linkerd-viz.png" title="linkerd viz" >}}

That's it! You now have a dynamically routed and monitored DC/OS cluster.

## linker-to-linker vs. simple-proxy configuration

The guide above described setting up a cluster in linker-to-linker mode, where
each Linkerd runs an `incoming` and `outgoing` server. This is the default
configuration in the Linkerd DC/OS Universe package, and it provides the
necessary topology to support `linkerd-viz`. If you are interested in a more
simplistic http proxy configuration, have a look at the
[simple-proxy](https://github.com/linkerd/linkerd-examples/tree/master/dcos/simple-proxy)
example in the linkerd-examples repo.

## Further reading

For more information about configuring Linkerd, see the
[Linkerd Configuration](https://api.linkerd.io/latest/linkerd) page.

For more information about linkerd-viz, see the
[linkerd-viz GitHub repo](https://github.com/linkerd/linkerd-viz).
