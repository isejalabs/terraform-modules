terraform {
  required_providers {
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3.3"
    }
  }
}

provider "onepassword" {
  service_account_token = var.onepassword.service_account_token
}
