# Changelog

All _notable_ changes to this module will be documented in this file, following the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format. It won't include each and every change and commit (e.g. ci or documentation changes), but only the notable changes, in a human-readable format that commit messages sometimes do not provide.

This module tries to adhere to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Hence, a change to the version number X.Y.Z will indicate a

- **X+1: breaking changes** in **major** version numbers,
- **Y+1: feature updates** (and possbily bug fixes) in **minor** version numbers, and
- **Z+1: bug fixes** only in **patch** version numbers.

<!--
> [!NOTE]
> [!TIP]
> [!IMPORTANT]
> [!WARNING]
> [!CAUTION]
-->

<!---
## [Unreleased Template]
### Changed

### Added

### Removed

### Fixed

## [X.Y.Z] - YYYY-MM-DD
-->

## [Unreleased]

### Added

- `web_authn.relying_party_id` (module-wide) and `realms[*].web_authn` (per realm: `relying_party_id`, `user_verification_requirement`). The relying-party ID is now always set explicitly, by default to the hostname of `keycloak_url`, which is what Keycloak derived before; the plan shows it as an in-place change of the WebAuthn policy. Changing it later invalidates every enrolled passkey and security key.
- `realms[*].second_factor` (default `null`): replaces the realm's browser flow with `browser-mfa`, which asks every password login for a WebAuthn authenticator or a TOTP code and sends a user with neither through the registration of one (`enroll = "webauthn"` or `"totp"`). Keycloak's built-in `browser` flow is left untouched.

### Changed

### Removed

### Fixed

## [0.4.0] - 2026-11-02

### Added

- `client_item_title`: the provider can log in with the client-credentials grant of a service-account client (as created by the new `keycloak-automation` module) instead of an admin login. ([#82](https://github.com/isejalabs/terraform-modules/issues/82))

### Changed

- `admin_item_title` is optional now; exactly one of it and `client_item_title` must be set, so existing callers keep working unchanged. ([#82](https://github.com/isejalabs/terraform-modules/issues/82))

### Removed

### Fixed

## [0.3.0] - 2026-11-01

### Added

- `saml_clients`: SAML clients (service providers) per realm with signed assertions, the ACS URL as the only redirect URI and mappers for user ID, alias, optionally e-mail, and the group list; `saml_claims` and `saml_signature_algorithm` tune the attribute names and the signature. New outputs `saml_idp_metadata_urls` and `saml_client_ids`. Built for the Checkmk Ultimate sites. ([#84](https://github.com/isejalabs/terraform-modules/issues/84))

### Changed

### Removed

### Fixed

## [0.2.0] - 2026-10-25

### Added

- `ldap.user_attributes` (username, e-mail, first name, last name) and explicit user attribute mappers per realm, including read-only creation/modify timestamps. ([#N](https://github.com/isejalabs/terraform-modules/issues/72))

### Changed

- The federation deletes Keycloak's default mappers (`delete_default_mappers`), which only takes effect when the federation is created: an existing federation must be replaced once (`-replace`) to adopt this. ([#N](https://github.com/isejalabs/terraform-modules/issues/72))

### Removed

- The default Kerberos principal attribute mapper is no longer created; Kerberos is set up separately (isejalabs/homelab#1827).

### Fixed

- The first name is read from `givenName`, not `cn` (the full name in UCS), which showed users as "Sebastian Klamar Klamar". ([#N](https://github.com/isejalabs/terraform-modules/issues/72))

## [0.1.0] - 2026-10-25

### Added

- Initial module: one Keycloak realm per entry of `realms` (password policy, brute-force detection, security headers, WebAuthn policy), each with a read-only, importing LDAP federation to UCS over LDAPS with several connection URLs for failover and a per-realm user filter, a group mapper, and a `groups` client scope with a group-membership mapper. The provider login and the LDAP bind credential are read from 1Password. Uses the `keycloak/keycloak` provider (`~> 5.10`). The realm settings, security headers, brute-force detection, WebAuthn policy, group claim and the LDAP/group-mapper tuning are variables with defaults. An offline `tofu test` (mocked providers) covers the per-realm resources, the federation settings, defaults/overrides and the input validation. ([#66](https://github.com/isejalabs/terraform-modules/issues/66))
