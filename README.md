# PURR - Pacman Ultra Rate Ranker

PURR is a wrapper function for [rate-mirrors](https://github.com/westandskif/rate-mirrors) that provides enhanced mirror management capabilities for Arch Linux systems.

## Dependencies

PURR requires [rate-mirrors](https://github.com/westandskif/rate-mirrors) to be installed on your system. Rate-mirrors is the core tool that performs the actual mirror speed testing and ranking. PURR extends its functionality by adding automated backup management, multi-repository support, and enhanced logging capabilities.

## Features

- Automatic mirror optimization using rate-mirrors
- Comprehensive backup and restore functionality
- Automatic backup creation before updates
- Undo capability for last mirror update
- Detailed backup metadata including system information
- Support for multiple repository types
- Secure file handling with proper permissions
- Extensive error handling and logging
- Compatible with both bash and zsh shells

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
purr -c                 # Create backup of system mirrors and configuration
purr -u                 # Undo last mirror update

### Options

- `-q`: Quiet mode, suppress stdout
- `-l`: Enable additional file logging to /var/log/rate-mirror.log in RFC5424 format (Note: All operations are logged to journald regardless of this flag)
- `-s`: Show available backups
- `-r`: Restore backup from specified date
- `-c`: Create backup of system mirrors and configuration
- `-u`: Undo last mirror update

## License

MIT License - See LICENSE file for details
```
