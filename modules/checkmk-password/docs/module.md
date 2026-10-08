<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_checkmk"></a> [checkmk](#requirement\_checkmk) | 0.0.5 |
| <a name="requirement_onepassword"></a> [onepassword](#requirement\_onepassword) | ~> 3.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_checkmk"></a> [checkmk](#provider\_checkmk) | 0.0.5 |
| <a name="provider_onepassword"></a> [onepassword](#provider\_onepassword) | ~> 3.3 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| checkmk_password.this | resource |
| [onepassword_item.source](https://registry.terraform.io/providers/1Password/onepassword/latest/docs/data-sources/item) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_checkmk"></a> [checkmk](#input\_checkmk) | Checkmk site URL (including the site name, no trailing slash, for example `https://monitoring.example.com/prod`) and the automation user the provider authenticates as. The user needs only the Password Store, folder, host, ruleset and activation permissions, see ADR 0015 in isejalabs/homelab. | <pre>object({<br/>    url      = string<br/>    username = string<br/>    secret   = string<br/>  })</pre> | n/a | yes |
| <a name="input_comment"></a> [comment](#input\_comment) | Comment of the Password Store entry. Defaults to a note that the entry is managed by OpenTofu. | `string` | `null` | no |
| <a name="input_field_label"></a> [field\_label](#input\_field\_label) | Label of the field in that section whose value is stored in Checkmk. | `string` | `"SECRET_KEY"` | no |
| <a name="input_item_title"></a> [item\_title](#input\_item\_title) | Title of the 1Password item holding the secret, for example `checkmk-monitoring#dev`. | `string` | n/a | yes |
| <a name="input_onepassword"></a> [onepassword](#input\_onepassword) | 1Password service account token used to read the secret. | <pre>object({<br/>    service_account_token = string<br/>  })</pre> | n/a | yes |
| <a name="input_onepassword_vault_id"></a> [onepassword\_vault\_id](#input\_onepassword\_vault\_id) | UUID of the 1Password vault holding the source item. | `string` | n/a | yes |
| <a name="input_password_id"></a> [password\_id](#input\_password\_id) | Identifier of the Password Store entry in Checkmk, referenced by rules. Cannot be changed after creation. Must not start with a digit or contain `.` or `#` (Checkmk rejects those); only letters, digits, `_` and `-` are accepted here. | `string` | n/a | yes |
| <a name="input_section_label"></a> [section\_label](#input\_section\_label) | Label of the section in the 1Password item that contains the field. | `string` | `"rustfs"` | no |
| <a name="input_title"></a> [title](#input\_title) | Human-readable title of the Password Store entry. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_password_id"></a> [password\_id](#output\_password\_id) | Identifier of the Password Store entry, for referencing it in rules. |
<!-- END_TF_DOCS -->
