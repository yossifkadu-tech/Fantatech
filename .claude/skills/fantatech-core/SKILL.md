---
name: fantatech-core
description: Protect and extend the FantaTech core architecture — capability-first device model, adapter isolation, and change policy. Load first for any non-trivial FantaTech task.
---

# FantaTech Core Skill

## Purpose

Protect and extend the FantaTech core architecture.

## Rules

- Never duplicate existing functionality.
- Search before creating new services.
- Prefer interfaces and adapters.
- Keep manufacturer-specific logic outside the core.
- Keep UI independent from protocols.
- Use normalized Device and Capability models.

## Device abstraction

Every device should expose:

id
name
manufacturer
model
protocol
category
capabilities
state
availability
metadata

## Capability principle

The UI should ask:

"What can this device do?"

not:

"Which manufacturer created this device?"

## Example

Bad:

if device.manufacturer == "Tuya"

Good:

if device.capabilities.contains("brightness")

## Change policy

Core changes require extra caution.

Prefer extending interfaces rather than modifying existing behavior.
