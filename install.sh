#!/bin/bash
set -e
sudo -v || { echo "❌ Se requieren privilegios de administrador."; exit 1; }

echo "🚀 Iniciando instalación automática de Debian Trixie..."

# Verificar conectividad
if ! curl -fsI https://deb.debian.org >/dev/null 2?&1; then
  echo "❌ No hay conectividad con deb.debian.org"
  echo "Por favor verifica tu conexion a Internet"
  exit 1
else
  echo "Connectividad confirmada con deb.debian.org."
fi

# Instalar Ansible si no está
if ! command -v ansible >/dev/null 2>&1; then
  echo "🧩 Instalando Ansible..."
  sudo apt update -y && sudo apt install -y ansible
fi

# Ejecutar roles en orden
echo "📦 Instalando prerequisitos..."
sudo ansible-playbook roles/prereqs/main.yml

echo "⚙️ Instalando Ansible si falta..."
sudo ansible-playbook roles/ansible_install/main.yml

echo "🎨 Copiando dotfiles y fondos..."
sudo ansible-playbook roles/clone_dotfiles/main.yml

echo "🧰 Preparando entorno base..."
sudo ansible-playbook roles/window_managers/main.yml

echo "🔄 Actualizando sistema..."
bash usr_local_bin/update-system.sh

echo "✅ Instalación completada"
