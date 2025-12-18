# Azure Landing Zone Terraform Implementation ☁️🏗️

**Production-ready Azure Landing Zone (ALZ)** implementation using **Terraform** that provides flexible networking architectures, essential security policies, and follows Microsoft's Cloud Adoption Framework best practices.

> Language: This README is available in Chinese. See [README.zh-CN.md](README.zh-CN.md).

## 🎯 **What This Implementation Provides**

This Terraform implementation delivers a **practical and balanced approach** to Azure Landing Zones:

- 🏗️ **Complete ALZ Management Group Hierarchy** - Full Microsoft-recommended structure
- 🌐 **Flexible Network Architecture** - Choose Hub & Spoke, Virtual WAN, or no networking
- 🛡️ **Essential Security Policies** - Core security controls without overwhelming complexity
- 📊 **Centralized Monitoring** - Log Analytics workspaces and automation accounts
- 💰 **Cost-Conscious Design** - Optional resource deployment to control expenses
- 🔧 **Production-Ready** - Supports both audit and enforce policy modes

## 🆕 New Features

Recent updates add practical capabilities to simplify validation and enable compute and monitoring scenarios:

- 🖥️ **Compute Module (Optional)**
  - Enable VM deployment flags via `deploy_compute_resources`
  - Configurable `vm_os_type`, `vm_size`, public IP options
- 🔑 **SSH Key Generation Modes**
  - Terraform-generated keys when `generate_ssh_key = true`
  - External/local public key support and validation checks
  - Guidance on state protection when storing private keys
- 📈 **Azure Monitor Integration**
  - Data Collection Rules and Monitor Agent enablement
  - Log Analytics workspace creation for prod/non-prod
  - See the Chinese guide: [AZURE_MONITOR_GUIDE.md](AZURE_MONITOR_GUIDE.md)
- 🔒 **TLS Provider Support**
  - Enables secure key/tls operations for certain scenarios
- ✅ **Enhanced Validation Tooling**
  - `validate-alz.sh` for environment and configuration checks
  - `validate-alz-features.sh` for feature completeness checks
  - Comprehensive documentation: `VALIDATION_SCRIPT_ASSESSMENT.md`, `VALIDATION_SCRIPTS_GUIDE.md`

## 📊 **Architecture Overview**

```mermaid
graph TB
    subgraph "Azure Tenant"
        TenantRoot["🏢 Tenant Root Group"]
        
        subgraph "ALZ Management Groups"
            ALZRoot["📁 [Org] ALZ Root<br/>Governance & Policies"]
            
            subgraph "Platform Services"
                Platform["🔧 Platform"]
                Connectivity["🌐 Connectivity<br/>Hub VNet or vWAN"]
                Identity["👤 Identity<br/>Azure AD Services"]
                Management["⚙️ Management<br/>Log Analytics & Automation"]
        Monitor["📈 Monitor<br/>Agent & DCR"]
            end
            
            subgraph "Workload Landing Zones"
                LandingZones["🚀 Landing Zones"]
                Production["🏭 Production<br/>Prod Workloads"]
                NonProduction["🧪 Non-Production<br/>Dev/Test Workloads"]
        Compute["🖥️ Compute Module<br/>Optional VM Resources"]
            end
            
            Sandboxes["🏖️ Sandboxes<br/>Learning & Innovation"]
            Decommissioned["📦 Decommissioned<br/>Legacy Resources"]
        end
        
        subgraph "Optional Infrastructure" 
            subgraph "Hub & Spoke Network"
                HubVNet["🏢 Hub Virtual Network<br/>10.0.0.0/22"]
                SharedSvcs["📡 Shared Services<br/>10.0.0.0/24"]
                MgmtSvcs["⚙️ Management<br/>10.0.1.0/24"]
                BastionSub["🛡️ Bastion Subnet<br/>10.0.2.0/26"]
                FwSub["🔥 Firewall Subnet<br/>10.0.3.0/26"]
            end
            
            subgraph "Virtual WAN Alternative"
                vWAN["🌐 Virtual WAN"]
                vHub["🔗 Virtual Hub<br/>10.0.0.0/24"]
                ERGateway["🔌 ExpressRoute Gateway"]
                VPNGateway["🔐 VPN Gateway"]
            end
            
            subgraph "Management Resources"
                LogAnalytics["📈 Log Analytics Workspaces<br/>Production & Non-Production"]
                AutomationAcct["🤖 Azure Automation Account"]
        DataCollection["📊 Data Collection Rules (DCR)"]
            end
            
      subgraph "Access & Keys"
        SSHKeys["🔑 SSH Keys<br/>Terraform or External"]
        TLSProv["🔒 TLS Provider<br/>Key/Cert Utilities"]
      end
        end
    end

    %% Relationships
    TenantRoot --> ALZRoot
    ALZRoot --> Platform
    ALZRoot --> LandingZones
    ALZRoot --> Sandboxes
    ALZRoot --> Decommissioned
    
    Platform --> Connectivity
    Platform --> Identity  
  Platform --> Management
  Platform --> Monitor
    
    LandingZones --> Production
    LandingZones --> NonProduction
  LandingZones --> Compute
    
    %% Optional Infrastructure Connections
    Connectivity -.-> HubVNet
    Connectivity -.-> vWAN
    HubVNet --> SharedSvcs
    HubVNet --> MgmtSvcs
    HubVNet --> BastionSub
    HubVNet --> FwSub
    vWAN --> vHub
    vHub -.-> ERGateway
    vHub -.-> VPNGateway
  Management -.-> LogAnalytics
    Management -.-> AutomationAcct
  Monitor -.-> DataCollection
  Monitor --> LogAnalytics
  Compute -.-> LogAnalytics
  SSHKeys -.-> Compute
  TLSProv -.-> SSHKeys
  TLSProv -.-> Compute

    %% Styling
    classDef mgmtGroup fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef platform fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef workload fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef network fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef optional fill:#f5f5f5,stroke:#616161,stroke-width:1px,stroke-dasharray: 5 5
    
    class ALZRoot,TenantRoot mgmtGroup
  class Platform,Connectivity,Identity,Management,Monitor platform
  class LandingZones,Production,NonProduction,Compute,Sandboxes,Decommissioned workload
    class HubVNet,vWAN,SharedSvcs,MgmtSvcs,BastionSub,FwSub,vHub network
  class LogAnalytics,AutomationAcct,DataCollection,ERGateway,VPNGateway,SSHKeys optional
    class TLSProv optional
```

