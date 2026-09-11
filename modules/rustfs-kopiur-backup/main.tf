locals {
  # Only var.name (the shared "kopiur-backup" stem) and var.env differ in format between the bucket/user
  # name and the 1Password item title -- computed here once so neither this module nor its callers repeat
  # the literal.
  full_name = "${var.env}-${var.name}"
}

module "bucket_user" {
  source = "../rustfs-bucket-user"

  name = local.full_name
}

resource "random_password" "kopia_password" {
  length  = 40
  special = false

  # If this is ever imported (adopting a pre-existing repository password instead of generating a new
  # one), don't let a mismatch between its actual original parameters and the ones above force a
  # replacement -- that would silently regenerate a real, already-in-use kopia repository password.
  lifecycle {
    ignore_changes = [length, special]
  }
}

module "secret" {
  source = "../onepassword-item"

  vault_id = var.onepassword_vault_id
  title    = "${var.name}#${var.env}"
  note     = "Managed by OpenTofu -- edit terraform-modules//modules/rustfs-kopiur-backup and re-apply, don't hand-edit fields here."

  sections = [
    {
      label = "s3"
      fields = [
        { label = "AWS_ACCESS_KEY_ID", value = module.bucket_user.access_key, type = "CONCEALED" },
        { label = "AWS_SECRET_ACCESS_KEY", value = module.bucket_user.secret_key, type = "CONCEALED" },
        { label = "KOPIA_PASSWORD", value = random_password.kopia_password.result, type = "CONCEALED" },
      ]
    },
  ]
}
