# Read-only monitoring identity: may query quota and usage of the listed buckets and nothing else. Deliberately
# no s3:ListBucket, no object ARN ("/*"), no quota-setting actions and no admin:* actions -- see README.
resource "rustfs_policy" "this" {
  name = "${var.name}-ro"

  statement = [
    {
      effect = "Allow"
      action = ["s3:GetBucketQuota"]
      ressource = [
        for bucket in var.bucket_names : "arn:aws:s3:::${bucket}"
      ]
    },
  ]
}

resource "random_password" "user_secret" {
  length  = 40
  special = false

  # If this is ever imported (e.g. disaster recovery, re-adopting a user that already exists on RustFS), don't
  # let a mismatch between its actual original parameters and the ones above force a replacement -- that would
  # silently regenerate a real, already-in-use secret.
  lifecycle {
    ignore_changes = [length, special]
  }
}

resource "rustfs_user" "this" {
  access_key = var.name
  secret_key = random_password.user_secret.result
  policy     = rustfs_policy.this.name
}

module "secret" {
  source = "../onepassword-item"

  vault_id = var.onepassword_vault_id
  title    = coalesce(var.item_title, var.name)
  note     = "Managed by OpenTofu -- edit terraform-modules//modules/rustfs-bucket-reader and re-apply, don't hand-edit fields here."

  sections = [
    {
      label = "rustfs"
      fields = [
        { label = "ACCESS_KEY", value = rustfs_user.this.access_key, type = "CONCEALED" },
        { label = "SECRET_KEY", value = rustfs_user.this.secret_key, type = "CONCEALED" },
      ]
    },
  ]
}
