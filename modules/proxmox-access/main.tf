data "onepassword_item" "client_secret" {
  for_each = var.realms

  vault = var.onepassword_vault_id
  title = each.value.client_secret_item_title
}

resource "proxmox_realm_openid" "this" {
  for_each = var.realms

  realm      = each.key
  issuer_url = each.value.issuer_url
  client_id  = each.value.client_id
  comment    = each.value.comment

  # Write-only: never in the state or the plan. Raise client_key_version to send a rotated secret.
  client_key_wo         = data.onepassword_item.client_secret[each.key].password
  client_key_wo_version = each.value.client_key_version

  username_claim    = each.value.username_claim
  groups_claim      = each.value.groups_claim
  scopes            = each.value.scopes
  query_userinfo    = each.value.query_userinfo
  autocreate        = each.value.autocreate
  groups_autocreate = each.value.groups_autocreate
  groups_overwrite  = each.value.groups_overwrite
  default           = each.value.default
}

resource "proxmox_virtual_environment_role" "this" {
  for_each = var.roles

  role_id    = each.key
  privileges = each.value
}

resource "proxmox_virtual_environment_group" "this" {
  for_each = var.groups

  group_id = each.key
  comment  = each.value.comment
}

resource "proxmox_acl" "this" {
  for_each = var.acls

  path      = each.value.path
  role_id   = each.value.role_id
  group_id  = proxmox_virtual_environment_group.this[each.value.group_id].group_id
  propagate = each.value.propagate

  # A custom role has to exist before it is granted.
  depends_on = [proxmox_virtual_environment_role.this]
}
