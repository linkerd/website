---
title: Proxy Log Level
description: Syntax of the proxy log level.
---

The Linkerd proxy's log level can be configured via the:

* `LINKERD_PROXY_LOG` environment variable
* `--proxy-log-level` CLI flag of the `install`, `inject` and `upgrade` commands
* `config.linkerd.io/proxy-log-level` annotation
  (see [Proxy Configuration](../proxy-configuration/))
  which sets `LINKERD_PROXY_LOG` environment-variable on the injected sidecar
* an [endpoint on the admin port](../../tasks/modifying-proxy-log-level/)
  of a running proxy.

The log level is a comma-separated list of log directives, which is
based on the logging syntax of the [`env_logger` crate](https://docs.rs/env_logger/0.6.1/env_logger/#enabling-logging).

A log directive consists of either:

* A level (e.g. `info`), which sets the global log level, or
* A module path (e.g. `foo` or `foo::bar::baz`), or
* A module path followed by an equals sign and a level (e.g. `foo=warn`
or `foo::bar::baz=debug`), which sets the log level for that module

A level is one of:

* `trace`
* `debug`
* `info`
* `warn`
* `error`

A module path represents the path to a Rust module. It consists of one or more
module names, separated by `::`.

A module name starts with a letter, and consists of alphanumeric characters and `_`.

The proxy's default log level is set to `warn,linkerd2_proxy=info`.
