variable "name" {
  description = "Canonical name for this bucket/user/policy triple. Used verbatim for the bucket name and the dedicated user's access key, and as the base name (with a `-rw` suffix) for its policy -- one input so all three never drift apart."
  type        = string
}

variable "policy_actions" {
  description = "S3 actions the dedicated bucket user is allowed to perform, scoped to its own bucket only."
  type        = list(string)
  default = [
    "s3:GetObject",
    "s3:PutObject",
    "s3:DeleteObject",
    "s3:ListBucket",
  ]
}

variable "quota" {
  description = "Bucket storage quota, in bytes."
  type        = number
  default     = 10 * 1024 * 1024 * 1024 # 10 GiB
}

variable "versioning_enabled" {
  description = "Whether to enable bucket versioning."
  type        = bool
  default     = false
}
