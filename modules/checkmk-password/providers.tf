terraform {
  required_providers {
    # Community provider, not listed in the OpenTofu registry (only in the Terraform registry), hence the full
    # address. Pinned exactly: it is a young single-maintainer project, so an upgrade should be deliberate.
    checkmk = {
      source  = "registry.terraform.io/blackmesaltd/checkmk"
      version = "0.0.5"
    }
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3.3"
    }
  }
}

# Like the rustfs modules, this one is used directly as a Terragrunt root, so it owns provider configuration
# (credentials come in as sensitive variables) rather than leaving it to a caller.
# https://developer.hashicorp.com/terraform/language/modules/develop/providers

provider "checkmk" {
  url      = var.checkmk.url
  username = var.checkmk.username
  password = var.checkmk.secret
  # A Password Store entry needs no activation; never activate implicitly, as activation applies every pending
  # change on the site, not only the ones made here.
  activate = "manual"
}

provider "onepassword" {
  service_account_token = var.onepassword.service_account_token
}
