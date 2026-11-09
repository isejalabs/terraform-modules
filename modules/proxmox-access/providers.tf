terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.120"
    }
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3.3"
    }
  }
}

# Like keycloak-realm, this module is used directly as a Terragrunt root, so it owns provider configuration rather than
# leaving it to a caller. Only the REST API is used (no SSH): realms, groups, roles and ACLs are cluster-wide
# configuration (`/etc/pve/domains.cfg`, `user.cfg`), so one apply configures every node of the cluster.
# https://developer.hashicorp.com/terraform/language/modules/develop/providers

provider "proxmox" {
  endpoint  = var.proxmox.endpoint
  insecure  = var.proxmox.insecure
  api_token = var.proxmox.api_token
}

provider "onepassword" {
  service_account_token = var.onepassword.service_account_token
}
