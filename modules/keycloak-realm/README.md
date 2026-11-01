# keycloak-realm

Realm content for a Keycloak instance, for the identity platform described in [ADR 0016 in isejalabs/homelab](https://github.com/isejalabs/homelab/blob/main/docs/decisions/0016-identity-and-web-sso.md) (point 7: realm content as code; the server itself is deployed by the Keycloak Operator through Flux):

- one realm per entry of `realms` (`iseja` and `admin` in the homelab), with a password policy, brute-force detection, security headers and a WebAuthn policy,
- in each realm a **read-only** LDAP federation to the directory (UCS), users imported and synced periodically, with a user filter per realm so the realms admit disjoint accounts,
- a group mapper that imports the directory groups, and a `groups` client scope that puts the group names into a `groups` claim for the clients that add it,
- optionally SAML clients (`saml_clients`) for applications that only speak SAML, such as the Checkmk Ultimate sites.

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

Everything else has a default that is what the homelab runs with and can be overridden: `realm_settings` (self-registration, e-mail login, `ssl_required`), `security_headers`, `brute_force`, `web_authn`, `groups_claim` (scope and claim name), and the optional attributes of `ldap` (search scope, timeouts, federation and mapper names, how memberships are read, and `user_attributes`: which LDAP attribute feeds Keycloak's username, e-mail, first name and last name; defaults `uid`, `mail`, `givenName`, `sn`). The Keycloak default of reading the first name from `cn` is deliberately not used: in UCS `cn` is the full name. Keycloak's default mappers are only deleted when a federation is created, so replace an existing federation once (`-replace`) to adopt this. Deliberately fixed: the federation and the group mapper are read-only and importing, because UCS stays authoritative.

See [`docs/module.md`](docs/module.md) for the full auto-generated reference.

## SAML clients

`saml_clients` registers service providers that only speak SAML, one client per entry and realm. Checkmk, for example, accepts accounts of one realm per SAML connection, so a site that serves everyday and admin accounts gets two entries with the same entity ID, one in each realm:

```hcl
saml_clients = {
  "mon-iseja" = {
    realm     = "iseja"
    client_id = "https://monitoring.example.com/site/check_mk/saml_metadata.py" # entity ID of the SP
    acs_url   = "https://monitoring.example.com/site/check_mk/saml_acs.py?acs"
  }
  "mon-admin" = {
    realm         = "admin"
    client_id     = "https://monitoring.example.com/site/check_mk/saml_metadata.py"
    acs_url       = "https://monitoring.example.com/site/check_mk/saml_acs.py?acs"
    include_email = true
  }
}
```

- **Signing:** Keycloak signs the assertion and the document with RSA-SHA256 (`saml_signature_algorithm`), which Checkmk accepts, and sends the user ID as the name ID.
- **Attributes** (names in `saml_claims`, URI format): the user ID (the username; Checkmk requires a name starting with `http`), the alias, the group names (multi-valued, plain names, from the groups imported out of the directory), and the e-mail address only for entries with `include_email`. An application that notifies by e-mail would otherwise notify every user it creates.
- **Request signatures:** the SP signs its requests with its own certificate. Unless `signing_certificate` is given, Keycloak does not require signed requests; add the certificate once the SP has created it to turn that on.
- **Metadata:** the output `saml_idp_metadata_urls` has the identity provider metadata URL per realm, which the SP imports.

## 1Password items

- `admin_item_title`: the Keycloak admin login the provider authenticates with (`admin-cli`, password grant, `master` realm). Either a Login item (`username`, `password`) or an item with fields labelled `username` and `password`, which is what the External Secrets `extract` of the bootstrap admin reads. It is the Keycloak Operator's bootstrap admin until a dedicated service account client replaces it.
- `ldap.bind_item_title`: the item whose `password` is the bind credential of the read-only directory account (`ldap.bind_dn`).

## Tests

`tests/realm.tftest.hcl` runs offline (`tofu test` in this directory): both providers are mocked and every run is a plan, so nothing connects to Keycloak, an LDAP server or 1Password, and the hostnames and DNs in it are placeholders. It checks one realm, federation and group mapper per entry, the federation is read-only and imports users, connection URLs are joined in order, the bind credential comes from 1Password, defaults and overrides of the settings above, and that a plain `ldap://` URL or the `master` realm is rejected. `tests/saml.tftest.hcl` does the same for the SAML clients: signed assertions, the ACS URL as the only redirect URI, the mappers (e-mail only on request), signed requests only with a certificate, and invalid realms, URLs and duplicate client IDs are rejected.

## Caveats

- The bind credential and the provider login end up in plaintext in the Terraform state, like other secrets managed by Terraform here. Protect the backend accordingly.
- Keycloak creates the federation without connecting to the directory. A wrong URL, bind DN or filter shows up at the first sync (or with "Test connection" in the admin console), not at apply time.
- The attribute and object class defaults (`uid`, `entryUUID`, `inetOrgPerson`, `posixGroup`, `uniqueMember`) are those of UCS; verify them against the directory before the first sync.
- `user_filter` decides which realm an account may log in to. Keep the filters disjoint; an account that matches both realms' filters gets two identities.
- Changing the realm name destroys and recreates the realm (and everything in it), and every issuer URL changes with it.
- Brute-force detection only temporarily locks an account in Keycloak; it does not lock the UCS account. UCS stays authoritative for locking or disabling an account.
- Group names are imported as top-level Keycloak groups; the `groups` claim carries the names without a path.
- The SAML client settings are checked offline against the provider schema only; whether an SP accepts the assertion (signature algorithm, attribute names) is only known with a real SP. The Checkmk side was not exercised with this module at the time of the first release.
- A SAML client with `full_scope_allowed = false` sends no realm roles; authorization must come from the group attribute.

## Feedback

Want something added or changed? Open an [issue](https://github.com/isejalabs/terraform-modules/issues).
