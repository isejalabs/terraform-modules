# No secret is exposed as an output on purpose: the credential's only intended destination is the 1Password
# item, so it never shows up in `terraform output` or wrapper-module outputs.

output "policy_name" {
  description = "Name of the read-only quota policy attached to the user."
  value       = rustfs_policy.this.name
}

output "access_key" {
  description = "Access key of the monitoring user (not a secret; the secret key is only written to 1Password)."
  value       = rustfs_user.this.access_key
}

output "item_uuid" {
  description = "UUID of the 1Password item holding the credentials."
  value       = module.secret.item_uuid
}
