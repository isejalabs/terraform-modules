resource "rustfs_policy" "this" {
  name = var.name

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

  # Preserve the existing key if this module is imported or re-adopted.
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
  title    = var.name
  note     = "Managed by OpenTofu -- edit terraform-modules//modules/rustfs-bucket-reader and re-apply, don't hand-edit fields here."

  sections = [
    {
      label = "s3"
      fields = [
        { label = "AWS_ACCESS_KEY_ID", value = rustfs_user.this.access_key, type = "CONCEALED" },
        { label = "AWS_SECRET_ACCESS_KEY", value = random_password.user_secret.result, type = "CONCEALED" },
      ]
    },
  ]
}
