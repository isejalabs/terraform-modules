# AGENTS.md

This file provides guidance to AI coding agents (Claude Code, and others reading `AGENTS.md`) when working with code in this repository. `CLAUDE.md` is a symlink to this file.

@.commons/agents/AGENTS.common.md

## About

A monorepo of small, independent Terraform/OpenTofu modules, each living under `modules/<name>/`, meant to be consumed individually (e.g. `source = "git::https://github.com/isejalabs/terraform-modules.git//modules/<name>"`) from other repos' root configs — see [isejalabs/homelab](https://github.com/isejalabs/homelab) and [isejalabs/terraform-proxmox-talos](https://github.com/isejalabs/terraform-proxmox-talos) for real-world consumers. There is no root module tying them together; each `modules/<name>/` is fully standalone.

## Modules

- [`onepassword-item`](modules/onepassword-item) — generic module to create/manage a single 1Password item with an arbitrary set of sections/fields, reusable by any module that generates credentials.
- [`rustfs-bucket-user`](modules/rustfs-bucket-user) — provisions a bucket, quota, least-privilege policy, and dedicated user on a RustFS-backed S3-compatible store.
- [`rustfs-kopiur-backup`](modules/rustfs-kopiur-backup) — orchestrates `rustfs-bucket-user` and `onepassword-item` to provision kopiur's per-environment backup bucket/user and write the resulting credentials into 1Password.
- [`talos-proxmox`](modules/talos-proxmox) — **proof of concept.** Provisions Proxmox VMs and bootstraps a Talos Linux Kubernetes cluster on them in one module.
- [`vehagn-k8s`](modules/vehagn-k8s) — **stub only** (no `.tf` files, just `README.md`/`CHANGELOG.md`). Moved to its own repo, [`isejalabs/terraform-proxmox-talos`](https://github.com/isejalabs/terraform-proxmox-talos); kept here so history and inbound links stay resolvable.
- [`vms`](modules/vms) — **proof of concept.** Provisions Proxmox VMs for Talos Linux Kubernetes nodes via the `bpg/proxmox` and `siderolabs/talos` providers.

The root [README.md](README.md)'s own Modules table is the source of truth for the current list — keep both in sync when adding/removing a module.

## Commands

There is no application build/test suite — this is pure Terraform/OpenTofu HCL, and no live Proxmox/RustFS/1Password environment is available to actually `apply` from this sandbox. Standard workflow per module:

```sh
cd modules/<name>
tofu fmt -recursive
tofu validate
tofu plan
```

- `docs/module.md` inside each module (with `.tf` files) is auto-generated from variable/output definitions by `terraform-docs` via `.github/workflows/terraform-docs.yaml`, on push to `main` only — deliberately not on PRs, to avoid interfering with Renovate PRs; contributors' PRs get updated docs once merged. Don't hand-edit the generated table content — edit the variable/output `description` blocks instead and let CI regenerate it.
- No repo-wide `tofu fmt` CI enforcement here (unlike `isejalabs/terraform-proxmox-talos`) — run `tofu fmt -recursive` yourself before committing.

## Conventions specific to this repo

- Each module is independent: no shared variables across `modules/<name>/` directories, and (per Terraform's own guidance on [providers within modules](https://developer.hashicorp.com/terraform/language/modules/develop/providers)) modules don't configure their own providers — the calling root config does, as shown in each module's own README `## Usage` example.
- **Each module keeps its own `CHANGELOG.md`** (`modules/<name>/CHANGELOG.md`), following [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) — add an entry under that module's `[Unreleased]` section (in the matching `Added`/`Changed`/`Removed`/`Fixed` group) alongside any PR that changes its behavior or variables, not for pure CI/doc tweaks. Modules version independently of each other and of the repo as a whole; there is no repo-wide `CHANGELOG.md`.
- Renovate (`renovate.json`) manages dependency bumps across all modules; a `# renovate: datasource=... depName=...` comment convention (via its `customManagers` regex, matching `.hcl`/`.tf`/`.tftpl`/`.yaml`/`.sh` files) lets Renovate track versions embedded in strings that aren't normal provider blocks.
- Each module's README documents its own caveats/gotchas in detail (see e.g. `modules/rustfs-bucket-user/README.md`'s `## Caveats`) — add to that section rather than burying a gotcha in a code comment only.
