output "policy_name" {
  description = "Name of the bucket-scoped quota-read policy."
  value       = rustfs_policy.this.name
}

output "onepassword_item_uuid" {
  description = "UUID of the 1Password item containing the monitoring credentials."
  value       = module.secret.item_uuid
}
