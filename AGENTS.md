# AGENTS.md — ansible-container

## What This Is

Ansible automation that provisions **Docker CE** or **Podman** (selectable) and optionally **Portainer CE** on Linux servers. Targets Rocky/AlmaLinux 9-10, Ubuntu 22.04+, Debian 10+.

## Key Commands

```bash
# Syntax check (run before any playbook change)
ansible-playbook container.yml --syntax-check

# Lint (ansible-lint must be in venv)
pip install -r requirements.txt
ansible-lint container.yml

# Full provision (uses inventory from ansible.cfg)
ansible-playbook container.yml

# Limit to one environment
ansible-playbook container.yml --limit local
ansible-playbook container.yml --limit dev

# Run a single role
ansible-playbook container.yml --tags docker
ansible-playbook container.yml --tags podman
ansible-playbook container.yml --tags portainer

# Connectivity check
ansible all -m ping

# Molecule tests (Docker required on control node)
pip install -r requirements.txt
molecule test
molecule converge   # create + apply only
molecule verify     # run verifiers
molecule destroy    # cleanup
```

## Architecture

- **Single playbook**: `container.yml` — roles applied conditionally via `container_runtime` var.
- **`group_vars/all.yml`** is the control file: `container_runtime: docker|podman`, `portainer_enabled`, `use_proxy`, proxy URLs.
- **OS-family branching**: each role loads `vars/RedHat.yml` or `vars/Debian.yml` via `ansible_os_family`. New OS families need a matching vars file in every role.
- **`roles/*/defaults/main.yml`** defines `proxy_env` as a ternary dict — use `environment: "{{ proxy_env }}"` on any internet-fetching task.
- **Portainer gate** is inside the role (`when: portainer_enabled | bool`), not in the playbook.
- **Molecule** uses `geerlingguy/docker-*-ansible` images; runs privileged with cgroup mounts.

## Conventions (Enforced)

- **FQCN only**: `ansible.builtin.dnf`, `ansible.builtin.template`, etc. No shorthand module names.
- **Every task must have `name:`** — ansible-lint hard requirement.
- **`changed_when:` required** on `command`/`shell` tasks.
- **`become: true`** is global in `ansible.cfg` — don't repeat per-task unless overriding.
- **Inventory** default is `inventory/hosts.yml` (set in `ansible.cfg`).
- **Conventional commits**: `feat:`, `fix:`, `chore:`.

## Testing

- `molecule test` spins up 3 containers (Rocky 9, Ubuntu 22.04, Debian 11) via Docker driver.
- `molecule converge` defaults to `container_runtime: docker`. To test Podman, modify `molecule/default/converge.yml`.
- Verifiers check `docker --version` and systemd service status — **not Podman-aware yet**.

## Local Dev (Terraform + Vagrant)

```bash
cd terraform-vagrant
terraform init && terraform apply -auto-approve
vagrant ssh
terraform destroy -auto-approve
```

Note: `terraform-vagrant/id_rsa` is committed for convenience — never reuse on real servers.

## Common Gotchas

- `host_key_checking = False` in `ansible.cfg` — acceptable for dev, not prod.
- Podman role creates `/var/run/docker.sock` symlink to podman socket — global exposure risk in rootful mode.
- `requirements.txt` pins `molecule>=6.0.0` and `ansible-core>=2.14.0`.
