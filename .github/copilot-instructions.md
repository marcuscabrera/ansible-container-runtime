# Copilot Instructions — ansible-container

## Project Overview

Ansible automation that provisions container runtimes (**Docker CE** or **Podman**) and optionally deploys **Portainer CE** on Linux servers. Supports Rocky Linux, AlmaLinux (9/10), Ubuntu (22.04+), and Debian (10+).

---

## Commands

```bash
# Validate connectivity to all hosts
ansible -i inventory/hosts.yml all -m ping

# Check playbook syntax
ansible-playbook -i inventory/hosts.yml container.yml --syntax-check

# Run full provisioning (all hosts)
ansible-playbook -i inventory/hosts.yml container.yml

# Target a specific environment group
ansible-playbook -i inventory/hosts.yml container.yml --limit local
ansible-playbook -i inventory/hosts.yml container.yml --limit dev
ansible-playbook -i inventory/hosts.yml container.yml --limit prd

# Run a single role by tag
ansible-playbook -i inventory/hosts.yml container.yml --tags docker
ansible-playbook -i inventory/hosts.yml container.yml --tags podman
ansible-playbook -i inventory/hosts.yml container.yml --tags portainer

# Lint (ansible-lint must be installed)
ansible-lint container.yml
```

---

## Architecture

### Entry Point

`container.yml` is the only playbook. It targets all hosts and applies roles conditionally:
- `docker` role runs when `container_runtime == 'docker'` (tagged `docker`)
- `podman` role runs when `container_runtime == 'podman'` (tagged `podman`)
- `portainer` role always runs (the `portainer_enabled` gate is **inside** the role, not at the playbook level)

### Variable Hierarchy

| File | Purpose |
|---|---|
| `group_vars/all.yml` | Global control switches (`container_runtime`, `portainer_enabled`, `use_proxy`, etc.) |
| `roles/<role>/defaults/main.yml` | Role-level defaults, including the `proxy_env` computed dict |
| `roles/<role>/vars/<OsFamily>.yml` | OS-specific package lists and repo URLs, loaded dynamically |

### OS-Family Branching Pattern

Each role starts by loading OS-specific variables:
```yaml
- name: Load OS-specific variables
  ansible.builtin.include_vars: "{{ ansible_os_family }}.yml"
```
Files are named `RedHat.yml` and `Debian.yml` inside `roles/<role>/vars/`. All subsequent tasks branch on `when: ansible_os_family == 'RedHat'` or `when: ansible_os_family == 'Debian'`.

### Proxy Pattern

The `proxy_env` variable in each role's `defaults/main.yml` is a ternary expression:
```yaml
proxy_env: "{{ (use_proxy | bool) | ternary({'http_proxy': http_proxy, 'https_proxy': https_proxy}, {}) }}"
```
Use it as `environment: "{{ proxy_env }}"` on any task that fetches from the internet. When `use_proxy: false`, this resolves to an empty dict — no environment variables are set.

### Podman Docker-Compatibility Layer

The `podman` role creates two symlinks to maintain tool compatibility:
- `/var/run/docker.sock` → `/var/run/podman/podman.sock`
- `/usr/bin/docker-compose` → `$(which podman-compose)`

Portainer always mounts `/var/run/docker.sock`, so it works with both runtimes.

### Local Test Infrastructure

`terraform-vagrant/` provisions a Rocky Linux 9 VM via Terraform + Vagrant + VirtualBox for local testing. Key workflow:
```bash
cd terraform-vagrant
terraform init
terraform apply -auto-approve   # creates VM, runs vagrant up
vagrant ssh                     # access VM
terraform destroy -auto-approve # tear down
```
A hash of the rendered `Vagrantfile` is passed to the Vagrant resource so Terraform detects structural changes and recreates the VM automatically.

> **Note:** `terraform-vagrant/id_rsa` and `id_rsa.pub` are committed for convenience but should never be reused on real servers. Regenerate them locally with `ssh-keygen -t rsa -b 4096 -f terraform-vagrant/id_rsa -N ""` if needed.

---

## Key Conventions

- **Always use FQCN** for Ansible modules: `ansible.builtin.dnf`, `ansible.builtin.template`, etc. — never shorthand like `dnf:` or `template:`.
- **Every task must have a `name:`** property — this is a hard requirement enforced by ansible-lint.
- **`changed_when:` must be defined** on `command`/`shell` tasks to avoid spurious change reporting.
- **New OS families** require adding a corresponding `vars/<OsFamily>.yml` file inside each affected role plus `when:` conditions in tasks.
- **Commit convention**: `feat: ...`, `fix: ...`, `chore: ...` (conventional commits style).
- The default inventory is set in `ansible.cfg` (`inventory = inventory/hosts.yml`) — omitting `-i` will use it automatically.
- `become: true` is set globally in `ansible.cfg`; do not repeat it per-task unless overriding.
