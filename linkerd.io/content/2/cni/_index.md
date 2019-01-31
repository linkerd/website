+++
date = "2018-07-31T12:00:00-07:00"
title = "Experimental: CNI Plugin"
aliases = [
  "/2/cni-plugin/"
]
[menu.l5d2docs]
  name = "Experimental: CNI Plugin"
  weight = 14
+++
### Problem - CAP_NET_ADMIN
Some security conscious cluster setups disallow the linux capability, [CAP_NET_ADMIN](http://man7.org/linux/man-pages/man7/capabilities.7.html). This is done because when a user has this capability it provides unrestricted access to the network interfaces, including the network card itself; users can capture traffic, change firewall rules and routing tables, and much more. Kubernetes allows cluster administrators to lock down these clusters to prevent users from having this capability unless explicitly allowed. A user in this secured cluster cannot use the `initContainer` provided with the standard linkerd installation because the `initContainer` requires the `NET_ADMIN` capability to write iptables for the pod. These iptables rules are required to allow the `linkerd-proxy` to intercept and route network traffic. An administrator can allow a `ServiceAccount` the `NET_ADMIN` capability, but then every pod that is created in that `ServiceAccount` will have this privilege and this is a security concern.

### Solution - CNI Plugin
One solution to this scenario is to use a CNI Plugin to write the iptables for the pod. See below for usage instructions of this feature and further for more information on CNI.

### Usage
> Note: It is important that the Linkerd CNI DaemonSet is deployed successfully before installing the rest of the linkerd control-plane.

#### Basic Installation
Install the Linkerd CNI DaemonSet
```bash
linkerd install-cni | kubectl apply -f -
```

Once the DaemonSet is up and running, install the Linkerd Control Plane without the `initContainer`s
```bash
linkerd install --linkerd-cni-enabled | kubectl apply -f -
```

After the control plane is ready, inject services without the `initContainer`s
```bash
linkerd inject --linkerd-cni-enabled deployment.yaml | kubectl apply -f -
```

Additionally, there are flags that you can use to customize the installation. See `linkerd install-cni --help` for more information. Note that many of the flags are similar to the flags that can be used to configure the proxy. If you change a port here, you will want to ensure the corresponding ports are changed there as well.

The most important flags are:

1. `--dest-cni-net-dir`: This is the directory on the node where the CNI Configuration resides. It defaults to: `/etc/cni/net.d`.
2. `--dest-cni-bin-dir`: This is the directory on the node where the CNI Plugin binaries reside. It defaults to: `/opt/cni/bin`.
3. `--cni-log-level`: Setting this to `debug` will allow more verbose logging. In order to view the CNI Plugin logs, you must be able to see the `kubelet` logs. One way to do this is to log onto the node and use `journalctl -t kubelet`. The string `linkerd-cni:` can be used as a search to find the plugin log output.

#### Container Network Interface (CNI)
Detailed information about CNI can be found on the [GitHub page](https://github.com/containernetworking/cni). For our purposes, it suffices to know that CNI consists of 3 major parts: a CNI Runtime, a configuration file, and a binary (CNI plugin). The CNI Runtime is an implementation of the [CNI Spec](https://github.com/containernetworking/cni/blob/master/SPEC.md) and the implementation changes based on the container runtime. The parts that we control include the configuration and the binary.

##### Linkerd CNI Configuration
The CNI Configuration file tells the CNI Runtime which CNI Plugin binaries to run and in which order. At the end of the CNI Plugin chain (if there is more than one plugin required), a pod is expected to have an IP Address assigned to it. The `DaemonSet` installed via `linkerd install-cni` looks for any existing CNI Configuration and will append its configuration at the end of the current CNI Plugin chain.

##### Linkerd CNI Plugin Binary
The CNI Runtime will use the CNI Configuration to figure out which CNI Plugin binaries to run and in which order. These binaries will be executed, in order, every time a pod is attempting to start. The `linkerd-cni` binary is what is responsible for writing the iptables rules for the pod.