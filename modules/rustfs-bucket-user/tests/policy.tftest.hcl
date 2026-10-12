# Offline test (no RustFS needed): the read/write policy covers exactly the user's own bucket and its objects, and keeps
# its name. Run: tofu test (from this directory)

mock_provider "rustfs" {}
mock_provider "random" {}

variables {
  name = "dev-kopiur-backup"
}

run "policy_is_scoped_to_own_bucket_and_objects" {
  command = plan

  assert {
    condition     = module.user.granted_resources == toset(["arn:aws:s3:::dev-kopiur-backup", "arn:aws:s3:::dev-kopiur-backup/*"])
    error_message = "The policy must cover only the user's own bucket and its objects."
  }

  assert {
    condition     = module.user.granted_actions == toset(["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"])
    error_message = "The default actions must stay read/write."
  }

  assert {
    condition     = output.policy_name == "dev-kopiur-backup-rw" && output.bucket_name == "dev-kopiur-backup"
    error_message = "Policy and bucket names must stay as before."
  }
}
