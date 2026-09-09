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
  }
}

provider "rustfs" {
  endpoint      = var.rustfs.endpoint
  access_key    = var.rustfs.access_key
  access_secret = var.rustfs.access_secret
  ssl           = true
}
