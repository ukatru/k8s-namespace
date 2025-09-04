# Namespace Deployment Guide

This guide explains how to deploy namespaces to different clusters based on environment (prod vs non-prod).

## Overview

The k8s-namespace chart is configured to deploy namespaces to different clusters based on the `clusterEnv` setting:

- **Non-prod cluster**: Deploys only non-prod environments (sbox, dev, test)
- **Prod cluster**: Deploys only prod environments

## Deployment Process

### 1. Create Application-Specific Values File

Create an application-specific values file with your application details:

```yaml
# my-app-values.yaml
appName: "my-application"
snowApmId: "apm12345678"
gitlabProjIds:
  - "12345"
  - "67890"

# Define your environments as needed
environments:
  sbox:
    labels:
      environment-type: sandbox
      cost-center: dev-ops
  dev:
    labels:
      environment-type: development
      cost-center: dev-ops
  test:
    labels:
      environment-type: testing
      cost-center: qa
  prod:
    labels:
      environment-type: production
      cost-center: operations
```

### 2. Deploy to Non-Prod Cluster

```bash
helm upgrade --install my-app-namespaces . \
  -f my-app-values.yaml \
  -f values-nonprod.yaml \
  --namespace namespace-controller
```

This will deploy only the non-prod environments (sbox, dev, test) to your non-prod cluster.

### 3. Deploy to Prod Cluster

```bash
helm upgrade --install my-app-namespaces . \
  -f my-app-values.yaml \
  -f values-prod.yaml \
  --namespace namespace-controller
```

This will deploy only the prod environment to your prod cluster.

## Environment Selection Logic

The chart uses the `clusterEnv` parameter to determine which environments to deploy:

- `clusterEnv: "non-prod"` - Deploys all environments except prod
- `clusterEnv: "prod"` - Deploys only the prod environment
- `clusterEnv: "all"` - Deploys all environments (default)

## Validation

You can validate what will be deployed using the Helm template command:

```bash
# Validate non-prod deployment
helm template my-app . -f my-app-values.yaml -f values-nonprod.yaml

# Validate prod deployment
helm template my-app . -f my-app-values.yaml -f values-prod.yaml
```
