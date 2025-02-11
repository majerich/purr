#!/usr/bin/env bash
#
# Installation script for purr

readonly INSTALL_DIR="/usr/local"
readonly BIN_DIR="${INSTALL_DIR}/bin"
readonly LIB_DIR="${INSTALL_DIR}/lib/purr"

function install_purr() {
  # Create directories
  sudo mkdir -p "${BIN_DIR}" "${LIB_DIR}"

  # Install main executable
  sudo install -m 755 src/bin/purr "${BIN_DIR}/purr"

  # Install library files
  for lib in backup mirrors permissions logging utils; do
    sudo install -m 644 "src/lib/purr/${lib}.sh" "${LIB_DIR}/${lib}.sh"
  done

  printf "Purr installed successfully to %s\n" "${BIN_DIR}/purr"
}

install_purr

# vim: fenc=utf-8:ts=2:sw=2:sta:et:sts=2:fdm=marker:ai:ft=sh:tw=80:
# vim: cc=80:commentstring=#%s:
