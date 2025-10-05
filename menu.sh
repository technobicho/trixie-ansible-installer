#!/usr/bin/env bash
# menu.sh - Instalador de entornos WM con Ansible (versión Debian segura)
# Autor: ChatGPT (revisión 2025)
# Compatible con Debian 12/13 y derivados

set -e

# --- Colores ---
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RESET="\033[0m"

# --- Función log ---
log() { echo -e "${GREEN}[INFO]${RESET} $1"; }
warn() { echo -e "${YELLOW}[WARN]${RESET} $1"; }
error() { echo -e "${RED}[ERROR]${RESET} $1"; }

# --- Verificar sudo ---
if ! sudo -v >/dev/null 2>&1; then
  error "Este script requiere privilegios de sudo."
  exit 1
fi

# --- Instalar dependencias básicas ---
log "Verificando dependencias básicas..."
sudo apt update -y
sudo apt install -y dialog git curl python3 python3-apt python3-pip

# --- Verificar instalación de Ansible ---
if ! command -v ansible >/dev/null 2>&1; then
  log "Ansible no está instalado. Instalando mediante APT..."
  if grep -qi "debian" /etc/os-release; then
    sudo apt install -y ansible
  elif grep -qi "ubuntu" /etc/os-release; then
    sudo apt install -y ansible
  else
    warn "Distribución no Debian/Ubuntu detectada. Intentando instalación genérica."
    python3 -m pip install --break-system-packages ansible
  fi
else
  log "Ansible ya está instalado."
fi

# --- Crear archivo temporal para variables ---
ANSIBLE_VARS_FILE=".ansible_vars.yml"

# --- Menú principal ---
menu_principal() {
  CHOICES=$(dialog --stdout --checklist "Selecciona los componentes a instalar:" 20 70 10 \
    1 "Instalar prerequisitos del sistema" ON \
    2 "Instalar gestores de ventanas (WM)" ON \
    3 "Instalar gestores de inicio (DM)" ON \
    4 "Instalar paquetes de software" ON \
    5 "Instalar aplicaciones extra" ON \
    6 "Clonar y configurar dotfiles (trixie-6-wm-en-1)" ON)

  echo "selected:" $CHOICES

  echo "---" > "$ANSIBLE_VARS_FILE"
  [[ $CHOICES =~ 1 ]] && echo "install_prereqs: true" >> "$ANSIBLE_VARS_FILE"
  [[ $CHOICES =~ 2 ]] && echo "install_wm: true" >> "$ANSIBLE_VARS_FILE"
  [[ $CHOICES =~ 3 ]] && echo "install_dm: true" >> "$ANSIBLE_VARS_FILE"
  [[ $CHOICES =~ 4 ]] && echo "install_sw: true" >> "$ANSIBLE_VARS_FILE"
  [[ $CHOICES =~ 5 ]] && echo "install_apps: true" >> "$ANSIBLE_VARS_FILE"
  [[ $CHOICES =~ 6 ]] && echo "clone_dotfiles: true" >> "$ANSIBLE_VARS_FILE"

  menu_modo
}

# --- Menú de ejecución local o remota ---
menu_modo() {
  MODE=$(dialog --stdout --menu "Selecciona modo de instalación:" 12 60 4 \
    1 "Localhost (máquina actual)" \
    2 "Remoto (hosts en inventory)")

  if [[ $MODE == "1" ]]; then
    ansible-playbook -i inventory playbook.yml --ask-become-pass -e @"$ANSIBLE_VARS_FILE"
  else
    LIMIT=$(dialog --stdout --inputbox "Introduce el nombre o grupo del host remoto (según inventory):" 8 60)
    ansible-playbook -i inventory playbook.yml --limit "$LIMIT" --ask-become-pass -e @"$ANSIBLE_VARS_FILE"
  fi
}

clear
log "=== Instalador de entornos de escritorio (Ansible) ==="
menu_principal
