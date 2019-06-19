+++
aliases = ["/doc/dtabs", "/dtabs", "/in-depth/dtabs", "/advanced/dtabs"]
description = "Explains delegation tables and delegation rules, the primary mechanism by which Linkerd dynamically routes requests."
title = "Dtabs"
weight = 30
[menu.docs]
parent = "advanced"
weight = 25

+++
Delegation tables (dtabs for short) are lists of routing rules that take a
"logical path" (e.g., a popular ice cream store) and transform it into to a
"concrete name" where that thing is located (e.g., 2790 Harrison St, San
Francisco, CA 94110).  This is a process we call "resolution" and it happens via
a series of prefix rewrites.

In addition to this documentation, you can refer to [Finagle's dtab
docs](http://twitter.github.io/finagle/guide/Names.html). You can also
experiment with the dtab playground feature of a running Linkerd instance by
browsing to `http://localhost:9990/delegator`. See the [Administration]({{% ref
"/1/administration/dtab-playground.md" %}}) page for more details on the
dtab playground.

## Paths

The simplest dtab contains a single rule (called a dentry)

```dtab
/iceCreamStore => /smitten;
```

This dentry is really only useful for ice cream stores, so the rule does not
apply to the path `/shoeStore/windowShop/sandals`.

But for the path `/iceCreamStore/try/allFlavors`, the prefix matches the
dentry's left-hand side (source) and is replaced with the right-hand side
(destination) to create the new path: `/smitten/try/allFlavors`

## Dentries & ordering

Dtabs can (and often do) have more than one dentry. For example, we could list
several stores:

```dtab
/smitten       => /USA/CA/SF/Octavia/432;
/iceCreamStore => /smitten;
/iceCreamStore => /humphrys;
```

When we try to resolve a path that matches more than one prefix, bottom
dentries take precedence. So the path `/iceCreamStore/try/allFlavors` would
resolve first as `/humphrys/try/allFlavors`. However, if the address for
humphrys is unknown (as in this example), we  fall back to
`/smitten/try/allFlavors`, which ultimately resolves to
`/USA/CA/SF/Octavia/432/try/allFlavors`.

----

### STEP-BY-STEP Example

With the dtab:

```dtab
/iceCreamStore    => /smitten;
/smitten/try      => /smittenLocation/waitInLine/thenTry;
/smittenLocation  => /sanfrancisco/octavia/432;
/california       => /USA/CA;
/sanfrancisco     => /california/SF;
```

And the path:

```dtab
/iceCreamStore/try/allFlavors
```

Here are the resolution steps:

`/iceCreamStore/try/allFlavors` first matches the rule `/iceCreamStore =>
/smitten;` and is rewritten to

`/smitten/try/allFlavors` which matches the rule `smitten/try =>
/smittenLocation/waitInLine/thenTry;` and is rewritten to

`/smittenLocation/waitInLine/thenTry/allFlavors` which matches the rule
`/smittenLocation => /sanfrancisco/octavia/432;` and is rewritten to

`/sanfrancisco/octavia/432/waitInLine/thenTry/allFlavors` which matches the
rule `/sanfrancisco => /california/SF;` and is rewritten to

`/california/SF/octavia/432/waitInLine/thenTry/allFlavors` which matches the rule
`/california  => /USA/CA`; and is rewritten to

`/USA/CA/SF/octavia/432/waitInLine/thenTry/allFlavors`!

----

Note that every time a prefix match is made, we start with the newly-made path
and look through the entire dtab again from bottom to top. This is useful, but
also makes it easy to loop accidentally! Consider the following infinite dtab
(and don't worry, Finagle exits after too many recursive calls):

```dtab
/iceCream        => /youScream;
/youScream       => /weAllScream/for;
/weAllScream/for => /iceCream;
```

## Namers & addresses

So far we have only discussed routing on paths. In order for Finagle to
successfully route a request, the path must eventually resolve to a concrete
name. Most of these concrete names (in Finagle they are called "bound
addresses") are defined by or looked up using namers.

Finagle provides one such namer called `/$/inet` which interprets the two
subsequent path segments as an ip address and port. So the path
`/$/inet/127.0.0.1/4140` would resolve to the bound address `127.0.0.1:4140`

Linkerd also provides a suite of namers for many different service discovery
mechanisms. Some examples are [`/#/io.l5d.consul`]({{% linkerdconfig
"consul-service-discovery-experimental" %}}), [`/#/io.l5d.k8s`]({{%
linkerdconfig "kubernetes-service-discovery-experimental" %}}), and
[`/#/io.l5d.marathon`]({{% linkerdconfig
"marathon-service-discovery-experimental" %}}). See more on these and others in
the [Linkerd documentation on namers]({{% linkerdconfig "namers" %}}).

Once a namer converts a path into a bound address, the routing is considered
complete and any residual path segments not used in prefix matching will
remain unused.  As an example, let's define a namer `/#/routeOnMethod` that takes
the next path segment and routes traffic based on if it's a GET or POST.  Then
for the dtab `/http/1.1 => /#/routeOnMethod;`, the path `/http/1.1/GET/host/users`
will be rewritten to `/#/routeOnMethod/GET/host/users` and the prefix
`/#/routeOnMethod/GET` will resolve to a bound address. The rest of the
segments–`/host` and `/users` –have no bearing on where the traffic is routed.

Namers aren't limited to resolving paths, however. At their most basic, namers
are functions that operate on the path segments that follow it.  Consider the
namer `/#/multiply` that multiplies the next two segments together and returns a
single number. For the dtab:

```dtab
/byNine  => /#/multiply/9;
/byEight => /#/multiply/8;
/bySeven => /#/multiply/7;
```

The path `/byNine/3` will be rewritten to `/#/multiply/9/3` and finally to `/27`.

## Wildcards

When receiving paths like `/http/1.1/GET/chocolate/icecream`, we may not be
interested in using every path segment when routing the request. If all icecream
needs to be routed to `/smitten`, it doesn't matter what flavor it is. One way
to write this dtab is to list all possible flavors:

```dtab
/http/1.1/GET/chocolate/icecream => /smitten;
/http/1.1/GET/vanilla/icecream => /smitten;
/http/1.1/GET/rockyroad/icecream => /smitten;
/http/1.1/GET/strawberry/icecream => /smitten;
/http/1.1/GET/mintchip/icecream => /smitten;
...
```

A simpler and more elegant solution is to replace the flavors segment with a
wildcard that will match any string for that segment.

```dtab
/http/1.1/GET/*/icecream => /smitten;
```

## Alternates, unions, & weights

When two dentries have the same prefix, we call them alternates. We saw an
example of one above. Here it is again:

```dtab
/smitten       => /USA/CA/SF/Octavia/432;
/iceCreamStore => /smitten;
/iceCreamStore => /humphrys;
```

Alternates can also be specified using the pipe operator:

```dtab
/smitten       => /USA/CA/SF/Harrison/2790;
/iceCreamStore => /humphrys | /smitten;
```

In both of these examples, humphrys is the first ice cream store address we
try to resolve. But if the address is not found we proceed to smitten (and if
smitten is not found either, the whole routing operation fails–no one gets ice
cream). You can specify any number of alternates `/humphrys | /smitten |
/birite | /three-twins` ...

Dtabs also support unions with the following syntax `/iceCreamStore =>
/humphrys & /smitten`.  In this example we have an equal chance of routing the
path to either store. If we wanted to be more likely to enter one store than
another, we can add weights to each path:

```dtab
/smitten       => 3 * /SF/Octavia/432 & 1 * /SF/California/2404;
/iceCreamStore => 0.7 * /humphrys & 0.3 * /smitten;
```

Weights can be decimals or integers.

## Negative, failure, & empty resolutions

If a namer isn't able to find a concrete address, it returns a negative
resolution. This signals to Finagle that this path was a dud, and if there are
any alternate paths to try, now would be a good time. If all paths are
negative, Finagle throws an error. This kind of fallback logic can be tested
with the symbol `~` which Finagle interprets as a negative resolution.
For example:

```dtab
/iceCreamStore => ~ | /smitten;
```

If we want  to stop before checking any alternate paths, we should use failure
instead of negative. Failure is specified using `/$/fail` or even shorter `!`,
like in this dtab where we route to smitten or bust:

```dtab
/iceCreamStore => /smitten | !;
```

Namers sometimes also return failure resolutions. For example the `/multiply`
namer might return a failure for the path `/multiply/cats/dogs`.

There is a final resolution called empty. It is invoked via `/$/nil` or `$`, and
it is usually only used in test scenarios.
