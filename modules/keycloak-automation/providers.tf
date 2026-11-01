terraform {
  required_providers {
    keycloak = {
      source  = "keycloak/keycloak"
      version = "~> 5.10"
    }
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3.3"
    }
  }
}

# Like keycloak-realm, this module is used directly as a Terragrunt root, so it owns provider configuration
# (credentials come in through 1Password and sensitive variables) rather than leaving it to a caller. onepassword-item
# is a pure child module, so its provider is configured here too.
# https://developer.hashicorp.com/terraform/language/modules/develop/providers

provider "onepassword" {
  service_account_token = var.onepassword.service_account_token
}

# Logs in with the password grant of the `admin-cli` client in the `master` realm, as the bootstrap (break-glass)
# administrator. This is the one place that credential is used: the module creates the client that keycloak-realm
# uses afterwards instead.
provider "keycloak" {
  client_id = "admin-cli"
  url       = var.keycloak_url
  username  = local.admin_username
  password  = local.admin_password
}
