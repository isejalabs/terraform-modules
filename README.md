# terraform-modules
Infrastructure modules to be used with Terragrunt and Terraform/OpenTofu

## Modules

- [`checkmk-password`](modules/checkmk-password) -- Stores one field of a 1Password item as a Checkmk Password Store entry, via the community `blackmesaltd/checkmk` provider, so Checkmk rules can reference it without carrying the secret inline.
- [`onepassword-item`](modules/onepassword-item) -- Generic module to create/manage a single 1Password item with an arbitrary set of sections/fields, reusable by any module that generates credentials.
- [`rustfs-bucket-user`](modules/rustfs-bucket-user) -- Provisions a bucket, quota, least-privilege policy, and dedicated user on a RustFS-backed S3-compatible store, so each consumer gets its own bucket and its own scoped credentials instead of sharing admin credentials.
- [`rustfs-bucket-reader`](modules/rustfs-bucket-reader) -- Provisions a dedicated read-only user whose policy allows only `s3:GetBucketQuota` on existing buckets (for capacity monitoring), and writes its credentials into 1Password.
- [`rustfs-kopiur-backup`](modules/rustfs-kopiur-backup) -- Orchestrates `rustfs-bucket-user` and `onepassword-item` to provision kopiur's per-environment backup bucket/user and write the resulting credentials into 1Password.
- [`talos-proxmox`](modules/talos-proxmox) -- **Proof of concept.** Provisions Proxmox VMs *and* bootstraps a Talos Linux Kubernetes cluster on them in one module (machine secrets/config, image factory schematic, cluster health/kubeconfig).
- [`vehagn-k8s`](modules/vehagn-k8s) -- Moved to its own repo, [`isejalabs/terraform-proxmox-talos`](https://github.com/isejalabs/terraform-proxmox-talos).
- [`vms`](modules/vms) -- **Proof of concept.** Provisions Proxmox VMs for Talos Linux Kubernetes nodes (control-plane/worker) via the `bpg/proxmox` and `siderolabs/talos` providers.

Each module directory has its own `docs/module.md` with the full auto-generated reference (inputs/outputs/resources/requirements), kept in sync by CI.
