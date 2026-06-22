#!/bin/bash

# Atualiza índices e instala o Podman e utilitários de compatibilidade
echo "Instalando Podman, Podman Compose e ferramentas de compatibilidade..."
sudo dnf install -y podman podman-docker podman-compose

# Habilita o socket do Podman (caso precise de compatibilidade com a API do Docker)
echo "Ativando e iniciando o socket do Podman..."
sudo systemctl enable --now podman.socket

# Permite que usuários executem containers rootless sem restrições de rede/portas baixas
# (Opcional, mas recomendado para desenvolvimento)
# sudo sysctl net.ipv4.ip_unprivileged_port_start=80

# Testa a instalação executando um container rootless de teste
echo "Testando a instalação do Podman..."
podman run --rm hello-world

echo "Podman instalado com sucesso!"
echo "Você pode usar comandos 'docker' normalmente se o pacote 'podman-docker' estiver ativo."
