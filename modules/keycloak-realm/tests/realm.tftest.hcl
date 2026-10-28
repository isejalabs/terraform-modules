# Offline test (no Keycloak, LDAP server or 1Password needed): one realm and one UCS federation per entry of `realms`,
# the federation is read-only and takes the bind credential from 1Password, settings have working defaults and can be
# overridden, and invalid input is rejected.
#
# Both providers are mocked and every run is a `plan`, so nothing here ever connects anywhere: the hostnames, DNs and
# the item names below are placeholders (example.com is reserved for documentation) and only have to be well-formed.
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

run "defaults_and_overrides" {
  command = plan

  assert {
    condition     = keycloak_realm.this["iseja"].ssl_required == "external" && keycloak_ldap_user_federation.ucs["iseja"].search_scope == "SUBTREE" && keycloak_ldap_group_mapper.ucs["iseja"].membership_attribute_type == "DN"
    error_message = "Without overrides, the documented defaults must apply."
  }

  assert {
    condition     = keycloak_openid_client_scope.groups["iseja"].name == "groups"
    error_message = "The groups client scope defaults to the name `groups`."
  }
}

run "settings_can_be_overridden" {
  command = plan

  variables {
    realm_settings = { ssl_required = "all" }
    brute_force    = { wait_increment_seconds = 120 }
    groups_claim   = { scope_name = "memberships", claim_name = "roles" }
    ldap = {
      connection_urls = ["ldaps://dc1.example.com:636"]
      bind_dn         = "uid=keycloak-ro,cn=users,dc=example,dc=com"
      bind_item_title = "keycloak-ldap-bind#dev"
      search_scope    = "ONE_LEVEL"
      read_timeout    = "30s"
    }
  }

  assert {
    condition     = keycloak_realm.this["iseja"].ssl_required == "all"
    error_message = "realm_settings must override the default."
  }

  assert {
    condition     = keycloak_realm.this["iseja"].security_defenses[0].brute_force_detection[0].wait_increment_seconds == 120
    error_message = "brute_force must override the default."
  }

  assert {
    condition     = keycloak_ldap_user_federation.ucs["iseja"].search_scope == "ONE_LEVEL" && keycloak_ldap_user_federation.ucs["iseja"].read_timeout == "30s"
    error_message = "ldap must override search scope and timeout."
  }

  assert {
    condition     = keycloak_openid_client_scope.groups["iseja"].name == "memberships" && keycloak_openid_group_membership_protocol_mapper.groups["iseja"].claim_name == "roles"
    error_message = "groups_claim must rename the scope and the claim."
  }
}

run "user_attribute_mappers_replace_the_defaults" {
  command = plan

  assert {
    condition     = keycloak_ldap_user_federation.ucs["iseja"].delete_default_mappers
    error_message = "Keycloak's default mappers must be deleted, the module creates its own."
  }

  assert {
    condition     = keycloak_ldap_user_attribute_mapper.ucs["iseja/first name"].ldap_attribute == "givenName" && keycloak_ldap_user_attribute_mapper.ucs["iseja/last name"].ldap_attribute == "sn" && keycloak_ldap_user_attribute_mapper.ucs["admin/email"].ldap_attribute == "mail"
    error_message = "The first name must come from givenName, not cn."
  }

  assert {
    condition     = length(keycloak_ldap_user_attribute_mapper.ucs) == 12 && keycloak_ldap_user_attribute_mapper.ucs["iseja/email"].always_read_value_from_ldap
    error_message = "Six mappers per realm, and the e-mail address is always read from the directory."
  }
}
