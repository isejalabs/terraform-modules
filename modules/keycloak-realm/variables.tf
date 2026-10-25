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
    - The remaining optional attributes tune the federation and the group mapper (names, search scope, timeouts, how memberships are read); the defaults are the values the homelab runs with.

    Deliberately not variables: the federation is always read-only, importing, and without registrations, and the group mapper is read-only (ADR 0016 point 3: UCS stays authoritative).
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

    name                           = optional(string, "ucs")
    search_scope                   = optional(string, "SUBTREE")
    trust_email                    = optional(bool, true)
    connection_timeout             = optional(string, "10s")
    read_timeout                   = optional(string, "10s")
    use_truststore_spi             = optional(string, "ALWAYS")
    group_mapper_name              = optional(string, "groups")
    group_membership_type          = optional(string, "DN")
    group_membership_user_attr     = optional(string, "uid")
    group_memberof_attribute       = optional(string, "memberOf")
    group_user_roles_strategy      = optional(string, "LOAD_GROUPS_BY_MEMBER_ATTRIBUTE")
    group_ignore_missing           = optional(bool, true)
    group_drop_non_existing_synced = optional(bool, true)
    group_preserve_inheritance     = optional(bool, false)

    # LDAP attributes behind the Keycloak user fields. Keycloak's own defaults read the first name from `cn`, which
    # is the full name in UCS.
    user_attributes = optional(object({
      username   = optional(string, "uid")
      email      = optional(string, "mail")
      first_name = optional(string, "givenName")
      last_name  = optional(string, "sn")
    }), {})
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

variable "realm_settings" {
  description = "Settings applied to every realm. The defaults suit realms that only federate a directory: no self-registration, no password reset or username editing in Keycloak, no e-mail login."
  type = object({
    ssl_required             = optional(string, "external")
    login_with_email_allowed = optional(bool, false)
    duplicate_emails_allowed = optional(bool, false)
    registration_allowed     = optional(bool, false)
    reset_password_allowed   = optional(bool, false)
    edit_username_allowed    = optional(bool, false)
    verify_email             = optional(bool, false)
  })
  default = {}
}

variable "security_headers" {
  description = "Browser security headers set by every realm."
  type = object({
    x_frame_options                     = optional(string, "DENY")
    content_security_policy             = optional(string, "frame-src 'self'; frame-ancestors 'self'; object-src 'none';")
    content_security_policy_report_only = optional(string, "")
    x_content_type_options              = optional(string, "nosniff")
    x_robots_tag                        = optional(string, "none")
    x_xss_protection                    = optional(string, "1; mode=block")
    strict_transport_security           = optional(string, "max-age=31536000; includeSubDomains")
  })
  default = {}
}

variable "brute_force" {
  description = "Brute-force detection of every realm; the number of failures before a lockout is `max_login_failures` per realm. Times are in seconds, except `quick_login_check_milli_seconds`."
  type = object({
    permanent_lockout                = optional(bool, false)
    wait_increment_seconds           = optional(number, 60)
    quick_login_check_milli_seconds  = optional(number, 1000)
    minimum_quick_login_wait_seconds = optional(number, 60)
    max_failure_wait_seconds         = optional(number, 900)
    failure_reset_time_seconds       = optional(number, 43200)
  })
  default = {}
}

variable "web_authn" {
  description = "WebAuthn policy of every realm (second factor with passkeys, YubiKeys or platform authenticators)."
  type = object({
    signature_algorithms          = optional(list(string), ["ES256", "RS256"])
    user_verification_requirement = optional(string, "preferred")
  })
  default = {}
}

variable "groups_claim" {
  description = "Name of the client scope and of the token claim that carry the group names. Clients add the scope to receive the claim."
  type = object({
    scope_name = optional(string, "groups")
    claim_name = optional(string, "groups")
    full_path  = optional(bool, false)
  })
  default = {}
}
