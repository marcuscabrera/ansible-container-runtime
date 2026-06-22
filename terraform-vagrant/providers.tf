# Configuração do Provedor Terraform para Vagrant
# Define o provider bmatcuk/vagrant para orquestração local de máquinas virtuais.

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    vagrant = {
      source  = "bmatcuk/vagrant"
      version = "~> 4.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

# Declaração do provider sem configurações adicionais, conforme especificação.
provider "vagrant" {}
