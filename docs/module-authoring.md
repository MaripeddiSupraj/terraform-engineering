# Module Authoring Guide

A module is accepted only when it is reusable, understandable, and testable.

## Scope

Prefer a cohesive capability such as `network`, `aks`, or `key-vault`. Avoid both one-resource wrappers with no policy value and huge platform modules that expose hundreds of unrelated switches.

## Interface

- Input names describe intent.
- Defaults are safe and unsurprising.
- Provider-native behavior remains visible.
- Outputs support composition without leaking secret data.

## Testing

Use Terraform native tests. Provider-backed modules should use mock providers for fast structural/unit checks where possible; integration tests that create real cloud resources belong in a separately approved workflow with explicit cost and cleanup controls.

## Documentation

Document:

- purpose;
- security defaults;
- important inputs/outputs;
- minimal example;
- known operational constraints.
