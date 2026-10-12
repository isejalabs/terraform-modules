output "bucket_name" {
  value = rustfs_bucket.this.name
}

output "policy_name" {
  value = module.user.policy_name
}

output "access_key" {
  value = module.user.access_key
}

output "secret_key" {
  value     = module.user.secret_key
  sensitive = true
}
