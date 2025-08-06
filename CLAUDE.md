# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Python-based notification manager for ntfy.sh that helps manage build notifications, deployment alerts, and other development events across multiple repositories. The system is designed for both public and private repositories with secure topic generation for sensitive projects.

## Development Commands

### Setup and Installation
```bash
# Quick setup for current git repository
./quick-setup.sh

# Setup for private repositories with enhanced security
./private-repo-setup.sh

# Manual Python dependency installation
uv add requests
```

### Usage Models

**1. Centralized Management (Local Development)**
- Tek `ntfy-manager.json` dosyası ile multiple repository'leri yönet
- Local development environment'ta ideal
- Tüm projelerinizi tek yerden kontrol edin

**2. Repository-Specific (CI/CD)**
- Her repository kendi `ntfy-manager.json` dosyasını tutar
- GitHub Actions ve CI/CD pipeline'ları için ideal
- Repository isolation sağlar

### Repository Setup for GitHub Actions

**🎯 Recommended: Centralized Approach**
Python dosyaları merkezi repository'de kalır, sadece workflow kopyalanır:

```bash
# 1. Repository'yi merkezi config'e ekle (eğer yoksa)
uv run python ./ntfy-manager.py add-repo mvp-api --private

# 2. Sadece workflow'u kopyala (Python dosyaları kopyalanmaz!)
./setup-simple-ntfy.sh mvp-api /path/to/mvp-api

# 3. Target repository'de commit ve push
cd /path/to/mvp-api
git add .github/workflows/ntfy-notifications.yml
git commit -m "Add ntfy.sh notification workflow"
git push
```


### Core Commands
```bash
# Repository management
uv run python ./ntfy-manager.py add-repo <repo-name>                    # Add public repository
uv run python ./ntfy-manager.py add-repo <repo-name> --private          # Add private repository
uv run python ./ntfy-manager.py list                                     # List all repositories

# Event management
uv run python ./ntfy-manager.py toggle <repo> <event>                    # Toggle event on/off
uv run python ./ntfy-manager.py toggle <repo> <event> --enable          # Enable event
uv run python ./ntfy-manager.py toggle <repo> <event> --disable         # Disable event

# Send notifications
uv run python ./ntfy-manager.py send <repo> <event> "message"           # Send notification
uv run python ./ntfy-manager.py send auto <event> "message"             # Use current git repo
uv run python ./ntfy-manager.py send <repo> <event> "message" --priority urgent

# View notifications
uv run python ./ntfy-manager.py view                                     # View all notifications
uv run python ./ntfy-manager.py view --repo <repo>                       # View specific repo
uv run python ./ntfy-manager.py view --follow                           # Live follow mode
```

### Testing
Run the notification system by sending test messages:
```bash
uv run python ./ntfy-manager.py send auto test "Test notification"
```

## Architecture

### Core Components

**ntfy-manager.py** (main application):
- `NtfyManager` class: Central notification management system
- Repository management with secure topic generation for private repos
- Event-based notification system with priority levels
- Configuration persistence in JSON format

**Configuration System** (ntfy-manager.json):
- Repository-specific settings with topic mapping
- Event configuration (enabled/disabled, priority, title)
- Global settings including authentication and server configuration
- Private repository support with hashed topic names

**Setup Scripts**:
- `quick-setup.sh`: Standard repository setup with dependency checks
- `private-repo-setup.sh`: Enhanced setup for private repositories with security features

### Key Features

1. **Repository Management**: Automatic git repository detection and registration
2. **Event System**: Build, deploy, test, error, push, PR, and release events
3. **Security**: Private repositories use MD5-hashed topic names to prevent exposure
4. **Priority Levels**: low, default, high, urgent notification priorities
5. **Authentication**: Token-based authentication for ntfy.sh servers
6. **Multi-server Support**: Can work with self-hosted ntfy servers

### Event Types
- `build`: Build status notifications (enabled by default)
- `deploy`: Deployment notifications (high priority, enabled by default)  
- `test`: Test result notifications (disabled by default)
- `error`: Error alerts (urgent priority, enabled by default)
- `push`: Git push notifications
- `pr`: Pull request notifications
- `release`: Release notifications

## Development Notes

- The system uses Python 3.13+ with minimal dependencies (only `requests`)
- Configuration is stored in `ntfy-manager.json` with auto-save functionality
- Private repositories generate secure 8-character hash-based topic names
- The `auto` parameter automatically detects the current git repository name
- All executable files have proper permissions (`chmod +x`)

## Integration Examples

The system integrates with CI/CD pipelines, git hooks, cron jobs, and build scripts. See `examples.md` for detailed usage patterns and integration examples.