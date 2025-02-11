#!/usr/bin/env bash
#
# Logging functions for purr

# Function: log
# Description: Logs message to system logger and file
# Arguments:
#   $1 - Priority level
#   $2 - Message to log
# Returns: 0 on success
function log() {
  local priority="${1:?Missing priority}"
  local message="${2:?Missing message}"
  local level="${LOG_LEVELS[priority]:-UNKNOWN}"

  logger -t "mirror-update" "[${level}] ${message}"
  if ((FILE_LOG)); then
    printf '<'%s'>1 %s %s rate-mirror - - - [%s] %s\n' \
      "${priority}" "${RFC_DATE}" "${HOSTNAME}" "${level}" "${message}" |
      sudo tee -a "${LOG_FILE}" >/dev/null
  fi
}

# Function: output
# Description: Formats and outputs message
# Arguments:
#   $1 - Priority (color code)
#   $2 - Message
#   $3 - Symbol
# Returns: 0 on success
function output() {
  local priority="${1:?Missing priority}"
  local message="${2:?Missing message}"
  local symbol="${3:?Missing symbol}"

  if ((!QUIET)); then
    printf '\033[%sm%s\033[0m %s\n' "${priority}" "${symbol}" "${message}"
  fi
  log "${priority}" "${message}"
}

# Function: msg
# Description: Outputs informational message
# Arguments:
#   $1 - Message to display
function msg() {
  output "34" "${1:?Missing message}" "→"
}

# Function: err
# Description: Outputs error message
# Arguments:
#   $1 - Error message to display
function err() {
  output "31" "${1:?Missing error message}" "✗" >&2
}

# Function: debug
# Description: Outputs debug message if enabled
# Arguments:
#   $1 - Debug message to display
function debug() {
  if ((DEBUG)); then
    output "36" "${1:?Missing debug message}" "●"
  fi
}

# vim: fenc=utf-8:ts=2:sw=2:sta:et:sts=2:fdm=marker:ai:ft=sh:tw=80:
# vim: cc=80:commentstring=#%s:
