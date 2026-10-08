output "host_name" {
  description = "Name of the API-only host carrying the RustFS quota services."
  value       = checkmk_host.this.host_name
}

output "rule_descriptions" {
  description = "Descriptions of the special-agent rules created (empty while rules_enabled is false)."
  value       = [for r in checkmk_rule.special_agent : r.properties.description]
}
