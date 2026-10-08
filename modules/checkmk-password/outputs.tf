# The secret is deliberately not an output: its only destination is the Checkmk Password Store.

output "password_id" {
  description = "Identifier of the Password Store entry, for referencing it in rules."
  value       = checkmk_password.this.password_id
}
