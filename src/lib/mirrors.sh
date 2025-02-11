#!/usr/bin/env bash
#
# Mirror management functions for purr

# Function: detect_repos
# Description: Detects available repository mirrorlists
# Outputs: Populates FOUND_REPOS array
# Returns: 0 on success
function detect_repos() {
  mapfile -t FOUND_REPOS < <(
    find "${MIRROR_PATH}" -type f -name "*mirrorlist" \
      -exec basename {} \; | sed 's/-mirrorlist//'
  )
}

# Function: generate_mirrors
# Description: Generates new mirror list using rate-mirrors
# Arguments:
#   $1 - Output file path
#   $2 - Repository name
# Returns: 0 on success, E_MIRRORS on error
function generate_mirrors() {
  local output_file="${1:?Missing output file}"
  local repo="${2:?Missing repository}"

  if ! command -v rate-mirrors >/dev/null; then
    err "rate-mirrors not found"
    return "${E_MIRRORS}"
  fi
  rate-mirrors --save="${output_file}" "${repo}" &>/dev/null
}

# Function: update_files
# Description: Updates mirror files with new content
# Arguments:
#   $1 - Source file name
#   $2 - Target file path
# Returns: 0 on success, E_MIRRORS on error
function update_files() {
  local source="${1:?Missing source file}"
  local target="${2:?Missing target file}"

  verify_permissions "${MIRROR_PATH}" "w" || return "${E_PERMISSION}"

  if ! sudo mv "${MIRROR_PATH}/${source}"{,-backup} &>/dev/null ||
    ! sudo mv "${target}" "${MIRROR_PATH}/${source}" &>/dev/null; then
    return "${E_MIRRORS}"
  fi
}

# Function: check_mirror_handler
# Description: Checks for active mirror management services
# Returns: 0 if no handlers active, E_HANDLER if found
function check_mirror_handler() {
  local -r handlers=(
    "ghostmirror|--user"
    "reflector|system"
  )

  local name
  local scope
  local cmd

  for handler in "${handlers[@]}"; do
    name="${handler%|*}"
    scope="${handler#*|}"
    cmd="systemctl"
    [[ "${scope}" == "--user" ]] && cmd+=" --user"

    if ${cmd} is-active --quiet "${name}.timer"; then
      printf '%s\n\n%s\n' \
        "Your mirrors are currently managed by '${name}'" \
        "No action taken."
      log 3 "Update blocked: ${name} active"
      return "${E_HANDLER}"
    fi
  done
  return "${E_SUCCESS}"
}

# vim: fenc=utf-8:ts=2:sw=2:sta:et:sts=2:fdm=marker:ai:ft=sh:tw=80:
# vim: cc=80:commentstring=#%s:
