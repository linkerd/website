+++
date = "2018-07-31T12:00:00-07:00"
title = "Example: debugging an app"
[menu.l5d2docs]
  name = "Example: Debugging"
  weight = 8
+++

This section assumes you've followed the steps in the
[Getting Started](../getting-started) guide and have Linkerd and the demo
application running in a Kubernetes cluster.

## Using Linkerd to debug a failing service

The demo application has some issues. Let's use Linkerd to diagnose these
issues.

If you glance at the Linkerd dashboard (by running the `linkerd dashboard`
command), you should see all the services in the `emojivoto` namespace. Each
service running Linkerd shows success rate, requests per second and latency
percentiles.

That's pretty neat, but the first thing you might notice is that the success
rate is well below 100%! Click on `web` and let's dig in.

You should now be looking at the Deployment page for the web service. The first
thing you'll see here is that the web service is taking traffic from `vote-bot`
(a service included with emojivoto to continually generate a lower level of
life traffic). The web service also has two outgoing dependencies, `emoji` and
`voting`.

While the emoji service is handling every request from web successfully, it
looks like the voting service is failing some requests! A failure in a dependent
service may be exactly what is causing the errors that web is returning.

Let's scroll a little further down the page, we'll see a live list of all
traffic endpoints that "web" is receiving. This is interesting:

There are two calls that are not at 100%: the first is vote-bot's call to the
`/api/vote` endpoint. The second is the `VotePoop` call from the web service to
its dependent service, `voting`. Very interesting! Since `/api/vote` is an
incoming call, and `VotePoop` is an outgoing call, this is a good clue that this
endpoint is what's causing the problem!

Finally, to dig a little deeper, we can click on the `tap` icon in the far right
column. This will take use to the live list of requests that match only this
endpoint. We can confirm that the requests are failing (they all have a
[gRPC status code 2](https://godoc.org/google.golang.org/grpc/codes#Code),
indicating an error).

At this point, we have everything required to either fix the problem ourselves
or chat with another team to get the endpoint fixed and fix the services.
