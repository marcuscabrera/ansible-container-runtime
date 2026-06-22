#!/bin/bash

# Remove pacotes antigos conflitantes
sudo dnf remove -y docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine || true

# Instala utilitários necessários
sudo dnf install -y dnf-plugins-core

# Adiciona repositório oficial do Docker (CentOS/RHEL)
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Instala o Docker Engine e componentes
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Pós-instalação: ativa e inicia os serviços
sudo systemctl enable --now docker
sudo systemctl enable --now containerd

# Adiciona usuário ao grupo docker
sudo usermod -aG docker $USER

# Testa a instalação
docker run hello-world

echo "Docker instalado com sucesso! Faça logout/login ou execute 'newgrp docker' para aplicar as permissões do grupo."