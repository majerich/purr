# Function: purr
#
# Updates and manages repository mirrorlists for detected package repositories
# 
# Usage:
#   purr [-q] [-l]          # Update mirrors (quiet/logging optional)
#   purr -s                 # Show available backups
#   purr -r BACKUP_DATE     # Restore specific backup
#   purr -c                 # Create backup of system mirrors and configuration
#   purr -u                 # Undo last mirror update
#
# Options:
#   -q: Quiet mode, suppress stdout
#   -l: Enable additional file logging to /var/log/rate-mirror.log in RFC5424
#       format (Always logs to journald regardless of this flag)
#   -s: Show available backups
#   -r: Restore backup from specified date
#   -c: Create backup of system mirrors and configuration
#   -u: Undo last mirror update

purr() {
  # VARIABLES
  local -r VERSION="1.0.0"
  local -r BACKUP_PATH="/var/cache/rate-mirror"
  local -r LOG_FILE="/var/log/rate-mirror.log"
  local -r MIRROR_PATH="/etc/pacman.d"
  local -r MAX_BACKUPS=5
  local -r RFC_DATE="$(date '+%Y-%m-%dT%H:%M:%S%z')"
  local -r HOSTNAME="${HOSTNAME:-$(hostname)}"
  local -r METADATA_FILE="$(mktemp)"
  local -a FOUND_REPOS=()
  local -r E_GENERAL=1
  local -r E_SUDO=2
  local -r E_HANDLER=3
  local -r E_BACKUP=4
  local -r E_RESTORE=5
  local -r E_MIRRORS=6

  # Set restrictive umask
  umask 077

  # SUB-FUNCTIONS
  # Logging and Output Functions
  __log() {
    local priority="${1:?}" message="${2:?}"
    logger -t "mirror-update" "${message}"
    (( FILE_LOG )) && printf '<'%s'>1 %s %s rate-mirror - - - %s\n' \
      "${priority}" "${RFC_DATE}" "${HOSTNAME}" "${message}" | \
      sudo tee -a "${LOG_FILE}" >/dev/null
  }

  __output() {
    local priority="${1:?}" message="${2:?}" symbol="${3:?}"
    (( ! QUIET )) && \
      printf '\033[%sm%s\033[0m %s\n' "${priority}" "${symbol}" "${message}"
    __log "${priority}" "${message}"
  }

  __msg() { __output "34" "${1:?}" "→"; }
  __err() { __output "31" "${1:?}" "✗" >&2; }

  # Metadata and Backup Functions
  __generate_metadata() {
    cat > "${METADATA_FILE:?}" << EOF
{
  "backup": {
    "timestamp": "$(date -Iseconds)",
    "hostname": "${HOSTNAME}",
    "username": "$(whoami)",
    "kernel": "$(uname -r)",
    "os_release": "$(< /etc/os-release grep '^VERSION=' | cut -d'=' -f2- | tr -d '"')",
    "purr_version": "${VERSION}",
    "arch": "$(uname -m)",
    "pacman_version": "$(pacman -V | head -n1 | cut -d' ' -f2)",
    "rate_mirrors_version": "$(rate-mirrors --version 2>&1 | head -n1)"
  }
}
EOF
  }

  __backup() {
    local date_stamp
    date_stamp="$(date +%Y%m%d_%H%M%S)"
    local backup_file="${BACKUP_PATH}/${date_stamp}.tar.gz"
    local temp_dir
    temp_dir="$(mktemp -d)"
    
    __generate_metadata || return ${E_BACKUP}
    
    sudo mkdir -p "${BACKUP_PATH}" || return ${E_BACKUP}
    
    # Copy files to temp directory maintaining structure
    sudo install -d "${temp_dir}/etc/pacman.d" || return ${E_BACKUP}
    sudo cp -a /etc/pacman.conf "${temp_dir}/etc/" || return ${E_BACKUP}
    sudo cp -a /etc/pacman.d/mirrorlist* "${temp_dir}/etc/pacman.d/" || return ${E_BACKUP}
    sudo cp -a /etc/pacman.d/gnupg "${temp_dir}/etc/pacman.d/" || return ${E_BACKUP}
    install -m 644 "${METADATA_FILE}" "${temp_dir}/metadata.json" || return ${E_BACKUP}
    
    # Create archive from temp directory
    sudo tar czf "${backup_file}" -C "${temp_dir}" . || return ${E_BACKUP}
    
    # Cleanup
    rm -rf "${temp_dir}"
    rm -f "${METADATA_FILE}"
    
    # Maintain backup limit using find
    find "${BACKUP_PATH}" -name "*.tar.gz" -type f -printf '%T@ %p\0' | \
      sort -z -n | head -z -n -${MAX_BACKUPS} | cut -z -d' ' -f2- | \
      xargs -0 -r sudo rm
      
    __msg "Configuration backup created: ${backup_file}"
  }

  __show_backups() {
    [[ ! -d "${BACKUP_PATH}" ]] && {
      __err "No backups found"
      return ${E_BACKUP}
    }
    printf '%s\n' "Available backups:"
    find "${BACKUP_PATH}" -name "*.tar.gz" -type f -printf '%T@ %p\0' | \
      sort -z -rn | cut -z -d' ' -f2- | \
      while IFS= read -r -d '' backup; do
        printf '  %s\n' "$(basename "${backup}" .tar.gz)"
      done
  }

  __restore_backup() {
    local backup_file="${BACKUP_PATH}/${1:?}.tar.gz"
    [[ ! -f "${backup_file}" ]] && {
      __err "Backup not found: ${1}"
      return ${E_RESTORE}
    }
    sudo tar xzf "${backup_file}" -C "${MIRROR_PATH}" || return ${E_RESTORE}
    __msg "Restored mirrors from backup: ${1}"
  }

  __undo() {
    local latest_backup
    latest_backup="$(find "${BACKUP_PATH}" -name "*.tar.gz" -type f -printf '%T@ %p\0' | \
      sort -z -rn | head -z -n1 | cut -z -d' ' -f2-)"
      
    [[ -z "${latest_backup}" ]] && {
      __err "No backup found to undo"
      return ${E_BACKUP}
    }

    local temp_dir
    temp_dir="$(mktemp -d)"
    tar xzf "${latest_backup}" -C "${temp_dir}" || return ${E_RESTORE}

    local changed=false
    while IFS= read -r -d '' file; do
      local backup_file="${temp_dir}${file}"
      local current_file="${file}"
      
      if [[ -f "${current_file}" ]]; then
        local backup_hash
        local current_hash
        backup_hash="$(sha256sum "${backup_file}" | cut -d' ' -f1)"
        current_hash="$(sha256sum "${current_file}" | cut -d' ' -f1)"
        
        if [[ "${backup_hash}" != "${current_hash}" ]]; then
          sudo cp -a "${backup_file}" "${current_file}"
          changed=true
        fi
      else
        sudo cp -a "${backup_file}" "${current_file}"
        changed=true
      fi
    done < <(cd "${temp_dir}" && find . -type f ! -name metadata.json -print0)

    rm -rf "${temp_dir}"
    
    if ${changed}; then
      sudo rm -f "${latest_backup}"
      __msg "Successfully undid last mirror update"
      return 0
    else
      __msg "No changes needed - files match backup"
      return 0
    fi
  }

  # Mirror Management Functions
  __detect_repos() {
    local find_cmd
    find_cmd="$(find "${MIRROR_PATH}" -type f -name "*mirrorlist" \
                -exec basename {} \; | sed 's/-mirrorlist//')"
    mapfile -t FOUND_REPOS < <(printf '%s\n' "${find_cmd}")
  }

  __generate_mirrors() {
    command -v rate-mirrors >/dev/null || {
      __err "rate-mirrors not found"
      return ${E_MIRRORS}
    }
    rate-mirrors --save="${1:?}" "${2:?}" &>/dev/null
  }

  __update_files() {
    [[ -w "${MIRROR_PATH}" ]] || {
      __err "Mirror path not writable"
      return ${E_MIRRORS}
    }
    sudo mv "${MIRROR_PATH}/${1:?}"{,-backup} &>/dev/null &&
    sudo mv "${2:?}" "${MIRROR_PATH}/${1}" &>/dev/null
  }

  __cleanup() {
    local file
    for file in "$@"; do
      [[ -f "${file}" ]] && rm -f "${file}"
    done
  }

  __check_mirror_handler() {
    local handlers=(
      "ghostmirror|--user"
      "reflector|system"
    )
    
    for handler in "${handlers[@]}"; do
      local name="${handler%|*}"
      local scope="${handler#*|}"
      local cmd="systemctl"
      [[ "${scope}" == "--user" ]] && cmd+=" --user"
      
      ${cmd} is-active --quiet "${name}.timer" && {
        printf '%s\n\n%s\n' \
          "Your mirrors are currently managed by '${name}'" \
          "No action taken."
        __log 3 "Update blocked: ${name} active"
        return ${E_HANDLER}
      }
    done
    return 0
  }

  # MAIN
  # Set up trap handlers
  trap '__cleanup "${METADATA_FILE}" "${tmp_files[@]}"' EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM

  # Shell detection and option parsing
  case "${SHELL:A}" in
    *zsh)
      setopt LOCAL_OPTIONS PIPE_FAIL ERR_EXIT
      local -A opts
      zparseopts -D -E -A opts q l s r: c u || {
        printf '%s\n' 'Invalid option provided' >&2
        return ${E_GENERAL}
      }
      local QUIET="${+opts[-q]}"
      local FILE_LOG="${+opts[-l]}"
      local SHOW_BACKUPS="${+opts[-s]}"
      local RESTORE_MODE="${+opts[-r]}"
      local RESTORE_DATE="${opts[-r]}"
      local CONFIG_BACKUP="${+opts[-c]}"
      local UNDO_MODE="${+opts[-u]}"
      ;;
    *bash)
      set -o pipefail -o errexit
      local QUIET=0 FILE_LOG=0 SHOW_BACKUPS=0 RESTORE_MODE=0 CONFIG_BACKUP=0 UNDO_MODE=0
      local RESTORE_DATE=""
      while getopts "qlsr:cu" opt; do
        case "${opt}" in
          q) QUIET=1 ;;
          l) FILE_LOG=1 ;;
          s) SHOW_BACKUPS=1 ;;
          r) RESTORE_MODE=1; RESTORE_DATE="${OPTARG}" ;;
          c) CONFIG_BACKUP=1 ;;
          u) UNDO_MODE=1 ;;
          *) printf '%s\n' 'Invalid option provided' >&2; return ${E_GENERAL} ;;
        esac
      done
      ;;
    *)
      printf '%s\n' 'Unsupported shell environment. Use bash or zsh.' >&2
      return ${E_GENERAL}
      ;;
  esac

  # Handle operation modes
  (( CONFIG_BACKUP )) && {
    __backup
    return $?
  }

  (( SHOW_BACKUPS )) && {
    __show_backups
    return $?
  }

  (( RESTORE_MODE )) && {
    [[ -z "${RESTORE_DATE}" ]] && {
      __err "Restore date required"
      return ${E_RESTORE}
    }
    __restore_backup "${RESTORE_DATE}"
    return $?
  }

  (( UNDO_MODE )) && {
    __undo
    return $?
  }

  # Check for other mirror handlers
  __check_mirror_handler || return ${E_HANDLER}

  # Ensure sudo access
  sudo -v || {
    __err "Sudo access required"
    return ${E_SUDO}
  }

  (( FILE_LOG )) && {
    sudo touch "${LOG_FILE}"
    sudo chmod 644 "${LOG_FILE}"
  }

  __detect_repos
  (( ${#FOUND_REPOS[@]} == 0 )) && {
    __err "No repository mirrorlists found"
    return ${E_MIRRORS}
  }

  __log 6 "Starting mirror update process"
  __msg "Found repositories: ${(j:, :)FOUND_REPOS}"

  # Create backup before making changes
  __backup || return ${E_BACKUP}

  local success=true
  local -a tmp_files=()
  for repo in "${FOUND_REPOS[@]}"; do
    tmp_files+=("$(mktemp)")
    if __generate_mirrors "${tmp_files[-1]}" "${repo}"; then
      if __update_files "${repo}-mirrorlist" "${tmp_files[-1]}"; then
        __msg "${repo^} mirrors updated"
      else
        success=false
        __err "Failed updating ${repo^} mirrors"
      fi
    else
      success=false
      __err "Failed generating ${repo^} mirrors"
    fi
  done

  ${success} && {
    __msg "Mirror update completed successfully"
    __log 6 "Mirror update process completed"
  }
}

# ---
# vim: fenc=utf-8:ts=2:sw=2:sta:et:sts=2:fdm=marker:ai:ft=sh:tw=80:
# vim: cc=80:commentstring=#%s:
