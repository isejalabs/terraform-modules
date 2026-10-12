<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_checkmk"></a> [checkmk](#requirement\_checkmk) | 0.0.5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_checkmk"></a> [checkmk](#provider\_checkmk) | 0.0.5 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| checkmk_activation.this | resource |
| checkmk_host.this | resource |
| checkmk_rule.check_interval | resource |
| checkmk_rule.special_agent | resource |
| [terraform_data.activation_trigger](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_check_interval_minutes"></a> [check\_interval\_minutes](#input\_check\_interval\_minutes) | How often Checkmk fetches the data of the API-only host and checks its services, in minutes. Checkmk's default is one minute, which would mean one request per bucket every minute against the RustFS (and a warning-level RustFS event for each); the monitoring plan calls for 15 minutes. Applied to all services of the host, including the one that runs the special agent. | `number` | `15` | no |
| <a name="input_checkmk"></a> [checkmk](#input\_checkmk) | Checkmk site URL (including the site name, no trailing slash, for example `https://monitoring.example.com/prod`) and the automation user the provider authenticates as. See the README for the least-privilege role the user needs. | <pre>object({<br/>    url      = string<br/>    username = string<br/>    secret   = string<br/>  })</pre> | n/a | yes |
| <a name="input_endpoint"></a> [endpoint](#input\_endpoint) | Base URL of the RustFS admin/S3 endpoint the special agent queries, for example `https://fiona.home.iseja.net:9002` (no trailing slash). Required when `rules_enabled` is true. | `string` | `""` | no |
| <a name="input_folder"></a> [folder](#input\_folder) | Path of the existing Checkmk folder the host is created in, for example `/container/pve4`. The folder is not created or managed by this module. | `string` | `"/"` | no |
| <a name="input_host_alias"></a> [host\_alias](#input\_host\_alias) | Alias of the hosts; the identity key is appended in parentheses. | `string` | `"RustFS bucket quotas (API only)"` | no |
| <a name="input_host_name_format"></a> [host\_name\_format](#input\_host\_name\_format) | Pattern for the host name of each identity, with `%s` replaced by the identity key (the environment), for example `rustfs-%s.fiona.home.iseja.net`. Each identity gets its own dedicated API-only host: Checkmk runs only the first matching rule of the special-agent ruleset per host, so several identities on one host would leave all but one unpolled, and a special-agent rule on a host with the normal Checkmk agent would replace its agent connection and silence its own checks. | `string` | n/a | yes |
| <a name="input_identities"></a> [identities](#input\_identities) | RustFS monitoring identities to create a special-agent rule for, keyed by a short name (the environment), each with the RustFS access key, the identifier of the Checkmk Password Store entry holding its secret key (see the `checkmk-password` module), and the buckets to query. Quotes and backslashes are not allowed in the values: they are written into a Python literal. | <pre>map(object({<br/>    access_key  = string<br/>    password_id = string<br/>    buckets     = list(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_rules_enabled"></a> [rules\_enabled](#input\_rules\_enabled) | Whether to create the special-agent rules. Keep it `false` until the plugin that defines the ruleset `special_agents:rustfs_quota` is installed on the site: Checkmk rejects a rule for a ruleset it does not know. The hosts and the activation are created either way. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_host_names"></a> [host\_names](#output\_host\_names) | Names of the API-only hosts carrying the RustFS quota services, keyed by identity. |
| <a name="output_rule_descriptions"></a> [rule\_descriptions](#output\_rule\_descriptions) | Descriptions of the special-agent rules created (empty while rules\_enabled is false). |
<!-- END_TF_DOCS -->
