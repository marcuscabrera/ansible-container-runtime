# QWEN.md — ansible-container

## Project Overview

Ansible automation project for provisioning **Docker CE** or **Podman** container runtimes and optionally **Portainer CE** on Linux servers. Targets Rocky/AlmaLinux 9-10, Ubuntu 22.04+, and Debian 10+.

**Primary Purpose:** Infrastructure as Code (IaC) for container runtime deployment across heterogeneous Linux environments with proxy support and optional GUI management via Portainer.

---

## Architecture

### Single Playbook Design
- **`container.yml`** — Main playbook with conditional role execution via `container_runtime` variable
- **`group_vars/all.yml`** — Control file: `container_runtime: docker|podman`, `portainer_enabled`, `use_proxy`, proxy URLs
- **`ansible.cfg`** — Pre-configured with inventory path, become escalation, SSH pipelining

### OS-Family Branching Pattern
Each role loads OS-specific variables via `ansible_os_family`:
```
roles/docker/vars/RedHat.yml  → dnf, Rocky/Alma packages
roles/docker/vars/Debian.yml  → apt, Ubuntu/Debian packages
```
**New OS families require matching vars file in every role.**

### Role Structure
```
roles/
├── docker/     # Docker CE, CLI, containerd, buildx, compose plugin
├── podman/     # Podman, podman-docker, podman-compose + compat symlinks
└── portainer/  # Portainer CE via docker compose
```

### Proxy Pattern
- **`proxy_env`** defined in `roles/*/defaults/main.yml` as ternary dict
- Apply via `environment: "{{ proxy_env }}"` on any internet-fetching task
- Configures systemd override for Docker daemon when `use_proxy: true`

---

## Key Commands

### Syntax & Lint
```bash
# Syntax check (run before any playbook change)
ansible-playbook container.yml --syntax-check

# Lint (ansible-lint must be in venv)
pip install -r requirements.txt
ansible-lint container.yml
```

### Provisioning
```bash
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
```

### Molecule Tests
```bash
# Docker required on control node
pip install -r requirements.txt
molecule test              # full suite: create → converge → verify → destroy
molecule converge          # create + apply only
molecule verify            # run verifiers
molecule destroy           # cleanup
```

### Local Dev (Terraform + Vagrant)
```bash
cd terraform-vagrant
terraform init && terraform apply -auto-approve
vagrant ssh
terraform destroy -auto-approve
```
**Note:** `terraform-vagrant/id_rsa` is committed for convenience — never reuse on real servers.

---

## Configuration

### Control Variables (`group_vars/all.yml`)
| Variable | Default | Description |
|----------|---------|-------------|
| `container_runtime` | `docker` | Runtime selection: `docker` or `podman` |
| `portainer_enabled` | `true` | Deploy Portainer CE |
| `use_proxy` | `false` | Enable corporate proxy |
| `http_proxy` | — | HTTP proxy URL |
| `https_proxy` | — | HTTPS proxy URL |
| `deploy_dir` | `/opt/container` | Base directory for deployments |

### Inventory Structure (`inventory/hosts.yml`)
Multi-environment inventory with groups: `local`, `dev`, `pre`, `prd`

---

## Development Conventions

### Ansible Best Practices (Enforced)
1. **FQCN only** — `ansible.builtin.dnf`, `ansible.builtin.template`, etc. No shorthand module names.
2. **Every task must have `name:`** — ansible-lint hard requirement.
3. **`changed_when:` required** on `command`/`shell` tasks.
4. **`become: true`** is global in `ansible.cfg` — don't repeat per-task unless overriding.
5. **Inventory** default is `inventory/hosts.yml` (set in `ansible.cfg`).

### Code Style
- **Conventional commits:** `feat:`, `fix:`, `chore:`
- **YAML formatting:** 2-space indent, consistent quoting
- **Task naming:** Descriptive, action-oriented (e.g., "Install Docker CE packages (RedHat)")

### Testing Requirements
- All new roles must have Molecule tests
- Test against all supported distros: Rocky 9, Ubuntu 22.04, Debian 11
- Verifiers check service status and command availability

---

## Molecule Testing

### Configuration
- **Driver:** Docker with privileged mode and cgroup mounts
- **Images:** `geerlingguy/docker-*-ansible:latest`
- **Platforms:** Rocky 9, Ubuntu 22.04, Debian 11
- **Default converge:** `container_runtime: docker`

### Testing Podman
Modify `molecule/default/converge.yml`:
```yaml
vars:
  container_runtime: podman
  portainer_enabled: false
```

### Verifier Limitations
Current verifiers check `docker --version` and systemd service status — **not Podman-aware yet**.

---

## Common Patterns

### Adding a New OS Family
1. Create `roles/*/vars/<OSFamily>.yml` for each role
2. Define OS-specific package lists, repo URLs, prerequisites
3. Add test platform to `molecule/default/molecule.yml`
4. Update converge playbook if needed

### Proxy-Aware Task Pattern
```yaml
- name: Download something
  ansible.builtin.get_url:
    url: "{{ item.url }}"
    dest: "{{ item.dest }}"
  environment: "{{ proxy_env }}"
```

### Conditional Service Configuration
```yaml
- name: Configure service
  ansible.builtin.template:
    src: config.j2
    dest: /etc/service/config
  when: use_proxy | bool
  notify: Restart service
```

---

## Common Gotchas

1. **`host_key_checking = False`** in `ansible.cfg` — acceptable for dev, not prod.
2. **Podman socket symlink** — Podman role creates `/var/run/docker.sock` symlink to podman socket; global exposure risk in rootful mode.
3. **Molecule Docker requirement** — Molecule tests require Docker on control node.
4. **`requirements.txt` pins** — `molecule>=6.0.0` and `ansible-core>=2.14.0` are minimum versions.
5. **Portainer gate location** — Inside the role (`when: portainer_enabled | bool`), not in playbook.

---

## File Reference

| File | Purpose |
|------|---------|
| `container.yml` | Main playbook with conditional role execution |
| `ansible.cfg` | Ansible configuration (inventory, become, SSH) |
| `group_vars/all.yml` | Global control variables |
| `inventory/hosts.yml` | Multi-environment host inventory |
| `requirements.txt` | Python dependencies for testing |
| `roles/docker/` | Docker CE provisioning role |
| `roles/podman/` | Podman provisioning role |
| `roles/portainer/` | Portainer CE deployment role |
| `molecule/default/` | Molecule test configuration |
| `terraform-vagrant/` | Local development environment |

---

## Dependencies

### Control Node
- Ansible 2.14+
- Python 3.8+ (for Molecule)
- Docker (for Molecule tests)

### Target Nodes
- SSH access with sudo privileges
- Supported OS: Rocky/AlmaLinux 9-10, Ubuntu 22.04+, Debian 10+
