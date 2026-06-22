# Definição de Outputs do Terraform
# Exibe informações úteis após a conclusão do provisionamento da infraestrutura.

output "vagrant_vm_id" {
  value       = vagrant_vm.rocky_vm.id
  description = "O ID interno do recurso vagrant_vm gerenciado pelo Terraform."
}

output "machine_names" {
  value       = vagrant_vm.rocky_vm.machine_names
  description = "Lista com os nomes das máquinas virtuais declaradas no Vagrantfile."
}

output "ssh_instructions" {
  value       = "Para acessar a VM de forma interativa, abra o terminal na pasta 'vagrant' e digite: vagrant ssh"
  description = "Mensagem com instruções para acesso SSH local."
}
