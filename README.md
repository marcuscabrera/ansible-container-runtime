# Ansible Automation - Provisionamento de Runtime de Contêineres

Projeto Ansible que automatiza o provisionamento e configuração completa de runtimes de contêineres (**Docker CE** ou **Podman**) e ferramentas acessórias (como **Portainer CE**) em servidores Linux corporativos.

Validado para as seguintes distribuições:
- **Rocky Linux** e **AlmaLinux** (versões 9 e 10)
- **Ubuntu** (22.04 LTS ou superior)
- **Debian** (10 ou superior)

---

## Funcionalidades

- **Seleção dinâmica de runtime** -- alterne entre Docker CE e Podman editando uma única variável.
- **Suporte multi-distribuição** -- gerenciadores de pacotes e repositórios oficiais para famílias RedHat (dnf/yum) e Debian (apt).
- **Instalação completa** -- Docker (CE, CLI, Containerd, Buildx, Compose plugin) ou Podman (Podman, Podman-Docker, Podman Compose).
- **Proxy corporativo** -- suporte a provisionamento atrás de proxies HTTP/HTTPS.
- **Compatibilidade legada** -- criação automática de symlinks (`docker.sock`, `docker-compose`) ao usar Podman.
- **Portainer CE** -- deploy opcional via Docker Compose para gestão visual de contêineres.

---

## Tecnologias

| Categoria | Ferramentas |
|-----------|-------------|
| Automação | Ansible 2.14+, Ansible Lint |
| Runtimes | Docker CE, Podman |
| Composição | Docker Compose, Podman Compose |
| Gestão | Portainer CE |
| Infra local | Vagrant, Terraform |
| Testes | Molecule (Docker driver) |
| Linguagem | YAML (playbooks/roles) |

---

## Estrutura do Projeto

```
ansible-container/
├── ansible.cfg              # Configurações padrão do Ansible
├── container.yml            # Playbook principal
├── group_vars/
│   └── all.yml              # Variáveis globais (runtime, proxy, Portainer)
├── inventory/
│   ├── hosts.yml            # Inventário multi-ambiente (YAML)
│   └── hosts.inv            # Inventário alternativo (INI)
├── roles/
│   ├── docker/              # Instalação completa do Docker CE
│   ├── podman/              # Instalação completa do Podman
│   └── portainer/           # Deploy do Portainer CE
├── molecule/
│   └── default/             # Testes automatizados em contêineres
│       ├── molecule.yml
│       ├── converge.yml
│       └── verify.yml
├── terraform-vagrant/       # Laboratório local (VM via Vagrant+Terraform)
├── requirements.txt         # Dependências Python (Molecule, Ansible)
└── README.md
```

---

## Instalação e Configuração

### Pré-requisitos na máquina controladora

1. **Python 3.8+**
2. **Ansible Core 2.14+**
3. **Docker** (para testes com Molecule)
4. **SSH configurado** para os servidores de destino

### Passo 1 -- Instalar dependências

```bash
# Dependências Python (Ansible + Molecule)
pip install -r requirements.txt
```

O arquivo `requirements.txt` define:

```
molecule>=6.0.0
molecule-plugins[docker]>=23.0.0
ansible-core>=2.14.0
ansible-lint>=6.0.0
```

### Passo 2 -- Configurar variáveis globais

Edite `group_vars/all.yml`:

```yaml
# Diretório de deploy nos servidores
deploy_dir: /opt/container

# Runtime: 'docker' ou 'podman'
container_runtime: docker

# Portainer (true/false)
portainer_enabled: true

# Proxy corporativo (se necessário)
use_proxy: false
http_proxy: "http://[IP ou Hostname]:12321"
https_proxy: "http://[IP ou Hostname]:12321"
```

### Passo 3 -- Configurar o inventário

Edite `inventory/hosts.yml` com seus servidores:

```yaml
all:
  children:
    local:
      hosts:
        vm1.local.example.com:
          ansible_host: 192.168.56.10
          ansible_user: ansible
    dev:
      hosts:
        vm2.dev.example.com:
          ansible_host: 10.0.1.20
```

---

## Exemplos de Uso

### Validar conectividade e sintaxe

```bash
# Testar conectividade SSH com todos os hosts
ansible all -m ping

# Validar sintaxe do playbook
ansible-playbook container.yml --syntax-check

# Lint com ansible-lint
ansible-lint container.yml
```

