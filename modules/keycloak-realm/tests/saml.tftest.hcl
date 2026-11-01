# Offline test of the SAML clients (see realm.tftest.hcl for the setup): one client per entry with signed assertions
# and the ACS URL as the only redirect URI, the mappers every client needs, the e-mail mapper only on request, a
# client signature required only when the SP's certificate is given, and invalid input is rejected.
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

  saml_clients = {
    "mon-iseja" = {
      realm     = "iseja"
      client_id = "https://mon.example.com/site/check_mk/saml_metadata.py"
      acs_url   = "https://mon.example.com/site/check_mk/saml_acs.py?acs"
    }
    "mon-admin" = {
      realm         = "admin"
      client_id     = "https://mon.example.com/site/check_mk/saml_metadata.py"
      acs_url       = "https://mon.example.com/site/check_mk/saml_acs.py?acs"
      name          = "Monitoring (admin)"
      include_email = true
    }
  }
}

run "one_client_per_entry_in_its_realm" {
  command = plan

  assert {
    condition     = length(keycloak_saml_client.this) == 2 && keycloak_saml_client.this["mon-admin"].name == "Monitoring (admin)" && keycloak_saml_client.this["mon-iseja"].name == "mon-iseja"
    error_message = "Every entry must get a client; the name falls back to the key."
  }

  assert {
    condition     = keycloak_saml_client.this["mon-iseja"].client_id == keycloak_saml_client.this["mon-admin"].client_id
    error_message = "The same entity ID can be registered once per realm."
  }
}

run "assertions_are_signed_and_the_acs_url_is_the_only_redirect" {
  command = plan

  assert {
    condition     = keycloak_saml_client.this["mon-iseja"].sign_assertions && keycloak_saml_client.this["mon-iseja"].sign_documents && keycloak_saml_client.this["mon-iseja"].signature_algorithm == "RSA_SHA256"
    error_message = "Assertion and document must be signed with RSA-SHA256, which Checkmk accepts."
  }

  assert {
    condition     = keycloak_saml_client.this["mon-iseja"].valid_redirect_uris == toset(["https://mon.example.com/site/check_mk/saml_acs.py?acs"]) && keycloak_saml_client.this["mon-iseja"].assertion_consumer_post_url == "https://mon.example.com/site/check_mk/saml_acs.py?acs"
    error_message = "The ACS URL must be the only redirect URI and the POST binding endpoint."
  }

  assert {
    condition     = keycloak_saml_client.this["mon-iseja"].name_id_format == "username" && keycloak_saml_client.this["mon-iseja"].force_name_id_format
    error_message = "The name ID must be the username."
  }

  assert {
    condition     = !keycloak_saml_client.this["mon-iseja"].client_signature_required
    error_message = "Without the SP's certificate a signed request can not be required."
  }
}

run "signed_requests_are_required_once_the_certificate_is_known" {
  command = plan

  variables {
    saml_clients = {
      "mon-iseja" = {
        realm               = "iseja"
        client_id           = "https://mon.example.com/site/check_mk/saml_metadata.py"
        acs_url             = "https://mon.example.com/site/check_mk/saml_acs.py?acs"
        signing_certificate = "MIIBexample"
      }
    }
  }

  assert {
    condition     = keycloak_saml_client.this["mon-iseja"].client_signature_required && keycloak_saml_client.this["mon-iseja"].signing_certificate == "MIIBexample"
    error_message = "With the certificate, Keycloak must require signed requests."
  }
}

