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

- `var.item_title` (optional, defaults to `var.name`): title of the 1Password item, so it can follow a different naming convention than the RustFS-side names (for example `<thing>#<env>`).

### Changed

### Removed

### Fixed

## [0.1.0] - 2026-10-03

### Added

- `rustfs_policy` allowing only the bucket-scoped `s3:GetBucketQuota` action on the existing buckets listed in `var.bucket_names` (no object ARN, `ListBucket`, quota-setting or `admin:*` actions), a dedicated `rustfs_user` with a generated secret attached to it, and a 1Password item (via `onepassword-item`) holding both credential fields concealed ([#36](https://github.com/isejalabs/terraform-modules/pull/36)).
- `var.name` (required): used verbatim as the user's access key and the 1Password item title, and with a `-ro` suffix as the policy name.
- `var.bucket_names` validation: an empty set or a blank name is rejected.
- Offline `tofu test` (mocked providers) asserting the policy shape.
- No credential output, not even the non-secret access key; the 1Password item is the single delivery path.
