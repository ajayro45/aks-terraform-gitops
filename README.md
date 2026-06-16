# AKS Terraform + GitOps Infrastructure

A production-ready, single-click deployment for Azure Kubernetes Service (AKS) with:
- **Terraform**: Infrastructure as Code for AKS cluster provisioning
- **ArgoCD**: GitOps deployment automation
- **Prometheus**: Metrics collection
- **Grafana**: Monitoring and visualization
- **Cert-Manager**: Automatic TLS certificate management
- **Ingress-Nginx**: Load balancing and ingress
- **GitHub Actions**: Automated CI/CD pipeline

## Quick Start

### Prerequisites
- Azure subscription with active credentials
- GitHub account with repo access
- Terraform installed locally (v1.5+)
- `az` CLI configured
- `kubectl` installed

### One-Click Deployment

1. **Set up GitHub Secrets** (Settings > Secrets and variables > Actions)
   - `AZURE_SUBSCRIPTION_ID`: Your Azure subscription ID
   - `AZURE_CLIENT_ID`: Service principal client ID
   - `AZURE_CLIENT_SECRET`: Service principal client secret
   - `AZURE_TENANT_ID`: Azure tenant ID
   - `GITHUB_TOKEN`: GitHub PAT with repo access

2. **Trigger the workflow**
   - Go to Actions > "Provision AKS Cluster"
   - Click "Run workflow"
   - Select environment (dev/staging/prod)
   - Monitor the deployment

3. **Access your cluster**
   ```bash
   # Get credentials
   az aks get-credentials --resource-group aks-dev-rg --name aks-dev
   
   # Verify
   kubectl get nodes
   ```

## Project Structure

```
.
├── .github/workflows/              # GitHub Actions CI/CD
│   ├── provision-cluster.yml       # Main provisioning workflow
│   ├── destroy-cluster.yml         # Cluster teardown
│   └── validate.yml                # Pre-flight validation
├── terraform/                      # Infrastructure as Code
│   ├── main.tf                     # AKS cluster definition
│   ├── variables.tf                # Input variables
│   ├── outputs.tf                  # Output values
│   ├── github.tf                   # GitHub repo & secrets
│   ├── environments/
│   │   ├── dev.tfvars              # Development environment
│   │   ├── staging.tfvars          # Staging environment
│   │   └── prod.tfvars             # Production environment
│   └── backend.tf                  # Terraform state management
├── argocd-bootstrap/               # ArgoCD bootstrap configuration
│   ├── values.yaml                 # Helm chart values
│   └── GITOPS_README.md            # GitOps repo README
├── k8s-manifests/                  # Kubernetes manifests
│   ├── namespaces.yaml             # Cluster namespaces
│   ├── rbac.yaml                   # RBAC policies
│   ├── network-policies.yaml       # Network segmentation
│   └── resource-quotas.yaml        # Resource limits
├── helm-charts/                    # Helm chart values
│   ├── prometheus/
│   │   ├── Chart.yaml
│   │   └── values.yaml
│   └── grafana/
│       ├── Chart.yaml
│       └── values.yaml
└── docs/                           # Documentation
    ├── DEPLOYMENT.md               # Deployment guide
    ├── ARCHITECTURE.md             # System design
    ├── OPERATIONS.md               # Day-2 operations
    ├── TROUBLESHOOTING.md          # Common issues
    └── SECURITY.md                 # Security best practices
```

## Features

✅ **Production-Ready**
- Multi-environment support (dev/staging/prod)
- Terraform remote state with Azure Storage
- Network policies and RBAC
- Resource quotas and pod disruption budgets

✅ **High Availability**
- Multi-zone node pools
- Auto-scaling enabled
- Pod anti-affinity rules

✅ **Security**
- Pod security policies
- Network segmentation
- Sealed secrets for GitOps
- Private cluster option

✅ **Observability**
- Prometheus metrics collection
- Grafana dashboards
- Centralized logging (optional Loki)
- Alert routing via AlertManager

✅ **GitOps**
- ArgoCD for continuous deployment
- Declarative infrastructure
- Git as single source of truth

## Documentation

- **[DEPLOYMENT.md](docs/DEPLOYMENT.md)** - Step-by-step deployment guide
- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - System design and components
- **[OPERATIONS.md](docs/OPERATIONS.md)** - Day-2 operations and maintenance
- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[SECURITY.md](docs/SECURITY.md)** - Security best practices

## Cost Estimation

Estimated monthly cost (dev environment):
- AKS cluster: ~$30
- 3x Standard_B2s nodes: ~$150
- Load balancers & storage: ~$50
- **Total: ~$230/month**

For production, allocate 2-3x more for HA setup.

## Next Steps

1. Clone this repository
2. Add GitHub Secrets (see Prerequisites)
3. Run the provision workflow
4. Access Grafana, Prometheus, and ArgoCD (see DEPLOYMENT.md)

## Support

For issues:
1. Check [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
2. Review GitHub Issues
3. Check Azure AKS documentation

## License

MIT License
