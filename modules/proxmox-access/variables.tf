variable "proxmox" {
  description = "How to reach the Proxmox VE API. `api_token` is the full token string (`user@realm!tokenid=secret`) of a token that may manage realms, groups, roles and ACLs (privileges `Realm.Allocate`, `Group.Allocate`, `Sys.Modify`, `Permissions.Modify`, `User.Modify`, in practice the `Administrator` role on `/`)."
  type = object({
    endpoint  = string
    insecure  = optional(bool, false)
    api_token = string
  })
  sensitive = true
}

variable "onepassword" {
  description = "1Password service account token used to read the client secrets of the OpenID Connect clients."
  type = object({
    service_account_token = string
  })
  sensitive = true
}

variable "onepassword_vault_id" {
  description = "UUID of the 1Password vault that holds the client-secret items named in `realms`."
  type        = string
}

variable "realms" {
  description = <<-EOT
    OpenID Connect realms, keyed by the Proxmox realm ID (letters, digits, `.`, `-`, `_`; starts with a letter; at most 32 characters). The realm ID is the part after the `@` of every user it creates, and it is appended to the group names of the claim (see `groups`).

    - `issuer_url`: the issuer of the identity provider, for example `https://auth.example.com/realms/admin`. Proxmox reads the rest from its discovery document, so every node must reach and trust it.
    - `client_id`, `client_secret_item_title`: the OIDC client and the title of the 1Password item whose `password` field is its secret. The secret is sent as the write-only `client_key_wo` and is never stored in the state. Proxmox does not return it, so Terraform cannot see a change of the item: raise `client_key_version` to push a rotated secret.
    - `username_claim`: claim that becomes the user name (`username` is Keycloak's `preferred_username`).
    - `groups_claim`: claim with the list of group names. Proxmox maps a name `x` in realm `r` to the existing group `x-r`.
    - `autocreate`: create the user at the first login. Rights come from group membership only, so a user without a mapped group has none.
    - `groups_autocreate`: let the claim create groups. Keep `false`: a group that is not declared in `groups` (with its ACL) then grants nothing and cannot be created by a token's content.
    - `groups_overwrite`: replace the user's groups at every login (`true`), so that removing a member from the group in the directory takes effect at the next login; `false` only adds.
    - `default`: preselect the realm on the login page. At most one realm of the cluster should be the default (the existing one stays it until the new one is proven).
  EOT
  type = map(object({
    issuer_url               = string
    client_id                = string
    client_secret_item_title = string
    client_key_version       = optional(number, 1)
    comment                  = optional(string)
    username_claim           = optional(string, "username")
    groups_claim             = optional(string, "groups")
    scopes                   = optional(string)
    query_userinfo           = optional(bool, true)
    autocreate               = optional(bool, true)
    groups_autocreate        = optional(bool, false)
    groups_overwrite         = optional(bool, true)
    default                  = optional(bool, false)
  }))
  default = {}

  validation {
    condition     = alltrue([for id, r in var.realms : can(regex("^[A-Za-z][A-Za-z0-9._-]{0,31}$", id))])
    error_message = "A realm ID starts with a letter, may contain letters, digits, '.', '-' and '_', and has at most 32 characters."
  }

  validation {
    condition     = alltrue([for id, r in var.realms : startswith(r.issuer_url, "https://")])
    error_message = "The issuer_url of every realm must use HTTPS."
  }

  validation {
    condition     = length([for id, r in var.realms : id if r.default]) <= 1
    error_message = "At most one realm may be the login-page default."
  }

  validation {
    condition     = alltrue([for id in keys(var.realms) : !contains(["pam", "pve"], lower(id))])
    error_message = "The realm IDs pam and pve belong to Proxmox."
  }
}

variable "groups" {
  description = "Proxmox groups, keyed by group ID, for example `sec.app.proxmox.admin-kc-admin`. A claim value `x` of realm `r` becomes the group `x-r`, so the key is the claim value, a dash and the realm ID. Membership is not managed here: it comes from the claim at login."
  type = map(object({
    comment = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for id, g in var.groups : can(regex("^[A-Za-z0-9._-]+$", id))])
    error_message = "A group ID may contain letters, digits, '.', '-' and '_' only."
  }
}

variable "roles" {
  description = "Custom roles, keyed by role ID, with their privileges, for example `{ Operator = [\"VM.Audit\", \"VM.Console\", \"VM.PowerMgmt\"] }`. The built-in roles (`Administrator`, `PVEAuditor`, ...) are not declared here and can be used in `acls` directly."
  type        = map(list(string))
  default     = {}

  validation {
    condition     = alltrue([for id, privs in var.roles : length(privs) > 0])
    error_message = "A role needs at least one privilege."
  }
}

variable "acls" {
  description = "Access rules, keyed by a free label. `group_id` must be a group declared in `groups`; `role_id` a custom role of `roles` or a built-in one; `path` an ACL path such as `/`, `/vms/100`, `/pool/ops` or `/storage/local`."
  type = map(object({
    path      = string
    role_id   = string
    group_id  = string
    propagate = optional(bool, true)
  }))
  default = {}

  validation {
    condition     = alltrue([for k, a in var.acls : startswith(a.path, "/")])
    error_message = "An ACL path starts with '/'."
  }

  validation {
    condition     = alltrue([for k, a in var.acls : contains(keys(var.groups), a.group_id)])
    error_message = "Every ACL must name a group that is declared in 'groups'."
  }
}
