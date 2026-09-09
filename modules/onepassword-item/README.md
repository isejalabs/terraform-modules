# onepassword-item

Generic module to create/manage a single 1Password item (`onepassword_item`) with an arbitrary set of
sections/fields. Knows nothing about what the fields contain -- any module that generates credentials
(a database password, an S3 access key, an API token, ...) can reuse this to write them into 1Password
instead of hand-rolling its own `onepassword_item` resource.

See the [Changelog](CHANGELOG.md) for all notable changes.

## Provider

Uses the official [`1Password/onepassword`](https://registry.terraform.io/providers/1Password/onepassword)
provider, authenticated via a [service account token](https://developer.1password.com/docs/service-accounts/)
(simplest for a CLI-driven `apply` -- no dependency on any particular environment's in-cluster Connect
instance being network-reachable from wherever Terraform runs).

## Usage

```hcl
module "kopiur_backup_secret" {
  source = "git::https://github.com/isejalabs/terraform-modules.git//modules/onepassword-item"

  onepassword = {
    service_account_token = var.onepassword_service_account_token
  }
  vault_id = var.onepassword_vault_id
  title    = "kopiur-backup#dev"
  note     = "Managed by OpenTofu -- edit terraform-modules//modules/rustfs-kopiur-backup and re-apply, don't hand-edit fields here."

  sections = [
    {
      label = "s3"
      fields = [
        { label = "access_key", value = "..." },
        { label = "secret_key", value = "...", type = "CONCEALED" },
      ]
    }
  ]
}
```

Every item created by this module is tagged `iac-managed` by default (`var.tags`), so it's clear at a
glance in the 1Password UI that hand-editing fields will be reverted on the next `apply`.

See [`docs/module.md`](docs/module.md) for the full auto-generated reference (all inputs/outputs/resources).

## Caveats

- The `1Password/onepassword` provider manages the whole item as one resource -- there's no per-field
  ownership. If an item also needs something hand-maintained, either have this module own the *entire*
  item (generate every field it needs, even ones that could otherwise be manual) or use a separate item
  for the hand-maintained parts. Splitting ownership of the same item between Terraform and a human is a
  drift/conflict risk.
