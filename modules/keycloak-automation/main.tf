data "onepassword_item" "admin" {
  vault = var.onepassword_vault_id
  title = var.admin_item_title
}

locals {
  # A Login item exposes `username`/`password` directly; an item made of plain fields keeps them in sections.
  admin_fields = merge([for s in data.onepassword_item.admin.section : { for f in s.field : f.label => f.value }]...)

  admin_username = coalesce(data.onepassword_item.admin.username, try(local.admin_fields["username"], null))
  admin_password = coalesce(data.onepassword_item.admin.password, try(local.admin_fields["password"], null))
}

# The client only ever uses the client-credentials grant: no browser flow, no password grant, no implicit flow.
resource "keycloak_openid_client" "this" {
  realm_id    = "master"
  client_id   = var.client_id
  name        = "Terragrunt automation"
  description = "Managed by OpenTofu (terraform-modules//modules/keycloak-automation). Service account for realm automation; the break-glass admin is a different identity."
  enabled     = true

  access_type                  = "CONFIDENTIAL"
  service_accounts_enabled     = true
  standard_flow_enabled        = false
  implicit_flow_enabled        = false
  direct_access_grants_enabled = false

  # Keycloak generates the secret; changing this value rotates it.
  client_secret_regenerate_when_changed = {
    rotation = var.secret_rotation
  }
}

# Creating realms is a realm role of the master realm. Keycloak grants the creator all realm-management roles of the
# realm it creates, so no more is needed for realms this client creates itself.
resource "keycloak_openid_client_service_account_realm_role" "create_realm" {
  realm_id                = "master"
  service_account_user_id = keycloak_openid_client.this.service_account_user_id
  role                    = "create-realm"
}

# Every realm has a client `<realm>-realm` in the master realm that carries the roles for managing that realm.
data "keycloak_openid_client" "realm_management" {
  for_each = var.existing_realms

  realm_id  = "master"
  client_id = "${each.key}-realm"
}

# Keycloak has no composite `realm-admin` role in these clients (it is a role of the `realm-management` client of
# non-master realms), so the individual roles are assigned, the same set Keycloak grants the creator of a realm.
resource "keycloak_openid_client_service_account_role" "realm_management" {
  for_each = { for pair in setproduct(var.existing_realms, var.realm_management_roles) : "${pair[0]}/${pair[1]}" => pair }

  realm_id                = "master"
  service_account_user_id = keycloak_openid_client.this.service_account_user_id
  client_id               = data.keycloak_openid_client.realm_management[each.value[0]].id
  role                    = each.value[1]
}

module "client_secret" {
  source = "../onepassword-item"

  vault_id = var.onepassword_vault_id
  title    = var.client_item_title
  note     = "Managed by OpenTofu -- edit terraform-modules//modules/keycloak-automation and re-apply, don't hand-edit fields here."

  # A plain login item: the client ID is the username and the secret the password, which is what keycloak-realm reads.
  username = keycloak_openid_client.this.client_id
  password = keycloak_openid_client.this.client_secret
}
