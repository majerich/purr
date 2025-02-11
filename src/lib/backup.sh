#!/usr/bin/env bash
#
# Backup related functions for purr

# Function: generate_metadata
# Description: Creates JSON metadata for backup
# Outputs: Writes metadata to METADATA_FILE
# Returns: 0 on success, non-zero on error
function generate_metadata() {
  cat >"${METADATA_FILE:?Missing metadata file}" <<EOF
{
  "backup": {
    "timestamp": "$(date -Iseconds)",
    "hostname": "${HOSTNAME}",
    "username": "$(whoami)",
    "kernel": "$(uname -r)",
    "os_release": "$(</etc/os-release grep '^VERSION=' |
    cut -d'=' -f2- | tr -d '"')",
    "purr_version": "${VERSION}",
    "arch": "$(uname -m)",
    "pacman_version": "$(pacman -V | head -n1 | cut -d' ' -f2)",
    "rate_mirrors_version": "$(rate-mirrors --version 2>&1 | head -n1)",
    "checksum": "$(find /etc/pacman.d -type f -exec sha256sum {} \; |
      sort | sha256sum | cut -d' ' -f1)"
  }
}
EOF
}

# Function: backup
# Description: Creates backup of system mirrors and configuration
# Returns: 0 on success, E_BACKUP on error
function backup() {
  local date_stamp
  local backup_file
  local temp_dir

  date_stamp="$(date +%Y%m%d_%H%M%S)"
  backup_file="${BACKUP_PATH:?Missing backup path}/${date_stamp}.tar.gz"
  temp_dir="$(mktemp -d)" || return "${E_BACKUP}"

  verify_permissions "${BACKUP_PATH}" "w" || return "${E_PERMISSION}"
  generate_metadata || return "${E_BACKUP}"

  install -d "${temp_dir}/etc/pacman.d" || return "${E_BACKUP}"

  local file
  for file in /etc/pacman.conf /etc/pacman.d/mirrorlist* /etc/pacman.d/gnupg; do
    verify_permissions "${file}" "r" || continue
    cp -a "${file}" "${temp_dir}${file}" || return "${E_BACKUP}"
  done

  install -m 644 "${METADATA_FILE}" "${temp_dir}/metadata.json" ||
    return "${E_BACKUP}"

  sudo tar czf "${backup_file}" -C "${temp_dir}" . || return "${E_BACKUP}"
  verify_backup "${backup_file}" || return "${E_VALIDATION}"

  local -a old_backups
  mapfile -t old_backups < <(
    find "${BACKUP_PATH}" -name "*.tar.gz" -type f -printf '%T@ %p\0' |
      sort -z -n | head -z -n -"${MAX_BACKUPS}" | cut -z -d' ' -f2-
  )

  if ((${#old_backups[@]} > 0)); then
    sudo rm -f "${old_backups[@]}"
  fi

  msg "Configuration backup created: ${backup_file}"
  return "${E_SUCCESS}"
}

# Function: verify_backup
# Description: Verifies backup integrity
# Arguments:
#   $1 - Path to backup file
# Returns: 0 on success, E_VALIDATION on error
function verify_backup() {
  local backup_file="${1:?Missing backup file}"
  local temp_extract
  local expected_checksum

  temp_extract="$(mktemp -d)" || return "${E_BACKUP}"

  if ! tar xzf "${backup_file}" -C "${temp_extract}" metadata.json; then
    rm -rf "${temp_extract}"
    return "${E_VALIDATION}"
  fi

  expected_checksum="$(jq -r '.backup.checksum' <"${temp_extract}/metadata.json")"
  rm -rf "${temp_extract}"

  verify_checksum "${backup_file}" "${expected_checksum}" ||
    return "${E_VALIDATION}"
  return "${E_SUCCESS}"
}

# Function: restore_backup
# Description: Restores system from backup
# Arguments:
#   $1 - Backup date to restore
# Returns: 0 on success, E_RESTORE on error
function restore_backup() {
  local backup_date="${1:?Missing backup date}"
  local backup_file="${BACKUP_PATH}/${backup_date}.tar.gz"

  if [[ ! -f "${backup_file}" ]]; then
    err "Backup not found: ${backup_date}"
    return "${E_RESTORE}"
  fi

  verify_backup "${backup_file}" || return "${E_VALIDATION}"
  sudo tar xzf "${backup_file}" -C "/" || return "${E_RESTORE}"
  msg "Restored configuration from backup: ${backup_date}"
  return "${E_SUCCESS}"
}

# vim: fenc=utf-8:ts=2:sw=2:sta:et:sts=2:fdm=marker:ai:ft=sh:tw=80:
# vim: cc=80:commentstring=#%s:
