<!-- BEGIN_TF_DOCS -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_onepassword"></a> [onepassword](#requirement\_onepassword) (~> 3.3)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.6)

- <a name="requirement_rustfs"></a> [rustfs](#requirement\_rustfs) (~> 0.0.8)

## Providers

The following providers are used by this module:

- <a name="provider_random"></a> [random](#provider\_random) (~> 3.6)

- <a name="provider_rustfs"></a> [rustfs](#provider\_rustfs) (~> 0.0.8)

## Modules

The following Modules are called:

### <a name="module_secret"></a> [secret](#module\_secret)

Source: ../onepassword-item

Version:

## Resources

The following resources are used by this module:

- [random_password.user_secret](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) (resource)
- [rustfs_policy.this](https://registry.terraform.io/providers/weinmann-emt/rustfs/latest/docs/resources/policy) (resource)
- [rustfs_user.this](https://registry.terraform.io/providers/weinmann-emt/rustfs/latest/docs/resources/user) (resource)

## Required Inputs

The following input variables are required:

### <a name="input_bucket_names"></a> [bucket\_names](#input\_bucket\_names)

Description: Existing bucket names the monitoring user may query for quota and logical usage. No buckets are created or modified.

Type: `set(string)`

### <a name="input_name"></a> [name](#input\_name)

Description: Name for the dedicated RustFS user and policy. The same value is used as the 1Password item title.

Type: `string`

### <a name="input_onepassword"></a> [onepassword](#input\_onepassword)

Description: 1Password service account token used to write the generated monitoring credentials.

Type:

```hcl
object({
    service_account_token = string
  })
```

### <a name="input_onepassword_vault_id"></a> [onepassword\_vault\_id](#input\_onepassword\_vault\_id)

Description: UUID of the 1Password vault where the monitoring credential item is created.

Type: `string`

### <a name="input_rustfs"></a> [rustfs](#input\_rustfs)

Description: RustFS admin endpoint and credentials used only to provision the policy and user.

Type:

```hcl
object({
    endpoint      = string
    access_key    = string
    access_secret = string
  })
```

## Optional Inputs

No optional inputs.

## Outputs

The following outputs are exported:

### <a name="output_onepassword_item_uuid"></a> [onepassword\_item\_uuid](#output\_onepassword\_item\_uuid)

Description: UUID of the 1Password item containing the monitoring credentials.

### <a name="output_policy_name"></a> [policy\_name](#output\_policy\_name)

Description: Name of the bucket-scoped quota-read policy.
<!-- END_TF_DOCS -->