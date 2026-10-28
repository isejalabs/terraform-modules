# Changelog

All _notable_ changes to this module will be documented in this file, following the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format. It won't include each and every change and commit (e.g. ci or documentation changes), but only the notable changes, in a human-readable format that commit messages sometimes do not provide.

This module tries to adhere to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Hence, a change to the version number X.Y.Z will indicate a

- **X+1: breaking changes** in **major** version numbers,
- **Y+1: feature updates** (and possbily bug fixes) in **minor** version numbers, and
- **Z+1: bug fixes** only in **patch** version numbers.

<!--
> [!NOTE]
> [!TIP]
> [!IMPORTANT]
> [!WARNING]
> [!CAUTION]
-->

<!---
## [Unreleased Template]
### Changed

### Added

### Removed

### Fixed

## [X.Y.Z] - YYYY-MM-DD
-->

## [Unreleased]

### Added

### Changed

### Removed

### Fixed

## [0.4.0] - 2026-10-28

### Changed

- **Breaking:** the variable `folder` is replaced by `folder_format`. With a `%s` placeholder (e.g.
  `/K8S/envs/%s`), each environment gets its own existing folder, filled with the environment key (dev/qa/
  prod); without one, the plain path applies to every environment unchanged, same as the old `folder` behaved.
  Migration: rename `folder` to `folder_format`, keeping the same value if a shared folder is still wanted, or
  adding a `%s` for a per-environment one; applying this version moves each existing host to its (possibly
  unchanged) folder, an in-place update, not a replacement.
  ([#64](https://github.com/isejalabs/terraform-modules/issues/64))

## [0.3.0] - 2026-10-26

### Added

- Variable `address_family` (`ip-v4-only`, the default, or `no-ip`) for the hosts' `tag_address_family`. With `no-ip`
  the hosts have no address, so Checkmk runs no host check (PING) and the host never goes DOWN when ICMP to the
  Longhorn endpoint's address is unanswered (for example a load-balancer virtual IP); the special agent only needs
  the endpoint from its rule. The default is unchanged, so this is not breaking.
  ([#76](https://github.com/isejalabs/terraform-modules/issues/76))

## [0.2.0] - 2026-10-16

### Changed

- **Breaking:** the Checkmk host name is now derived from each environment's `endpoint` (the hostname it
  already resolves to, scheme stripped) instead of a separate `host_name_format` pattern. Unlike
  `checkmk-rustfs-monitoring`, there is no shared endpoint across environments here needing a synthetic name --
  each environment's Longhorn already has its own real hostname. The variable `host_name_format` is removed.
  Migration: applying this version renames (destroys and recreates) every existing host.
  ([#60](https://github.com/isejalabs/terraform-modules/issues/60))
- **Breaking:** `tag_address_family` changed from `no-ip` to `ip-v4-only`. The synthetic-identity reason for
  withholding address resolution no longer applies now that the host name is the real, DNS-resolvable Longhorn
  hostname; resolving a real IPv4 address lets other active checks (HTTP, SSL certificate, ICMP) be added to
  the same host later without an explicit "connect to" override. Bundled into the same release as the host
  rename above, which already replaces every host, so this doesn't add an extra apply step.

## [0.1.0] - 2026-10-16

### Added

- Initial module: a dedicated API-only host per environment (`tag_address_family = no-ip`,
  `tag_agent = special-agents`) in an existing folder, one special-agent rule per environment for the ruleset
  `special_agents:longhorn_capacity` (endpoint only, no identity -- the Longhorn API has no authentication;
  gated by `rules_enabled`, default `false`), and an activation with `force_foreign_changes = false` that
  re-runs when a host or rule changes. Uses the community provider
  `registry.terraform.io/blackmesaltd/checkmk` (v0.0.5, pinned exactly, same as `checkmk-rustfs-monitoring`).
  A rule for the polling interval of the host (`check_interval_minutes`, default 5, matching the monitoring
  plan's starting point for Longhorn disk polling). Offline `tofu test` (mocked provider).
  ([#58](https://github.com/isejalabs/terraform-modules/issues/58))
