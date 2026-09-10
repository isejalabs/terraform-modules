<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.6 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.6 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bucket_user"></a> [bucket\_user](#module\_bucket\_user) | ../rustfs-bucket-user | n/a |
| <a name="module_secret"></a> [secret](#module\_secret) | ../onepassword-item | n/a |

## Resources

| Name | Type |
|------|------|
| [random_password.kopia_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_env"></a> [env](#input\_env) | Environment identifier, used to build the 1Password item title (kopiur-backup#<env>). | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Canonical name for the bucket/user/policy triple, passed through to rustfs-bucket-user. | `string` | n/a | yes |
| <a name="input_onepassword"></a> [onepassword](#input\_onepassword) | 1Password service account token used to write the generated credentials. | <pre>object({<br/>    service_account_token = string<br/>  })</pre> | n/a | yes |
| <a name="input_onepassword_vault_id"></a> [onepassword\_vault\_id](#input\_onepassword\_vault\_id) | UUID of the 1Password vault the kopiur-backup#<env> item is created in. | `string` | n/a | yes |
| <a name="input_rustfs"></a> [rustfs](#input\_rustfs) | RustFS admin endpoint and credentials used to provision the bucket/policy/user. | <pre>object({<br/>    endpoint      = string<br/>    access_key    = string<br/>    access_secret = string<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_access_key"></a> [access\_key](#output\_access\_key) | n/a |
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | n/a |
| <a name="output_onepassword_item_uuid"></a> [onepassword\_item\_uuid](#output\_onepassword\_item\_uuid) | n/a |
| <a name="output_policy_name"></a> [policy\_name](#output\_policy\_name) | n/a |
| <a name="output_secret_key"></a> [secret\_key](#output\_secret\_key) | n/a |
<!-- END_TF_DOCS -->
