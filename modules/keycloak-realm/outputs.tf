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
