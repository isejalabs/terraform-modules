# rustfs-user

The shared core of the RustFS users in this repository: a policy (`rustfs_policy`), a generated secret (`random_password`) and a user (`rustfs_user`) with a generated secret key, attached to that policy. It is a pure child module, used by [`rustfs-bucket-user`](../rustfs-bucket-user) (read/write on its own bucket) and [`rustfs-bucket-reader`](../rustfs-bucket-reader) (quota read on a list of buckets), which decide the buckets and the actions.

See the [Changelog](CHANGELOG.md) for all notable changes.

## Usage

This module has no provider configuration of its own, whatever calls it configures the `rustfs` provider (see the [`rustfs-bucket-user` README](../rustfs-bucket-user/README.md#usage)).

```hcl
module "user" {
  source = "git::https://github.com/isejalabs/terraform-modules.git//modules/rustfs-user"

  name         = "prod-checkmk-monitoring"
  policy_name  = "prod-checkmk-monitoring-ro"
  actions      = ["s3:GetBucketQuota"]
  bucket_names = ["prod-kopiur-backup"]
  # include_objects = true # also the object ARNs (<bucket>/*), for object actions
}
```

The policy has one `Allow` statement with the given `actions` on `arn:aws:s3:::<bucket>` for each bucket, and with `include_objects` also on `arn:aws:s3:::<bucket>/*`. It is deliberately not a read/write mode switch: the quota-reading monitoring identity has no object access, and a read-only object user (for example for restores) would be a third shape. The callers hold the presets. The buckets are only referenced by name, never created. The outputs `granted_actions` and `granted_resources` show what the policy grants.

See [`docs/module.md`](docs/module.md) for the full auto-generated reference (all inputs/outputs/resources).

## Tests

`tests/policy.tftest.hcl` runs offline with mocked providers (`tofu test` in this directory): bucket ARNs only by default, object ARNs only on request, the user attached to the policy, and empty action or bucket lists rejected.

## Caveats

The caveats of the RustFS user live here, once, for all modules built on it.

- No automated credential rotation / lifetime for the generated secret, see [#21](https://github.com/isejalabs/terraform-modules/issues/21). Manual rotation: replace `random_password.user_secret` (with `-replace`, at the address the caller gives it, for example `module.bucket_user.module.user.random_password.user_secret`); that forces `rustfs_user` to be replaced too, as `secret_key` is immutable on that resource.
- **If the RustFS user is deleted externally, `plan`/`apply` doesn't recover automatically, it hard-fails.** Unlike `onepassword_item` (which treats an externally deleted item as drift and plans a recreate), `rustfs_user`'s `Read` propagates the raw `NoSuchResource` API error instead of clearing the resource from state. Remediation: `terraform state rm <address>` for just that resource, then a normal `apply` recreates it, using the same secret already in `random_password.user_secret` state, so the credential itself doesn't change.
- **Disaster recovery (Terraform state lost, user still exists on RustFS): `rustfs_user.secret_key` cannot be recovered via plain `terraform import`.** The provider's `Read` never fetches it from RustFS (the admin API doesn't expose it), it only preserves what is in state, which after a fresh import is empty. As `secret_key` forces replacement on any change, importing `rustfs_user` as-is will always want to replace it on the next `apply`. If you have the real secret from another source (for example the 1Password item or a backed-up state), the only clean way to adopt it is state surgery: `terraform state pull`, patch the `rustfs_user` instance's `secret_key` (and bump `serial`) in the JSON, then `terraform state push`. `random_password.user_secret` imports normally: it has `lifecycle { ignore_changes = [length, special] }`, so the original generation parameters of an imported password don't force a replacement.
- Renaming (changing `name`) replaces the user and with it the credential: `name` is the access key. Treat it as stable once applied; callers that also derive other names from it (bucket, 1Password item) have more to lose, see their caveats.
- Adding or removing a bucket from `bucket_names` updates the policy in place.

## Feedback

Want something added or changed? Open an [issue](https://github.com/isejalabs/terraform-modules/issues).
