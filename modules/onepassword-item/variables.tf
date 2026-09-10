variable "onepassword" {
  description = "1Password service account token used to manage the item."
  type = object({
    service_account_token = string
  })
  sensitive = true
}

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

variable "sections" {
  description = "Sections and fields to write into the item."
  type = list(object({
    label = string
    fields = list(object({
      label = string
      value = string
      type  = optional(string, "STRING")
    }))
  }))
}
