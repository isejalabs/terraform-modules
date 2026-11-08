# Offline test (no Proxmox or 1Password needed): the OpenID Connect realm sends its secret write-only, rights come from
# declared groups and roles only, and invalid input is rejected.
#
# Both providers are mocked and every run is a plan, so nothing here ever connects anywhere: the hostnames and item
# names below are placeholders (example.com is reserved for documentation) and only have to be well-formed.
# Run: tofu test (from this directory)

mock_provider "proxmox" {}

mock_provider "onepassword" {
  mock_data "onepassword_item" {
    defaults = {
      username = "proxmox"
      password = "mock-secret"
    }
  }
}

variables {
  proxmox              = { endpoint = "https://pve.example.com:8006", api_token = "terraform@pve!mock=00000000-0000-0000-0000-000000000000" }
  onepassword          = { service_account_token = "token" }
  onepassword_vault_id = "vault-id"

  realms = {
    kc-admin = {
      issuer_url               = "https://auth.example.com/realms/admin"
      client_id                = "proxmox"
      client_secret_item_title = "keycloak-proxmox#admin"
    }
  }

  groups = {
    "sec.app.proxmox.admin-kc-admin" = { comment = "Administrators" }
  }

  roles = {
    Operator = ["VM.Audit", "VM.Console", "VM.PowerMgmt"]
  }

  acls = {
    admin = { path = "/", role_id = "Administrator", group_id = "sec.app.proxmox.admin-kc-admin" }
  }
}

run "realm_defaults_are_least_privilege" {
  command = plan

  assert {
    condition     = proxmox_realm_openid.this["kc-admin"].username_claim == "username" && proxmox_realm_openid.this["kc-admin"].groups_claim == "groups"
    error_message = "The realm must take the user name from 'username' and the groups from 'groups'."
  }

  assert {
    condition     = proxmox_realm_openid.this["kc-admin"].autocreate && !proxmox_realm_openid.this["kc-admin"].groups_autocreate && proxmox_realm_openid.this["kc-admin"].groups_overwrite
    error_message = "Users may be autocreated, groups may not, and the groups are replaced at every login."
  }

  assert {
    condition     = !proxmox_realm_openid.this["kc-admin"].default
    error_message = "A new realm must not become the login-page default."
  }
}

run "acl_binds_declared_group_and_role" {
  command = plan

  assert {
    condition     = proxmox_acl.this["admin"].path == "/" && proxmox_acl.this["admin"].role_id == "Administrator" && proxmox_acl.this["admin"].propagate
    error_message = "The ACL must grant the role on the path and propagate by default."
  }

  assert {
    condition     = proxmox_virtual_environment_role.this["Operator"].role_id == "Operator"
    error_message = "The custom role must be created."
  }
}

run "second_default_realm_is_rejected" {
  command = plan

  variables {
    realms = {
      a = { issuer_url = "https://auth.example.com/realms/a", client_id = "x", client_secret_item_title = "i", default = true }
      b = { issuer_url = "https://auth.example.com/realms/b", client_id = "x", client_secret_item_title = "i", default = true }
    }
    acls = {}
  }

  expect_failures = [var.realms]
}

run "plain_http_issuer_is_rejected" {
  command = plan

  variables {
    realms = {
      a = { issuer_url = "http://auth.example.com/realms/a", client_id = "x", client_secret_item_title = "i" }
    }
    acls = {}
  }

  expect_failures = [var.realms]
}

run "builtin_realm_names_are_rejected" {
  command = plan

  variables {
    realms = {
      pve = { issuer_url = "https://auth.example.com/realms/a", client_id = "x", client_secret_item_title = "i" }
    }
    acls = {}
  }

  expect_failures = [var.realms]
}

run "acl_for_undeclared_group_is_rejected" {
  command = plan

  variables {
    acls = {
      bad = { path = "/", role_id = "PVEAuditor", group_id = "nobody" }
    }
  }

  expect_failures = [var.acls]
}
