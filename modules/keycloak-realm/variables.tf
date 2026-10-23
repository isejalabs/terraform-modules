variable "onepassword" {
  description = "1Password service account token used to read the Keycloak admin login and the LDAP bind credential."
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
  description = "Title of the 1Password item holding the Keycloak admin login the provider authenticates with, for example `keycloak-bootstrap-admin#qa`. Read from the item's `username` and `password` (a Login item), or from fields with those labels in any section."
  type        = string
}

variable "ldap" {
  description = <<-EOT
    The LDAP directory (UCS) the realms federate, shared by all realms.

    - `connection_urls`: LDAPS URLs in failover order, for example both domain controllers with the more stable one first. Keycloak tries them in sequence.
    - `bind_dn`: DN of the read-only bind account.
    - `bind_item_title`: title of the 1Password item whose `password` holds the bind credential.
    - The attribute and object class defaults match UCS; adjust them for another directory.
  EOT
  type = object({
    connection_urls      = list(string)
    bind_dn              = string
    bind_item_title      = string
    username_attribute   = optional(string, "uid")
    rdn_attribute        = optional(string, "uid")
    uuid_attribute       = optional(string, "entryUUID")
    user_object_classes  = optional(list(string), ["inetOrgPerson", "organizationalPerson"])
    group_object_classes = optional(list(string), ["posixGroup"])
    group_name_attribute = optional(string, "cn")
    group_member_attr    = optional(string, "uniqueMember")
    full_sync_period     = optional(number, 86400)
    changed_sync_period  = optional(number, 3600)
  })

  validation {
    condition     = length(var.ldap.connection_urls) > 0 && alltrue([for u in var.ldap.connection_urls : startswith(u, "ldaps://")])
    error_message = "ldap.connection_urls must list at least one URL, and every URL must use ldaps://."
  }
}

variable "realms" {
  description = <<-EOT
    The realms to create, keyed by realm name (for example `iseja` and `admin`).

    - `display_name`: shown on the login page.
    - `users_dn`: LDAP subtree the users are searched in.
    - `user_filter`: LDAP filter admitting exactly the accounts of this realm, for example `(memberOf=cn=idm-users,...)`. Wrapped in parentheses by Keycloak, so give the full filter including them.
    - `groups_dn`: LDAP subtree of the groups imported and exposed in the `groups` claim.
    - `groups_filter`: LDAP filter restricting those groups, `null` for all of them.
    - `password_policy`: Keycloak password policy string. Only relevant for local credentials; UCS stays the authority for the password.
    - `max_login_failures`: failed logins before the temporary lockout (brute-force detection).
  EOT
  type = map(object({
    display_name       = string
    users_dn           = string
    user_filter        = string
    groups_dn          = string
    groups_filter      = optional(string)
    password_policy    = optional(string, "length(12) and notUsername")
    max_login_failures = optional(number, 5)
  }))

  validation {
    condition     = length(var.realms) > 0 && !contains(keys(var.realms), "master")
    error_message = "realms must not be empty and must not contain the master realm."
  }
}
