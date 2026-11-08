# Offline test of the OIDC clients (see realm.tftest.hcl for the setup): one client per entry with the authorization
# code flow only, the groups scope as a default scope, PKCE for public clients, the secret of a confidential client in
# a 1Password item and nowhere else, and invalid input is rejected.
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

  oidc_secret_item_title_format = "keycloak-oidc-%s#dev"

  oidc_clients = {
    "app-admin" = {
      realm         = "admin"
      redirect_uris = ["https://app.example.com/oauth2/callback"]
    }
    "app-iseja" = {
      realm                     = "iseja"
      client_id                 = "app"
      name                      = "App (iseja)"
      redirect_uris             = ["https://app.example.com/oauth2/callback"]
      post_logout_redirect_uris = ["https://app.example.com/"]
      web_origins               = ["https://app.example.com"]
      secret_item_title         = "keycloak-oidc-app#dev"
    }
    "spa" = {
      realm         = "iseja"
      public        = true
      groups_scope  = false
      redirect_uris = ["https://spa.example.com/*"]
    }
  }
}

run "one_client_per_entry_in_its_realm" {
  command = plan

  assert {
    condition     = length(keycloak_openid_client.this) == 3 && keycloak_openid_client.this["app-admin"].client_id == "app-admin" && keycloak_openid_client.this["app-iseja"].client_id == "app"
    error_message = "Every entry must get a client; the client ID falls back to the key."
  }

  assert {
    condition     = keycloak_openid_client.this["app-admin"].name == "app-admin" && keycloak_openid_client.this["app-iseja"].name == "App (iseja)"
    error_message = "The name falls back to the key."
  }
}

run "authorization_code_flow_only" {
  command = plan

  assert {
    condition     = alltrue([for c in keycloak_openid_client.this : c.standard_flow_enabled && !c.implicit_flow_enabled && !c.direct_access_grants_enabled && !c.service_accounts_enabled && !c.full_scope_allowed])
    error_message = "Only the authorization code flow may be enabled, and the role mappings must not be sent."
  }

  assert {
    condition     = keycloak_openid_client.this["app-admin"].access_type == "CONFIDENTIAL" && keycloak_openid_client.this["spa"].access_type == "PUBLIC"
    error_message = "Clients are confidential unless public is set."
  }

  assert {
    condition     = keycloak_openid_client.this["app-iseja"].valid_redirect_uris == toset(["https://app.example.com/oauth2/callback"]) && keycloak_openid_client.this["app-iseja"].valid_post_logout_redirect_uris == toset(["https://app.example.com/"]) && keycloak_openid_client.this["app-iseja"].web_origins == toset(["https://app.example.com"])
    error_message = "Redirect URIs, post-logout redirect URIs and web origins must be passed on."
  }
}

run "pkce_is_on_for_public_clients_only_unless_set" {
  command = plan

  assert {
    condition     = keycloak_openid_client.this["spa"].pkce_code_challenge_method == "S256" && keycloak_openid_client.this["app-admin"].pkce_code_challenge_method == null
    error_message = "PKCE defaults to S256 for public clients and to off for confidential ones."
  }
}

run "an_explicit_pkce_setting_overrides_the_default" {
  command = plan

  variables {
    oidc_clients = {
      "app" = {
        realm         = "admin"
        redirect_uris = ["https://app.example.com/oauth2/callback"]
        pkce          = true
      }
      "spa" = {
        realm         = "iseja"
        public        = true
        pkce          = false
        redirect_uris = ["https://spa.example.com/*"]
      }
    }
  }

  assert {
    condition     = keycloak_openid_client.this["app"].pkce_code_challenge_method == "S256" && keycloak_openid_client.this["spa"].pkce_code_challenge_method == null
    error_message = "An explicit pkce setting must override the default."
  }
}

run "groups_scope_is_a_default_scope_unless_switched_off" {
  command = plan

  assert {
    condition     = contains(keycloak_openid_client_default_scopes.this["app-admin"].default_scopes, "groups") && contains(keycloak_openid_client_default_scopes.this["app-admin"].default_scopes, "profile") && contains(keycloak_openid_client_default_scopes.this["app-admin"].default_scopes, "basic")
    error_message = "A client must get the groups scope on top of the Keycloak default scopes."
  }

  assert {
    condition     = !contains(keycloak_openid_client_default_scopes.this["spa"].default_scopes, "groups") && contains(keycloak_openid_client_default_scopes.this["spa"].default_scopes, "email")
    error_message = "groups_scope = false must leave the groups scope out."
  }
}

run "the_secret_of_a_confidential_client_goes_to_1password" {
  command = plan

  assert {
    condition     = length(module.oidc_client_secret) == 2 && !contains(keys(module.oidc_client_secret), "spa")
    error_message = "Only confidential clients get a 1Password item."
  }

  assert {
    condition     = output.oidc_secret_item_titles == { "app-admin" = "keycloak-oidc-app-admin#dev", "app-iseja" = "keycloak-oidc-app#dev" }
    error_message = "The item title comes from the format and the key, or from secret_item_title."
  }
}

run "issuer_urls_per_realm" {
  command = plan

  assert {
    condition     = output.oidc_issuer_urls == { admin = "https://auth.example.com/realms/admin", iseja = "https://auth.example.com/realms/iseja" }
    error_message = "The issuer is the Keycloak URL plus /realms/<realm>."
  }
}

run "no_clients_by_default" {
  command = plan

  variables {
    oidc_clients = {}
  }

  assert {
    condition     = length(keycloak_openid_client.this) == 0 && length(module.oidc_client_secret) == 0 && length(keycloak_openid_client_default_scopes.this) == 0
    error_message = "Without oidc_clients nothing OIDC-related is planned, so existing consumers are unaffected."
  }
}

run "unknown_realm_is_rejected" {
  command = plan

  variables {
    oidc_clients = {
      "app" = { realm = "nonexistent", redirect_uris = ["https://app.example.com/cb"] }
    }
  }

  expect_failures = [var.oidc_clients]
}

run "plain_http_redirect_is_rejected" {
  command = plan

  variables {
    oidc_clients = {
      "app" = { realm = "admin", redirect_uris = ["http://app.example.com/cb"] }
    }
  }

  expect_failures = [var.oidc_clients]
}

run "missing_redirect_uri_is_rejected" {
  command = plan

  variables {
    oidc_clients = {
      "app" = { realm = "admin", redirect_uris = [] }
    }
  }

  expect_failures = [var.oidc_clients]
}

run "duplicate_client_id_in_a_realm_is_rejected" {
  command = plan

  variables {
    oidc_clients = {
      "one" = { realm = "admin", client_id = "app", redirect_uris = ["https://app.example.com/cb"] }
      "two" = { realm = "admin", client_id = "app", redirect_uris = ["https://app.example.com/cb"] }
    }
  }

  expect_failures = [var.oidc_clients]
}

run "same_item_title_for_two_confidential_clients_is_rejected" {
  command = plan

  variables {
    oidc_clients = {
      "one" = { realm = "admin", redirect_uris = ["https://app.example.com/cb"], secret_item_title = "shared" }
      "two" = { realm = "iseja", redirect_uris = ["https://app.example.com/cb"], secret_item_title = "shared" }
    }
  }

  expect_failures = [var.oidc_clients]
}

run "item_title_format_needs_one_placeholder" {
  command = plan

  variables {
    oidc_secret_item_title_format = "keycloak-oidc"
  }

  expect_failures = [var.oidc_secret_item_title_format]
}
