# Offline test of the WebAuthn relying-party ID and the second-factor browser flow (see realm.tftest.hcl for the
# setup): the relying-party ID defaults to the hostname of keycloak_url and can be set module-wide or per realm, a realm
# without `second_factor` keeps the built-in browser flow, a realm with it gets the flow and the binding, and invalid
# input is rejected. Whether Keycloak runs the flow as intended is only known against a real instance.
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
    connection_urls = ["ldaps://dc1.example.com:636"]
    bind_dn         = "uid=keycloak-ro,cn=users,dc=example,dc=com"
    bind_item_title = "keycloak-ldap-bind#dev"
  }

  realms = {
    iseja = {
      display_name = "Iseja"
      users_dn     = "cn=users,dc=example,dc=com"
      user_filter  = "(memberOf=cn=idm-users,cn=groups,dc=example,dc=com)"
      groups_dn    = "cn=groups,dc=example,dc=com"
    }
    admin = {
      display_name = "Admin"
      users_dn     = "cn=users,dc=example,dc=com"
      user_filter  = "(memberOf=cn=idm-admins,cn=groups,dc=example,dc=com)"
      groups_dn    = "cn=groups,dc=example,dc=com"
    }
  }
}

run "relying_party_id_defaults_to_the_keycloak_hostname" {
  command = plan

  assert {
    condition     = alltrue([for r in keycloak_realm.this : r.web_authn_policy[0].relying_party_id == "auth.example.com"])
    error_message = "Without a setting, the relying-party ID must be the hostname of keycloak_url (no scheme, port or path)."
  }

  assert {
    condition     = alltrue([for r in keycloak_realm.this : r.web_authn_policy[0].user_verification_requirement == "preferred"])
    error_message = "User verification must default to preferred."
  }
}

run "relying_party_id_and_user_verification_can_be_set_module_wide_and_per_realm" {
  command = plan

  variables {
    keycloak_url = "https://auth.example.com:8443"
    web_authn    = { relying_party_id = "example.com" }
    realms = {
      iseja = {
        display_name = "Iseja"
        users_dn     = "cn=users,dc=example,dc=com"
        user_filter  = "(memberOf=cn=idm-users,cn=groups,dc=example,dc=com)"
        groups_dn    = "cn=groups,dc=example,dc=com"
      }
      admin = {
        display_name = "Admin"
        users_dn     = "cn=users,dc=example,dc=com"
        user_filter  = "(memberOf=cn=idm-admins,cn=groups,dc=example,dc=com)"
        groups_dn    = "cn=groups,dc=example,dc=com"
        web_authn    = { relying_party_id = "admin.example.com", user_verification_requirement = "required" }
      }
    }
  }

  assert {
    condition     = keycloak_realm.this["iseja"].web_authn_policy[0].relying_party_id == "example.com" && keycloak_realm.this["admin"].web_authn_policy[0].relying_party_id == "admin.example.com"
    error_message = "The module-wide relying-party ID must apply to every realm, a realm's own one must win."
  }

  assert {
    condition     = keycloak_realm.this["iseja"].web_authn_policy[0].user_verification_requirement == "preferred" && keycloak_realm.this["admin"].web_authn_policy[0].user_verification_requirement == "required"
    error_message = "A realm's own user verification must win over the module-wide one."
  }
}

run "hostname_is_taken_from_a_url_with_a_port" {
  command = plan

  variables {
    keycloak_url = "https://auth.example.com:8443"
  }

  assert {
    condition     = keycloak_realm.this["iseja"].web_authn_policy[0].relying_party_id == "auth.example.com"
    error_message = "A port in keycloak_url must not end up in the relying-party ID."
  }
}

run "no_second_factor_keeps_the_builtin_browser_flow" {
  command = plan

  assert {
    condition     = length(keycloak_authentication_flow.mfa) == 0 && length(keycloak_authentication_bindings.mfa) == 0
    error_message = "Without second_factor no flow and no binding may be created."
  }
}

run "second_factor_creates_flow_and_binding_for_that_realm_only" {
  command = plan

  variables {
    realms = {
      iseja = {
        display_name  = "Iseja"
        users_dn      = "cn=users,dc=example,dc=com"
        user_filter   = "(memberOf=cn=idm-users,cn=groups,dc=example,dc=com)"
        groups_dn     = "cn=groups,dc=example,dc=com"
        second_factor = { enroll = "totp" }
      }
      admin = {
        display_name  = "Admin"
        users_dn      = "cn=users,dc=example,dc=com"
        user_filter   = "(memberOf=cn=idm-admins,cn=groups,dc=example,dc=com)"
        groups_dn     = "cn=groups,dc=example,dc=com"
        second_factor = {}
      }
    }
  }

  assert {
    condition     = length(keycloak_authentication_flow.mfa) == 2 && keycloak_authentication_bindings.mfa["iseja"].browser_flow == "browser-mfa"
    error_message = "Every realm with second_factor needs the flow and must bind it as its browser flow."
  }

  assert {
    condition     = keycloak_authentication_execution.mfa_enroll["iseja"].authenticator == "auth-otp-form" && keycloak_authentication_execution.mfa_enroll["admin"].authenticator == "webauthn-authenticator"
    error_message = "enroll must pick the authenticator whose required action registers the factor; webauthn is the default."
  }

  assert {
    condition     = keycloak_authentication_execution.mfa_enroll["admin"].requirement == "REQUIRED" && keycloak_authentication_execution.mfa_password["admin"].requirement == "REQUIRED"
    error_message = "The password form and the enrollment must be REQUIRED."
  }

  assert {
    condition     = keycloak_authentication_execution_config.mfa_enroll_condition["admin"].config["check_result"] == "not-executed"
    error_message = "The enrollment must only run when the verification sub-flow did not."
  }

  # Keycloak 25+ ignores the creation order: entries with the same priority run in an arbitrary order.
  assert {
    condition = (
      keycloak_authentication_execution.mfa_cookie["admin"].priority < keycloak_authentication_subflow.mfa_forms["admin"].priority &&
      keycloak_authentication_execution.mfa_password["admin"].priority < keycloak_authentication_subflow.mfa_verify["admin"].priority &&
      keycloak_authentication_subflow.mfa_verify["admin"].priority < keycloak_authentication_subflow.mfa_enroll["admin"].priority &&
      keycloak_authentication_execution.mfa_verify_condition["admin"].priority < keycloak_authentication_subflow.mfa_factor["admin"].priority &&
      keycloak_authentication_execution.mfa_webauthn["admin"].priority < keycloak_authentication_execution.mfa_otp["admin"].priority &&
      keycloak_authentication_execution.mfa_enroll_condition["admin"].priority < keycloak_authentication_execution.mfa_enroll["admin"].priority
    )
    error_message = "Every entry of the flow needs an explicit priority that keeps the order password, verify, enroll."
  }
}

run "invalid_enroll_method_is_rejected" {
  command = plan

  variables {
    realms = {
      iseja = {
        display_name  = "Iseja"
        users_dn      = "cn=users,dc=example,dc=com"
        user_filter   = "(memberOf=cn=idm-users,cn=groups,dc=example,dc=com)"
        groups_dn     = "cn=groups,dc=example,dc=com"
        second_factor = { enroll = "sms" }
      }
    }
  }

  expect_failures = [var.realms]
}

run "invalid_user_verification_is_rejected" {
  command = plan

  variables {
    web_authn = { user_verification_requirement = "always" }
  }

  expect_failures = [var.web_authn]
}
