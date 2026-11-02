variable "vault_id" {
  description = "UUID of the 1Password vault the item is created in."
  type        = string
}

variable "title" {
  description = "Title of the 1Password item."
  type        = string
}

variable "category" {
  description = "Category of the 1Password item. Changing this on an existing item forces a destroy-then-create replacement."
  type        = string
  default     = "login"
}

variable "tags" {
  description = "Tags assigned to the item."
  type        = list(string)
  default     = ["iac-managed"]
}

variable "note" {
  description = "Plain-text note for the item."
  type        = string
  default     = null
}

variable "username" {
  description = "Username of the item (the top-level `username` of a login item), for example a client ID. Left unset, the item has no username."
  type        = string
  default     = null
}

variable "password" {
  description = "Password of the item (the top-level `password` of a login item), for example a client secret. Left unset, 1Password does not get a password from this module."
  type        = string
  default     = null
  sensitive   = true
}

variable "sections" {
  description = "Sections and fields to write into the item."
  default     = []
  type = list(object({
    label = string
    fields = list(object({
      label = string
      value = string
      type  = optional(string, "STRING")
    }))
  }))
}
