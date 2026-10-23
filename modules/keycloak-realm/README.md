# keycloak-realm

Realm content for a Keycloak instance, for the identity platform described in [ADR 0016 in isejalabs/homelab](https://github.com/isejalabs/homelab/blob/main/docs/decisions/0016-identity-and-web-sso.md) (point 7: realm content as code; the server itself is deployed by the Keycloak Operator through Flux):

- one realm per entry of `realms` (`iseja` and `admin` in the homelab), with a password policy, brute-force detection, security headers and a WebAuthn policy,
- in each realm a **read-only** LDAP federation to the directory (UCS), users imported and synced periodically, with a user filter per realm so the realms admit disjoint accounts,
- a group mapper that imports the directory groups, and a `groups` client scope that puts the group names into a `groups` claim for the clients that add it.

Kerberos, the MFA authentication flows and the OIDC clients are not part of this module yet; they follow with [isejalabs/homelab#1827](https://github.com/isejalabs/homelab/issues/1827) and the per-service integrations.

See the [Changelog](CHANGELOG.md) for all notable changes.

## Provider

Uses the official [`keycloak/keycloak`](https://registry.terraform.io/providers/keycloak/keycloak/latest/docs) provider (`~> 5.10`) and `1Password/onepassword`.

## Usage

Meant to be used directly as a Terragrunt root, so it configures both providers itself:

```hcl
module "keycloak_realm" {
  source = "git::https://github.com/isejalabs/terraform-modules.git//modules/keycloak-realm"

  onepassword          = { service_account_token = var.onepassword_token }
  onepassword_vault_id = "<vault uuid>"

  keycloak_url     = "https://auth.example.com"
  admin_item_title = "keycloak-bootstrap-admin#dev"

  ldap = {
    connection_urls = ["ldaps://dc1.example.com:636", "ldaps://dc2.example.com:636"] # failover order
    bind_dn         = "uid=keycloak-ro,cn=users,dc=example,dc=com"
    bind_item_title = "keycloak-ldap-bind#dev"
  }

  realms = {
    iseja = {
      display_name = "Iseja"
      users_dn     = "cn=users,dc=example,dc=com"
      user_filter  = "(memberOf=cn=idm-users,cn=groups,dc=example,dc=com)"
      groups_dn    = "cn=groups,dc=example,dc=com"
    }
    admin = {
      display_name = "Admin"
      users_dn     = "cn=users,dc=example,dc=com"
      user_filter  = "(memberOf=cn=idm-admins,cn=groups,dc=example,dc=com)"
      groups_dn    = "cn=groups,dc=example,dc=com"
    }
  }
}
```

See [`docs/module.md`](docs/module.md) for the full auto-generated reference.

## 1Password items

- `admin_item_title`: the Keycloak admin login the provider authenticates with (`admin-cli`, password grant, `master` realm). Either a Login item (`username`, `password`) or an item with fields labelled `username` and `password`, which is what the External Secrets `extract` of the bootstrap admin reads. It is the Keycloak Operator's bootstrap admin until a dedicated service account client replaces it.
- `ldap.bind_item_title`: the item whose `password` is the bind credential of the read-only directory account (`ldap.bind_dn`).

## Tests

`tests/realm.tftest.hcl` runs offline with mocked providers (`tofu test` in this directory): one realm, federation and group mapper per entry, the federation is read-only and imports users, connection URLs are joined in order, the bind credential comes from 1Password, and a plain `ldap://` URL or the `master` realm is rejected. It does not talk to a Keycloak or LDAP server.

## Caveats

- The bind credential and the provider login end up in plaintext in the Terraform state, like other secrets managed by Terraform here. Protect the backend accordingly.
- Keycloak creates the federation without connecting to the directory. A wrong URL, bind DN or filter shows up at the first sync (or with "Test connection" in the admin console), not at apply time.
- The attribute and object class defaults (`uid`, `entryUUID`, `inetOrgPerson`, `posixGroup`, `uniqueMember`) are those of UCS; verify them against the directory before the first sync.
- `user_filter` decides which realm an account may log in to. Keep the filters disjoint; an account that matches both realms' filters gets two identities.
- Changing the realm name destroys and recreates the realm (and everything in it), and every issuer URL changes with it.
- Brute-force detection only temporarily locks an account in Keycloak; it does not lock the UCS account. UCS stays authoritative for locking or disabling an account.
- Group names are imported as top-level Keycloak groups; the `groups` claim carries the names without a path.

## Feedback

Want something added or changed? Open an [issue](https://github.com/isejalabs/terraform-modules/issues).
