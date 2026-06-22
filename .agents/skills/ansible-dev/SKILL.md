---
name: ansible-dev
description: Especialista em Ansible para automação de infraestrutura, configuração de servidores, deploy de aplicações e gerenciamento de configuração. Use quando trabalhar com playbooks, roles, inventários, templates Jinja2, módulos Ansible ou estruturação de projetos Ansible.
---

# Ansible Developer Skill

Guia completo para desenvolvimento profissional com Ansible, cobrindo desde playbooks simples até arquiteturas complexas com roles e collections.

## When to Use This Skill

Use esta skill quando:
- Criar ou modificar playbooks Ansible
- Estruturar projetos Ansible escaláveis
- Trabalhar com roles e collections
- Escrever templates Jinja2
- Configurar inventários dinâmicos
- Debuggar problemas em execuções
- Implementar boas práticas de automação

## Estrutura de Projeto Ansible

```
project/
├── ansible.cfg              # Configuração do Ansible
├── inventory/
│   ├── production/          # Inventário de produção
│   │   ├── hosts.yml        # Definição de hosts e grupos
│   │   ├── group_vars/      # Variáveis por grupo
│   │   │   ├── all.yml
│   │   │   └── webservers.yml
│   │   └── host_vars/       # Variáveis por host
│   │       └── server01.yml
│   └── staging/
│       └── ...
├── playbooks/
│   ├── site.yml             # Playbook principal
│   ├── deploy.yml           # Deploy de aplicação
│   └── setup.yml            # Setup inicial
├── roles/
│   ├── common/              # Role de configurações base
│   │   ├── tasks/
│   │   ├── handlers/
│   │   ├── templates/
│   │   ├── files/
│   │   ├── vars/
│   │   ├── defaults/
│   │   ├── meta/
│   │   └── README.md
│   └── webserver/
│       └── ...
├── collections/
│   └── requirements.yml     # Collections externas
├── filter_plugins/          # Filtros customizados
├── callback_plugins/        # Callbacks customizados
├── group_vars/              # Variáveis globais (alternativa)
├── host_vars/               # Variáveis de host (alternativa)
└── vault/                   # Arquivos criptografados
    └── secrets.yml
```

### ansible.cfg Recomendado

```ini
[defaults]
inventory = inventory/production/hosts.yml
remote_user = ansible
private_key_file = ~/.ssh/ansible_rsa
host_key_checking = False
retry_files_enabled = False
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts_cache
fact_caching_timeout = 3600
stdout_callback = yaml
callback_whitelist = profile_tasks, timer
bin_ansible_callbacks = True
interpreter_python = auto_silent
roles_path = ./roles:/usr/share/ansible/roles
nocows = 1

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
pipelining = True
control_path = /tmp/ansible-ssh-%%h-%%p-%%r
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
```

## Playbooks

### Estrutura Básica

```yaml
---
- name: Configurar servidores web
  hosts: webservers
  become: true
  gather_facts: true
  
  vars:
    http_port: 80
    max_clients: 200
    
  vars_files:
    - vars/common.yml
    
  pre_tasks:
    - name: Verificar conectividade
      ansible.builtin.ping:
      
  roles:
    - role: common
    - role: nginx
      vars:
        nginx_worker_processes: 4
        
  tasks:
    - name: Instalar pacotes
      ansible.builtin.apt:
        name:
          - curl
          - vim
          - htop
        state: present
        update_cache: true
      tags: packages
      
    - name: Configurar firewall
      ansible.builtin.ufw:
        rule: allow
        port: "{{ http_port }}"
        proto: tcp
      notify: restart ufw
      
  post_tasks:
    - name: Verificar serviço
      ansible.builtin.uri:
        url: "http://localhost:{{ http_port }}"
        status_code: 200
      
  handlers:
    - name: restart ufw
      ansible.builtin.service:
        name: ufw
        state: restarted
```

### Playbook de Deploy

```yaml
---
- name: Deploy da aplicação
  hosts: app_servers
  become: true
  serial: "25%"  # Rolling deploy
  max_fail_percentage: 30
  
  vars:
    app_version: "{{ deploy_version | default('latest') }}"
    app_path: /opt/myapp
    backup_path: /opt/backups
    
  tasks:
    - name: Registrar timestamp do deploy
      ansible.builtin.set_fact:
        deploy_timestamp: "{{ ansible_date_time.iso8601 }}"
        
    - name: Criar backup
      ansible.builtin.archive:
        path: "{{ app_path }}"
        dest: "{{ backup_path }}/myapp-{{ deploy_timestamp }}.tar.gz"
      when: backup_before_deploy | default(true)
      tags: backup
      
    - name: Baixar nova versão
      ansible.builtin.get_url:
        url: "https://artifacts.example.com/myapp-{{ app_version }}.tar.gz"
        dest: /tmp/myapp-{{ app_version }}.tar.gz
        mode: '0644'
      
    - name: Parar serviço
      ansible.builtin.systemd:
        name: myapp
        state: stopped
      
    - name: Extrair aplicação
      ansible.builtin.unarchive:
        src: /tmp/myapp-{{ app_version }}.tar.gz
        dest: "{{ app_path }}"
        remote_src: true
        owner: app
        group: app
      
    - name: Instalar dependências
      ansible.builtin.pip:
        requirements: "{{ app_path }}/requirements.txt"
        virtualenv: "{{ app_path }}/venv"
      
    - name: Executar migrações
      ansible.builtin.command:
        cmd: "{{ app_path }}/venv/bin/python manage.py migrate"
        chdir: "{{ app_path }}"
      when: run_migrations | default(false)
      
    - name: Iniciar serviço
      ansible.builtin.systemd:
        name: myapp
        state: started
        enabled: true
        daemon_reload: true
      
    - name: Verificar health check
      ansible.builtin.uri:
        url: "http://localhost:8080/health"
        status_code: 200
      register: health_check
      retries: 5
      delay: 10
      until: health_check.status == 200
```

## Roles

### Estrutura Completa

```
roles/myrole/
├── defaults/main.yml      # Variáveis padrão (menor precedência)
├── vars/main.yml          # Variáveis da role (alta precedência)
├── tasks/main.yml         # Tasks principais
├── tasks/install.yml      # Tasks de instalação
├── tasks/configure.yml    # Tasks de configuração
├── handlers/main.yml      # Handlers
├── templates/             # Templates Jinja2
│   ├── nginx.conf.j2
│   └── app.service.j2
├── files/                 # Arquivos estáticos
│   └── script.sh
├── meta/main.yml          # Dependências e metadata
├── molecule/              # Testes
│   └── default/
│       ├── converge.yml
│       ├── molecule.yml
│       └── verify.yml
├── README.md              # Documentação
└── .travis.yml            # CI
```

### meta/main.yml

```yaml
---
galaxy_info:
  role_name: nginx
  namespace: mycompany
  author: Nome do Autor
  description: Instala e configura o Nginx
  company: Minha Empresa
  license: MIT
  min_ansible_version: "2.14"
  
  platforms:
    - name: Ubuntu
      versions:
        - jammy
        - focal
    - name: EL
      versions:
        - "9"
        - "8"
        
  galaxy_tags:
    - web
    - nginx
    - proxy
    
dependencies:
  - role: common
    vars:
      common_required_packages:
        - ca-certificates
        - openssl
```

### tasks/main.yml com Includes Condicionais

```yaml
---
- name: Incluir variáveis específicas do OS
  ansible.builtin.include_vars: "{{ item }}"
  with_first_found:
    - "{{ ansible_distribution }}-{{ ansible_distribution_version }}.yml"
    - "{{ ansible_distribution }}.yml"
    - "{{ ansible_os_family }}.yml"
    - default.yml
  tags: always

- name: Incluir tasks de instalação
  ansible.builtin.include_tasks: install.yml
  when: nginx_install | default(true)
  tags: install

- name: Incluir tasks de configuração
  ansible.builtin.include_tasks: configure.yml
  tags: configure

- name: Incluir tasks de SSL
  ansible.builtin.include_tasks: ssl.yml
  when: nginx_ssl_enabled | default(false)
  tags: ssl
```

## Inventários

### Inventário YAML (Recomendado)

```yaml
---
all:
  children:
    webservers:
      hosts:
        web01.example.com:
          ansible_host: 192.168.1.10
          nginx_worker_processes: 8
        web02.example.com:
          ansible_host: 192.168.1.11
      vars:
        http_port: 80
        https_port: 443
        
    databases:
      hosts:
        db01.example.com:
          ansible_host: 192.168.1.20
          postgres_version: "15"
        db02.example.com:
          ansible_host: 192.168.1.21
          postgres_version: "15"
          postgres_replica: true
          postgres_primary: db01.example.com
          
    loadbalancers:
      hosts:
        lb01.example.com:
          ansible_host: 192.168.1.5
          haproxy_frontend_port: 80
          
  vars:
    ansible_user: ansible
    ansible_ssh_private_key_file: ~/.ssh/ansible_rsa
    ansible_python_interpreter: /usr/bin/python3
    datacenter: dc1
    environment: production
```

### Inventário Dinâmico (AWS)

```yaml
---
plugin: amazon.aws.aws_ec2
regions:
  - us-east-1
  - us-west-2
  
filters:
  instance-state-name: running
  tag:Environment: production
  
keyed_groups:
  - key: tags.Role
    prefix: role
  - key: tags.Environment
    prefix: env
  - key: instance_type
    prefix: type
  
hostnames:
  - tag:Name
  - private-ip-address
  
compose:
  ansible_host: public_ip_address | default(private_ip_address)
  ansible_user: "'ec2-user' if 'amazon' in image_id else 'ubuntu'"
```

## Variáveis

### Hierarquia de Precedência (da menor para maior)

1. defaults/main.yml em roles
2. Inventory group_vars/all
3. Inventory group_vars/* 
4. Inventory host_vars/*
5. Playbook group_vars/all
6. Playbook group_vars/*
7. Playbook host_vars/*
8. Host facts / cached set_facts
9. Play vars
10. Play vars_prompt
11. Play vars_files
12. Role vars (vars/main.yml)
13. Block vars
14. Task vars
15. Extra vars (-e na linha de comando) - MAIOR PRECEDÊNCIA

### Boas Práticas com Variáveis

```yaml
# defaults/main.yml - sempre definir valores padrão seguros
nginx_install: true
nginx_version: ""
nginx_worker_processes: "{{ ansible_processor_vcpus | default(1) }}"
nginx_worker_connections: 4096
nginx_user: "{{ 'www-data' if ansible_os_family == 'Debian' else 'nginx' }}"
nginx_sites:
  - name: default
    template: default.conf.j2
    server_name: _
    listen: 80
    root: /var/www/html

# vars/main.yml - valores que não devem ser sobrescritos
nginx_required_packages:
  Debian:
    - nginx-full
    - ssl-cert
  RedHat:
    - nginx
    - openssl
    
nginx_config_path: "/etc/nginx"
nginx_sites_path: "{{ nginx_config_path }}/sites-enabled"
```

### Variáveis Criptografadas com Vault

```bash
# Criar arquivo criptografado
ansible-vault create group_vars/all/vault.yml

# Editar arquivo criptografado
ansible-vault edit group_vars/all/vault.yml

# Criptografar arquivo existente
ansible-vault encrypt group_vars/all/secrets.yml

# Descriptografar
ansible-vault decrypt group_vars/all/secrets.yml

# Executar com vault
ansible-playbook -i inventory/production site.yml --ask-vault-pass
ansible-playbook -i inventory/production site.yml --vault-password-file ~/.vault_pass
```

```yaml
# group_vars/all/vault.yml (criptografado)
vault_database_password: "senha_super_secreta"
vault_api_key: "sk-abc123xyz"
vault_ssh_private_key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  ...
  -----END OPENSSH PRIVATE KEY-----

# group_vars/all/database.yml (não criptografado)
database_password: "{{ vault_database_password }}"
```

## Templates Jinja2

### Template Nginx

```jinja2
# {{ ansible_managed }}
user {{ nginx_user }};
worker_processes {{ nginx_worker_processes }};
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections {{ nginx_worker_connections }};
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;

    # Gzip
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml application/json 
               application/javascript application/rss+xml 
               application/atom+xml image/svg+xml;

    # Rate limiting
    {% if nginx_rate_limit_enabled %}
    limit_req_zone $binary_remote_addr zone=default:10m rate={{ nginx_rate_limit }};
    {% endif %}

    # Include sites
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
```

### Template Systemd

```jinja2
# {{ ansible_managed }}
[Unit]
Description={{ app_name }} Application
After=network.target {{ app_dependencies | join(' ') }}
Wants=network.target

[Service]
Type=simple
User={{ app_user }}
Group={{ app_group }}
WorkingDirectory={{ app_path }}
Environment="PATH={{ app_path }}/venv/bin:/usr/local/bin:/usr/bin:/bin"
{% for env in app_environment %}
Environment="{{ env.key }}={{ env.value }}"
{% endfor %}
EnvironmentFile=-/etc/default/{{ app_name }}

ExecStart={{ app_path }}/venv/bin/gunicorn \
    --bind {{ app_bind_address }}:{{ app_port }} \
    --workers {{ app_workers }} \
    --worker-class uvicorn.workers.UvicornWorker \
    --access-logfile - \
    --error-logfile - \
    --capture-output \
    --enable-stdio-inheritance \
    {{ app_module }}

ExecReload=/bin/kill -s HUP $MAINPID
KillMode=mixed
TimeoutStopSec=30
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

## Handlers

### Boas Práticas

```yaml
---
# handlers/main.yml
- name: restart nginx
  ansible.builtin.service:
    name: nginx
    state: restarted
  listen: restart webserver
  
- name: reload nginx
  ansible.builtin.service:
    name: nginx
    state: reloaded
  listen: reload webserver
  
- name: validate nginx config
  ansible.builtin.command: nginx -t
  changed_when: false
  listen: validate nginx

# Uso em tasks
- name: Configurar nginx
  ansible.builtin.template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    validate: nginx -t -c %s
  notify:
    - validate nginx
    - reload nginx
```

## Módulos Comuns

### Sistema e Pacotes

```yaml
# apt/yum/dnf - Gerenciamento de pacotes
- name: Instalar pacotes
  ansible.builtin.apt:
    name:
      - nginx
      - postgresql
    state: present
    update_cache: true
    cache_valid_time: 3600

# service/systemd - Controle de serviços
- name: Garantir serviço em execução
  ansible.builtin.systemd:
    name: nginx
    state: started
    enabled: true
    daemon_reload: true

# user/group - Gerenciamento de usuários
- name: Criar usuário de aplicação
  ansible.builtin.user:
    name: myapp
    uid: 1500
    groups: docker,www-data
    append: true
    shell: /bin/bash
    home: /opt/myapp
    system: true
    create_home: true
```

### Arquivos e Templates

```yaml
# template - Templates Jinja2
- name: Configurar aplicação
  ansible.builtin.template:
    src: app.config.j2
    dest: /etc/myapp/config.yml
    owner: myapp
    group: myapp
    mode: '0640'
    validate: myapp --validate-config %s
    backup: true
  notify: restart myapp

# copy - Arquivos estáticos
- name: Copiar script
  ansible.builtin.copy:
    src: scripts/backup.sh
    dest: /usr/local/bin/backup.sh
    owner: root
    group: root
    mode: '0755'

# file - Gerenciamento de arquivos/diretórios
- name: Criar diretório de logs
  ansible.builtin.file:
    path: /var/log/myapp
    state: directory
    owner: myapp
    group: myapp
    mode: '0750'

# lineinfile/blockinfile - Edição de arquivos
- name: Configurar sysctl
  ansible.builtin.sysctl:
    name: net.ipv4.ip_forward
    value: '1'
    sysctl_set: true
    state: present
    reload: true
```

### Networking

```yaml
# ufw/firewalld - Firewall
- name: Configurar firewall
  ansible.builtin.ufw:
    rule: allow
    port: "{{ item }}"
    proto: tcp
  loop:
    - "22"
    - "80"
    - "443"

# uri - Requisições HTTP
- name: Verificar endpoint
  ansible.builtin.uri:
    url: "https://api.example.com/health"
    method: GET
    status_code: 200
    headers:
      Authorization: "Bearer {{ api_token }}"
    return_content: true
  register: health_response
```

### Cloud e Contêineres

```yaml
# docker_container - Gerenciar contêineres
- name: Executar contêiner Redis
  community.docker.docker_container:
    name: redis
    image: redis:7-alpine
    state: started
    restart_policy: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    env:
      REDIS_PASSWORD: "{{ redis_password }}"

# k8s - Kubernetes
- name: Aplicar manifesto
  kubernetes.core.k8s:
    state: present
    definition:
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: myapp
        namespace: production
      spec:
        replicas: 3
        selector:
          matchLabels:
            app: myapp
        template:
          metadata:
            labels:
              app: myapp
          spec:
            containers:
              - name: myapp
                image: "myapp:{{ app_version }}"
```

## Debugging e Troubleshooting

### Estratégias de Debug

```yaml
- name: Debug - Mostrar todas as variáveis
  ansible.builtin.debug:
    var: ansible_facts
    
- name: Debug - Mensagem formatada
  ansible.builtin.debug:
    msg: "Instalando {{ item }} na versão {{ package_versions[item] }}"
  loop: "{{ packages_to_install }}"
  
- name: Debug - Somente quando verboso
  ansible.builtin.debug:
    msg: "Valor de config: {{ config_value }}"
    verbosity: 2

# Registrar saída de comandos
- name: Verificar espaço em disco
  ansible.builtin.command: df -h
  register: disk_space
  changed_when: false

- name: Mostrar resultado
  ansible.builtin.debug:
    var: disk_space.stdout_lines
```

### Execução com Debug

```bash
# Verbose modes
ansible-playbook site.yml -v      # Mais detalhes
ansible-playbook site.yml -vv     # Tasks e resultados
ansible-playbook site.yml -vvv    # Conexões SSH
ansible-playbook site.yml -vvvv   # Debug completo

# Dry run (check mode)
ansible-playbook site.yml --check --diff

# Limitar hosts
ansible-playbook site.yml --limit webservers
ansible-playbook site.yml --limit 'web01.example.com'

# Start at task
ansible-playbook site.yml --start-at-task "Configurar nginx"

# Tags
ansible-playbook site.yml --tags install,configure
ansible-playbook site.yml --skip-tags backup

# Step-by-step
ansible-playbook site.yml --step
```

## Error Handling

```yaml
- name: Task que pode falhar
  ansible.builtin.command: /opt/scripts/optional.sh
  register: script_result
  failed_when: script_result.rc != 0 and script_result.rc != 2
  changed_when: "'changed' in script_result.stdout"
  ignore_errors: "{{ ignore_optional_errors | default(false) }}"
  
- name: Block with rescue
  block:
    - name: Tentar operação arriscada
      ansible.builtin.command: /opt/risky.sh
      
    - name: Continuar se sucesso
      ansible.builtin.debug:
        msg: "Operação bem-sucedida"
        
  rescue:
    - name: Executar em caso de falha
      ansible.builtin.debug:
        msg: "Falha detectada, executando cleanup"
        
    - name: Cleanup
      ansible.builtin.file:
        path: /tmp/partial_data
        state: absent
        
  always:
    - name: Sempre executar
      ansible.builtin.debug:
        msg: "Bloco finalizado"
```

## Loops e Condições

```yaml
# Loop simples
- name: Criar usuários
  ansible.builtin.user:
    name: "{{ item.name }}"
    groups: "{{ item.groups }}"
    state: present
  loop:
    - { name: 'alice', groups: 'developers' }
    - { name: 'bob', groups: 'ops' }

# Loop sobre dict
- name: Configurar variáveis de ambiente
  ansible.builtin.lineinfile:
    path: /etc/environment
    line: "{{ item.key }}={{ item.value }}"
  loop: "{{ app_environment | dict2items }}"

# Loop com until (retry)
- name: Aguardar serviço
  ansible.builtin.uri:
    url: http://localhost:8080/health
  register: result
  until: result.status == 200
  retries: 10
  delay: 5

# Condições
- name: Instalar apenas no Debian
  ansible.builtin.apt:
    name: htop
  when: ansible_os_family == 'Debian'

- name: Múltiplas condições
  ansible.builtin.debug:
    msg: "Configurar SSL"
  when:
    - ssl_enabled | default(false)
    - ansible_distribution_major_version | int >= 20
    - inventory_hostname in groups['webservers']
```

## Testes com Molecule

```yaml
# molecule/default/molecule.yml
---
driver:
  name: docker

platforms:
  - name: instance-ubuntu-2204
    image: ubuntu:22.04
    command: /lib/systemd/systemd
    privileged: true
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
    
  - name: instance-rocky-9
    image: rockylinux:9
    command: /lib/systemd/systemd
    privileged: true
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro

provisioner:
  name: ansible
  lint:
    name: ansible-lint
  inventory:
    group_vars:
      all:
        nginx_ssl_enabled: false

verifier:
  name: ansible

lint: |
  set -e
  yamllint .
  ansible-lint
```

```yaml
# molecule/default/converge.yml
---
- name: Converge
  hosts: all
  become: true
  roles:
    - role: nginx
```

```yaml
# molecule/default/verify.yml
---
- name: Verify
  hosts: all
  gather_facts: false
  tasks:
    - name: Verificar se nginx está instalado
      ansible.builtin.command: nginx -v
      changed_when: false
      
    - name: Verificar se serviço está rodando
      ansible.builtin.service:
        name: nginx
        state: started
      check_mode: true
      register: service_status
      failed_when: service_status.changed
      
    - name: Testar requisição HTTP
      ansible.builtin.uri:
        url: http://localhost
        status_code: 200
      register: http_response
      
    - name: Verificar configuração
      ansible.builtin.assert:
        that:
          - http_response.status == 200
```

## Comandos Úteis

```bash
# Inventário
ansible-inventory -i inventory/production --list
ansible-inventory -i inventory/production --graph
ansible-inventory -i inventory/production --host web01.example.com

# Facts
cat ~/.ansible/facts_cache/web01.example.com

# Ansible-lint
ansible-lint playbooks/
ansible-lint --fix playbooks/

# Syntax check
ansible-playbook --syntax-check site.yml

# Galaxy
cd roles
ansible-galaxy role init myrole
ansible-galaxy role install geerlingguy.nginx

# Collections
ansible-galaxy collection install community.docker
ansible-galaxy collection install -r collections/requirements.yml
```

## Referências

- [Documentação Oficial Ansible](https://docs.ansible.com/)
- [Ansible Galaxy](https://galaxy.ansible.com/)
- [Ansible Lint](https://ansible-lint.readthedocs.io/)
- [Molecule](https://molecule.readthedocs.io/)
- [Jinja2 Templates](https://jinja.palletsprojects.com/)
