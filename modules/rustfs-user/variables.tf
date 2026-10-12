variable "name" {
  description = "Access key of the user. Treat it as stable once applied: changing it replaces the user and, with it, its credential."
  type        = string

  validation {
    condition     = trimspace(var.name) != ""
    error_message = "name must not be blank."
  }
}

variable "policy_name" {
  description = "Name of the policy created for the user (callers use a suffix such as `-rw` or `-ro` on the user name, which tells the two kinds apart in the RustFS console)."
  type        = string

  validation {
    condition     = trimspace(var.policy_name) != ""
    error_message = "policy_name must not be blank."
  }
}

variable "actions" {
  description = "S3 actions the user is allowed to perform on the given buckets, for example `[\"s3:GetBucketQuota\"]`."
  type        = list(string)

  validation {
    condition     = length(var.actions) > 0 && alltrue([for a in var.actions : trimspace(a) != ""])
    error_message = "actions must contain at least one action, and no blank entries."
  }
}

variable "bucket_names" {
  description = "Names of the buckets the policy applies to. They are only referenced by name in the policy ARNs; the module neither creates nor manages them, so buckets created outside Terraform can be listed too."
  type        = set(string)

  validation {
    condition     = length(var.bucket_names) > 0 && alltrue([for bucket in var.bucket_names : trimspace(bucket) != ""])
    error_message = "bucket_names must contain at least one bucket, and no blank names; an empty list would produce a policy that grants nothing and a blank name an invalid ARN."
  }
}

variable "include_objects" {
  description = "Whether the policy also covers the objects of the buckets (the ARN `<bucket>/*`), as needed for object actions such as `s3:GetObject`. `false` limits it to the bucket ARNs, which is enough for bucket-level actions like `s3:GetBucketQuota` and keeps the user without any object access."
  type        = bool
  default     = false
}
