output "bucket_name" {
  value = module.bucket_user.bucket_name
}

output "policy_name" {
  value = module.bucket_user.policy_name
}

output "access_key" {
  value = module.bucket_user.access_key
}

output "secret_key" {
  value     = module.bucket_user.secret_key
  sensitive = true
}

output "onepassword_item_uuid" {
  value = module.secret.item_uuid
}
