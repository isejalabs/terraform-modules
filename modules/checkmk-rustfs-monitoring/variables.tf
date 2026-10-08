variable "checkmk" {
  description = "Checkmk site URL (including the site name, no trailing slash, for example `https://monitoring.example.com/prod`) and the automation user the provider authenticates as. See the README for the least-privilege role the user needs."
  type = object({
    url      = string
    username = string
    secret   = string
  })
  sensitive = true
}

variable "host_name" {
  description = "Name of the API-only host that carries the RustFS quota services, for example `rustfs.fiona.home.iseja.net`. It is a dedicated host: a special-agent rule on a host with the normal Checkmk agent would replace the agent connection and silence that host's own checks."
  type        = string

  validation {
    condition     = trimspace(var.host_name) != ""
    error_message = "host_name must not be empty."
  }
}

variable "folder" {
  description = "Path of the existing Checkmk folder the host is created in, for example `/container/pve4`. The folder is not created or managed by this module."
  type        = string
  default     = "/"

  validation {
    condition     = startswith(var.folder, "/")
    error_message = "folder must be a folder path starting with `/`."
  }
}

variable "host_alias" {
  description = "Alias of the host."
  type        = string
  default     = "RustFS bucket quotas (API only)"
}

variable "rules_enabled" {
  description = "Whether to create the special-agent rules. Keep it `false` until the plugin that defines the ruleset `special_agents:rustfs_quota` is installed on the site: Checkmk rejects a rule for a ruleset it does not know. The host and the activation are created either way."
  type        = bool
  default     = false
}

variable "endpoint" {
  description = "Base URL of the RustFS admin/S3 endpoint the special agent queries, for example `https://fiona.home.iseja.net:9002` (no trailing slash). Required when `rules_enabled` is true."
  type        = string
  default     = ""

  validation {
    condition     = !var.rules_enabled || (can(regex("^https?://[^/'\\\\]+$", var.endpoint)))
    error_message = "endpoint must be a base URL like https://host:port (no path, no trailing slash, no quotes or backslashes) when rules_enabled is true."
  }
}

variable "identities" {
  description = "RustFS monitoring identities to create a special-agent rule for, keyed by a short name (the environment), each with the RustFS access key, the identifier of the Checkmk Password Store entry holding its secret key (see the `checkmk-password` module), and the buckets to query. Quotes and backslashes are not allowed in the values: they are written into a Python literal."
  type = map(object({
    access_key  = string
    password_id = string
    buckets     = list(string)
  }))
  default = {}

  validation {
    condition = alltrue(flatten([
      for k, v in var.identities : concat(
        [length(v.buckets) > 0],
        [for s in concat([k, v.access_key, v.password_id], v.buckets) : trimspace(s) != "" && !can(regex("['\\\\]", s))]
      )
    ]))
    error_message = "Each identity needs at least one bucket, and no blank values; quotes and backslashes are not allowed."
  }
}
