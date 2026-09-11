variable "name" {
  description = "Base name for the bucket/user/policy triple and the 1Password item title. Combined with var.env as \"<env>-<name>\" (bucket/user/policy, passed through to rustfs-bucket-user) and \"<name>#<env>\" (1Password item title)."
  type        = string
  default     = "kopiur-backup"
}

variable "env" {
  description = "Environment identifier. Combined with var.name to build the bucket/user/policy name (\"<env>-<name>\") and the 1Password item title (\"<name>#<env>\")."
  type        = string
}

variable "rustfs" {
  description = "RustFS admin endpoint and credentials used to provision the bucket/policy/user."
  type = object({
    endpoint      = string
    access_key    = string
    access_secret = string
  })
  sensitive = true
}

variable "onepassword" {
  description = "1Password service account token used to write the generated credentials."
  type = object({
    service_account_token = string
  })
  sensitive = true
}

variable "onepassword_vault_id" {
  description = "UUID of the 1Password vault the \"<name>#<env>\" item (see var.name) is created in."
  type        = string
}
