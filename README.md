# Azure project Terraform starter

This is a Terraform-first starter for the **Administering cloud solutions** project.
It covers the core infrastructure and adds sample application code, Kubernetes manifests, helper scripts, and KQL queries.

## What is included

- Resource group and mandatory tags
- Two VNets and subnet separation
- Exactly two public IPs: Jump VM and Application Gateway
- Windows Jump VM with restricted RDP source IPs
- Private AKS cluster with OIDC + workload identity enabled
- User-assigned identity for workloads so it survives AKS recreation
- ACR, Key Vault, Storage Account, PostgreSQL Flexible Server
- Function App with VNet integration and private endpoint
- Private endpoints and private DNS zones for key private services
- Log Analytics, Application Insights, VM AMA + DCR, AKS container monitoring
- Application Gateway skeleton with `/aks` and `/functionap` path routing
- Azure File Sync foundation resources
- Sample AKS app, sample Function App, helper scripts, workbook KQL queries

## Important limits / manual finishing points

This repo is intentionally honest about the hard parts:

1. **Application Gateway certificate**
   - The code expects a Key Vault secret named `appgw-cert`.
   - Import a self-signed PFX into Key Vault, then keep the secret name or update the Terraform placeholder.

2. **AKS backend behind Application Gateway**
   - The Application Gateway contains a placeholder AKS backend IP (`10.50.1.10`).
   - Replace it with the private IP of your actual AKS ingress path, usually an internal NGINX ingress service or another private ingress endpoint.

3. **Azure File Sync server endpoint**
   - Terraform can create the Storage Sync Service, Sync Group, and Cloud Endpoint.
   - The on-premises/jump-VM-side server registration and server endpoint attachment are commonly finished after the Azure File Sync agent is installed on the Windows server.

4. **Function App deployment package**
   - Infrastructure is created here, but the Python Function code still needs to be zipped and deployed.

## Suggested deployment order

```bash
cp terraform.tfvars.example terraform.tfvars
# edit values
terraform init
terraform plan
terraform apply
```

Then finish:

1. Build and push the AKS image to ACR.
2. Import the TLS certificate into Key Vault.
3. Install ingress in AKS and update the Application Gateway AKS backend target.
4. Deploy Function App code.
5. Apply the Kubernetes manifests after replacing placeholders.
6. Install Azure File Sync agent on the Jump VM and connect the server endpoint.

## Build and push sample AKS image

```bash
ACR_NAME=$(terraform output -raw acr_login_server | cut -d. -f1)
az acr build -r "$ACR_NAME" -t aks-sample:latest ./apps/aks_app
```

## Deploy the Function App code

From `apps/function_app/`, create a zip package and deploy it with Azure CLI or VS Code Azure Functions extension.

## Kubernetes manifest placeholders to replace

- `REPLACE_WITH_WORKLOAD_UAMI_CLIENT_ID`
- `REPLACE_WITH_ACR_LOGIN_SERVER`
- `REPLACE_WITH_STORAGE_ACCOUNT_NAME`
- `REPLACE_WITH_KEY_VAULT_NAME`

## Grading helpers

- `scripts/list_resources.sh`
- `scripts/list_resources.py`
- `workbook-queries.kql`

## Notes

- Smallest SKUs vary by subscription and region. If a burstable size is unavailable, change the variable value.
- The code uses RBAC for Key Vault instead of legacy access policies.
- Provider versions can evolve. Re-run `terraform init -upgrade` before final submission.
