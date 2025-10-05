# trixie-ansible-installer

Paquete portable para instalar Window Managers y software en Debian 13 (Trixie) usando Bash + Ansible.

## Requisitos
- Debian 13 (probado)
- Usuario con permisos sudo

## Uso (local)
1. Descomprimir y entrar al directorio:
   ```
   tar xzf trixie-ansible-installer.tar.gz
   cd trixie-ansible-installer
   chmod +x menu.sh
   ./menu.sh
   ```

## Uso (remoto)
- Edita `inventory` y agrega tus hosts con `ansible_user`/`ansible_ssh_private_key_file`.
- Cuando el `menu.sh` pregunte por Remote, indica el `limit` (ej: `all`, `host1`, o nombre de grupo).

