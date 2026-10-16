output "host_names" {
  description = "Names of the API-only hosts carrying the Longhorn capacity services, keyed by environment."
  value       = { for k, h in checkmk_host.this : k => h.host_name }
}

output "rule_descriptions" {
  description = "Descriptions of the special-agent rules created (empty while rules_enabled is false)."
  value       = [for r in checkmk_rule.special_agent : r.properties.description]
}
