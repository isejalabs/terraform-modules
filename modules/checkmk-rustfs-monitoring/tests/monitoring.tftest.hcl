# Offline test (no Checkmk needed): the host is API-only, rules exist only when enabled and carry the agreed contract,
# the activation never forces foreign changes, and bad input is rejected. Run: tofu test (from this directory)

mock_provider "checkmk" {}

variables {
  checkmk   = { url = "https://checkmk.example.com/prod", username = "terraform", secret = "automation-secret" }
  host_name = "rustfs.fiona.example.com"
  folder    = "/container/pve4"
  endpoint  = "https://fiona.example.com:9002"
  identities = {
    dev = {
      access_key  = "dev-checkmk-monitoring"
      password_id = "dev_checkmk_monitoring"
      buckets     = ["dev-kopiur-backup", "dev-longhorn-backup"]
    }
  }
}

run "host_is_api_only_and_no_rules_by_default" {
  command = plan

  assert {
    condition     = checkmk_host.this.attributes["tag_agent"] == "special-agents" && checkmk_host.this.attributes["tag_address_family"] == "no-ip"
    error_message = "The host must be API-only: no IP address and no Checkmk agent."
  }

  assert {
    condition     = checkmk_host.this.host_name == "rustfs.fiona.example.com" && checkmk_host.this.folder == "/container/pve4"
    error_message = "Host name and folder must be the given ones."
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
    condition     = checkmk_rule.special_agent["dev"].conditions.host_name.match_on == toset(["rustfs.fiona.example.com"]) || checkmk_rule.special_agent["dev"].conditions.host_name.match_on == tolist(["rustfs.fiona.example.com"])
    error_message = "The rule must apply to the API-only host only."
  }
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

run "folder_without_leading_slash_is_rejected" {
  command = plan

  variables {
    folder = "container/pve4"
  }

  expect_failures = [var.folder]
}
