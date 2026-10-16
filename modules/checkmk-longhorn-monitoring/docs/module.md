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
| <a name="input_check_interval_minutes"></a> [check\_interval\_minutes](#input\_check\_interval\_minutes) | How often Checkmk fetches the data of the API-only host and checks its services, in minutes. Checkmk's default is one minute; the monitoring plan starts at five minutes for Longhorn disk polling, matching the standard service interval. Applied to all services of the host, including the one that runs the special agent. | `number` | `5` | no |
| <a name="input_checkmk"></a> [checkmk](#input\_checkmk) | Checkmk site URL (including the site name, no trailing slash, for example `https://monitoring.example.com/prod`) and the automation user the provider authenticates as. See the README for the least-privilege role the user needs. | <pre>object({<br/>    url      = string<br/>    username = string<br/>    secret   = string<br/>  })</pre> | n/a | yes |
| <a name="input_environments"></a> [environments](#input\_environments) | Environments to create a Longhorn capacity monitoring host and rule for, keyed by a short name, each with the base URL of that environment's Longhorn deployment (its existing UI route, which proxies the unauthenticated API through, for example `http://longhorn.dev.example.com`). Quotes and backslashes are not allowed in the endpoint: it is written into a Python literal. | <pre>map(object({<br/>    endpoint = string<br/>  }))</pre> | `{}` | no |
| <a name="input_folder"></a> [folder](#input\_folder) | Path of the existing Checkmk folder the hosts are created in, for example `/container/pve4`. The folder is not created or managed by this module. | `string` | `"/"` | no |
| <a name="input_host_alias"></a> [host\_alias](#input\_host\_alias) | Alias of the hosts; the environment key is appended in parentheses. | `string` | `"Longhorn disk capacity (API only)"` | no |
| <a name="input_rules_enabled"></a> [rules\_enabled](#input\_rules\_enabled) | Whether to create the special-agent rules. Keep it `false` until the plugin that defines the ruleset `special_agents:longhorn_capacity` is installed on the site: Checkmk rejects a rule for a ruleset it does not know. The hosts and the activation are created either way. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_host_names"></a> [host\_names](#output\_host\_names) | Names of the API-only hosts carrying the Longhorn capacity services, keyed by environment. |
| <a name="output_rule_descriptions"></a> [rule\_descriptions](#output\_rule\_descriptions) | Descriptions of the special-agent rules created (empty while rules\_enabled is false). |
<!-- END_TF_DOCS -->
