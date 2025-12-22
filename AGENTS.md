# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Contributing

For development workflow, environment setup, and validation procedures, see [CONTRIBUTING.md](CONTRIBUTING.md).

## Key Tools

### hass-cli

Query the running Home Assistant instance for entity IDs, state, and available services. Requires authentication (check `.env` for credentials).

Common commands:

```bash
# List all entities (useful for finding entity IDs)
hass-cli entity list

# Get state of a specific entity
hass-cli state get <entity_id>

# List available services
hass-cli service list

# List all areas
hass-cli area list
```

**Alternative**: If `hass-cli` is not working or authentication is unavailable, you can read registry information directly from JSON files in `.storage/`:

- `.storage/core.area_registry` - Areas and their floor assignments
- `.storage/core.floor_registry` - Floor definitions
- `.storage/core.entity_registry` - Entity definitions and area assignments
- `.storage/core.device_registry` - Device definitions and area assignments

### validate-config

Validate Home Assistant configuration using Docker (same validation as CI):

```bash
./scripts/validate-config
```

## Repository Overview

This is a Home Assistant configuration repository that uses:

- **Nix flakes** for development environment and dependency management
- **GitHub Actions** for automated configuration validation
- **Pre-commit hooks** for local validation

## Configuration Architecture

### File Organization

- **`configuration.yaml`** - Main configuration file that uses `!include` directives to load modular components
- **`automations/`** - Individual automation YAML files (loaded via `!include_dir_list`)
- **`scripts.yaml`** - Script definitions (loaded via `!include`)
- **`scenes.yaml`** - Scene definitions (loaded via `!include`)
- **`blueprints/`** - Reusable automation and script blueprints organized by type
- **`esphome/`** - ESPHome device configurations
- **`pyscript/`** - Python scripts for advanced automations
- **`themes/`** - Frontend theme definitions (loaded via `!include_dir_merge_named`)

## Configuration Best Practices

### Input Helpers

**IMPORTANT**: Never use the `initial` attribute in input helper configurations (e.g., `input_number`, `input_boolean`, `input_text`, `input_select`, etc.). The `initial` attribute causes values to be reset to their initial state whenever Home Assistant restarts, which results in loss of state and unexpected behavior. Always omit the `initial` attribute to preserve values across restarts.
