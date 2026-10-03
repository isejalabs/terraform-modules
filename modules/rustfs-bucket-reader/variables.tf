variable "name" {
  description = "Canonical name for this user/policy pair. Used verbatim for the user's access key and the 1Password item title, and as the base name (with a `-ro` suffix) for the policy -- one input so they never drift apart. Required (no default) so the identity is always named after its consumer and environment; treat it as stable once applied, as changing it replaces the user, policy and item."
  type        = string
}

variable "bucket_names" {
  description = "Names of the existing buckets the user may read quota information for. These are only referenced by name in the policy; the module neither creates nor manages them, so buckets created outside Terraform can be listed too."
  type        = set(string)

  validation {
    condition     = length(var.bucket_names) > 0 && alltrue([for bucket in var.bucket_names : trimspace(bucket) != ""])
    error_message = "bucket_names must contain at least one bucket, and no blank names; an empty list would produce a policy that grants nothing and a blank name an invalid ARN."
  }
}

variable "onepassword_vault_id" {
  description = "UUID of the 1Password vault the credentials item is created in."
  type        = string
}

variable "rustfs" {
  description = "RustFS admin endpoint and credentials used to provision the policy and user."
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