### TLS Provider Placement & Purpose

- Location: Under "Access & Keys" alongside `SSHKeys` in the architecture.
- Purpose: Provides secure key and certificate utilities used by optional compute scenarios and SSH key workflows.
- Interactions:
  - Assists `SSHKeys` when generating or handling key material
  - Supports `Compute` module for scenarios needing TLS key/cert operations

## 🏗️ **What Gets Deployed**

### **Core Components (Always Deployed)**
1. **Management Group Hierarchy** - Complete ALZ structure with 9 management groups
2. **Subscription Assignments** - Optional assignment of subscriptions to management groups

### **Optional Components (Configurable)**
3. **Connectivity Infrastructure** - Hub & Spoke VNet OR Virtual WAN architecture
4. **Security Policies** - 8 essential security policies (audit or enforce mode)
5. **Management Resources** - Log Analytics workspaces and Azure Automation
6. **Monitoring Setup** - Data collection rules and centralized logging

## 🛡️ **Security Policies Deployed**

When `deploy_core_policies = true`, the following **essential security controls** are applied:

| Policy | Purpose | Target Scope | Enforcement |
|--------|---------|-------------|-------------|
| **Secure Storage Transfer** | Require HTTPS for storage accounts | All Resources | Configurable |
| **SQL Encryption** | Require Transparent Data Encryption | All Resources | Configurable |
| **VM Backup Protection** | Require Azure Backup for VMs | Landing Zones | Configurable |
| **Location Restrictions** | Limit resource deployment regions | All Resources | Configurable |
| **Resource Tagging (Presence)** | Require Environment, CostCenter, Owner tags on resource groups | Management Groups (Platform & Landing Zones) | Configurable |
| **Tag Value Enforcement (RG)** | Enforce specific tag values on resource groups (Environment/CostCenter/Owner) | Management Groups (Platform & Landing Zones) | Configurable |
| **Network Security** | Block RDP/SSH from Internet | Landing Zones | Configurable |
| **Key Vault Protection** | Require purge protection | All Resources | Configurable |
| **Activity Log Retention** | Ensure logging compliance | All Resources | Configurable |

**Policy Modes:**
- `DoNotEnforce` (Audit Mode) - Report violations without blocking
- `Default` (Enforce Mode) - Block non-compliant resource deployment

## 🏷️ **Tag Governance (Presence & Value)**

