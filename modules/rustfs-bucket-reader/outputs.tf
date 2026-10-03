# No credential is exposed as an output on purpose, neither the secret key nor the (non-secret) access key: the
# credentials' only intended destination is the 1Password item, so they never show up in `terraform output`.

output "policy_name" {
  description = "Name of the read-only quota policy attached to the user."
  value       = rustfs_policy.this.name
}

output "item_uuid" {
  description = "UUID of the 1Password item holding the credentials."
  value       = module.secret.item_uuid
}
