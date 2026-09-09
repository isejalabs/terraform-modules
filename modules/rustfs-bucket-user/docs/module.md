<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.6 |
| <a name="requirement_rustfs"></a> [rustfs](#requirement\_rustfs) | ~> 0.0.8 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_random"></a> [random](#provider\_random) | 3.9.0 |
| <a name="provider_rustfs"></a> [rustfs](#provider\_rustfs) | 0.0.8 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [random_password.user_secret](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [rustfs_bucket.this](https://registry.terraform.io/providers/weinmann-emt/rustfs/latest/docs/resources/bucket) | resource |
| [rustfs_policy.this](https://registry.terraform.io/providers/weinmann-emt/rustfs/latest/docs/resources/policy) | resource |
| [rustfs_quota.this](https://registry.terraform.io/providers/weinmann-emt/rustfs/latest/docs/resources/quota) | resource |
| [rustfs_user.this](https://registry.terraform.io/providers/weinmann-emt/rustfs/latest/docs/resources/user) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_name"></a> [name](#input\_name) | Canonical name for this bucket/user/policy triple. Used verbatim for the bucket name and the dedicated user's access key, and as the base name (with a `-rw` suffix) for its policy -- one input so all three never drift apart. | `string` | n/a | yes |
| <a name="input_policy_actions"></a> [policy\_actions](#input\_policy\_actions) | S3 actions the dedicated bucket user is allowed to perform, scoped to its own bucket only. | `list(string)` | <pre>[<br/>  "s3:GetObject",<br/>  "s3:PutObject",<br/>  "s3:DeleteObject",<br/>  "s3:ListBucket"<br/>]</pre> | no |
| <a name="input_quota"></a> [quota](#input\_quota) | Bucket storage quota, in bytes. | `number` | `10737418240` | no |
| <a name="input_rustfs"></a> [rustfs](#input\_rustfs) | RustFS admin endpoint and credentials used to provision the bucket/policy/user. | <pre>object({<br/>    endpoint      = string<br/>    access_key    = string<br/>    access_secret = string<br/>  })</pre> | n/a | yes |
| <a name="input_versioning_enabled"></a> [versioning\_enabled](#input\_versioning\_enabled) | Whether to enable bucket versioning. | `bool` | `false` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_access_key"></a> [access\_key](#output\_access\_key) | n/a |
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | n/a |
| <a name="output_policy_name"></a> [policy\_name](#output\_policy\_name) | n/a |
| <a name="output_secret_key"></a> [secret\_key](#output\_secret\_key) | n/a |
<!-- END_TF_DOCS -->
