locals {
  # One host per environment, named after the real hostname of that environment's Longhorn deployment (the
  # endpoint itself, scheme stripped) -- unlike checkmk-rustfs-monitoring, there is no shared endpoint across
  # environments here that would need a synthetic per-identity name: each environment's Longhorn already has its
  # own real, resolvable hostname, so the Checkmk host name matches the thing you'd actually go check. Checkmk
  # runs only the first matching rule of the special-agent ruleset per host, so several environments on one host
  # would leave all but one polled -- hence still one host each.
  host_names = { for k, v in var.environments : k => regex("^https?://([^/]+)", v.endpoint)[0] }

  rules = var.rules_enabled ? var.environments : {}

  # Python-literal string values, as the Checkmk rule API expects `value_raw`. The variable validation rules out
  # quotes and backslashes, so plain single-quoting is safe.
  py = { for k, v in local.rules : k => {
    endpoint = "'${v.endpoint}'"
  } }
}

# Dedicated hosts, one per environment, with no Checkmk agent connection (only the configured special agent) --
# but, unlike checkmk-rustfs-monitoring's synthetic identities, resolved to a real IPv4 address rather than
# no-ip: the host name is the real, DNS-resolvable Longhorn hostname, so there is no synthetic-identity reason
# to withhold address resolution. This lets other active checks (HTTP, SSL certificate, ICMP) be added to the
# same host later without needing an explicit "connect to" override, since Checkmk can resolve the host's own
# primary address itself.
resource "checkmk_host" "this" {
  for_each = local.host_names

  host_name = each.value
  folder    = var.folder

  attributes = {
    alias              = "${var.host_alias} (${each.key})"
    tag_address_family = "ip-v4"
    tag_agent          = "special-agents"
  }
}

# One rule per environment, each on the host of that environment, for the ruleset defined by the Longhorn capacity
# special agent plugin (contract v0): endpoint only, since the Longhorn API has no authentication of its own.
resource "checkmk_rule" "special_agent" {
  for_each = local.rules

  ruleset   = "special_agents:longhorn_capacity"
  folder    = "/"
  value_raw = "{'endpoint': ${local.py[each.key].endpoint}}"

  properties = {
    description = "Longhorn disk capacity ${each.key}"
    comment     = "Managed by OpenTofu -- edit terraform-modules//modules/checkmk-longhorn-monitoring and re-apply, don't hand-edit."
  }

  # Always set explicit conditions: the provider fails ("inconsistent result after apply") for a rule without them.
  conditions = {
    host_name = {
      match_on = [checkmk_host.this[each.key].host_name]
      operator = "one_of"
    }
  }
}

# Polling interval of the host. With Checkmk's default of one minute, every disk would be queried every minute. The
# ruleset is built into Checkmk (unlike the special-agent ruleset), so this rule exists independently of rules_enabled.
# The value is in minutes; no service condition, so it also covers the service that runs the special agent.
resource "checkmk_rule" "check_interval" {
  for_each = local.host_names

  ruleset   = "extra_service_conf:check_interval"
  folder    = "/"
  value_raw = format("%.1f", var.check_interval_minutes)

  properties = {
    description = "Longhorn capacity monitoring: check interval of ${each.value}"
    comment     = "Managed by OpenTofu -- edit terraform-modules//modules/checkmk-longhorn-monitoring and re-apply, don't hand-edit."
  }

  conditions = {
    host_name = {
      match_on = [each.value]
      operator = "one_of"
    }
  }
}

# Changes whenever the host or a rule changes, so the activation below re-runs. A `terraform_data` resource is used
# because it always exists: `replace_triggered_by` cannot reference `checkmk_rule.special_agent` directly, since that
# resource has no instances while rules_enabled is false and every plan would then fail ("no change found").
resource "terraform_data" "activation_trigger" {
  input = sha256(jsonencode({
    hosts = {
      for k, h in checkmk_host.this : k => {
        name       = h.host_name
        folder     = h.folder
        attributes = h.attributes
      }
    }
    check_interval = { for k, r in checkmk_rule.check_interval : k => r.value_raw }
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

  depends_on = [checkmk_host.this, checkmk_rule.special_agent, checkmk_rule.check_interval]
}
