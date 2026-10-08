# The source item is looked up by title (an API lookup, so a `#` in the title is fine, unlike in an `op://`
# secret reference).
data "onepassword_item" "source" {
  vault = var.onepassword_vault_id
  title = var.item_title
}

locals {
  secret = data.onepassword_item.source.section_map[var.section_label].field_map[var.field_label].value
}

resource "checkmk_password" "this" {
  password_id = var.password_id
  title       = var.title
  password    = local.secret
  comment     = coalesce(var.comment, "Managed by OpenTofu -- edit terraform-modules//modules/checkmk-password and re-apply, don't hand-edit.")
}
