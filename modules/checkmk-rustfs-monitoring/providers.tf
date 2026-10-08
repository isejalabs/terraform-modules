terraform {
  required_providers {
    # Community provider, not listed in the OpenTofu registry (only in the Terraform registry), hence the full
    # address. Pinned exactly: it is a young single-maintainer project, so an upgrade should be deliberate.
    checkmk = {
      source  = "registry.terraform.io/blackmesaltd/checkmk"
      version = "0.0.5"
    }
  }
}

# Like the other Terragrunt-root modules, this one owns its provider configuration (credentials come in as a
# sensitive variable). https://developer.hashicorp.com/terraform/language/modules/develop/providers

provider "checkmk" {
  url      = var.checkmk.url
  username = var.checkmk.username
  password = var.checkmk.secret
  # Never activate implicitly: activation applies every pending change on the site. Activation is an explicit
  # resource below.
  activate = "manual"
}
