# terraform-modules
Infrastructure modules to be used with Terragrunt and Terraform/OpenTofu

## Modules

- [`vms`](modules/vms) -- Provisions Proxmox VMs for Talos Linux Kubernetes nodes (control-plane/worker) via the `bpg/proxmox` and `siderolabs/talos` providers.
- [`talos-proxmox`](modules/talos-proxmox) -- Provisions Proxmox VMs *and* bootstraps a Talos Linux Kubernetes cluster on them in one module (machine secrets/config, image factory schematic, cluster health/kubeconfig).
- [`vehagn-k8s`](modules/vehagn-k8s) -- Moved to its own repo, [`isejalabs/terraform-proxmox-talos`](https://github.com/isejalabs/terraform-proxmox-talos).
- [`rustfs-bucket-user`](modules/rustfs-bucket-user) -- Provisions a bucket, quota, least-privilege policy, and dedicated user on a RustFS-backed S3-compatible store, so each consumer gets its own bucket and its own scoped credentials instead of sharing admin credentials.

Each module directory has its own `docs/module.md` with the full auto-generated reference (inputs/outputs/resources/requirements), kept in sync by CI.
