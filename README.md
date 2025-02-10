# PURR - Pacman Ultra Rate Ranker

PURR is a wrapper function for [rate-mirrors](https://github.com/westandskif/rate-mirrors) that provides enhanced mirror management capabilities for Arch Linux systems.

## Dependencies

PURR requires [rate-mirrors](https://github.com/westandskif/rate-mirrors) to be installed on your system. Rate-mirrors is the core tool that performs the actual mirror speed testing and ranking. PURR extends its functionality by adding automated backup management, multi-repository support, and enhanced logging capabilities.

## Features

- Automatic mirror rating and optimization
- Backup management for mirror lists
- Support for multiple repositories
- Shell-agnostic implementation (works with bash and zsh)
- Logging capabilities
- Quiet mode operation

## Installation

```bash
git clone https://github.com/majerich/purr.git
cd purr
sudo cp src/purr.sh /usr/local/lib/
```

## Usage

```bash
purr [-q] [-l]          # Update mirrors (quiet/logging optional)
purr -s                 # Show available backups
purr -r BACKUP_DATE     # Restore specific backup
```

### Options

- `-q`: Quiet mode, suppress stdout
- `-l`: Enable logging to /var/log/rate-mirror.log
- `-s`: Show available backups
- `-r`: Restore backup from specified date

## License

MIT License - See LICENSE file for details
