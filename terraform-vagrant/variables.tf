# Definição de Variáveis para Customização da VM Rocky Linux 9

variable "box_name" {
  type        = string
  description = "Nome da Box do Vagrant (ex: generic/rocky9 ou rockylinux/9)"
  default     = "generic/rocky9"
}

variable "vcpu" {
  type        = number
  description = "Quantidade de vCPUs alocadas para a máquina virtual"
  default     = 2
}

variable "memory" {
  type        = number
  description = "Quantidade de memória RAM em megabytes (MB) para a máquina virtual"
  default     = 4096
}

variable "ip_address" {
  type        = string
  description = "Endereço IP privado estático na rede host-only (private_network) para a VM"
  default     = "192.168.56.10"
}

variable "vm_name" {
  type        = string
  description = "Nome identificador e hostname da máquina virtual"
  default     = "rocky9-relay"
}
