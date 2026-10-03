variable "name" {
  description = "Canonical name for this user/policy pair. Used verbatim for the user's access key and the 1Password item title, and as the base name (with a `-ro` suffix) for the policy -- one input so they never drift apart."
  type        = string
  default     = "rustfs-monitoring"
}

variable "buckets" {
  description = "Names of the existing buckets the user may read quota information for. These are only referenced by name in the policy; the module neither creates nor manages them, so buckets created outside Terraform can be listed too."
  type        = set(string)

  validation {
    condition     = length(var.buckets) > 0
    error_message = "At least one bucket is required; an empty resource list would produce a policy that grants nothing."
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
