# Architecture

## Design principle

The framework is vendor-neutral in **workflow and contracts**, not in resource implementation.

```text
Request contract
   |
Architecture intent
   |
Blueprint selection
   |
Provider-native modules
   |
Terraform execution
```

A `kubernetes-platform` capability can exist across providers while each implementation keeps its native semantics (AKS/EKS/GKE/OKE).

## Layers

### 1. Request contract

Human language can be normalized into `schemas/infrastructure-request.schema.json`. The request is not Terraform; it records intent, provider, environment, region, capability, and constraints.

### 2. Blueprint

A blueprint is a root Terraform composition representing a deployable platform. It calls reviewed modules. It may define backend/provider wiring and environment-level policy inputs.

### 3. Provider modules

Modules remain small enough to understand, test, and version. They expose provider-native capabilities instead of hiding meaningful differences.

### 4. Quality gates

Formatting, initialization, validation, Terraform tests, linting, static security scanning, and saved planning are separate gates.

### 5. Approval and execution

Pull-request validation does not imply execution permission. A saved plan creates the review boundary. Production execution should use an environment-protected workflow with workload federation.

### 6. Evidence

Generated plans, plan JSON, security reports, approvals, and runtime verification are evidence. They are sensitive operational artifacts and are not committed to Git.
