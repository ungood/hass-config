# Contributing

This guide explains how to make changes to this Home Assistant configuration repository.

## Tenets

1. Use meaningful names for files and entities.
2. Follow the Home Assistant style guide.
3. Use blueprints to reduce code duplication.
4. Use floors, areas, and labels to specify entities for automation.
5. Use scripts to encapsulate complex logic.

## Spec-driven development

This repository uses spec-driven development to steer AI-assisted automation. Each specification describes the desired behavior of the system, and the automation rules are written to achieve that behavior.

Specifications are stored in the `specs/` directory. When implementing automations:
1. Create or update a spec file in `specs/` describing the desired behavior
2. Implement the automation based on the spec
3. Reference the spec file in the automation's description or comments
