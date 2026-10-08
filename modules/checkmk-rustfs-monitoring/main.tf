# Dedicated API-only host: no IP address and no Checkmk agent, only the configured special agents.
resource "checkmk_host" "this" {
  host_name = var.host_name
  folder    = var.folder

  attributes = {
    alias              = var.host_alias
    tag_address_family = "no-ip"
    tag_agent          = "special-agents"
  }
}

locals {
  rules = var.rules_enabled ? var.identities : {}

  # Python-literal string values, as the Checkmk rule API expects `value_raw`. The variable validation rules out
  # quotes and backslashes, so plain single-quoting is safe.
  py = { for k, v in local.rules : k => {
    endpoint    = "'${var.endpoint}'"
    access_key  = "'${v.access_key}'"
    password_id = "'${v.password_id}'"
    buckets     = join(", ", [for b in v.buckets : "'${b}'"])
  } }
}

# One rule per identity for the ruleset defined by the RustFS quota special agent plugin (contract v0):
# endpoint, access_key, secret_key (a Password Store reference, never the secret itself) and buckets.
resource "checkmk_rule" "special_agent" {
  for_each = local.rules

  ruleset   = "special_agents:rustfs_quota"
  folder    = "/"
  value_raw = "{'endpoint': ${local.py[each.key].endpoint}, 'access_key': ${local.py[each.key].access_key}, 'secret_key': ('cmk_postprocessed', 'stored_password', (${local.py[each.key].password_id}, '')), 'buckets': [${local.py[each.key].buckets}]}"

  properties = {
    description = "RustFS bucket quota ${each.key}"
    comment     = "Managed by OpenTofu -- edit terraform-modules//modules/checkmk-rustfs-monitoring and re-apply, don't hand-edit."
  }

  # Always set explicit conditions: the provider fails ("inconsistent result after apply") for a rule without them.
  conditions = {
    host_name = {
      match_on = [checkmk_host.this.host_name]
      operator = "one_of"
    }
  }
}

# Changes whenever the host or a rule changes, so the activation below re-runs. A `terraform_data` resource is used
# because it always exists: `replace_triggered_by` cannot reference `checkmk_rule.special_agent` directly, since that
# resource has no instances while rules_enabled is false and every plan would then fail ("no change found").
resource "terraform_data" "activation_trigger" {
  input = sha256(jsonencode({
    host = {
      name       = checkmk_host.this.host_name
      folder     = checkmk_host.this.folder
      attributes = checkmk_host.this.attributes
    }
    rules = {
      for k, r in checkmk_rule.special_agent : k => {
        value_raw   = r.value_raw
        description = r.properties.description
        conditions  = r.conditions
      }
    }
  }))
}

# Activates the pending changes. force_foreign_changes is false on purpose: the provider default (true) would also
# activate changes other users have pending in the UI; with false the activation fails instead, and those changes
# have to be resolved first. The provider has no `triggers` argument, so the activation is replaced (re-run)
# whenever the trigger above changes.
resource "checkmk_activation" "this" {
  force_foreign_changes = false

  lifecycle {
    replace_triggered_by = [terraform_data.activation_trigger]
  }

  depends_on = [checkmk_host.this, checkmk_rule.special_agent]
}
