# Second factor for the realms that set `second_factor`: the browser flow asks for the password, then for a passkey /
# security key (WebAuthn) or a one-time code (TOTP), and sends a user who has neither through the required action that
# registers one. Realms without `second_factor` keep Keycloak's built-in `browser` flow.
#
#   browser-mfa
#   ├ Cookie                                                       ALTERNATIVE   (an existing SSO session)
#   └ browser-mfa forms                                            ALTERNATIVE
#     ├ Username Password Form                                     REQUIRED      (the directory checks the password)
#     ├ browser-mfa verify                                         CONDITIONAL
#     │ ├ Condition - user configured                              REQUIRED      (the user has a factor below)
#     │ └ browser-mfa factor                                       REQUIRED
#     │   ├ WebAuthn Authenticator                                 ALTERNATIVE   (shown first when both are set up)
#     │   └ OTP Form                                               ALTERNATIVE   (the fallback, or "try another way")
#     └ browser-mfa enroll                                         CONDITIONAL
#       ├ Condition - sub-flow executed (verify, not executed)     REQUIRED      (the user had no factor)
#       └ WebAuthn Authenticator or OTP Form (`enroll`)            REQUIRED      (its setup page is the required action)
#
# Keycloak 25+ ignores the creation order, so every entry has an explicit `priority` (10, 20, 30 within its parent): a
# flow whose entries all have priority 0 runs them in an arbitrary order (the factor before the password form).
#
# The alternatives alone would fail the login of a user without a factor (Keycloak only offers setup for a REQUIRED
# authenticator), hence the second sub-flow. Keycloak's own `browser` flow is not edited, so unsetting `second_factor`
# restores it. Kerberos is not part of this flow.

locals {
  second_factor_realms = { for name, r in var.realms : name => r.second_factor if r.second_factor != null }

  mfa_flow = {
    browser = "browser-mfa"
    forms   = "browser-mfa forms"
    verify  = "browser-mfa verify"
    factor  = "browser-mfa factor"
    enroll  = "browser-mfa enroll"
  }

  enroll_authenticator = { webauthn = "webauthn-authenticator", totp = "auth-otp-form" }
}

resource "keycloak_authentication_flow" "mfa" {
  for_each = local.second_factor_realms

  realm_id    = keycloak_realm.this[each.key].id
  alias       = local.mfa_flow.browser
  description = "Browser flow with a second factor after the password (WebAuthn or TOTP)."
}

resource "keycloak_authentication_execution" "mfa_cookie" {
  for_each = local.second_factor_realms

  realm_id          = keycloak_realm.this[each.key].id
  parent_flow_alias = keycloak_authentication_flow.mfa[each.key].alias
  authenticator     = "auth-cookie"
  requirement       = "ALTERNATIVE"
  priority          = 10
}

resource "keycloak_authentication_subflow" "mfa_forms" {
  for_each = local.second_factor_realms

  realm_id          = keycloak_realm.this[each.key].id
  parent_flow_alias = keycloak_authentication_flow.mfa[each.key].alias
  alias             = local.mfa_flow.forms
  requirement       = "ALTERNATIVE"
  priority          = 20

  depends_on = [keycloak_authentication_execution.mfa_cookie]
}

resource "keycloak_authentication_execution" "mfa_password" {
  for_each = local.second_factor_realms

  realm_id          = keycloak_realm.this[each.key].id
  parent_flow_alias = keycloak_authentication_subflow.mfa_forms[each.key].alias
  authenticator     = "auth-username-password-form"
  requirement       = "REQUIRED"
  priority          = 10
}

# The user has a factor: ask for it.
resource "keycloak_authentication_subflow" "mfa_verify" {
  for_each = local.second_factor_realms

  realm_id          = keycloak_realm.this[each.key].id
  parent_flow_alias = keycloak_authentication_subflow.mfa_forms[each.key].alias
  alias             = local.mfa_flow.verify
  requirement       = "CONDITIONAL"
  priority          = 20

  depends_on = [keycloak_authentication_execution.mfa_password]
}

