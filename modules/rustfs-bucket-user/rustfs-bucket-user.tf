resource "rustfs_bucket" "this" {
  name = var.name
}

resource "rustfs_quota" "this" {
  bucket = rustfs_bucket.this.name
  quota  = var.quota
}

# TODO: rustfs_bucket_versioning exists on the weinmann-emt/rustfs provider's main branch but isn't in any
# published release yet (latest is v0.0.8) -- wire this up once a release ships it.
# resource "rustfs_bucket_versioning" "this" {
#   count  = var.versioning_enabled ? 1 : 0
#   bucket = rustfs_bucket.this.name
#   status = "Enabled"
# }

# Scopes the dedicated user down to only this bucket, rather than reusing the admin credentials.
resource "rustfs_policy" "this" {
  name = "${var.name}-rw"

  statement = [
    {
      effect = "Allow"
      action = var.policy_actions
      ressource = [
        "arn:aws:s3:::${rustfs_bucket.this.name}",
        "arn:aws:s3:::${rustfs_bucket.this.name}/*",
      ]
    },
  ]
}

resource "random_password" "user_secret" {
  length  = 40
  special = false
}

resource "rustfs_user" "this" {
  access_key = var.name
  secret_key = random_password.user_secret.result
  policy     = rustfs_policy.this.name
}
