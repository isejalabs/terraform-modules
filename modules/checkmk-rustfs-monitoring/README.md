# checkmk-rustfs-monitoring

The shared Checkmk side of the RustFS bucket quota monitoring: one API-only host, one special-agent rule per RustFS monitoring identity, and an activation. It is the singleton counterpart to the per-environment [`checkmk-password`](../checkmk-password) module. See [ADR 0015 in isejalabs/homelab](https://github.com/isejalabs/homelab/blob/main/docs/decisions/0015-checkmk-configuration-as-code.md) for why Checkmk is configured through Terraform and for the spike results this module builds on.

See the [Changelog](CHANGELOG.md) for all notable changes.

## What it creates

- **An API-only host** (`tag_address_family = no-ip`, `tag_agent = special-agents`) in an existing folder. It must be a dedicated host: on a host with the normal Checkmk agent, a special-agent rule **replaces** the TCP agent connection (Checkmk generates only the special-agent program and no TCP connection), which would silence the existing checks of that host, for example the TrueNAS host itself. On the API-only host Checkmk shows "No Checkmk agent, all configured special agents" and address "No IP".
- **One `checkmk_rule` per identity** for the ruleset `special_agents:rustfs_quota`, applying to that host only. Created only when `rules_enabled` is `true`.
- **A `checkmk_activation`** that makes the changes effective.

The module does not create or manage the folder, the Password Store entries (that is `checkmk-password`), or the plugin that defines the ruleset.

## Rule contract (v0)

The plugin that implements the special agent has to accept exactly these parameters per rule, which the module writes as the rule's `value_raw`:

| Parameter | Value |
| --- | --- |
| `endpoint` | the RustFS base URL, for example `https://fiona.home.iseja.net:9002` |
| `access_key` | the identity's access key |
| `secret_key` | a Password Store reference (`('cmk_postprocessed', 'stored_password', ('<password_id>', ''))`), never the secret |
| `buckets` | list of the bucket names to query |

The agent receives the reference as `<id>:<path>` and resolves it itself with `cmk.utils.password_store.lookup`, so the secret is never on the command line.

## Usage

```hcl
module "checkmk_rustfs_monitoring" {
  source = "git::https://github.com/isejalabs/terraform-modules.git//modules/checkmk-rustfs-monitoring"

  checkmk = {
    url      = "https://monitoring.example.com/prod" # site URL incl. site name, no trailing slash
    username = "terraform"
    secret   = var.checkmk_automation_secret
  }

  host_name = "rustfs.fiona.example.com"
  folder    = "/container/pve4"

  rules_enabled = false # keep false until the plugin is installed on the site
  endpoint      = "https://fiona.example.com:9002"
  identities = {
    dev = {
      access_key  = "dev-checkmk-monitoring"
      password_id = "dev_checkmk_monitoring"
      buckets     = ["dev-kopiur-backup", "dev-longhorn-backup"]
    }
  }
}
```

`rules_enabled` stays `false` until the plugin is installed on the site (otherwise Checkmk rejects the rule: it does not know the ruleset). The host and the activation are created either way. See [`docs/module.md`](docs/module.md) for the full auto-generated reference.

## Activation: safe by design

The provider's `checkmk_activation` defaults to `force_foreign_changes = true`, which activates **all** pending changes on the site, including ones other users left half-done in the UI. The module sets it to `false`. If someone else has pending changes, the activation fails (the provider reports "Activation Failed ... status 401") and activates nothing; the host and rule changes made by this module stay pending. To recover, resolve the other pending changes in Checkmk (activate or discard them), then run the apply again. This was verified against a throwaway Checkmk Raw 2.4: with a pending change from another user the apply failed and that change stayed pending, and after it was resolved a re-apply completed with nothing pending.

The provider has no `triggers` argument for the activation, and `replace_triggered_by` cannot point at the rules (no instances while `rules_enabled` is false: every plan would fail with "no change found"). The module therefore uses a `terraform_data` resource that carries a hash of the host and the rules and replaces the activation whenever that hash changes.

## Checkmk side

The automation user needs the Password Store, folder, host, ruleset and activation permissions; the role described in [`checkmk-password`'s README](../checkmk-password/README.md#checkmk-side) (cloned from `no_permissions`, 14 permissions) is enough. `wato.activateforeign` is among them but is not used to force foreign changes here.

## Outputs

`host_name` and `rule_descriptions`.

## Tests

`tests/monitoring.tftest.hcl` runs offline with a mocked provider (`tofu test` in this directory): the host is API-only, no rule exists by default, the rule's `value_raw` follows the contract exactly and applies to the host only, the activation never forces foreign changes, and bad input (missing endpoint, quotes in values, no buckets, a folder without a leading slash) is rejected. The module was also applied, changed, re-planned and destroyed for real against a throwaway Checkmk Raw 2.4.0p37, including the foreign-change case above; that run is not part of the committed tests as it needs a Checkmk server. The live run found the `replace_triggered_by` problem above.

## Caveats

- The provider is a young single-maintainer project and not in the OpenTofu registry; the module addresses it as `registry.terraform.io/blackmesaltd/checkmk` and pins it exactly.
- Values written into `value_raw` must not contain quotes or backslashes (validated), as they end up in a Python literal.
- Rule value formats are Checkmk-version specific (Checkmk 2.5 changes the Password Store reference representation); re-validate after a Checkmk upgrade.
- A host's attributes are replaced as a whole on update by the provider: do not edit this host in the UI, or Terraform will reset it.

## Feedback

Want something added or changed? Open an [issue](https://github.com/isejalabs/terraform-modules/issues).