### Provisionamento completo

```bash
# Aplica o runtime configurado (Docker ou Podman) + Portainer
ansible-playbook container.yml

# Limitar a um grupo de hosts específico
ansible-playbook container.yml --limit dev
```

### Executar apenas uma role (tags)

```bash
# Apenas Docker
ansible-playbook container.yml --tags docker

# Apenas Podman
ansible-playbook container.yml --tags podman

# Apenas Portainer
ansible-playbook container.yml --tags portainer
```

### Modo dry-run (check)

```bash
# Simular alterações sem aplicar
ansible-playbook container.yml --check --diff
```

---

## Testes com Molecule

O projeto utiliza **Molecule** com driver Docker para testar as roles em contêineres temporários, eliminando a necessidade de VMs para validação de sintaxe e convergência.

### Executar testes

```bash
# Suíte completa (create, converge, verify, destroy)
molecule test

# Ciclo de desenvolvimento interativo
molecule create      # Criar contêineres
molecule converge     # Aplicar playbook
molecule verify       # Executar verificações
molecule destroy      # Limpar contêineres

# Apenas convergir (reutiliza contêineres existentes)
molecule converge
```

### Plataformas de teste

| Plataforma | Imagem | Status |
|------------|--------|--------|
| Rocky Linux 9 | `geerlingguy/docker-rockylinux9-ansible` | Funcional |
| Ubuntu 22.04 | `geerlingguy/docker-ubuntu2204-ansible` | Funcional |
| Debian 11 | `geerlingguy/docker-debian11-ansible` | Limitacao WSL2 |

> **Nota**: Em ambiente WSL2, o Debian 11 nao inicia systemd corretamente. Teste em maquina real ou VM para validacao completa. Portainer nao e viavel em Docker-in-Docker (DinD) devido a limitacoes de overlay mount no WSL2.

### Configuracao do Molecule

O Molecule usa `command: /sbin/init` e cgroups `:rw` para que systemd funcione como PID 1 dentro dos contêineres. O `ANSIBLE_ROLES_PATH` e configurado via variavel de ambiente apontando para `roles/`.

---

## Infraestrutura Local (Vagrant + Terraform)

Para criar um laboratório local rápido:

```bash
cd terraform-vagrant
terraform init
terraform apply -auto-approve

# Acessar a VM
vagrant ssh

# Destruir quando nao precisar mais
terraform destroy -auto-approve
```

---

## Contribuindo

### Processo

1. Fork o repositorio.
2. Crie uma branch de feature: `git checkout -b feat/nova-funcionalidade`.
3. Implemente seguindo as diretrizes abaixo.
4. Commite usando convencional commits: `feat:`, `fix:`, `chore:`.
5. Abra um Pull Request.

### Diretrizes de código

- **FQCN obrigatório**: use `ansible.builtin.dnf`, `ansible.builtin.template`, etc. Nunca modulos shorthand.
- **Toda task deve ter `name:`**: requisito do ansible-lint.
- **`changed_when:` obrigatório** em tasks `command`/`shell`.
- **`become: true`** e global em `ansible.cfg` -- nao repetir por task.
- **Validar em multi-distribuição**: testar em pelo menos uma RedHat e uma Debian.
- **Lint antes de commitar**: `ansible-lint container.yml`.

### Pull Requests

- Descreva a mudanca no titulo e corpo do PR.
- Inclua o resultado do `molecule converge` (ou `molecule test` se possivel).
- PRs sem erros de lint e com testes passando serao revisados com prioridade.

---

## Licença

Este projeto e distribuido sob a licença **Apache License 2.0**.

---

## Contato

- **Issues**: Abra uma issue no repositorio do projeto.
- **Email**: marcus.cabrera@gmail.com

---

## Roadmap

- [ ] Integracao com Grafana Loki/Elasticsearch para logs de containers.
- [ ] Drivers de storage customizaveis (overlay2 parametrizado).
- [ ] Podman rootless opcional para maior seguranca.
- [ ] Suporte a Kubernetes local (K3s / MicroK8s).
- [ ] Pipeline CI/CD com GitHub Actions (lint + molecule test).
- [ ] Remover `host_key_checking = False` para ambientes produtivos.
