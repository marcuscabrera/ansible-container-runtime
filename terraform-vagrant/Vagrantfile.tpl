# -*- mode: ruby -*-
# vi: set ft=ruby :

# Template do Vagrantfile parametrizado pelo Terraform
# Este arquivo é renderizado dinamicamente substituindo as variáveis fornecidas.

Vagrant.configure("2") do |config|
  # Configuração básica da Box e Hostname
  config.vm.box = "${box_name}"
  config.vm.hostname = "${vm_name}"

  # Configuração para login com a chave id_rsa privada
  ssh_keys = [
    File.expand_path("../id_rsa", __FILE__),
    "~/.ssh/id_rsa",
    "~/.vagrant.d/insecure_private_key"
  ]
  config.ssh.private_key_path = ssh_keys.select { |p| File.exist?(File.expand_path(p)) }
  config.ssh.insert_key = false

  # Configuração de rede Host-Only com IP Estático
  config.vm.network "private_network", ip: "${ip_address}"

  # Customização específica para o VirtualBox
  config.vm.provider "virtualbox" do |vb|
    vb.name = "${vm_name}"
    vb.memory = ${memory}
    vb.cpus = ${vcpu}
    
    # Melhora o desempenho desabilitando áudio e outros periféricos não usados em servidores
    vb.customize ["modifyvm", :id, "--audio", "none"]
    vb.customize ["modifyvm", :id, "--usb", "off"]
  end

  # Script de provisionamento opcional via Shell (exemplo Rocky Linux 9)
  config.vm.provision "shell", inline: <<-SHELL
    echo "[PROVISIONING] Iniciando provisionamento do Rocky Linux 9..."
    
    # Atualiza pacotes instalados excluindo kernel para acelerar o processo local
    dnf update -y --exclude=kernel*
    
    # Instala utilitários básicos e úteis
    dnf install -y curl wget bind-utils net-tools git vim
    
    # Garante a criação do diretório .ssh e adiciona a chave pública autorizada
    mkdir -p /home/vagrant/.ssh
    if ! grep -qFx "${ssh_public_key}" /home/vagrant/.ssh/authorized_keys; then
      echo "${ssh_public_key}" >> /home/vagrant/.ssh/authorized_keys
      chmod 700 /home/vagrant/.ssh
      chmod 600 /home/vagrant/.ssh/authorized_keys
      chown -R vagrant:vagrant /home/vagrant/.ssh
    fi

    echo "[PROVISIONING] Rocky Linux 9 configurado e pronto para uso!"
  SHELL

  # Provisionamento com Ansible
  # --------------------------------------------------------------------------
  # Opção 1: Executado no Host (Recomendado se usando WSL, Linux ou macOS)
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "../container.yml"
    ansible.groups = {
      "local" => ["${vm_name}"]
    }
    ansible.compatibility_mode = "2.0"
  end

  # Opção 2: Executado no Guest VM (Útil se o Host for Windows puro sem WSL/Ansible)
  # Para usar esta opção, comente a Opção 1 acima e descomente as linhas abaixo.
  # Nota: Requer compartilhar a pasta 'ansible' para que o Guest tenha acesso aos playbooks.
  # config.vm.synced_folder "../ansible", "/vagrant/ansible"
  # config.vm.provision "ansible_local" do |ansible|
  #   ansible.playbook = "/vagrant/ansible/smtp-proxy.yml"
  #   ansible.groups = {
  #     "dev" => ["${vm_name}"]
  #   }
  #   ansible.compatibility_mode = "2.0"
  # end
end

