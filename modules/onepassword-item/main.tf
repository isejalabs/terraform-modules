resource "onepassword_item" "this" {
  vault    = var.vault_id
  title    = var.title
  category = var.category
  tags     = var.tags

  note_value = var.note

  dynamic "section" {
    for_each = var.sections
    content {
      label = section.value.label

      dynamic "field" {
        for_each = section.value.fields
        content {
          label = field.value.label
          value = field.value.value
          type  = field.value.type
        }
      }
    }
  }
}
