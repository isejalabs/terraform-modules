# OIDC clients for applications that sign humans in with OpenID Connect, either natively (Flux Operator, Proxmox) or
# through an OIDC-aware reverse proxy such as oauth2-proxy (Longhorn, Zigbee2MQTT). Every client is attached to one
# realm, so an application that accepts accounts from two realms gets two clients, one per realm.

locals {
  # PKCE: public clients always use S256 unless the entry says otherwise, confidential ones only on request.
  oidc_pkce = { for key, c in var.oidc_clients : key => (c.pkce == null ? c.public : c.pkce) }

  # Clients whose generated secret is handed on through 1Password (confidential ones only; a public client has none).
  oidc_confidential_clients = { for key, c in var.oidc_clients : key => c if !c.public }
}

resource "keycloak_openid_client" "this" {
  for_each = var.oidc_clients

  realm_id  = keycloak_realm.this[each.value.realm].id
  client_id = coalesce(each.value.client_id, each.key)
  name      = coalesce(each.value.name, each.key)
  enabled   = true

  access_type = each.value.public ? "PUBLIC" : "CONFIDENTIAL"

  # Authorization code flow only: no implicit flow, no password grant, no service account.
  standard_flow_enabled        = true
  implicit_flow_enabled        = false
  direct_access_grants_enabled = false
  service_accounts_enabled     = false

  pkce_code_challenge_method = local.oidc_pkce[each.key] ? "S256" : null

  valid_redirect_uris             = each.value.redirect_uris
  valid_post_logout_redirect_uris = each.value.post_logout_redirect_uris
  web_origins                     = each.value.web_origins

  # The tokens carry the user claims and the groups, not the realm role mappings of the account.
  full_scope_allowed = false
}

# The default scopes of a new client (the realm defaults of Keycloak, `oidc_default_scopes`), plus `groups` so that
# the group names of the directory land in the ID token, the access token and the userinfo response. The resource is
# authoritative for the default scopes of the client; the optional scopes are left alone.
resource "keycloak_openid_client_default_scopes" "this" {
  for_each = var.oidc_clients

  realm_id  = keycloak_openid_client.this[each.key].realm_id
  client_id = keycloak_openid_client.this[each.key].id

  default_scopes = concat(
    var.oidc_default_scopes,
    each.value.groups_scope ? [var.groups_claim.scope_name] : [],
  )

  depends_on = [keycloak_openid_client_scope.groups]
}

# The generated secret of a confidential client goes into a 1Password item: a login item with the client ID as
# `username` and the secret as `password`, the same shape the keycloak-automation module writes. An ExternalSecret hands
# it to the application (oauth2-proxy, Flux Operator), Terragrunt or Ansible can read it for the others. It is
# deliberately not an output.
module "oidc_client_secret" {
  source   = "../onepassword-item"
  for_each = local.oidc_confidential_clients

  vault_id = var.onepassword_vault_id
  title    = coalesce(each.value.secret_item_title, format(var.oidc_secret_item_title_format, each.key))
  note     = "Managed by OpenTofu -- edit terraform-modules//modules/keycloak-realm (oidc_clients) and re-apply, don't hand-edit fields here."

  username = keycloak_openid_client.this[each.key].client_id
  password = keycloak_openid_client.this[each.key].client_secret
}
