#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VARS_FILE="${SCRIPT_DIR}/.ansible_vars.yml"

ensure_dialog() {
  if ! command -v dialog >/dev/null 2>&1; then
    echo "Instalando dialog..."
    sudo apt-get update -y && sudo apt-get install -y dialog
  fi
}

ensure_ansible() {
  if ! command -v ansible-playbook >/dev/null 2>&1; then
    echo "Instalando ansible..."
    sudo apt-get update -y
    sudo apt-get install -y python3 python3-apt python3-pip -y
    sudo pip3 install ansible
  fi
}

ensure_dialog
ensure_ansible

WM_OPTIONS=(
  bspwm "BSPWM" off
  dwm "DWM" off
  i3 "I3" off
  qtile "Qtile" off
  openbox "Openbox" off
  sway "Sway" off
)

SOFT_OPTIONS=(
  minimo "Mínimo" off
  basico "Básico" off
  intermedio "Intermedio" off
  full "Full" off
)

APPS_OPTIONS=(
  scrcpy "scrcpy" off
  virt-manager "virt-manager" off
  flatpak "flatpak" off
  cockpit "cockpit" off
  nerdfonts-jbm "nerdfonts-jbm" off
  nerdfonts-all "nerdfonts-all" off
)

DM_OPTIONS=(
  lightdm "LightDM" off
  sddm "SDDM" off
  ly "ly (experimental)" off
)

TARGET_OPTIONS=(
  local "Localhost (run locally)" on
  remote "Remote (use inventory)" off
)

TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

WMS=$(dialog --title "Window Managers" --checklist "Seleccioná WMs (Espacio para marcar):" 20 78 10 "${WM_OPTIONS[@]}" 3>&1 1>&2 2>&3) || true
SOFT=$(dialog --title "Paquetes de Software" --radiolist "Seleccioná un Pack de Software:" 20 78 10 "${SOFT_OPTIONS[@]}" 3>&1 1>&2 2>&3) || true
APPS=$(dialog --title "Aplicaciones Adicionales" --checklist "Seleccioná Aplicaciones (Espacio para marcar):" 20 78 10 "${APPS_OPTIONS[@]}" 3>&1 1>&2 2>&3) || true
DM=$(dialog --title "Display Manager" --radiolist "Seleccioná Display Manager:" 20 78 10 "${DM_OPTIONS[@]}" 3>&1 1>&2 2>&3) || true
TARGET=$(dialog --title "Destino" --radiolist "Ejecutar local o remoto (inventory):" 10 60 2 "${TARGET_OPTIONS[@]}" 3>&1 1>&2 2>&3) || true

LIMIT="all"
if [[ "$TARGET" == *remote* ]]; then
  LIMIT=$(dialog --inputbox "Indica el inventory limit (ej: all, host1, grupo):" 8 60 "all" 3>&1 1>&2 2>&3) || true
fi

normalize() { echo "$1" | sed 's/"//g' | tr -d '\n' | sed 's/ /\n/g' | sed '/^$/d' | tr '\n' ' ' | sed 's/ $//'; }
WMS_N=$(normalize "$WMS")
APPS_N=$(normalize "$APPS")
DM_N=$(normalize "$DM")
SOFT_N=$(normalize "$SOFT")

cat > "$VARS_FILE" <<EOF
install_wms: [${WMS_N// /, }]
software_pack: "${SOFT_N}"
install_apps: [${APPS_N// /, }]
display_manager: "${DM_N}"
repo_gitlab: "https://gitlab.com/linux-en-casa/trixie-6-wm-en-1.git"
repo_wallpapers: "https://gitlab.com/linux-en-casa/wallpapers.git"
zig_version: "zig-x86_64-linux-0.15.1"
zig_url: "https://ziglang.org/download/0.15.1/zig-x86_64-linux-0.15.1.tar.xz"
log_file: "{{ lookup('env','HOME') }}/install_log.txt"
ansible_target: "${TARGET}"
ansible_limit: "${LIMIT}"
EOF

dialog --title "Resumen" --msgbox "Se lanzará Ansible con las selecciones. Verifica inventory si usarás modo remoto.

WMs: ${WMS_N}
Pack: ${SOFT_N}
Apps: ${APPS_N}
DM: ${DM_N}
Destino: ${TARGET}
Inventory limit: ${LIMIT}" 15 78

if [[ "$TARGET" == *remote* ]]; then
  ansible-playbook -i inventory playbook.yml --extra-vars "@${VARS_FILE}" --limit "$LIMIT" --ask-become-pass
else
  ansible-playbook -i inventory playbook.yml --extra-vars "@${VARS_FILE}" --limit localhost --ask-become-pass
fi

exit 0

