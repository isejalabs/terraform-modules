output "policy_name" {
  description = "Name of the policy attached to the user."
  value       = rustfs_policy.this.name
}

output "access_key" {
  description = "Access key of the user."
  value       = rustfs_user.this.access_key
}

output "secret_key" {
  description = "Generated secret key of the user."
  value       = rustfs_user.this.secret_key
  sensitive   = true
}

output "granted_actions" {
  description = "The actions the policy allows."
  value       = rustfs_policy.this.statement[0].action
}

output "granted_resources" {
  description = "The resource ARNs the policy applies to (bucket ARNs, plus the object ARNs `/*` when `include_objects` is set)."
  value       = rustfs_policy.this.statement[0].ressource
}
