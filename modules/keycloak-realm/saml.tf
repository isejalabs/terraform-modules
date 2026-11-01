# SAML clients for applications that only speak SAML (Checkmk Ultimate sites, isejalabs/homelab#1727). Keycloak is
# the identity provider; every client is attached to one realm, so a site that accepts both everyday and admin
# accounts gets two clients, one per realm.

locals {
  # Mappers that every client gets, or only some: the e-mail address is mapped on request.
  saml_user_property_mappers = merge([
    for key, c in var.saml_clients : merge(
      {
        "${key}/user-id" = { client = key, name = "user-id", property = "username", attribute = var.saml_claims.user_id }
        "${key}/alias"   = { client = key, name = "alias", property = var.saml_claims.alias_property, attribute = var.saml_claims.alias }
      },
      c.include_email ? {
        "${key}/email" = { client = key, name = "email", property = "email", attribute = var.saml_claims.email }
      } : {},
    )
  ]...)
}

resource "keycloak_saml_client" "this" {
  for_each = var.saml_clients

  realm_id  = keycloak_realm.this[each.value.realm].id
  client_id = each.value.client_id
  name      = coalesce(each.value.name, each.key)
  enabled   = true

  # The assertion with the attributes is what an SP verifies; the document is signed as well. Checkmk accepts RSA or
  # ECDSA with SHA-256/384/512 only and rejects the rest.
  sign_documents          = true
  sign_assertions         = true
  signature_algorithm     = var.saml_signature_algorithm
  signature_key_name      = "KEY_ID"
  include_authn_statement = true

  name_id_format       = "username"
  force_name_id_format = true
  force_post_binding   = true

  # Checkmk signs its authentication requests with its own certificate. Keycloak can only verify them once that
  # certificate is known, so a request is not required to be signed until `signing_certificate` is given.
  client_signature_required = each.value.signing_certificate != null
  signing_certificate       = each.value.signing_certificate

  valid_redirect_uris         = [each.value.acs_url]
  master_saml_processing_url  = each.value.acs_url
  assertion_consumer_post_url = each.value.acs_url

  # Checkmk has no single-logout endpoint, so a front-channel logout would only redirect into a dead end.
  front_channel_logout = false

  # The assertion carries the attributes below, not the realm role mappings.
  full_scope_allowed = false
}

resource "keycloak_saml_user_property_protocol_mapper" "this" {
  for_each = local.saml_user_property_mappers

  realm_id  = keycloak_saml_client.this[each.value.client].realm_id
  client_id = keycloak_saml_client.this[each.value.client].id
  name      = each.value.name

  user_property              = each.value.property
  saml_attribute_name        = each.value.attribute
  saml_attribute_name_format = "URI Reference"
}

# The names of the directory groups of the user (imported by the LDAP group mapper) as a multi-valued attribute. The
# application maps them to its own roles. No dedicated provider resource exists for the SAML group list mapper.
resource "keycloak_generic_protocol_mapper" "saml_groups" {
  for_each = var.saml_clients

  realm_id        = keycloak_saml_client.this[each.key].realm_id
  client_id       = keycloak_saml_client.this[each.key].id
  name            = "groups"
  protocol        = "saml"
  protocol_mapper = "saml-group-membership-mapper"

  config = {
    "attribute.name"       = var.saml_claims.groups
    "attribute.nameformat" = "URI Reference"
    "full.path"            = tostring(var.saml_claims.groups_full_path)
    "single"               = "false"
  }
}
