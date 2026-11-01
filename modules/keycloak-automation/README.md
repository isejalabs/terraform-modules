# keycloak-automation

The identity that automates a Keycloak instance, so that routine realm automation ([`keycloak-realm`](../keycloak-realm)) does not hold the break-glass administrator's login ([ADR 0016 in isejalabs/homelab](https://github.com/isejalabs/homelab/blob/main/docs/decisions/0016-identity-and-web-sso.md), point 9; [isejalabs/homelab#1942](https://github.com/isejalabs/homelab/issues/1942)):

- a **confidential client** `terragrunt` in the `master` realm that can only use the **client-credentials grant** (service account; no browser flow, no implicit flow, no password grant),
- the realm role `create-realm` for that service account, and `realm-admin` of the `<realm>-realm` client of every realm named in `existing_realms`, nothing else (in particular not the `admin` role),
- the generated client secret, written to a 1Password **login item** (`client_item_title`: client ID as username, secret as password), which `keycloak-realm` reads through its own `client_item_title`.

Uses the official [`keycloak/keycloak`](https://registry.terraform.io/providers/keycloak/keycloak/latest/docs) provider (`~> 5.10`) and `1Password/onepassword`, and the [`onepassword-item`](../onepassword-item) module.

See the [Changelog](CHANGELOG.md) for all notable changes.

## How the roles come about

The client needs the least that lets `keycloak-realm` run. Checked against the [provider documentation](https://registry.terraform.io/providers/keycloak/keycloak/latest/docs#assigning-roles) and the Keycloak source (`AdminRoles`, `RealmsAdminResource`), not yet against a live instance:

- `create-realm` is a realm role of the `master` realm. When a user without the `admin` role creates a realm, Keycloak grants that user all realm-management roles of the new realm's `<realm>-realm` client. The service account is such a user, so realms that `keycloak-realm` creates itself (a fresh instance) need nothing more.
- A realm that exists already (created by the bootstrap admin earlier, or brought back by a restore) is not covered by that. Name it in `existing_realms`: the client gets `realm-admin`, the composite of all realm-management roles of that realm's `<realm>-realm` client, for that realm only.

## Usage

Meant to be used directly as a Terragrunt root, so it configures both providers itself. Apply it **once per Keycloak instance, before `keycloak-realm`**, with the break-glass administrator; this is the only place that login is still used for automation:

```hcl
module "keycloak_automation" {
  source = "git::https://github.com/isejalabs/terraform-modules.git//modules/keycloak-automation"

  onepassword          = { service_account_token = var.onepassword_token }
  onepassword_vault_id = "<vault uuid>"

  keycloak_url      = "https://auth.example.com"
  admin_item_title  = "keycloak-bootstrap-admin#dev" # break-glass login, used for this unit only
  client_item_title = "keycloak-terragrunt#dev"      # written by this module

  existing_realms = ["iseja", "admin"] # empty on a fresh instance
}
```

Then point `keycloak-realm` at the new item (`client_item_title = "keycloak-terragrunt#dev"`, and drop `admin_item_title`).

## 1Password item

`client_item_title` is created and managed by this module: a login item whose username is the client ID and whose password is the client secret. Do not edit it by hand; rotate through the module (below).

## Rotating the secret

Change `secret_rotation` to a new value (for example the date) and apply this module with the break-glass administrator. Keycloak generates a new secret, the 1Password item is updated in the same apply, and the next `keycloak-realm` run reads the new one. The old secret stops working at once; a `keycloak-realm` apply running at that moment fails and is repeated.

## Tests

`tests/automation.tftest.hcl` runs offline (`tofu test` in this directory): both providers are mocked and every run is a plan, so nothing connects to Keycloak or 1Password, and the hostname and item names in it are placeholders. It checks the client is confidential and uses only the client-credentials grant in the `master` realm, the `create-realm` role, `realm-admin` only for the realms in `existing_realms`, the rotation value, and that the `master` realm is rejected in `existing_realms`.

## Caveats

- **The client secret is in the Terraform state** of this unit (as the provider returns it) and in the 1Password item. Protect the backend accordingly. `keycloak-realm` reads the secret through 1Password, so its state holds it as well. The bootstrap admin's login is read by this unit's state too; that stays the case as long as the unit exists.
- **The client lives in the `master` realm of the Keycloak database.** Restoring a dump from another environment (or an older dump) replaces it: the restored `master` realm has that dump's client and secret, which do not match the 1Password item of this environment. Sign in with the break-glass administrator of the restored data (its password is the dump's, not necessarily the 1Password one), then apply this module again with `secret_rotation` changed; if the restored realm has no such client, the apply recreates it (a leftover one of the same client ID must be imported or deleted first).
- `existing_realms` needs the realms to exist when it is applied (the module looks up their `<realm>-realm` clients). Add a realm to the list only after it was created; on a fresh instance leave it empty and let `keycloak-realm` create the realms.
- The bootstrap administrator is not changed by this module. Keep its item; it is the emergency access ([isejalabs/homelab `docs/keycloak-break-glass.md`](https://github.com/isejalabs/homelab/blob/main/docs/keycloak-break-glass.md)).
- Whether the set of roles is exactly enough for every resource `keycloak-realm` manages (realm settings, LDAP federation and its mappers, client scopes) was derived from the documentation and source, not yet run against a live instance. If an apply of `keycloak-realm` is refused with a 403, the missing role is the one to add here, not the `admin` role.

## Feedback

Want something added or changed? Open an [issue](https://github.com/isejalabs/terraform-modules/issues).
