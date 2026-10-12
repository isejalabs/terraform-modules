# Read-only monitoring identity: may query quota and usage of the listed buckets and nothing else. Deliberately
# no s3:ListBucket, no object ARN ("/*"), no quota-setting actions and no admin:* actions -- see README.
module "user" {
  source = "../rustfs-user"

  name         = var.name
  policy_name  = "${var.name}-ro"
  actions      = ["s3:GetBucketQuota"]
  bucket_names = var.bucket_names
}

# The user resources used to live in this module directly; keep the live ones (no replacement of a credential in use).
moved {
  from = rustfs_policy.this
  to   = module.user.rustfs_policy.this
}

moved {
  from = random_password.user_secret
  to   = module.user.random_password.user_secret
}

moved {
  from = rustfs_user.this
  to   = module.user.rustfs_user.this
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
        { label = "ACCESS_KEY", value = module.user.access_key, type = "CONCEALED" },
        { label = "SECRET_KEY", value = module.user.secret_key, type = "CONCEALED" },
      ]
    },
  ]
}
