output "realms" {
  description = "The managed OpenID Connect realm IDs (the part after `@` in a user ID)."
  value       = keys(proxmox_realm_openid.this)
}

output "groups" {
  description = "The managed Proxmox group IDs."
  value       = keys(proxmox_virtual_environment_group.this)
}

output "roles" {
  description = "The managed custom role IDs."
  value       = keys(proxmox_virtual_environment_role.this)
}
