<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_checkmk"></a> [checkmk](#requirement\_checkmk) | 0.0.5 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_checkmk"></a> [checkmk](#provider\_checkmk) | 0.0.5 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| checkmk_activation.this | resource |
| checkmk_host.this | resource |
| checkmk_rule.special_agent | resource |
| [terraform_data.activation_trigger](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_checkmk"></a> [checkmk](#input\_checkmk) | Checkmk site URL (including the site name, no trailing slash, for example `https://monitoring.example.com/prod`) and the automation user the provider authenticates as. See the README for the least-privilege role the user needs. | <pre>object({<br/>    url      = string<br/>    username = string<br/>    secret   = string<br/>  })</pre> | n/a | yes |
| <a name="input_endpoint"></a> [endpoint](#input\_endpoint) | Base URL of the RustFS admin/S3 endpoint the special agent queries, for example `https://fiona.home.iseja.net:9002` (no trailing slash). Required when `rules_enabled` is true. | `string` | `""` | no |
| <a name="input_folder"></a> [folder](#input\_folder) | Path of the existing Checkmk folder the host is created in, for example `/container/pve4`. The folder is not created or managed by this module. | `string` | `"/"` | no |
| <a name="input_host_alias"></a> [host\_alias](#input\_host\_alias) | Alias of the host. | `string` | `"RustFS bucket quotas (API only)"` | no |
| <a name="input_host_name"></a> [host\_name](#input\_host\_name) | Name of the API-only host that carries the RustFS quota services, for example `rustfs.fiona.home.iseja.net`. It is a dedicated host: a special-agent rule on a host with the normal Checkmk agent would replace the agent connection and silence that host's own checks. | `string` | n/a | yes |
| <a name="input_identities"></a> [identities](#input\_identities) | RustFS monitoring identities to create a special-agent rule for, keyed by a short name (the environment), each with the RustFS access key, the identifier of the Checkmk Password Store entry holding its secret key (see the `checkmk-password` module), and the buckets to query. Quotes and backslashes are not allowed in the values: they are written into a Python literal. | <pre>map(object({<br/>    access_key  = string<br/>    password_id = string<br/>    buckets     = list(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_rules_enabled"></a> [rules\_enabled](#input\_rules\_enabled) | Whether to create the special-agent rules. Keep it `false` until the plugin that defines the ruleset `special_agents:rustfs_quota` is installed on the site: Checkmk rejects a rule for a ruleset it does not know. The host and the activation are created either way. | `bool` | `false` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_host_name"></a> [host\_name](#output\_host\_name) | Name of the API-only host carrying the RustFS quota services. |
| <a name="output_rule_descriptions"></a> [rule\_descriptions](#output\_rule\_descriptions) | Descriptions of the special-agent rules created (empty while rules\_enabled is false). |
<!-- END_TF_DOCS -->
