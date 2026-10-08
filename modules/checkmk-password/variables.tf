variable "checkmk" {
  description = "Checkmk site URL (including the site name, no trailing slash, for example `https://monitoring.example.com/prod`) and the automation user the provider authenticates as. The user needs only the Password Store, folder, host, ruleset and activation permissions, see ADR 0015 in isejalabs/homelab."
  type = object({
    url      = string
    username = string
    secret   = string
  })
  sensitive = true
}

variable "onepassword" {
  description = "1Password service account token used to read the secret."
  type = object({
    service_account_token = string
  })
  sensitive = true
}

variable "onepassword_vault_id" {
  description = "UUID of the 1Password vault holding the source item."
  type        = string
}

variable "item_title" {
  description = "Title of the 1Password item holding the secret, for example `checkmk-monitoring#dev`."
  type        = string
}

variable "section_label" {
  description = "Label of the section in the 1Password item that contains the field."
  type        = string
  default     = "rustfs"
}

variable "field_label" {
  description = "Label of the field in that section whose value is stored in Checkmk."
  type        = string
  default     = "SECRET_KEY"
}

variable "password_id" {
  description = "Identifier of the Password Store entry in Checkmk, referenced by rules. Cannot be changed after creation. Must not start with a digit or contain `.` or `#` (Checkmk rejects those); only letters, digits, `_` and `-` are accepted here."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z_][A-Za-z0-9_-]*$", var.password_id))
    error_message = "password_id must start with a letter or underscore and contain only letters, digits, underscores and hyphens."
  }
}

variable "title" {
  description = "Human-readable title of the Password Store entry."
  type        = string
}

variable "comment" {
  description = "Comment of the Password Store entry. Defaults to a note that the entry is managed by OpenTofu."
  type        = string
  default     = null
}
