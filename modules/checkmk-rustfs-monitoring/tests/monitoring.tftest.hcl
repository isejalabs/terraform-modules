# Offline test (no Checkmk needed): the host is API-only, rules exist only when enabled and carry the agreed contract,
# the activation never forces foreign changes, and bad input is rejected. Run: tofu test (from this directory)

mock_provider "checkmk" {}

variables {
  checkmk          = { url = "https://checkmk.example.com/prod", username = "terraform", secret = "automation-secret" }
  host_name_format = "rustfs-%s.fiona.example.com"
  folder           = "/container/pve4"
  endpoint         = "https://fiona.example.com:9002"
  identities = {
    dev = {
      access_key  = "dev-checkmk-monitoring"
      password_id = "dev_checkmk_monitoring"
      buckets     = ["dev-kopiur-backup", "dev-longhorn-backup"]
    }
    qa = {
      access_key  = "qa-checkmk-monitoring"
      password_id = "qa_checkmk_monitoring"
      buckets     = ["qa-kopiur-backup"]
    }
  }
}

run "host_is_api_only_and_no_rules_by_default" {
  command = plan

  assert {
    condition     = alltrue([for h in checkmk_host.this : h.attributes["tag_agent"] == "special-agents" && h.attributes["tag_address_family"] == "no-ip"])
    error_message = "Every host must be API-only: no IP address and no Checkmk agent."
  }

  assert {
    condition     = checkmk_host.this["dev"].host_name == "rustfs-dev.fiona.example.com" && checkmk_host.this["qa"].host_name == "rustfs-qa.fiona.example.com" && checkmk_host.this["dev"].folder == "/container/pve4"
    error_message = "There must be one host per identity, named by the pattern, in the given folder."
  }

  assert {
    condition     = length(checkmk_host.this) == 2
    error_message = "Exactly one host per identity."
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

run "rule_follows_the_contract_when_enabled" {
  command = plan

  variables {
    rules_enabled = true
  }

  assert {
    condition     = checkmk_rule.special_agent["dev"].ruleset == "special_agents:rustfs_quota"
    error_message = "The rule must target the RustFS quota special agent ruleset."
  }

  assert {
    condition     = checkmk_rule.special_agent["dev"].value_raw == "{'endpoint': 'https://fiona.example.com:9002', 'access_key': 'dev-checkmk-monitoring', 'secret_key': ('cmk_postprocessed', 'stored_password', ('dev_checkmk_monitoring', '')), 'buckets': ['dev-kopiur-backup', 'dev-longhorn-backup']}"
    error_message = "value_raw must be the agreed contract with a Password Store reference, never a secret."
  }

  assert {
    condition     = length(checkmk_rule.special_agent) == 2 && checkmk_rule.special_agent["qa"].conditions.host_name.match_on[0] == "rustfs-qa.fiona.example.com" && strcontains(checkmk_rule.special_agent["qa"].value_raw, "qa-checkmk-monitoring")
    error_message = "Each identity needs its own rule on its own host with its own credentials."
  }

  assert {
    condition     = checkmk_rule.special_agent["dev"].conditions.host_name.match_on == toset(["rustfs-dev.fiona.example.com"]) || checkmk_rule.special_agent["dev"].conditions.host_name.match_on == tolist(["rustfs-dev.fiona.example.com"])
    error_message = "The rule must apply to the host of its identity only."
  }
}

run "polling_interval_defaults_to_15_minutes_and_covers_the_host_only" {
  command = plan

  assert {
    condition     = checkmk_rule.check_interval["dev"].ruleset == "extra_service_conf:check_interval" && checkmk_rule.check_interval["dev"].value_raw == "15.0"
    error_message = "The host must be polled every 15 minutes by default."
  }

  assert {
    condition     = checkmk_rule.check_interval["dev"].conditions.host_name.match_on == toset(["rustfs-dev.fiona.example.com"]) || checkmk_rule.check_interval["dev"].conditions.host_name.match_on == tolist(["rustfs-dev.fiona.example.com"])
    error_message = "The interval rule must apply to the host of its identity only."
  }
}

run "polling_interval_is_configurable" {
  command = plan

  variables {
    check_interval_minutes = 5
  }

  assert {
    condition     = checkmk_rule.check_interval["dev"].value_raw == "5.0"
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

run "rules_enabled_without_endpoint_is_rejected" {
  command = plan

  variables {
    rules_enabled = true
    endpoint      = ""
  }

  expect_failures = [var.endpoint]
}

run "quote_in_bucket_name_is_rejected" {
  command = plan

  variables {
    identities = {
      dev = {
        access_key  = "dev-checkmk-monitoring"
        password_id = "dev_checkmk_monitoring"
        buckets     = ["it's-a-bucket"]
      }
    }
  }

  expect_failures = [var.identities]
}

run "identity_without_buckets_is_rejected" {
  command = plan

  variables {
    identities = {
      dev = {
        access_key  = "dev-checkmk-monitoring"
        password_id = "dev_checkmk_monitoring"
        buckets     = []
      }
    }
  }

  expect_failures = [var.identities]
}

run "host_name_format_without_placeholder_is_rejected" {
  command = plan

  variables {
    host_name_format = "rustfs.fiona.example.com"
  }

  expect_failures = [var.host_name_format]
}

run "folder_without_leading_slash_is_rejected" {
  command = plan

  variables {
    folder = "container/pve4"
  }

  expect_failures = [var.folder]
}
