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

# Logs in with the password grant of the `admin-cli` client in the `master` realm. The credentials are the
# bootstrap admin the Keycloak Operator created; a dedicated service account client replaces it once there is one.
provider "keycloak" {
  client_id = "admin-cli"
  url       = var.keycloak_url
  username  = local.admin_username
  password  = local.admin_password
}
