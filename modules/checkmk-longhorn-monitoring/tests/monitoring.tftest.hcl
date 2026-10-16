# Offline test (no Checkmk needed): the host has no Checkmk agent connection but is IPv4-resolved (not no-ip) and
# named after the real endpoint hostname, rules exist only when enabled and carry the agreed contract, the
# activation never forces foreign changes, and bad input is rejected. Run: tofu test (from this directory)

mock_provider "checkmk" {}

variables {
  checkmk = { url = "https://checkmk.example.com/prod", username = "terraform", secret = "automation-secret" }
  folder  = "/container/pve4"
  environments = {
    dev = { endpoint = "http://longhorn.dev.example.com" }
    qa  = { endpoint = "http://longhorn.qa.example.com" }
  }
}

run "host_has_no_agent_but_resolves_a_real_address" {
  command = plan

  assert {
    condition     = alltrue([for h in checkmk_host.this : h.attributes["tag_agent"] == "special-agents" && h.attributes["tag_address_family"] == "ip-v4-only"])
    error_message = "Every host must have no Checkmk agent and resolve a real IPv4 address (not no-ip): the host name is a real, resolvable hostname, so other active checks (HTTP, SSL, ICMP) can be added without an explicit target override."
  }

  assert {
    condition     = checkmk_host.this["dev"].host_name == "longhorn.dev.example.com" && checkmk_host.this["qa"].host_name == "longhorn.qa.example.com" && checkmk_host.this["dev"].folder == "/container/pve4"
    error_message = "The host name must be the real endpoint hostname (scheme stripped), not a synthetic pattern, in the given folder."
  }

  assert {
    condition     = length(checkmk_host.this) == 2
    error_message = "Exactly one host per environment."
  }

  assert {
    condition     = length(checkmk_rule.special_agent) == 0
    error_message = "No rule may exist while rules_enabled is false."
  }

  assert {
    condition     = checkmk_activation.this.force_foreign_changes == false
    error_message = "The activation must never force changes made by other users."
  }
}

run "host_name_strips_port_too" {
  command = plan

  variables {
    environments = {
      dev = { endpoint = "http://longhorn.dev.example.com:8080" }
    }
  }

  assert {
    condition     = checkmk_host.this["dev"].host_name == "longhorn.dev.example.com:8080"
    error_message = "The host name is the full authority component (host[:port]) of the endpoint."
  }
}

run "rule_follows_the_contract_when_enabled" {
  command = plan

  variables {
    rules_enabled = true
  }

  assert {
    condition     = checkmk_rule.special_agent["dev"].ruleset == "special_agents:longhorn_capacity"
    error_message = "The rule must target the Longhorn capacity special agent ruleset."
  }

  assert {
    condition     = checkmk_rule.special_agent["dev"].value_raw == "{'endpoint': 'http://longhorn.dev.example.com'}"
    error_message = "value_raw must be the agreed contract: endpoint only, no identity."
  }

  assert {
    condition     = length(checkmk_rule.special_agent) == 2 && checkmk_rule.special_agent["qa"].conditions.host_name.match_on[0] == "longhorn.qa.example.com" && strcontains(checkmk_rule.special_agent["qa"].value_raw, "longhorn.qa.example.com")
    error_message = "Each environment needs its own rule on its own host with its own endpoint."
  }

  assert {
    condition     = checkmk_rule.special_agent["dev"].conditions.host_name.match_on == toset(["longhorn.dev.example.com"]) || checkmk_rule.special_agent["dev"].conditions.host_name.match_on == tolist(["longhorn.dev.example.com"])
    error_message = "The rule must apply to the host of its environment only."
  }
}

run "polling_interval_defaults_to_5_minutes_and_covers_the_host_only" {
  command = plan

  assert {
    condition     = checkmk_rule.check_interval["dev"].ruleset == "extra_service_conf:check_interval" && checkmk_rule.check_interval["dev"].value_raw == "5.0"
    error_message = "The host must be polled every 5 minutes by default."
  }

  assert {
    condition     = checkmk_rule.check_interval["dev"].conditions.host_name.match_on == toset(["longhorn.dev.example.com"]) || checkmk_rule.check_interval["dev"].conditions.host_name.match_on == tolist(["longhorn.dev.example.com"])
    error_message = "The interval rule must apply to the host of its environment only."
  }
}

run "polling_interval_is_configurable" {
  command = plan

  variables {
    check_interval_minutes = 15
  }

  assert {
    condition     = checkmk_rule.check_interval["dev"].value_raw == "15.0"
    error_message = "check_interval_minutes must set the interval."
  }
}

run "polling_interval_below_one_minute_is_rejected" {
  command = plan

  variables {
    check_interval_minutes = 0
  }

  expect_failures = [var.check_interval_minutes]
}

run "quote_in_endpoint_is_rejected" {
  command = plan

  variables {
    environments = {
      dev = { endpoint = "http://it's-a-host.example.com" }
    }
  }

  expect_failures = [var.environments]
}

run "endpoint_with_path_is_rejected" {
  command = plan

  variables {
    environments = {
      dev = { endpoint = "http://longhorn.dev.example.com/v1" }
    }
  }

  expect_failures = [var.environments]
}

run "folder_without_leading_slash_is_rejected" {
  command = plan

  variables {
    folder = "container/pve4"
  }

  expect_failures = [var.folder]
}