This implementation includes practical tag governance at the management group scopes:

- **Presence Enforcement (Built-in)**: Require `Environment`, `CostCenter`, `Owner` tags on resource groups at Platform and Landing Zones.
- **Value Enforcement (Custom Policy)**: Optionally enforce specific values for those tags on resource groups.

Configuration knobs:
- `policy_enforcement_mode`: `DoNotEnforce` → Audit, `Default` → Deny.
- `required_environment_tag`, `required_cost_center_tag`, `required_owner_tag`: Desired tag values used by value-enforcement policy.

Plan & apply examples:
```powershell
# Generate plan (already part of defaults)
terraform plan -out "plans/tag-value-enforce.plan"

# Apply exactly the planned changes
terraform apply "plans/tag-value-enforce.plan"
```

## 🔐 **Secure VM Access via Azure Bastion**

To comply with the **Network Security Policy** that blocks SSH/RDP from the internet, this implementation uses **Azure Bastion** for secure VM management:

### Architecture
```
Internet User
    ↓
Azure Portal / Azure Bastion Service
    ↓
Azure Bastion Host (10.0.2.0/26)
    ↓
Private VMs (No public IP exposure)
```

### Configuration
- `deploy_azure_bastion = true` in `terraform.tfvars` enables Bastion
- VM Network Security Group rules:
  - ✅ SSH (port 22): Allowed from Bastion subnet only (10.0.2.0/26)
  - ✅ RDP (port 3389): Allowed from Bastion subnet only (10.0.2.0/26)
  - ❌ SSH/RDP: Blocked from internet (0.0.0.0/0)

### Usage: Access VM via Azure Bastion

**Option 1: Via Azure Portal (Easiest)**
```bash
# In Azure Portal:
1. Navigate to your Virtual Machine resource
2. Click "Connect" → "Bastion"
3. Select username and authentication method (SSH key or password)
4. Click "Connect" - browser-based terminal opens
```

**Option 2: Via Azure CLI (Native SSH)**
```bash
# Connect with SSH key
az network bastion ssh \
  --name "<bastion-name>" \
  --resource-group "<resource-group>" \
  --target-resource-id "<vm-resource-id>" \
  --auth-type "ssh-key" \
  --username "azureuser" \
  --ssh-key "@<path-to-private-key>"
```

**Option 3: Via RDP (for Windows VMs)**
```bash
# Enable RDP tunneling through Bastion
az network bastion rdp \
  --name "<bastion-name>" \
  --resource-group "<resource-group>" \
  --target-resource-id "<vm-resource-id>" \
  --username "azureuser"

# Then use Remote Desktop Connection to localhost:13389
```

### Benefits
- 🔒 VMs don't need public IP addresses
- 🌐 No exposure to internet-based SSH/RDP attacks
- 🔑 Managed authentication via Azure AD
- 📊 Full audit trail of access through Azure Monitor
- ✅ Complies with "Block RDP/SSH from Internet" policy

## 🌐 **Network Architecture Options**

### **Option 1: Hub & Spoke (Default)**
```
Hub VNet (10.0.0.0/22)
├── Shared Services (10.0.0.0/24)
├── Management (10.0.1.0/24)  
├── Azure Bastion (10.0.2.0/26)
└── Azure Firewall (10.0.3.0/26)

Connected Spoke VNets:
├── Production Workloads
├── Development Workloads
└── Management Workloads
```

### **Option 2: Virtual WAN**
```
Virtual WAN
└── Virtual Hub (10.0.0.0/24)
    ├── ExpressRoute Gateway (Optional)
    ├── VPN Gateway (Optional)
    └── Azure Firewall (Optional)

Connected VNets:
├── Production Workloads
├── Development Workloads
└── Management Workloads
```

### **Option 3: No Networking**
- Management groups and policies only
- Ideal for initial governance deployment
- Networking can be added later

## 🚀 **Quick Start**

### **1. Prerequisites**

**Azure Environment:**
```bash
# Azure CLI login with appropriate permissions
az login
az account set --subscription "<management-subscription-id>"

# Terraform >= 1.5.0
terraform version
```

**Terraform Backend Storage Account:**
You'll need an Azure Storage Account for Terraform state management. You can either:

**Option A: Use existing storage account**
- Ensure you have a storage account with a blob container
- Note the resource group name, storage account name, and container name

