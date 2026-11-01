variable "onepassword" {
  description = "1Password service account token used to read the bootstrap admin login and to write the automation client's credential."
  type = object({
    service_account_token = string
  })
  sensitive = true
}

variable "onepassword_vault_id" {
  description = "UUID of the 1Password vault holding the items below."
  type        = string
}

variable "keycloak_url" {
  description = "Base URL of the Keycloak instance, without a path and trailing slash, for example `https://auth.example.com`."
  type        = string
}

variable "admin_item_title" {
  description = "Title of the 1Password item holding the bootstrap (break-glass) admin login this module authenticates with, for example `keycloak-bootstrap-admin#qa`. Read from the item's `username` and `password` (a Login item), or from fields with those labels in any section."
  type        = string
}

variable "client_item_title" {
  description = "Title of the 1Password item this module creates for the automation client's credential, for example `keycloak-terragrunt#qa`. It is a login item: the username is the client ID and the password the client secret. `keycloak-realm` reads it (`client_item_title` there)."
  type        = string
}

variable "client_id" {
  description = "Client ID of the automation client in the `master` realm."
  type        = string
  default     = "terragrunt"
}

variable "existing_realms" {
  description = <<-EOT
    Names of realms that already exist and that the automation client has to manage, for example `["iseja", "admin"]`.

    The client may create realms (`create-realm`), and Keycloak makes the creator the administrator of every realm it creates. A realm that was created by somebody else (the bootstrap admin, a restore of a dump) is not covered by that, so name it here: the client then gets `realm-admin` of that realm's `<realm>-realm` client. The realm must exist when the module is applied; leave this empty on a fresh instance.
  EOT
  type        = set(string)
  default     = []

  validation {
    condition     = !contains(var.existing_realms, "master")
    error_message = "existing_realms must not contain the master realm: the automation client never manages it."
  }
}

variable "secret_rotation" {
  description = "Arbitrary value that, when changed, makes Keycloak generate a new client secret on the next apply (for example a date, `2026-11-01`). The new secret is written to the 1Password item in the same apply."
  type        = string
  default     = "initial"
}
