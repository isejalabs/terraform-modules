# rustfs-bucket-reader

Creates a dedicated RustFS user and policy that can read bucket quota statistics for a supplied set of
existing buckets. It does not create buckets or quotas, and grants no object access, quota changes, or
RustFS admin actions. This is intended for monitoring integrations that use RustFS's bucket quota
statistics API.

The generated access key and secret are written directly to a concealed-fields 1Password item through
[`onepassword-item`](../onepassword-item). The secret is deliberately not exposed as a module output.

See the [Changelog](CHANGELOG.md) for notable changes and [`docs/module.md`](docs/module.md) for the full
input/output/resource reference.

## Usage

```hcl
module "rustfs_monitoring" {
  source = "git::https://github.com/isejalabs/terraform-modules.git//modules/rustfs-bucket-reader"

  name = "checkmk-monitoring"
  bucket_names = [
    "prod-kopiur-backup",
    "prod-longhorn-backup",
  ]

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

The policy grants only `s3:GetBucketQuota` on each bucket ARN. RustFS currently uses this action for its
quota-statistics endpoint, quota reads, and quota-check endpoint. It does not grant `s3:ListBucket`, object
actions, quota-setting actions, or `admin:ServerInfo`. See the consuming homelab implementation issue for
the verified endpoint and policy rationale.

## Outputs

The module exposes the policy name and 1Password item UUID. It intentionally does not expose either
credential value; retrieve both from the managed 1Password item.

## Caveats

- RustFS IAM action-to-endpoint mapping means `s3:GetBucketQuota` also authorizes the quota-check API. That
  endpoint can perform usage reads but cannot modify quotas or objects.
- The generated credential is stored in Terraform state as well as in 1Password. Protect the backend and
  state backups accordingly.
- Changing `name` changes the user/policy/item identity and can replace managed resources; treat it as
  stable once applied.

## Feedback

Want something added or changed? Open an [issue](https://github.com/isejalabs/terraform-modules/issues).
