# checkmk-password

Stores one secret from 1Password in the [Checkmk](https://checkmk.com) Password Store:

- reads a field of a 1Password item (`data.onepassword_item`, looked up by title, then by section and field label), and
- creates a `checkmk_password` entry with it, so Checkmk rules (for example a special-agent rule) can reference the entry by its identifier instead of carrying the secret inline.

The motivating use is the per-environment RustFS monitoring identity: [`rustfs-bucket-reader`](../rustfs-bucket-reader) writes the credentials into a `checkmk-monitoring#<env>` 1Password item, and this module moves the secret key into Checkmk. See [ADR 0015 in isejalabs/homelab](https://github.com/isejalabs/homelab/blob/main/docs/decisions/0015-checkmk-configuration-as-code.md) for why Checkmk is configured through Terraform, which options were reviewed, and the spike results this module builds on.

See the [Changelog](CHANGELOG.md) for all notable changes.

## Provider

Uses the community provider [`blackmesaltd/checkmk`](https://github.com/BlackMesaLTD/terraform-provider-checkmk) against the Checkmk REST API. It is a young, single-maintainer project and is **not listed in the OpenTofu registry** (only in the Terraform registry), so the module addresses it as `registry.terraform.io/blackmesaltd/checkmk` and pins the exact version (0.0.5). Bump it deliberately, and re-test after Checkmk upgrades.

## Usage

Like [`rustfs-kopiur-backup`](../rustfs-kopiur-backup), this module is meant to be used directly as a Terragrunt root, so it configures both providers itself from sensitive variables:

```hcl
module "checkmk_password" {
  source = "git::https://github.com/isejalabs/terraform-modules.git//modules/checkmk-password"

  checkmk = {
    url      = "https://monitoring.example.com/prod" # site URL incl. site name, no trailing slash
    username = "terraform"
    secret   = var.checkmk_automation_secret
  }
  onepassword          = { service_account_token = var.onepassword_token }
  onepassword_vault_id = "<vault uuid>"

  item_title  = "checkmk-monitoring#dev"   # 1Password item holding the secret
  password_id = "dev_checkmk_monitoring"   # identifier rules can reference
  title       = "dev-checkmk-monitoring"
}
```

By default the field `SECRET_KEY` in the section `rustfs` is used (`section_label`, `field_label`), matching the item written by `rustfs-bucket-reader`. See [`docs/module.md`](docs/module.md) for the full auto-generated reference.

## Checkmk side

The `checkmk` variable is the site URL and an **automation user**. It does not need to be an administrator: a role cloned from the built-in `no_permissions` role and granted exactly `general.use`, `wato.use`, `wato.edit`, `wato.passwords`, `wato.edit_all_passwords`, `wato.edit_hosts`, `wato.manage_hosts`, `wato.edit_folders`, `wato.manage_folders`, `wato.all_folders`, `wato.see_all_folders`, `wato.rulesets`, `wato.activate` and `wato.activateforeign` is enough for this module and the other Checkmk modules (this module itself only uses the password permissions). A Password Store entry needs no activation, and the provider is configured with `activate = "manual"`, so this module never activates pending changes on the site.

## Outputs

`password_id` only. The secret is deliberately not exposed.

## Tests

`tests/password.tftest.hcl` runs offline with mocked providers (`tofu test` in this directory): the entry carries the selected 1Password field, `field_label` selects another field, and identifiers containing `#` or starting with a digit are rejected. It was also applied once for real against a throwaway Checkmk Raw 2.4.0p37 container with the strict role above; Checkmk's audit log recorded the entry being added and removed by that user. That live run is not part of the committed tests, as it needs a Checkmk server.

## Caveats

- The secret value is stored in plaintext in the Terraform state (the provider's `password` attribute is write-only towards Checkmk but part of the resource), like other secrets managed by Terraform here. Protect the backend accordingly.
- Rotating the secret in 1Password and re-applying updates the Password Store entry; anything referencing the entry by identifier keeps working.
- `password_id` cannot be changed after creation (it forces a replacement).
- Checkmk rejects identifiers that start with a digit or contain `.` or `#`; the module accepts letters, digits, `_` and `-`, starting with a letter or underscore.
- The Password Store only obfuscates its content, with the key in the same site directory (`etc/password_store.secret`); site filesystem access stays trusted.
- A rule referencing the entry from a custom special agent also needs the agent plugin installed on the site, which this module does not do.

## Feedback

Want something added or changed? Open an [issue](https://github.com/isejalabs/terraform-modules/issues).