resource "keycloak_authentication_execution" "mfa_verify_condition" {
  for_each = local.second_factor_realms

  realm_id          = keycloak_realm.this[each.key].id
  parent_flow_alias = keycloak_authentication_subflow.mfa_verify[each.key].alias
  authenticator     = "conditional-user-configured"
  requirement       = "REQUIRED"
  priority          = 10
}

resource "keycloak_authentication_subflow" "mfa_factor" {
  for_each = local.second_factor_realms

  realm_id          = keycloak_realm.this[each.key].id
  parent_flow_alias = keycloak_authentication_subflow.mfa_verify[each.key].alias
  alias             = local.mfa_flow.factor
  requirement       = "REQUIRED"
  priority          = 20

  depends_on = [keycloak_authentication_execution.mfa_verify_condition]
}

resource "keycloak_authentication_execution" "mfa_webauthn" {
  for_each = local.second_factor_realms

  realm_id          = keycloak_realm.this[each.key].id
  parent_flow_alias = keycloak_authentication_subflow.mfa_factor[each.key].alias
  authenticator     = "webauthn-authenticator"
  requirement       = "ALTERNATIVE"
  priority          = 10
}

resource "keycloak_authentication_execution" "mfa_otp" {
  for_each = local.second_factor_realms

  realm_id          = keycloak_realm.this[each.key].id
  parent_flow_alias = keycloak_authentication_subflow.mfa_factor[each.key].alias
  authenticator     = "auth-otp-form"
  requirement       = "ALTERNATIVE"
  priority          = 20

  depends_on = [keycloak_authentication_execution.mfa_webauthn]
}

# The user has no factor: register one through the required action of the authenticator.
resource "keycloak_authentication_subflow" "mfa_enroll" {
  for_each = local.second_factor_realms

  realm_id          = keycloak_realm.this[each.key].id
  parent_flow_alias = keycloak_authentication_subflow.mfa_forms[each.key].alias
  alias             = local.mfa_flow.enroll
  requirement       = "CONDITIONAL"
  priority          = 30

  depends_on = [keycloak_authentication_subflow.mfa_verify]
}

resource "keycloak_authentication_execution" "mfa_enroll_condition" {
  for_each = local.second_factor_realms

  realm_id          = keycloak_realm.this[each.key].id
  parent_flow_alias = keycloak_authentication_subflow.mfa_enroll[each.key].alias
  authenticator     = "conditional-sub-flow-executed"
  requirement       = "REQUIRED"
  priority          = 10
}

resource "keycloak_authentication_execution_config" "mfa_enroll_condition" {
  for_each = local.second_factor_realms

  realm_id     = keycloak_realm.this[each.key].id
  execution_id = keycloak_authentication_execution.mfa_enroll_condition[each.key].id
  alias        = "browser-mfa user has no factor"
  config = {
    flow_to_check = local.mfa_flow.verify
    check_result  = "not-executed"
  }
}

resource "keycloak_authentication_execution" "mfa_enroll" {
  for_each = local.second_factor_realms

  realm_id          = keycloak_realm.this[each.key].id
  parent_flow_alias = keycloak_authentication_subflow.mfa_enroll[each.key].alias
  authenticator     = local.enroll_authenticator[each.value.enroll]
  requirement       = "REQUIRED"
  priority          = 20

  depends_on = [keycloak_authentication_execution.mfa_enroll_condition]
}

resource "keycloak_authentication_bindings" "mfa" {
  for_each = local.second_factor_realms

  realm_id     = keycloak_realm.this[each.key].id
  browser_flow = keycloak_authentication_flow.mfa[each.key].alias

  depends_on = [
    keycloak_authentication_execution.mfa_enroll,
    keycloak_authentication_execution.mfa_otp,
  ]
}
