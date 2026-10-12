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

# The dedicated user, scoped down to only this bucket (and its objects), rather than reusing the admin credentials.
# The policy, the generated secret and the user are the shared core in rustfs-user.
module "user" {
  source = "../rustfs-user"

  name            = var.name
  policy_name     = "${var.name}-rw"
  actions         = var.policy_actions
  bucket_names    = [rustfs_bucket.this.name]
  include_objects = true
}

# The user resources used to live in this module directly; keep the live ones (no replacement of a credential in use).
moved {
  from = rustfs_policy.this
  to   = module.user.rustfs_policy.this
}

moved {
  from = random_password.user_secret
  to   = module.user.random_password.user_secret
}

moved {
  from = rustfs_user.this
  to   = module.user.rustfs_user.this
}
