# The bind credential and the admin login are deliberately not outputs.

output "realm_ids" {
  description = "Realm names, keyed by realm name, for referencing the realms (for example when registering clients)."
  value       = { for name, r in keycloak_realm.this : name => r.id }
}

output "groups_client_scope_ids" {
  description = "IDs of the `groups` client scope, keyed by realm name; clients add it to receive the `groups` claim."
  value       = { for name, s in keycloak_openid_client_scope.groups : name => s.id }
}
