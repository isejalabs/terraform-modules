variable "checkmk" {
  description = "Checkmk site URL (including the site name, no trailing slash, for example `https://monitoring.example.com/prod`) and the automation user the provider authenticates as. See the README for the least-privilege role the user needs."
  type = object({
    url      = string
    username = string
    secret   = string
  })
  sensitive = true
}

variable "folder_format" {
  description = "Path of the existing Checkmk folder each host is created in, optionally with `%s` as a placeholder for the environment key -- for example `/K8S/envs/%s` gives dev/qa/prod each their own folder, while a plain path like `/misc` (no `%s`) puts every environment in the same shared folder. The folder is not created or managed by this module."
  type        = string

  validation {
    condition     = startswith(var.folder_format, "/") && length(regexall("%s", var.folder_format)) <= 1
    error_message = "folder_format must be a folder path starting with `/` and contain at most one `%s` placeholder for the environment key."
  }
}

variable "host_alias" {
  description = "Alias of the hosts; the environment key is appended in parentheses."
  type        = string
  default     = "Longhorn disk capacity (API only)"
}

variable "rules_enabled" {
  description = "Whether to create the special-agent rules. Keep it `false` until the plugin that defines the ruleset `special_agents:longhorn_capacity` is installed on the site: Checkmk rejects a rule for a ruleset it does not know. The hosts and the activation are created either way."
  type        = bool
  default     = false
}

variable "environments" {
  description = "Environments to create a Longhorn capacity monitoring host and rule for, keyed by a short name, each with the base URL of that environment's Longhorn deployment (its existing UI route, which proxies the unauthenticated API through, for example `http://longhorn.dev.example.com`). Quotes and backslashes are not allowed in the endpoint: it is written into a Python literal."
  type = map(object({
    endpoint = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.environments :
      trimspace(k) != "" && can(regex("^https?://[^/'\\\\]+$", v.endpoint))
    ])
    error_message = "Each environment needs a non-blank key and an endpoint like http(s)://host[:port] (no path, no trailing slash, no quotes or backslashes)."
  }
}

variable "check_interval_minutes" {
  description = "How often Checkmk fetches the data of the API-only host and checks its services, in minutes. Checkmk's default is one minute; the monitoring plan starts at five minutes for Longhorn disk polling, matching the standard service interval. Applied to all services of the host, including the one that runs the special agent."
  type        = number
  default     = 5

  validation {
    condition     = var.check_interval_minutes >= 1 && var.check_interval_minutes <= 1440
    error_message = "check_interval_minutes must be between 1 and 1440 (one day)."
  }
}