**Option B: Create new storage account**
```bash
# Create resource group for Terraform state
az group create --name "rg-terraform-state-prod" --location "westus3"

# Create storage account
az storage account create \
  --name "stterraformstateprod001" \
  --resource-group "rg-terraform-state-prod" \
  --location "westus3" \
  --sku "Standard_LRS" \
  --encryption-services blob

# Create container
az storage container create \
  --name "tfstate" \
  --account-name "stterraformstateprod001"
```

### **2. Backend Configuration**
This implementation uses Azure Storage as the Terraform backend for state management. You need to set up the backend configuration before deployment.

**Option 1: Using Backend Config File (Recommended)**
```bash
# Copy the example configuration
cp backend.conf.example backend.conf

# Edit backend.conf with your values
# Required values:
# - resource_group_name: Resource group containing the storage account
# - storage_account_name: Name of your Terraform state storage account  
# - container_name: Container name (e.g., "tfstate")
# - key: State file key (e.g., "alz/terraform.tfstate")
# - subscription_id: Azure subscription ID
# - tenant_id: Azure tenant ID
```

**Option 2: Using CLI Parameters**
```bash
# Initialize with CLI parameters
terraform init \
  -backend-config="resource_group_name=rg-terraform-state-prod" \
  -backend-config="storage_account_name=stterraformstateprod001" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=alz/terraform.tfstate" \
  -backend-config="use_azuread_auth=true" \
  -backend-config="subscription_id=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" \
  -backend-config="tenant_id=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

**Backend Authentication Methods:**
- **Azure AD Auth** (Recommended): `use_azuread_auth = true`
- **Access Key**: `access_key = "your-storage-account-access-key"`
- **SAS Token**: `sas_token = "your-sas-token"`

### **3. Configuration**
Edit `terraform.tfvars` for your environment:
```hcl
# Core Settings
root_management_group_name = "Contoso ALZ"
resource_prefix           = "contoso"
org_name                 = "contoso" 
location                 = "westus3"

# Network Architecture Choice
network_architecture = "hub_spoke"  # or "vwan" or "none"
deploy_connectivity_resources = true

# Security Policies
deploy_core_policies    = true
policy_enforcement_mode = "DoNotEnforce"  # Start in audit mode

# Optional Resources
deploy_log_analytics_workspace = true
deploy_automation_account      = true
```

### **4. Validate & Deploy**
```bash
# Optional: Run comprehensive validation script
./validate-alz.sh

# Optional: Run features validation for compute/monitor/ssh
./validate-alz-features.sh

# Initialize Terraform with backend configuration
terraform init -backend-config=backend.conf

# Review deployment plan
terraform plan

# Deploy infrastructure
terraform apply
```

**📋 Validation Script (Optional but Recommended)**

The included `validate-alz.sh` script performs comprehensive pre-deployment checks:
- ✅ Azure CLI and Terraform installation & versions
- ✅ Azure authentication and permissions
- ✅ Terraform configuration validation
- ✅ Required variables and configuration recommendations
- ✅ Dry-run terraform plan execution

Run `./validate-alz.sh` before deployment to catch common issues early.

For feature coverage (Compute/SSH/Monitor), also run `./validate-alz-features.sh`.

## 🗃️ **State Management**

This implementation uses **Azure Storage** for Terraform state management with the following benefits:

- **🔒 Secure State Storage** - State files stored in Azure Storage with encryption
- **👥 Team Collaboration** - Shared state access for multiple team members
- **🔐 Access Control** - Azure RBAC and Azure AD authentication
- **📋 State Locking** - Automatic state locking to prevent concurrent modifications
- **🔄 Versioning** - State file versioning and backup capabilities

### **Backend File Structure**
```
backend.conf                 # Your backend configuration (gitignored)
backend.conf.example         # Template file with examples
versions.tf                  # Terraform and provider version constraints
```

The `backend.conf` file is automatically excluded from git commits to protect sensitive information.

## 📁 **Module Structure**

```
azure-terraform-alz/
├── main.tf                    # Root orchestration
├── versions.tf                # Terraform & provider versions + backend config
├── variables.tf               # Input variables  
├── locals.tf                  # Computed values
├── outputs.tf                 # Output values
├── terraform.tfvars           # Configuration
├── backend.conf.example       # Backend configuration template
├── validate-alz.sh            # Pre-deployment validation script
├── .gitignore                 # Excludes sensitive files and state
└── modules/
    ├── management_groups/     # ALZ management group hierarchy
    │   ├── main.tf           # Management group resources
    │   ├── variables.tf      # Module variables
    │   └── outputs.tf        # Management group IDs
    ├── connectivity/          # Network infrastructure
    │   ├── main.tf           # Hub & Spoke or Virtual WAN
    │   ├── variables.tf      # Network configuration
    │   └── outputs.tf        # Network resource outputs
    ├── core_policies/         # Essential security policies
    │   ├── main.tf           # Policy definitions & assignments
    │   ├── variables.tf      # Policy configuration
    │   └── outputs.tf        # Policy assignment IDs
    └── optional_resources/    # Management resources
        ├── main.tf           # Log Analytics, Automation
        ├── variables.tf      # Optional resource flags
        └── outputs.tf        # Resource outputs
```

## ⚙️ **Configuration Options**

### **Network Architecture Selection**
```hcl
network_architecture = "hub_spoke"  # Traditional hub and spoke
network_architecture = "vwan"       # Virtual WAN for complex connectivity  
network_architecture = "none"       # Management groups and policies only
```

### **Subscription Assignments**
```hcl
# Assign subscriptions to management groups (optional)
connectivity_subscription_id = "00000000-0000-0000-0000-000000000000"
identity_subscription_id     = "11111111-1111-1111-1111-111111111111" 
management_subscription_id   = "22222222-2222-2222-2222-222222222222"
```

### **Hub & Spoke Network Settings**
```hcl
hub_vnet_address_space = ["10.0.0.0/22"]

hub_subnets = {
  "snet-shared-services" = { address_prefixes = ["10.0.0.0/24"] }
  "snet-management"      = { address_prefixes = ["10.0.1.0/24"] }
  "AzureBastionSubnet"   = { address_prefixes = ["10.0.2.0/26"] }
  "AzureFirewallSubnet"  = { address_prefixes = ["10.0.3.0/26"] }
}
```

### **Virtual WAN Settings**
```hcl
virtual_hub_address_prefix   = "10.0.0.0/24"
deploy_express_route_gateway = false
deploy_vpn_gateway          = false
```

## 🎯 **Deployment Strategies**

### **Strategy 1: Phased Approach (Recommended)**
```bash
# Phase 0: Setup Backend Configuration
cp backend.conf.example backend.conf
# Edit backend.conf with your storage account details

# Phase 0.5: Validate Configuration (Recommended)
./validate-alz.sh

# Phase 1: Management Groups + Audit Policies
terraform init -backend-config=backend.conf
terraform apply \
  -var="deploy_connectivity_resources=false" \
  -var="policy_enforcement_mode=DoNotEnforce"

# Phase 2: Add Networking
terraform apply \
  -var="deploy_connectivity_resources=true"

# Phase 3: Enable Policy Enforcement (Optional)
terraform apply \
  -var="policy_enforcement_mode=Default"
```

### **Strategy 2: All-at-Once**
```bash
# Setup backend and deploy everything with audit-mode policies
./validate-alz.sh  # Optional validation
terraform init -backend-config=backend.conf
terraform apply
```

## 🗂️ **Baselines & Plan Summaries**

Keep plan artifacts tidy and summarized with the maintenance script:

```powershell
# Generate summaries for default baseline plans and commit/push
pwsh -NoProfile scripts/maintain-baselines.ps1

# Defaults include:
# - plans/baseline-policy.plan
# - plans/baseline-network.plan
# - plans/tag-value-enforce.plan
# - plans/baseline-defender.plan
```

Outputs:
- plans/baseline-policy.changes.md
- plans/baseline-network.changes.md
- plans/tag-value-enforce.changes.md
- plans/baseline-defender.changes.md

### Compliance Snapshot (Auto-archived)

Maintenance script now exports compliance snapshots (JSON + Markdown) and auto-commits/pushes:

```powershell
# One-click maintenance + compliance snapshot
pwsh scripts/maintain-baselines.ps1

# On-demand snapshot (artifacts under plans/compliance)
pwsh scripts/export-compliance-snapshot.ps1

