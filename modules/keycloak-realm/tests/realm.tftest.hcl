# Offline test (no Keycloak or 1Password needed): one realm and one UCS federation per entry of `realms`, the
# federation is read-only and takes the bind credential from 1Password, and invalid input is rejected.
# Run: tofu test (from this directory)

mock_provider "keycloak" {}

mock_provider "onepassword" {
  mock_data "onepassword_item" {
    defaults = {
      username = "admin"
      password = "mock-secret"
    }
  }
}

variables {
  onepassword          = { service_account_token = "token" }
  onepassword_vault_id = "vault-id"
  keycloak_url         = "https://auth.example.com"
  admin_item_title     = "keycloak-bootstrap-admin#dev"

  ldap = {
    connection_urls = ["ldaps://dc1.example.com:636", "ldaps://dc2.example.com:636"]
    bind_dn         = "uid=keycloak-ro,cn=users,dc=example,dc=com"
    bind_item_title = "keycloak-ldap-bind#dev"
  }

  realms = {
    iseja = {
      display_name  = "Iseja"
      users_dn      = "cn=users,dc=example,dc=com"
      user_filter   = "(memberOf=cn=idm-users,cn=groups,dc=example,dc=com)"
      groups_dn     = "cn=groups,dc=example,dc=com"
      groups_filter = "(cn=app-*)"
    }
    admin = {
      display_name = "Admin"
      users_dn     = "cn=users,dc=example,dc=com"
      user_filter  = "(memberOf=cn=idm-admins,cn=groups,dc=example,dc=com)"
      groups_dn    = "cn=groups,dc=example,dc=com"
    }
  }
}

run "one_realm_and_federation_per_entry" {
  command = plan

  assert {
    condition     = length(keycloak_realm.this) == 2 && length(keycloak_ldap_user_federation.ucs) == 2
    error_message = "Every entry of realms must get a realm and an LDAP federation."
  }

  assert {
    condition     = keycloak_ldap_user_federation.ucs["admin"].custom_user_search_filter == "(memberOf=cn=idm-admins,cn=groups,dc=example,dc=com)"
    error_message = "Each realm must use its own user filter."
  }
}

run "federation_is_read_only_and_fails_over" {
  command = plan

  assert {
    condition     = keycloak_ldap_user_federation.ucs["iseja"].edit_mode == "READ_ONLY" && keycloak_ldap_user_federation.ucs["iseja"].import_enabled
    error_message = "UCS stays authoritative: read-only, users imported."
  }

  assert {
    condition     = keycloak_ldap_user_federation.ucs["iseja"].connection_url == "ldaps://dc1.example.com:636 ldaps://dc2.example.com:636"
    error_message = "Connection URLs must be space-separated in the given order."
  }

  assert {
    condition     = keycloak_ldap_user_federation.ucs["iseja"].bind_credential == "mock-secret"
    error_message = "The bind credential must come from the 1Password item."
  }
}

run "plain_ldap_url_is_rejected" {
  command = plan

  variables {
    ldap = {
      connection_urls = ["ldap://dc1.example.com:389"]
      bind_dn         = "uid=keycloak-ro,cn=users,dc=example,dc=com"
      bind_item_title = "keycloak-ldap-bind#dev"
    }
  }

  expect_failures = [var.ldap]
}

run "master_realm_is_rejected" {
  command = plan

  variables {
    realms = {
      master = {
        display_name = "Master"
        users_dn     = "cn=users,dc=example,dc=com"
        user_filter  = "(uid=*)"
        groups_dn    = "cn=groups,dc=example,dc=com"
      }
    }
  }

  expect_failures = [var.realms]
}
