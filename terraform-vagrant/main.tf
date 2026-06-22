# Arquivo Principal do Terraform (main.tf)
# Este arquivo gerencia o ciclo de vida do Vagrantfile gerado dinamicamente e da VM.

# 1. Geração dinâmica do arquivo Vagrantfile a partir de um template.
# O uso de local_file garante que qualquer alteração nas variáveis ou no template
# resulte na re-renderização do Vagrantfile físico no disco.
resource "local_file" "vagrantfile" {
  filename = "${path.module}/Vagrantfile"
  content  = templatefile("${path.module}/Vagrantfile.tpl", {
    box_name       = var.box_name
    vcpu           = var.vcpu
    memory         = var.memory
    ip_address     = var.ip_address
    vm_name        = var.vm_name
    ssh_public_key = trimspace(file("${path.module}/id_rsa.pub"))
  })
}

# 2. Provisionamento e controle da máquina virtual pelo Vagrant.
#
# Dinâmica IMPORTANTE baseada na documentação do provider bmatcuk/vagrant:
# - Como o Terraform não monitora nativamente o conteúdo do arquivo físico Vagrantfile
#   para decidir se precisa atualizar/recriar a máquina, passamos o hash MD5 do
#   conteúdo do Vagrantfile através do mapa 'env'.
# - Quando o Vagrantfile é alterado, o hash MD5 muda, informando ao Terraform que a
#   VM precisa ser atualizada (ou destruída/recriada/recarregada dependendo das regras).
# - O bloco 'depends_on' é crucial aqui para evitar condições de corrida (race conditions).
#   Garante que o Terraform primeiro grave o arquivo Vagrantfile no disco através do
#   recurso 'local_file.vagrantfile' antes de tentar executar os comandos do Vagrant
#   (vagrant up / vagrant status).
resource "vagrant_vm" "rocky_vm" {
  vagrantfile_dir = path.module

  # O hash MD5 força o Terraform a detectar alterações no template do Vagrantfile
  env = {
    VAGRANTFILE_HASH = md5(local_file.vagrantfile.content)
  }

  # Garante a ordem de execução correta
  depends_on = [
    local_file.vagrantfile
  ]
}
