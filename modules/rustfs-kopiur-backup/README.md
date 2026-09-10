# rustfs-kopiur-backup

Orchestrator module for kopiur's per-environment backup buckets. Composes two generic building blocks --
it has no resources of its own beyond what's genuinely kopiur-specific:

- [`rustfs-bucket-user`](../rustfs-bucket-user) provisions the bucket, quota, least-privilege policy, and
  dedicated user on RustFS.
- [`onepassword-item`](../onepassword-item) writes the resulting credentials, plus a generated
  `KOPIA_PASSWORD`, into a single `kopiur-backup#<env>` 1Password item -- field labels `AWS_ACCESS_KEY_ID`,
  `AWS_SECRET_ACCESS_KEY`, and `KOPIA_PASSWORD`, matching exactly what `kopiur-repository`'s and
  `kopiur-secret`'s `ExternalSecret`s in `isejalabs/homelab` expect (`dataFrom.extract` pulls every field
  in the item as a flat key-value map, keyed by label).

See the [Changelog](CHANGELOG.md) for all notable changes, and [ROTATION.md](ROTATION.md) for how to
rotate each of the credentials this module touches -- they don't all rotate the same way.

## Usage

```hcl
module "dev_kopiur_backup" {
  source = "git::https://github.com/isejalabs/terraform-modules.git//modules/rustfs-kopiur-backup"

  name = "dev-kopiur-backup"
  env  = "dev"

  rustfs = {
    endpoint      = "rustfs.example.com:9000"
    access_key    = var.rustfs_admin_access_key
    access_secret = var.rustfs_admin_access_secret
  }
  onepassword = {
    service_account_token = var.onepassword_service_account_token
  }
  onepassword_vault_id = var.onepassword_vault_id
}
```

`name` is the bucket/user/policy name (see [`rustfs-bucket-user`](../rustfs-bucket-user)'s README);
`env` is used only to build the 1Password item title, `kopiur-backup#<env>` -- the two are separate inputs
because they don't share the same format (e.g. `name = "dev-kopiur-backup"`, `env = "dev"`).

See [`docs/module.md`](docs/module.md) for the full auto-generated reference (all inputs/outputs/resources).

## Outputs

`bucket_name`/`policy_name`/`access_key`/`secret_key` are passed straight through from
[`rustfs-bucket-user`](../rustfs-bucket-user). `onepassword_item_uuid` identifies the created 1Password
item.

## Caveats

- The generated `KOPIA_PASSWORD` lives only in this module's own state and the 1Password item -- there's
  no separate output for it (unlike `access_key`/`secret_key`), since it isn't meant to be consumed by
  anything other than the 1Password item itself.
- All caveats of [`rustfs-bucket-user`](../rustfs-bucket-user) and
  [`onepassword-item`](../onepassword-item) apply here too (rename safety, single-item ownership). Rotation
  is manual for now (see [ROTATION.md](ROTATION.md)) -- automating it is tracked in
  [#21](https://github.com/isejalabs/terraform-modules/issues/21).

## Feedback

Want something added or changed? Open an [issue](https://github.com/isejalabs/terraform-modules/issues).
