# Offline test (no RustFS/1Password needed): proves the generated policy stays least-privilege.
# Run: tofu test (from this directory)

mock_provider "rustfs" {}
mock_provider "random" {}
mock_provider "onepassword" {}

variables {
  name                 = "dev-checkmk-monitoring"
  bucket_names         = ["prod-kopiur-backup", "dev-longhorn-backup"]
  onepassword_vault_id = "vault-id"
  rustfs = {
    endpoint      = "rustfs.example.com:9000"
    access_key    = "admin"
    access_secret = "admin-secret"
  }
  onepassword = {
    service_account_token = "token"
  }
}

run "policy_is_quota_read_on_bucket_arns_only" {
  command = plan

  assert {
    condition     = length(rustfs_policy.this.statement) == 1
    error_message = "Policy must have exactly one statement."
  }

  assert {
    condition     = rustfs_policy.this.statement[0].effect == "Allow" && rustfs_policy.this.statement[0].action == toset(["s3:GetBucketQuota"])
    error_message = "Policy must only allow s3:GetBucketQuota."
  }

  assert {
    condition     = rustfs_policy.this.statement[0].ressource == toset(["arn:aws:s3:::dev-longhorn-backup", "arn:aws:s3:::prod-kopiur-backup"])
    error_message = "Policy must list exactly the given buckets with no object ARNs (/*)."
  }
}

run "empty_bucket_list_is_rejected" {
  command = plan

  variables {
    bucket_names = []
  }

  expect_failures = [var.bucket_names]
}

run "blank_bucket_name_is_rejected" {
  command = plan

  variables {
    bucket_names = ["dev-kopiur-backup", " "]
  }

  expect_failures = [var.bucket_names]
}
