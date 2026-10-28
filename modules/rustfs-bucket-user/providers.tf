terraform {
  required_providers {
    rustfs = {
      source  = "weinmann-emt/rustfs"
      version = "~> 0.1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
