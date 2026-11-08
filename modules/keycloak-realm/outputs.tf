# The bind credential and the admin login are deliberately not outputs.

output "realm_ids" {
  description = "Realm names, keyed by realm name, for referencing the realms (for example when registering clients)."
  value       = { for name, r in keycloak_realm.this : name => r.id }
}

output "groups_client_scope_ids" {
  description = "IDs of the `groups` client scope, keyed by realm name; clients add it to receive the `groups` claim."
  value       = { for name, s in keycloak_openid_client_scope.groups : name => s.id }
}

output "saml_idp_metadata_urls" {
  description = "SAML identity provider metadata URL per realm that has at least one SAML client, keyed by realm name; the SP imports it to learn the signing certificate and the endpoints."
  value       = { for realm in distinct([for c in var.saml_clients : c.realm]) : realm => "${var.keycloak_url}/realms/${realm}/protocol/saml/descriptor" }
}

output "saml_client_ids" {
  description = "Internal IDs of the SAML clients, keyed like `saml_clients`."
  value       = { for key, c in keycloak_saml_client.this : key => c.id }
}

output "oidc_client_ids" {
  description = "Internal IDs of the OIDC clients, keyed like `oidc_clients`. The generated secrets are deliberately not outputs; they are in the 1Password items (`oidc_secret_item_title_format`)."
  value       = { for key, c in keycloak_openid_client.this : key => c.id }
}

output "oidc_issuer_urls" {
  description = "OIDC issuer URL per realm, keyed by realm name; the discovery document is at `<issuer>/.well-known/openid-configuration`."
  value       = { for name in keys(var.realms) : name => "${var.keycloak_url}/realms/${name}" }
}

output "oidc_secret_item_titles" {
  description = "Title of the 1Password item holding the client secret, per confidential OIDC client, keyed like `oidc_clients`."
  value       = { for key, m in module.oidc_client_secret : key => coalesce(var.oidc_clients[key].secret_item_title, format(var.oidc_secret_item_title_format, key)) }
}
