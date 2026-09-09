<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_proxmox"></a> [proxmox](#requirement\_proxmox) | 0.83.1 |
| <a name="requirement_talos"></a> [talos](#requirement\_talos) | 0.8.1 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_proxmox"></a> [proxmox](#provider\_proxmox) | 0.83.1 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [proxmox_virtual_environment_vm.this](https://registry.terraform.io/providers/bpg/proxmox/0.83.1/docs/resources/virtual_environment_vm) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cluster"></a> [cluster](#input\_cluster) | talos k8s cluster configuration | <pre>object({<br/>    name          = optional(string, "talos")<br/>    talos_version = string<br/>  })</pre> | n/a | yes |
| <a name="input_env"></a> [env](#input\_env) | environment-specific prefix for e.g. hostnames (e.g. dev-, qa-) | `string` | n/a | yes |
| <a name="input_network"></a> [network](#input\_network) | node network configuration | <pre>object({<br/>    gateway = string<br/>    vlan_id = optional(number, 0)<br/>    domain  = string<br/>  })</pre> | n/a | yes |
| <a name="input_nodes"></a> [nodes](#input\_nodes) | Configuration for cluster nodes | <pre>map(object({<br/>    host_node     = optional(string, "pve2")<br/>    node_type     = string<br/>    datastore_id  = optional(string, "local-enc")<br/>    ip            = string<br/>    mac_address   = string<br/>    vm_id         = number<br/>    cpu           = number<br/>    ram_dedicated = number<br/>    update        = optional(bool, false)<br/>  }))</pre> | n/a | yes |
| <a name="input_proxmox"></a> [proxmox](#input\_proxmox) | n/a | <pre>object({<br/>    endpoint     = string<br/>    insecure     = bool<br/>    username     = string<br/>    api_token    = string<br/>  })</pre> | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
