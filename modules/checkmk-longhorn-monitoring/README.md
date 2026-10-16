# checkmk-longhorn-monitoring

The shared Checkmk side of the Longhorn disk capacity monitoring: one API-only host per environment, a
special-agent rule for each, and an activation. Structurally the singleton counterpart of
[`checkmk-rustfs-monitoring`](../checkmk-rustfs-monitoring), simplified because the Longhorn API has no
authentication of its own (no identity, no Password Store reference). See
[ADR 0015 in isejalabs/homelab](https://github.com/isejalabs/homelab/blob/main/docs/decisions/0015-checkmk-configuration-as-code.md)
for why Checkmk is configured through Terraform.

See the [Changelog](CHANGELOG.md) for all notable changes.

## What it creates

- **One API-only host per environment**, named after the real hostname of that environment's Longhorn
  deployment (the `endpoint`'s own hostname, scheme stripped -- for example `environments.dev.endpoint =
  "http://dev-longhorn.dev.iseja.net"` gives a host named `dev-longhorn.dev.iseja.net`; `tag_address_family =
  no-ip`, `tag_agent = special-agents`) in an existing folder. Unlike `checkmk-rustfs-monitoring`, there is no
  shared endpoint across environments here that would need a synthetic per-environment name: each environment
  already has its own real, resolvable hostname, so the Checkmk host name matches the thing you'd actually go
  check. Checkmk runs only the **first** matching rule of the special-agent ruleset per host, so one host for
  several environments would poll just one of them; hence one host each. The hosts must be dedicated: on a host
  with the normal Checkmk agent, a special-agent rule **replaces** the TCP agent connection, silencing the
  existing checks of that host.
- **One `checkmk_rule` per environment** for the ruleset `special_agents:longhorn_capacity`, applying to the
  host of that environment only. Created only when `rules_enabled` is `true`.
- **A polling-interval rule** (`extra_service_conf:check_interval`, `check_interval_minutes`, default 5,
  matching the plan's starting point for Longhorn disk polling). Applies to all services of the host, including
  the one that runs the special agent. Exists independently of `rules_enabled`, as the ruleset is built into
  Checkmk.
- **A `checkmk_activation`** that makes the changes effective.

The module does not create or manage the folder or the plugin that defines the ruleset.

## Rule contract (v0)

The plugin that implements the special agent has to accept exactly this parameter per rule, which the module
writes as the rule's `value_raw`:

| Parameter | Value |
| --- | --- |
| `endpoint` | the environment's Longhorn base URL, for example `http://longhorn.dev.iseja.net` (its existing UI route, which proxies the unauthenticated `/v1/*` API through) |

Unlike `checkmk-rustfs-monitoring`, there is no identity, access key or Password Store reference: the Longhorn
API trusts the network it's reachable on, the same way opening the dashboard in a browser does.

## Usage

```hcl
module "checkmk_longhorn_monitoring" {
  source = "git::https://github.com/isejalabs/terraform-modules.git//modules/checkmk-longhorn-monitoring"

  checkmk = {
    url      = "https://monitoring.example.com/prod" # site URL incl. site name, no trailing slash
    username = "terraform"
    secret   = var.checkmk_automation_secret
  }

  folder = "/container/pve4"

  rules_enabled = false # keep false until the plugin is installed on the site
  environments = {
    dev = { endpoint = "http://longhorn.dev.iseja.net" }
    qa  = { endpoint = "http://longhorn.qa.iseja.net" }
  }
}
```

### The `rules_enabled` switch

The special-agent rules use the ruleset `special_agents:longhorn_capacity`, defined by the plugin package
(`longhorn_capacity` in `isejalabs/checkmk-modules`), not by Checkmk itself. Checkmk rejects a rule for a
ruleset it does not know, so applying the rules before the plugin is installed on the site fails.
`rules_enabled` (default `false`) lets everything else apply first: the host, the polling interval and the
activation are created either way, and the rules follow once the plugin is there. Order: install the plugin on
the site, then set `rules_enabled = true` and apply. It also matters in the other direction: if the plugin is
removed while rules exist, Checkmk no longer shows them and Terraform wants to recreate them and fails, so set
`rules_enabled = false` and apply first, then remove the plugin. See [`docs/module.md`](docs/module.md) for the
full auto-generated reference.

## Activation: safe by design

The provider's `checkmk_activation` defaults to `force_foreign_changes = true`, which activates **all** pending
changes on the site, including ones other users left half-done in the UI. The module sets it to `false`; see
`checkmk-rustfs-monitoring`'s README for the verified behavior, which applies identically here (same module
shape, same provider resources).

## Checkmk side

The automation user needs the folder, host, ruleset and activation permissions; the role described in
[`checkmk-password`'s README](../checkmk-password/README.md#checkmk-side) (cloned from `no_permissions`, 14
permissions) is enough, minus the Password Store permissions this module never uses.

## Outputs

`host_names` (map of environment key to host name) and `rule_descriptions`.

## Tests

`tests/monitoring.tftest.hcl` runs offline with a mocked provider (`tofu test` in this directory): one
API-only host per environment, no rule exists by default, the rule's `value_raw` follows the contract exactly
(endpoint only) and applies to the host of its environment only, the activation never forces foreign changes,
and bad input (quotes in the endpoint, a path in the endpoint, a folder without a leading slash) is rejected.
Not yet applied for real against a live Checkmk site (see `checkmk-rustfs-monitoring`'s README for what that
verification looks like; this module should behave identically, being the same resource shapes with one fewer
field).

## Caveats

- The provider is a young single-maintainer project and not in the OpenTofu registry; the module addresses it
  as `registry.terraform.io/blackmesaltd/checkmk` and pins it exactly.
- The endpoint written into `value_raw` must not contain quotes or backslashes (validated), as it ends up in a
  Python literal.
- A host's attributes are replaced as a whole on update by the provider: do not edit this host in the UI, or
  Terraform will reset it.
- The Longhorn endpoint (the environment's existing UI route) carries no authentication: anyone who can reach
  it on the network can read, and apparently also change, Longhorn's configuration through it. That is an
  existing exposure of the Longhorn deployment itself, not something this module introduces or can fix — flagged
  separately against the homelab repo.

## Feedback

Want something added or changed? Open an [issue](https://github.com/isejalabs/terraform-modules/issues).
