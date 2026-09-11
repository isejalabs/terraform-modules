module "bucket_user" {
  source = "../rustfs-bucket-user"

  name = var.name
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
  title    = "kopiur-backup#${var.env}"
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
