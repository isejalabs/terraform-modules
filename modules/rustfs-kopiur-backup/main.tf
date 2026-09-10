module "bucket_user" {
  source = "../rustfs-bucket-user"

  name   = var.name
  rustfs = var.rustfs
}

resource "random_password" "kopia_password" {
  length  = 40
  special = false
}

module "secret" {
  source = "../onepassword-item"

  onepassword = var.onepassword
  vault_id    = var.onepassword_vault_id
  title       = "kopiur-backup#${var.env}"
  note        = "Managed by OpenTofu -- edit terraform-modules//modules/rustfs-kopiur-backup and re-apply, don't hand-edit fields here."

  sections = [
    {
      label = "s3"
      fields = [
        { label = "access_key", value = module.bucket_user.access_key },
        { label = "secret_key", value = module.bucket_user.secret_key, type = "CONCEALED" },
        { label = "KOPIA_PASSWORD", value = random_password.kopia_password.result, type = "CONCEALED" },
      ]
    },
  ]
}
