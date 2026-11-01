# The client secret and the admin login are deliberately not outputs.

output "client_id" {
  description = "Client ID of the automation client in the `master` realm."
  value       = keycloak_openid_client.this.client_id
}

output "service_account_user_id" {
  description = "ID of the service-account user behind the automation client."
  value       = keycloak_openid_client.this.service_account_user_id
}

output "client_item_uuid" {
  description = "UUID of the 1Password item holding the client credential."
  value       = module.client_secret.item_uuid
}
