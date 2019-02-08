+++
date = "2018-09-10T12:00:00-07:00"
title = "Experimental: High Availability"
[menu.l5d2docs]
  name = "Experimental: High Availability"
  weight = 14
+++

Linkerd can be ran in High Availability or HA mode.

This feature is **experimental** and it's only available in the [_edge_ release](../edge/).

Here's a short description of what `--ha` does to the `linkerd` install.

* Defaults the controller replicas to `3`
* Set's sane `cpu` + `memory` requests to the linkerd control plane components.
* Defaults to a sensible requests for the sidecar containers for the control plane + [_auto proxy injection_](../proxy-injection/).


### Setup
Because it's the control plane that requires the `ha` config, you'll need to use the `install` command with the `ha` flag.

```bash
linkerd install --ha | kubectl apply -f
```

You can also override the amount of controller replicas that you wish to run by passing in the `--controller-replicas` flag

```bash
linkerd install --ha --controller-replicas=2 | kubectl apply -f
```
