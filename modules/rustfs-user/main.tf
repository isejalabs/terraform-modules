# The shared core of the RustFS users: a policy, a generated secret and a user attached to the policy. The callers
# (rustfs-bucket-user, rustfs-bucket-reader) decide which buckets, which actions and whether objects are included.
resource "rustfs_policy" "this" {
  name = var.policy_name

  statement = [
    {
      effect = "Allow"
      action = var.actions
      ressource = concat(
        [for bucket in var.bucket_names : "arn:aws:s3:::${bucket}"],
        var.include_objects ? [for bucket in var.bucket_names : "arn:aws:s3:::${bucket}/*"] : [],
      )
    },
  ]
}

resource "random_password" "user_secret" {
  length  = 40
  special = false

  # If this is ever imported (e.g. disaster recovery, re-adopting a user that already exists on RustFS), don't let a
  # mismatch between its actual original parameters and the ones above force a replacement -- that would silently
  # regenerate a real, already-in-use secret.
  lifecycle {
    ignore_changes = [length, special]
  }
}

resource "rustfs_user" "this" {
  access_key = var.name
  secret_key = random_password.user_secret.result
  policy     = rustfs_policy.this.name
}
