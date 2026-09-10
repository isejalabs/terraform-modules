<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_onepassword"></a> [onepassword](#requirement\_onepassword) | ~> 3.3 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_onepassword"></a> [onepassword](#provider\_onepassword) | 3.3.1 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [onepassword_item.this](https://registry.terraform.io/providers/1Password/onepassword/latest/docs/resources/item) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_category"></a> [category](#input\_category) | Category of the 1Password item. | `string` | `"password"` | no |
| <a name="input_note"></a> [note](#input\_note) | Plain-text note for the item. | `string` | `null` | no |
| <a name="input_onepassword"></a> [onepassword](#input\_onepassword) | 1Password service account token used to manage the item. | <pre>object({<br/>    service_account_token = string<br/>  })</pre> | n/a | yes |
| <a name="input_sections"></a> [sections](#input\_sections) | Sections and fields to write into the item. | <pre>list(object({<br/>    label = string<br/>    fields = list(object({<br/>      label = string<br/>      value = string<br/>      type  = optional(string, "STRING")<br/>    }))<br/>  }))</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags assigned to the item. | `list(string)` | <pre>[<br/>  "iac-managed"<br/>]</pre> | no |
| <a name="input_title"></a> [title](#input\_title) | Title of the 1Password item. | `string` | n/a | yes |
| <a name="input_vault_id"></a> [vault\_id](#input\_vault\_id) | UUID of the 1Password vault the item is created in. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_item_uuid"></a> [item\_uuid](#output\_item\_uuid) | n/a |
<!-- END_TF_DOCS -->