run "mappers_user_id_alias_groups_and_email_on_request" {
  command = plan

  assert {
    condition     = keycloak_saml_user_property_protocol_mapper.this["mon-iseja/user-id"].user_property == "username" && keycloak_saml_user_property_protocol_mapper.this["mon-iseja/user-id"].saml_attribute_name == "https://iseja.net/claims/userid"
    error_message = "The user ID attribute must be the username under a URL-style name, as Checkmk requires."
  }

  assert {
    condition     = keycloak_saml_user_property_protocol_mapper.this["mon-iseja/alias"].user_property == "username"
    error_message = "The alias defaults to the username."
  }

  assert {
    condition     = length(keycloak_saml_user_property_protocol_mapper.this) == 5 && contains(keys(keycloak_saml_user_property_protocol_mapper.this), "mon-admin/email") && !contains(keys(keycloak_saml_user_property_protocol_mapper.this), "mon-iseja/email")
    error_message = "Only the client with include_email gets the e-mail mapper (2 + 3 mappers)."
  }

  assert {
    condition     = keycloak_generic_protocol_mapper.saml_groups["mon-iseja"].protocol_mapper == "saml-group-membership-mapper" && keycloak_generic_protocol_mapper.saml_groups["mon-iseja"].config["single"] == "false" && keycloak_generic_protocol_mapper.saml_groups["mon-iseja"].config["full.path"] == "false"
    error_message = "Groups must be sent as a multi-valued attribute of plain names."
  }
}

run "claims_can_be_renamed" {
  command = plan

  variables {
    saml_claims = { groups = "https://example.com/groups", alias_property = "firstName" }
  }

  assert {
    condition     = keycloak_generic_protocol_mapper.saml_groups["mon-iseja"].config["attribute.name"] == "https://example.com/groups" && keycloak_saml_user_property_protocol_mapper.this["mon-iseja/alias"].user_property == "firstName"
    error_message = "saml_claims must rename the groups attribute and change the alias property."
  }
}

run "metadata_urls_only_for_realms_with_a_client" {
  command = plan

  variables {
    saml_clients = {
      "mon-admin" = {
        realm     = "admin"
        client_id = "https://mon.example.com/site/check_mk/saml_metadata.py"
        acs_url   = "https://mon.example.com/site/check_mk/saml_acs.py?acs"
      }
    }
  }

  assert {
    condition     = output.saml_idp_metadata_urls == { admin = "https://auth.example.com/realms/admin/protocol/saml/descriptor" }
    error_message = "Only the realms with a SAML client get a metadata URL."
  }
}

run "no_clients_by_default" {
  command = plan

  variables {
    saml_clients = {}
  }

  assert {
    condition     = length(keycloak_saml_client.this) == 0 && length(keycloak_generic_protocol_mapper.saml_groups) == 0
    error_message = "Without saml_clients nothing SAML-related is planned, so existing consumers are unaffected."
  }
}

run "unknown_realm_is_rejected" {
  command = plan

  variables {
    saml_clients = {
      "mon" = {
        realm     = "nonexistent"
        client_id = "https://mon.example.com/site/check_mk/saml_metadata.py"
        acs_url   = "https://mon.example.com/site/check_mk/saml_acs.py?acs"
      }
    }
  }

  expect_failures = [var.saml_clients]
}

run "plain_http_acs_url_is_rejected" {
  command = plan

  variables {
    saml_clients = {
      "mon" = {
        realm     = "iseja"
        client_id = "https://mon.example.com/site/check_mk/saml_metadata.py"
        acs_url   = "http://mon.example.com/site/check_mk/saml_acs.py?acs"
      }
    }
  }

  expect_failures = [var.saml_clients]
}

run "duplicate_client_id_in_one_realm_is_rejected" {
  command = plan

  variables {
    saml_clients = {
      "a" = {
        realm     = "iseja"
        client_id = "https://mon.example.com/site/check_mk/saml_metadata.py"
        acs_url   = "https://mon.example.com/site/check_mk/saml_acs.py?acs"
      }
      "b" = {
        realm     = "iseja"
        client_id = "https://mon.example.com/site/check_mk/saml_metadata.py"
        acs_url   = "https://mon.example.com/site/check_mk/saml_acs.py?acs"
      }
    }
  }

  expect_failures = [var.saml_clients]
}
