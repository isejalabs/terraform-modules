terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    rustfs = {
      source  = "weinmann-emt/rustfs"
      version = "~> 0.0.8"
    }
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3.3"
    }
  }
}

# rustfs-bucket-user and onepassword-item are pure (provider-config-free) child modules -- Terraform
# requires the actual root to own provider configuration for it to work reliably when composed like this
# (https://developer.hashicorp.com/terraform/language/modules/develop/providers), so both providers are
# configured here instead of inside those modules.

provider "rustfs" {
  endpoint      = var.rustfs.endpoint
  access_key    = var.rustfs.access_key
  access_secret = var.rustfs.access_secret
  ssl           = true
}

provider "onepassword" {
  service_account_token = var.onepassword.service_account_token
}
