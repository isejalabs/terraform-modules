terraform {
  required_providers {
    rustfs = {
      source  = "weinmann-emt/rustfs"
      version = "~> 0.0.8"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    # Needed here too, not only in onepassword-item: without a source declared in the calling module, Terraform
    # resolves the nested module's provider to hashicorp/onepassword, which doesn't exist.
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3.3"
    }
  }
}

# Like rustfs-kopiur-backup, this module is used directly as a Terragrunt root, so it owns provider configuration
# (credentials come in as sensitive variables) rather than leaving it to a caller.
# https://developer.hashicorp.com/terraform/language/modules/develop/providers

provider "rustfs" {
  endpoint      = var.rustfs.endpoint
  access_key    = var.rustfs.access_key
  access_secret = var.rustfs.access_secret
  ssl           = true
}

provider "onepassword" {
  service_account_token = var.onepassword.service_account_token
}
