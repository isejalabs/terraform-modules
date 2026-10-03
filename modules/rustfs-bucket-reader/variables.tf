variable "name" {
  description = "Name for the dedicated RustFS user and policy. The same value is used as the 1Password item title."
  type        = string
}

variable "bucket_names" {
  description = "Existing bucket names the monitoring user may query for quota and logical usage. No buckets are created or modified."
  type        = set(string)

  validation {
    condition     = length(var.bucket_names) > 0 && alltrue([for bucket in var.bucket_names : trimspace(bucket) != ""])
    error_message = "bucket_names must contain at least one non-empty bucket name."
  }
}

variable "rustfs" {
  description = "RustFS admin endpoint and credentials used only to provision the policy and user."
  type = object({
    endpoint      = string
    access_key    = string
    access_secret = string
  })
  sensitive = true
}

variable "onepassword" {
  description = "1Password service account token used to write the generated monitoring credentials."
  type = object({
    service_account_token = string
  })
  sensitive = true
}

variable "onepassword_vault_id" {
  description = "UUID of the 1Password vault where the monitoring credential item is created."
  type        = string
}
