# proxmox-access

Human login to a Proxmox VE cluster through an identity provider, as code ([ADR 0016 in isejalabs/homelab](https://github.com/isejalabs/homelab/blob/main/docs/decisions/0016-identity-and-web-sso.md); [isejalabs/homelab#2235](https://github.com/isejalabs/homelab/issues/2235), [#2236](https://github.com/isejalabs/homelab/issues/2236)):

- **OpenID Connect realms** (`proxmox_realm_openid`): one per identity-provider realm, so that several can sit next to each other (for example the Keycloak realms `admin` and `iseja`) and are offered in the realm drop-down of the login page. The client secret is read from a 1Password item and sent **write-only** (`client_key_wo`): it never reaches the state or the plan.
- **Groups** (`proxmox_virtual_environment_group`), **custom roles** (`proxmox_virtual_environment_role`) and **ACLs** (`proxmox_acl`), so that rights are stated in Git and nothing but declared groups can grant them.

Uses the [`bpg/proxmox`](https://registry.terraform.io/providers/bpg/proxmox/latest/docs) provider (`~> 0.120`, the release that has the write-only key) and `1Password/onepassword`. Needs OpenTofu or Terraform 1.11 or later for the write-only argument.

See the [Changelog](CHANGELOG.md) for all notable changes.

## How the login maps to rights

1. The user picks the realm on the login page and is sent to the identity provider.
2. Proxmox builds the user ID `<username claim>@<realm ID>` (`sebi-adm@kc-admin`) and, with `autocreate`, creates it at the first login.
3. The values of the groups claim are mapped to Proxmox groups **with the realm ID appended**: the value `sec.app.proxmox.admin` in realm `kc-admin` selects the group `sec.app.proxmox.admin-kc-admin`. Only groups that exist are used (`groups_autocreate = false`), so declare them in `groups` with that suffix.
4. With `groups_overwrite` the user's groups are replaced at every login, so a member removed from the directory group loses the rights at the next login (an open session keeps working until its ticket expires, two hours at most).
5. The ACLs of `acls` give those groups their roles. A user without a mapped group exists but can do nothing.

Rights never come from the user entry: this module does not create users and does not manage group members.

## Usage

Meant to be used directly as a Terragrunt root, so it configures its providers itself. The API token has to be allowed to manage realms, groups, roles and ACLs.

```hcl
module "proxmox_access" {
  source = "git::https://github.com/isejalabs/terraform-modules.git//modules/proxmox-access"

  proxmox              = { endpoint = "https://pve.example.com:8006", api_token = var.api_token }
  onepassword          = { service_account_token = var.onepassword_token }
  onepassword_vault_id = "<vault uuid>"

  realms = {
    kc-admin = {
      issuer_url               = "https://auth.example.com/realms/admin"
      client_id                = "proxmox"
      client_secret_item_title = "keycloak-proxmox#admin"
      comment                  = "Keycloak (admin accounts)"
    }
  }

  groups = { "sec.app.proxmox.admin-kc-admin" = { comment = "Administrators through Keycloak" } }
  acls   = { admin = { path = "/", role_id = "Administrator", group_id = "sec.app.proxmox.admin-kc-admin" } }
}
```

## Tests

`tests/access.tftest.hcl` runs offline (`tofu test` in this directory): both providers are mocked and every run is a plan. It checks the least-privilege defaults of a realm (users yes, groups no, groups replaced at login, not the default realm), that an ACL binds a declared group and role, and that a second default realm, an HTTP issuer, the built-in realm names `pam`/`pve` and an ACL for an undeclared group are rejected.

## Caveats

- **Cluster-wide.** Realms, groups, roles and ACLs live in `/etc/pve` and are shared by all nodes; one apply configures the whole cluster, and a second cluster needs its own unit.
- **Every node must reach and trust the issuer.** Proxmox fetches the discovery document and the keys from each node. The issuer's certificate must chain to a CA the node trusts, and the node must resolve the host name.
- **The redirect URI is the page the user came from.** Proxmox uses the URL of the web interface (`https://<node>:8006`) as the redirect URI, so the client at the identity provider needs one entry per node host name a user may open, including a cluster alias.
- **Rotating the secret.** Proxmox never returns the key, so Terraform cannot detect a changed 1Password item: raise `client_key_version` of the realm after the rotation.
- **Removing a realm** is not rehearsed here: check what Proxmox does with the users the realm created before you delete one that has been in use.
- **The built-in realms and users stay out.** `pam`, `pve`, an Active Directory or LDAP realm and `root@pam` are not managed here and are not touched.
- Group membership is read-only here (`members` is computed by the provider). Do not add the `groups` argument to a user of an OpenID Connect realm by hand: the next login replaces it.
