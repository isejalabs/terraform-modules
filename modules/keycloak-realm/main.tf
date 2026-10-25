data "onepassword_item" "admin" {
  vault = var.onepassword_vault_id
  title = var.admin_item_title
}

data "onepassword_item" "ldap_bind" {
  vault = var.onepassword_vault_id
  title = var.ldap.bind_item_title
}

locals {
  # A Login item exposes `username`/`password` directly; an item made of plain fields keeps them in sections.
  admin_fields = merge([for s in data.onepassword_item.admin.section : { for f in s.field : f.label => f.value }]...)

  admin_username = coalesce(data.onepassword_item.admin.username, try(local.admin_fields["username"], null))
  admin_password = coalesce(data.onepassword_item.admin.password, try(local.admin_fields["password"], null))

  # Keycloak takes several URLs, separated by a space, and tries them in order.
  ldap_connection_url = join(" ", var.ldap.connection_urls)
}

resource "keycloak_realm" "this" {
  for_each = var.realms

  realm        = each.key
  display_name = each.value.display_name
  enabled      = true

  ssl_required = var.realm_settings.ssl_required

  login_with_email_allowed = var.realm_settings.login_with_email_allowed
  duplicate_emails_allowed = var.realm_settings.duplicate_emails_allowed
  registration_allowed     = var.realm_settings.registration_allowed
  reset_password_allowed   = var.realm_settings.reset_password_allowed
  edit_username_allowed    = var.realm_settings.edit_username_allowed
  verify_email             = var.realm_settings.verify_email

  password_policy = each.value.password_policy

  security_defenses {
    headers {
      x_frame_options                     = var.security_headers.x_frame_options
      content_security_policy             = var.security_headers.content_security_policy
      content_security_policy_report_only = var.security_headers.content_security_policy_report_only
      x_content_type_options              = var.security_headers.x_content_type_options
      x_robots_tag                        = var.security_headers.x_robots_tag
      x_xss_protection                    = var.security_headers.x_xss_protection
      strict_transport_security           = var.security_headers.strict_transport_security
    }
    brute_force_detection {
      permanent_lockout                = var.brute_force.permanent_lockout
      max_login_failures               = each.value.max_login_failures
      wait_increment_seconds           = var.brute_force.wait_increment_seconds
      quick_login_check_milli_seconds  = var.brute_force.quick_login_check_milli_seconds
      minimum_quick_login_wait_seconds = var.brute_force.minimum_quick_login_wait_seconds
      max_failure_wait_seconds         = var.brute_force.max_failure_wait_seconds
      failure_reset_time_seconds       = var.brute_force.failure_reset_time_seconds
    }
  }

  # Any WebAuthn authenticator (passkey, YubiKey, platform) as a second factor; the flows that require it are set up
  # separately (isejalabs/homelab#1827).
  web_authn_policy {
    relying_party_entity_name     = each.value.display_name
    signature_algorithms          = var.web_authn.signature_algorithms
    user_verification_requirement = var.web_authn.user_verification_requirement
  }
}

resource "keycloak_ldap_user_federation" "ucs" {
  for_each = var.realms

  name     = var.ldap.name
  realm_id = keycloak_realm.this[each.key].id
  enabled  = true

  username_ldap_attribute = var.ldap.username_attribute
  rdn_ldap_attribute      = var.ldap.rdn_attribute
  uuid_ldap_attribute     = var.ldap.uuid_attribute
  user_object_classes     = var.ldap.user_object_classes

  connection_url  = local.ldap_connection_url
  users_dn        = each.value.users_dn
  bind_dn         = var.ldap.bind_dn
  bind_credential = data.onepassword_item.ldap_bind.password

  custom_user_search_filter = each.value.user_filter
  search_scope              = var.ldap.search_scope

  # UCS stays authoritative (ADR 0016 point 3), so these are not variables: users are imported so Keycloak keeps
  # profiles, groups and MFA credentials during a UCS outage, but nothing is ever written back, and no account is
  # created in Keycloak.
  import_enabled     = true
  edit_mode          = "READ_ONLY"
  sync_registrations = false
  trust_email        = var.ldap.trust_email

  full_sync_period    = var.ldap.full_sync_period
  changed_sync_period = var.ldap.changed_sync_period

  connection_timeout = var.ldap.connection_timeout
  read_timeout       = var.ldap.read_timeout

  # Passwords are checked by binding as the user, never by reading a hash, so Keycloak has no password to validate
  # against its own policy.
  validate_password_policy = false
  use_truststore_spi       = var.ldap.use_truststore_spi
}

resource "keycloak_ldap_group_mapper" "ucs" {
  for_each = var.realms

  name                    = var.ldap.group_mapper_name
  realm_id                = keycloak_realm.this[each.key].id
  ldap_user_federation_id = keycloak_ldap_user_federation.ucs[each.key].id

  ldap_groups_dn             = each.value.groups_dn
  group_name_ldap_attribute  = var.ldap.group_name_attribute
  group_object_classes       = var.ldap.group_object_classes
  preserve_group_inheritance = var.ldap.group_preserve_inheritance
  ignore_missing_groups      = var.ldap.group_ignore_missing
  groups_ldap_filter         = each.value.groups_filter

  membership_ldap_attribute      = var.ldap.group_member_attr
  membership_attribute_type      = var.ldap.group_membership_type
  membership_user_ldap_attribute = var.ldap.group_membership_user_attr

  # Read-only like the federation: groups are imported, never written back.
  mode                                 = "READ_ONLY"
  user_roles_retrieve_strategy         = var.ldap.group_user_roles_strategy
  memberof_ldap_attribute              = var.ldap.group_memberof_attribute
  drop_non_existing_groups_during_sync = var.ldap.group_drop_non_existing_synced
}

# Client scope that puts the group names into a claim. Clients add it as they are registered.
resource "keycloak_openid_client_scope" "groups" {
  for_each = var.realms

  realm_id               = keycloak_realm.this[each.key].id
  name                   = var.groups_claim.scope_name
  description            = "Group names of the user, from the directory groups."
  include_in_token_scope = true
}

resource "keycloak_openid_group_membership_protocol_mapper" "groups" {
  for_each = var.realms

  realm_id        = keycloak_realm.this[each.key].id
  client_scope_id = keycloak_openid_client_scope.groups[each.key].id
  name            = var.groups_claim.claim_name
  claim_name      = var.groups_claim.claim_name
  full_path       = var.groups_claim.full_path

  add_to_id_token     = true
  add_to_access_token = true
  add_to_userinfo     = true
}
