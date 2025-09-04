# k8s-namespace Helm Chart

This Helm chart creates and configures Kubernetes namespaces and associated resources for different environments.

## Overview

The chart creates the following resources for each environment defined in the values file:

- Namespace
- ResourceQuota
- LimitRange
- NetworkPolicy
- Role, RoleBinding, and ClusterRoleBinding for access control

## Values Structure

The chart uses a flat environment structure in the values file. Each environment is defined as a key in the `environments` map, with environment-specific configurations as values.

### Example Values File

```yaml
appName: data-platform-poc
snowApmId: APM121000

gitlabProjIds:
- 123455
- 454354
environments:
  sbox:
    labels:
      environment-type: sandbox
      cost-center: dev-ops
    annotations:
      platform.eks.ukatru.cloud/description: "Sandbox environment for testing"
    resourceQuota:
      hard:
        limits.cpu: "8"
        limits.memory: 16Gi
        requests.cpu: "4"
        requests.memory: 8Gi
        pods: "20"
    limitRange:
      limits:
      - default:
          cpu: 500m
          memory: 512Mi
        defaultRequest:
          cpu: 100m
          memory: 128Mi
        type: Container
  dev: {}
  test: {}
  prod: {}
```

## Environment Configuration

Each environment can define the following configurations:

- `labels`: Custom labels to apply to the namespace
- `annotations`: Custom annotations to apply to the namespace
- `resourceQuota`: Resource quota configuration for the namespace
- `limitRange`: Limit range configuration for the namespace

### Default Values and Validation

If an environment is defined with an empty configuration (`{}`), the following defaults will be applied. Additionally, all resource values are validated against maximum allowed limits to prevent excessive resource allocation.

## Resource Quotas and Limit Ranges

The chart applies default resource quotas and limit ranges to each namespace when no specific values are provided. These defaults are:

### Resource Quotas
- CPU Limits: 50 cores (minimum) to 100 cores (maximum)
- Memory Limits: 100Gi (minimum) to 200Gi (maximum)
- CPU Requests: 50 cores (minimum) to 100 cores (maximum)
- Memory Requests: 100Gi (minimum) to 200Gi (maximum)
- Pods: 30 (default) up to 100 (maximum)

### Limit Ranges
- Default CPU: 50m (minimum) to 8000m (maximum)
- Default Memory: 0.5Gi (minimum) to 16Gi (maximum)
- Default Request CPU: 50m (minimum) to 8000m (maximum)
- Default Request Memory: 0.5Gi (minimum) to 16Gi (maximum)
- Max CPU per container: 8 cores (maximum)
- Max Memory per container: 16Gi (maximum)
- Min CPU per container: 50m (minimum)
- Min Memory per container: 10Mi (minimum)

### Validation Logic

The chart includes built-in validation logic to ensure that resource quotas and limit ranges stay within allowed boundaries. This validation is implemented through helper functions in `_helpers.tpl`:

1. `validateResourceQuota`: Validates and caps resource quota values
   - Ensures CPU is between 50-100 cores
   - Ensures memory is between 100-200Gi
   - Caps pod count at 100

2. `validateLimitRange`: Validates and caps limit range values
   - Ensures default/request CPU is between 50m-8000m
   - Ensures default/request memory is between 0.5Gi-16Gi
   - Caps max CPU at 8 cores
   - Caps max memory at 16Gi
   - Enforces min CPU of at least 50m
   - Enforces min memory of at least 10Mi

If values exceeding these limits are specified in the values file, they will be automatically capped to the maximum allowed values without causing errors. Similarly, if values below the minimum thresholds are specified, they will be raised to the minimum allowed values. This prevents excessive resource allocation while still providing flexibility within reasonable boundaries.

#### Default Resource Quota
```yaml
hard:
  limits.cpu: "50"
  limits.memory: 100Gi
  requests.cpu: "50"
  requests.memory: 100Gi
  pods: "30"
```

#### Default Limit Range
```yaml
limits:
- type: Container
  default:
    cpu: 50m
    memory: 0.5Gi
  defaultRequest:
    cpu: 50m
    memory: 0.5Gi
  max:
    cpu: 8
    memory: 16Gi
  min:
    cpu: 50m
    memory: 10Mi
```

## Usage

### Installation

```bash
helm install [RELEASE_NAME] ./k8s-namespace -f values.yaml
```

### Rendering Templates

```bash
helm template [RELEASE_NAME] ./k8s-namespace -f values.yaml
```

## Conditional Environment Deployment

The chart supports conditional deployment of environments based on the cluster environment type using the `clusterEnv` parameter in the values file. This allows you to selectively deploy only certain environments based on the cluster you're deploying to.

### clusterEnv Parameter

The `clusterEnv` parameter can be set to one of the following values:

- `all`: Deploy all environments (default)
- `non-prod`: Deploy all environments except `prod`
- `prod`: Deploy only the `prod` environment
- `dev`: Deploy all environments except `prod`
- `test`: Deploy only the `test` environment

### Example Usage

```bash
# Deploy all environments except prod
helm install namespace ./k8s-namespace --set clusterEnv=non-prod

# Deploy only the prod environment
helm install namespace ./k8s-namespace --set clusterEnv=prod
```

This feature is particularly useful in CI/CD pipelines where you want to skip deploying production namespaces to non-production clusters, or when you want to selectively deploy only certain environments.

## Namespace Naming Convention

Namespaces are named using the pattern: `[snowApmId]-[env]`

For example, with `snowApmId: APM121000` and environment `dev`, the namespace would be `apm121000-dev`.
