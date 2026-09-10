variable "name" {
  description = "Canonical name for the bucket/user/policy triple, passed through to rustfs-bucket-user."
  type        = string
}

variable "env" {
  description = "Environment identifier, used to build the 1Password item title (kopiur-backup#<env>)."
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
  description = "UUID of the 1Password vault the kopiur-backup#<env> item is created in."
  type        = string
}