# Schedule daily/weekly maintenance + snapshot
pwsh scripts/setup-maintenance-schedule.ps1 -CreateDaily
pwsh scripts/setup-maintenance-schedule.ps1 -CreateWeekly -WeeklyDay Sunday -WeeklyTime 02:30
```

## 📊 **Resource Outputs**

After deployment, you'll have access to:

- **Management Group IDs** - For workload subscription assignments
- **Network Resource IDs** - Hub VNet or Virtual WAN for spoke connections
- **Policy Assignment IDs** - For compliance monitoring
- **Log Analytics Workspace IDs** - For workload monitoring integration

## 🔍 **Monitoring & Compliance**

### **Policy Compliance**
- View compliance in Azure Policy blade
- Review violations before enabling enforce mode
- Export compliance reports for auditing

### **Centralized Logging**
- Production Log Analytics Workspace
- Non-Production Log Analytics Workspace  
- Azure Automation Account for runbook management

### **Cost Management**
- Resource tagging for cost allocation
- Optional resource deployment to control expenses
- Proper resource naming for cost center identification

## ❓ **FAQ**

### **Q: How do I set up the Terraform backend storage account?**
**A:** You need an Azure Storage Account before deployment:
1. Create a storage account and container (see Prerequisites section)
2. Copy `backend.conf.example` to `backend.conf`
3. Update `backend.conf` with your storage account details
4. Run `terraform init -backend-config=backend.conf`

**The `backend.conf` file is gitignored to protect sensitive information.**

### **Q: Can I migrate from local state to Azure backend?**
**A:** Yes! Use the `terraform init -migrate-state` command after configuring your backend:
```bash
# Add backend configuration to versions.tf (already done)
# Create backend.conf file with your storage details
terraform init -backend-config=backend.conf -migrate-state
```

### **Q: What permissions do I need for the backend storage account?**
**A:** For Azure AD authentication (recommended), you need:
- `Storage Blob Data Contributor` role on the storage account
- `Reader` role on the resource group containing the storage account
- Or use storage account access keys (less secure but simpler)

### **Q: What's the difference between this and the ALZ Accelerator?**
**A:** This implementation focuses on **essential ALZ components** with **simplified complexity**:
- **ALZ Accelerator**: 100+ policies, complex CI/CD setup, enterprise-scale complexity
- **This Implementation**: 8 essential policies, direct Terraform deployment, practical simplicity

### **Q: Can I add more policies later?**
**A:** Yes! The `core_policies` module is designed to be easily extended. You can add additional Azure Policy definitions and assignments as needed.

### **Q: Which network architecture should I choose?**
**A:**
- **Hub & Spoke**: Best for most scenarios, traditional networking teams, single-region deployments
- **Virtual WAN**: Best for multi-region, complex connectivity scenarios, SD-WAN integration
- **None**: Best for initial governance deployment, add networking later

### **Q: How do I add workload subscriptions?**
**A:** After deployment:
1. Create or identify workload subscriptions
2. Assign them to appropriate management groups (Production/Non-Production)
3. Deploy spoke VNets that peer to the hub infrastructure
4. Apply workload-specific policies and configurations

### **Q: Is this production-ready?**
**A:** Yes, but follow best practices:
- Start with audit mode policies (`DoNotEnforce`)
- Test connectivity before deploying workloads
- Gradually enable policy enforcement
- Monitor compliance before moving to production

## 📚 **Additional Resources**

- [Azure Landing Zones Documentation](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/)
- [Azure Policy Documentation](https://docs.microsoft.com/azure/governance/policy/)
- [Hub-Spoke Network Architecture](https://docs.microsoft.com/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)
- [Virtual WAN Documentation](https://docs.microsoft.com/azure/virtual-wan/)
- [Azure Management Groups](https://docs.microsoft.com/azure/governance/management-groups/)

### 📄 Documentation in Chinese
- 项目中文总览: [README.zh-CN.md](README.zh-CN.md)
- Azure 监控集成指南: [AZURE_MONITOR_GUIDE.md](AZURE_MONITOR_GUIDE.md)

---

## 🤝 **Contributing**

This implementation prioritizes:
- **Clarity** - Easy to understand and modify
- **Practicality** - Real-world production use
- **Flexibility** - Adaptable to different organizational needs
- **Maintainability** - Simple ongoing management

Feel free to fork and customize for your specific requirements!

## 📞 **Support**

- Create an [issue](https://github.com/travishankins/azure-terraform-alz/issues) for bug reports and feature requests
- Check [Azure Landing Zones documentation](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/) for architectural guidance
- Review [ALZ Accelerator](https://azure.github.io/Azure-Landing-Zones/accelerator/) for enterprise-scale patterns
- Explore [Azure Policy samples](https://docs.microsoft.com/azure/governance/policy/samples/) for additional governance policies
- Visit [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) for resource documentation

---

**Built with ❤️ following Azure Landing Zone best practices**