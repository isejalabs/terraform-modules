<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_onepassword"></a> [onepassword](#requirement\_onepassword) | ~> 3.3 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.6 |
| <a name="requirement_rustfs"></a> [rustfs](#requirement\_rustfs) | ~> 0.0.8 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_random"></a> [random](#provider\_random) | 3.9.1 |
| <a name="provider_rustfs"></a> [rustfs](#provider\_rustfs) | 0.0.8 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_secret"></a> [secret](#module\_secret) | ../onepassword-item | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [random_password.user_secret](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [rustfs_policy.this](https://registry.terraform.io/providers/weinmann-emt/rustfs/latest/docs/resources/policy) | resource |
| [rustfs_user.this](https://registry.terraform.io/providers/weinmann-emt/rustfs/latest/docs/resources/user) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_bucket_names"></a> [bucket\_names](#input\_bucket\_names) | Names of the existing buckets the user may read quota information for. These are only referenced by name in the policy; the module neither creates nor manages them, so buckets created outside Terraform can be listed too. | `set(string)` | n/a | yes |
| <a name="input_item_title"></a> [item\_title](#input\_item\_title) | Title of the 1Password item holding the credentials. Defaults to `name`. Set it to follow a different item naming convention than the RustFS-side names, for example `<thing>#<env>` for the `K8S` vault. Changing it on an existing deployment replaces the item. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Canonical name for this user/policy pair. Used verbatim for the user's access key (and, unless `item_title` is set, the 1Password item title), and as the base name (with a `-ro` suffix) for the policy -- one input so they never drift apart. Required (no default) so the identity is always named after its consumer and environment; treat it as stable once applied, as changing it replaces the user, policy and item. | `string` | n/a | yes |
| <a name="input_onepassword"></a> [onepassword](#input\_onepassword) | 1Password service account token used to write the generated credentials. | <pre>object({<br/>    service_account_token = string<br/>  })</pre> | n/a | yes |
| <a name="input_onepassword_vault_id"></a> [onepassword\_vault\_id](#input\_onepassword\_vault\_id) | UUID of the 1Password vault the credentials item is created in. | `string` | n/a | yes |
| <a name="input_rustfs"></a> [rustfs](#input\_rustfs) | RustFS admin endpoint and credentials used to provision the policy and user. | <pre>object({<br/>    endpoint      = string<br/>    access_key    = string<br/>    access_secret = string<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_item_uuid"></a> [item\_uuid](#output\_item\_uuid) | UUID of the 1Password item holding the credentials. |
| <a name="output_policy_name"></a> [policy\_name](#output\_policy\_name) | Name of the read-only quota policy attached to the user. |
<!-- END_TF_DOCS -->
