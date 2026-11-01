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

# Like the rustfs and checkmk modules, this one is used directly as a Terragrunt root, so it owns provider
# configuration (credentials come in through 1Password and sensitive variables) rather than leaving it to a caller.
# https://developer.hashicorp.com/terraform/language/modules/develop/providers

provider "onepassword" {
  service_account_token = var.onepassword.service_account_token
}

# Logs in with the client-credentials grant of the service-account client (client_item_title, created by the
# keycloak-automation module), or, when only admin_item_title is set, with the password grant of the `admin-cli` client
# in the `master` realm as that admin (the bootstrap admin the Keycloak Operator created). Arguments of the other grant
# stay null.
provider "keycloak" {
  client_id     = local.client_id
  client_secret = local.client_secret
  url           = var.keycloak_url
  username      = local.admin_username
  password      = local.admin_password
}
