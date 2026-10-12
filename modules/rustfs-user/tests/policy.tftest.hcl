# Offline test (no RustFS needed): the generated policy covers exactly the given buckets, with the object ARNs only
# when asked for, and the user is attached to it. Run: tofu test (from this directory)

mock_provider "rustfs" {}
mock_provider "random" {}

variables {
  name         = "dev-checkmk-monitoring"
  policy_name  = "dev-checkmk-monitoring-ro"
  actions      = ["s3:GetBucketQuota"]
  bucket_names = ["prod-kopiur-backup", "dev-longhorn-backup"]
}

run "bucket_arns_only_by_default" {
  command = plan

  assert {
    condition     = length(rustfs_policy.this.statement) == 1 && rustfs_policy.this.statement[0].effect == "Allow"
    error_message = "Policy must have exactly one Allow statement."
  }

  assert {
    condition     = rustfs_policy.this.statement[0].action == toset(["s3:GetBucketQuota"])
    error_message = "Policy must allow exactly the given actions."
  }

  assert {
    condition     = rustfs_policy.this.statement[0].ressource == toset(["arn:aws:s3:::dev-longhorn-backup", "arn:aws:s3:::prod-kopiur-backup"])
    error_message = "Policy must list exactly the given buckets with no object ARNs (/*)."
  }

  assert {
    condition     = rustfs_policy.this.name == "dev-checkmk-monitoring-ro" && rustfs_user.this.access_key == "dev-checkmk-monitoring" && rustfs_user.this.policy == "dev-checkmk-monitoring-ro"
    error_message = "The user must carry the given access key and be attached to the policy."
  }
}

run "object_arns_when_requested" {
  command = plan

  variables {
    actions         = ["s3:GetObject", "s3:ListBucket"]
    bucket_names    = ["dev-kopiur-backup"]
    include_objects = true
  }

  assert {
    condition     = rustfs_policy.this.statement[0].ressource == toset(["arn:aws:s3:::dev-kopiur-backup", "arn:aws:s3:::dev-kopiur-backup/*"])
    error_message = "With include_objects the policy must cover the bucket and its objects."
  }
}

run "empty_bucket_list_is_rejected" {
  command = plan

  variables {
    bucket_names = []
  }

  expect_failures = [var.bucket_names]
}

run "empty_action_list_is_rejected" {
  command = plan

  variables {
    actions = []
  }

  expect_failures = [var.actions]
}
