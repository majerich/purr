#!/usr/bin/env bash
#
# Permission management functions for purr

# Function: verify_permissions
# Description: Verifies file permissions
# Arguments:
#   $1 - Path to check
#   $2 - Permission to verify (r/w/x)
# Returns: 0 on success, E_PERMISSION on error
function verify_permissions() {
  local path="${1:?Missing path}"
  local perm="${2:?Missing permission}"

  if ! test -"${perm}" "${path}"; then
    err "Permission check failed: ${path} (${perm})"
    return "${E_PERMISSION}"
  fi
  return "${E_SUCCESS}"
}

# Function: verify_checksum
# Description: Verifies file checksum
# Arguments:
#   $1 - File to verify
#   $2 - Expected checksum
# Returns: 0 on success, E_VALIDATION on error
function verify_checksum() {
  local file="${1:?Missing file}"
  local expected="${2:?Missing checksum}"
  local actual

  actual="$(sha256sum "${file}" | cut -d' ' -f1)"
  if [[ "${actual}" != "${expected}" ]]; then
    err "Checksum verification failed for ${file}"
    return "${E_VALIDATION}"
  fi
  return "${E_SUCCESS}"
}

# vim: fenc=utf-8:ts=2:sw=2:sta:et:sts=2:fdm=marker:ai:ft=sh:tw=80:
# vim: cc=80:commentstring=#%s:
