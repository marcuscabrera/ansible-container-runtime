# Provisionamento Local (Rocky Linux 9) com Terraform & Vagrant

Este diretório contém a infraestrutura como código (IaC) para provisionar uma máquina virtual rodando **Rocky Linux 9** em seu ambiente de desenvolvimento local. A solução utiliza o Terraform em conjunto com o provider `bmatcuk/vagrant` para gerenciar o ciclo de vida do Vagrant de forma declarativa.

---

## 🛠️ Pré-requisitos

Antes de iniciar, certifique-se de ter as seguintes ferramentas instaladas em seu sistema:

1. **[Terraform](https://www.terraform.io/downloads)** (versão `>= 1.3.0`)
2. **[Vagrant](https://www.vagrantup.com/downloads)**
3. **[VirtualBox](https://www.virtualbox.org/wiki/Downloads)** (ou outro hypervisor compatível com o Vagrant)

---

## 📁 Estrutura do Diretório

* **[providers.tf](file:///c:/Tools/Code/neogrid-smtprelay/vagrant/providers.tf)**: Declaração dos provedores requeridos (`bmatcuk/vagrant` e `hashicorp/local`).
* **[variables.tf](file:///c:/Tools/Code/neogrid-smtprelay/vagrant/variables.tf)**: Definição de variáveis parametrizáveis para customizar recursos da máquina virtual (CPU, memória, IP, etc).
* **[terraform.tfvars](file:///c:/Tools/Code/neogrid-smtprelay/vagrant/terraform.tfvars)**: Valores customizados das variáveis para o ambiente local.
* **[main.tf](file:///c:/Tools/Code/neogrid-smtprelay/vagrant/main.tf)**: Código principal contendo a lógica de renderização dinâmica do `Vagrantfile` e declaração da VM.
* **[Vagrantfile.tpl](file:///c:/Tools/Code/neogrid-smtprelay/vagrant/Vagrantfile.tpl)**: Template base em Ruby para a geração dinâmica do `Vagrantfile`.
* **[outputs.tf](file:///c:/Tools/Code/neogrid-smtprelay/vagrant/outputs.tf)**: Saídas de informações pós-provisionamento.

---

## 🚀 Como Executar

Abra o terminal neste diretório e siga os passos abaixo:

## Pré-execução
Verifique se você tem as chaves SSH necessárias no diretório local:
```bash
ls -la id_rsa*
```
Caso contrário, gere as chaves:
```bash
ssh-keygen -t rsa -b 4096 -C "[EMAIL_ADDRESS]" -f "id_rsa" -N ""
```

### 1. Inicializar o Terraform
Baixe os providers necessários:
```bash
terraform init
```

### 2. Validar a Configuração
Verifique se a sintaxe e a semântica dos arquivos estão corretas:
```bash
terraform validate
```

### 3. Executar o Planejamento
Visualize as alterações que serão realizadas:
```bash
terraform plan
```

### 4. Aplicar e Iniciar a VM
Inicie o processo de criação da VM Rocky Linux 9:
```bash
terraform apply -auto-approve
```
*Este comando gerará o arquivo `Vagrantfile` dinamicamente no disco, executará o `vagrant up` e disparará o provisionamento automático do Ansible utilizando o playbook `smtp-proxy.yml`.*

### 5. Acessar a VM
Após a criação, conecte-se à VM local via SSH:
```bash
vagrant ssh
```

### 6. Destruir a VM
Quando não precisar mais da máquina, você pode removê-la completamente com:
```bash
terraform destroy -auto-approve
```

---

## 💡 Dinâmica de Atualização (Lifecycle)

Este projeto implementa uma boa prática crucial para integração Terraform-Vagrant:
* **Detecção de Alterações**: Como o Terraform não rastreia alterações estruturais dentro do `Vagrantfile` após a primeira execução, passamos um hash MD5 do conteúdo gerado no mapa `env` do recurso `vagrant_vm`:
  ```hcl
  env = {
    VAGRANTFILE_HASH = md5(local_file.vagrantfile.content)
  }
  ```
  Isso garante que, caso você altere o template `Vagrantfile.tpl` ou altere alguma variável (como memória ou CPU), o Terraform detectará a diferença de hash e atualizará/recriará a VM conforme necessário.
