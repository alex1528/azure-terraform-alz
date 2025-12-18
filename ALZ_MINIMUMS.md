# Azure Landing Zone (ALZ) 最小要求指南

本指南概述 ALZ 在任意规模部署中建议至少具备的三类属性，并给出在本仓库中的实现映射与验证方法。

## 身份（Identity）
- 建议：采用企业级身份管理（Microsoft Entra ID 等），并在平台级落地管理组层级和 RBAC 基线。
- 本仓库映射：
  - 管理组层级：`bingohr-root`/`bingohr-platform`/`bingohr-landingzones`/`bingohr-identity` 等（见 modules/management_groups）。
  - 策略与治理：核心策略在 `modules/core_policies` 赋予平台与着陆区管理组。
  - 建议补充：在管理组范围为平台/着陆区团队分配最小权限 RBAC；建立 Break-glass 账户与紧急流程（此部分通常以组织流程与 Entra 目录配置实现）。

## 网络架构设计（拓扑）
- 建议：显式定义拓扑（Hub/Spoke 等），并规划与本地互联的混合连接（ExpressRoute 或 VPN Gateway）。
- 本仓库映射：
  - Hub/Spoke：`modules/connectivity` 提供 Hub VNet、Bastion、Firewall、路由等。
  - 计算着陆：`modules/compute` 提供 Spoke/工作负载侧网络与示例 VM。
  - 建议补充：按需启用混合连接（`az network vnet-gateway`：VPN/ExpressRoute）。当前未强制启用，脚本会给出提醒。

## 资源组织（命名与标签）
  - 命名：统一前缀 `bingohr-` + 组件 + 区域 + 后缀（例如 `bingohr-connectivity-eastasia-rg`）。
  - 标签：为资源与资源组附加 `CostCenter`、`Environment`、`ManagedBy`、`Owner`、`Project` 等常用键。
  - 现状（已实施）：在平台与着陆区管理组范围启用内置策略 “Require a tag and its value on resource groups”，强制以下标签：
    - `Environment = BingoHR-ALZ`（平台：core-tag-env，着陆区：lz-tag-env）
    - `CostCenter = ALZ`（平台：core-tag-cost，着陆区：lz-tag-cost）
    - `Owner = ALZ`（平台：core-tag-owner，着陆区：lz-tag-owner）
  - 说明：可通过模块变量覆盖默认值（见 modules/core_policies/variables.tf）。

### 验证强制标签策略
使用计划文件或 Azure CLI 验证策略分配是否生效：

```powershell
# 直接应用已生成的策略启用计划
terraform apply "plans/tag-policy-enable.plan"
terraform plan -out "plans/tag-policy-extend.plan"

# 或使用 CLI 查看管理组范围的策略分配
az policy assignment list --scope "/providers/Microsoft.Management/managementGroups/bingohr-platform" | ConvertFrom-Json | where displayName -match "Require a tag"
az policy assignment list --scope "/providers/Microsoft.Management/managementGroups/bingohr-landingzones" | ConvertFrom-Json | where displayName -match "Require a tag"

# 按标签键筛选（Environment/CostCenter/Owner）
az policy assignment list --scope "/providers/Microsoft.Management/managementGroups/bingohr-platform" | ConvertFrom-Json | Where-Object { $_.parameters.tagName.value -in @('Environment','CostCenter','Owner') }
az policy assignment list --scope "/providers/Microsoft.Management/managementGroups/bingohr-landingzones" | ConvertFrom-Json | Where-Object { $_.parameters.tagName.value -in @('Environment','CostCenter','Owner') }
```

### 策略豁免（Sandbox）示例
出于研发/临时需求，可为着陆区中的特定策略创建到期豁免：
- 资源：`azurerm_management_group_policy_exemption.sandbox_exemptions`（见 modules/core_policies/main.tf）
- 启用方式：设置变量 `create_sandbox_exemptions = true` 并配置 `sandbox_exemption_expiry` 到期时间。
- 范围：默认示例对 `deny_rdp_from_internet` 创建豁免。可按需扩展至其他策略（不建议对强制标签策略豁免）。

## 一键验证（Windows PowerShell）
使用 Azure CLI 已登录的上下文，执行：

```powershell
pwsh scripts/validate-minimums.ps1 -Prefix "bingohr" -Region "eastasia"
```

说明：
- 身份：检查 `bingohr-identity` / `bingohr-platform` / `bingohr-landingzones` 管理组是否存在。
- 网络：检查 Hub VNet、Bastion、Firewall；如未检测到 VPN/ExpressRoute 网关则给出提醒。
- 资源组织：检查关键资源组上是否具备建议标签；在平台/着陆区范围是否存在与 Tag 相关的策略分配。

## 后续可选强化
- 自动化 RBAC：在管理组范围为平台、着陆区、运营团队绑定 Entra 组与最小权限角色。
- 混合网络：按需部署 `azurerm_virtual_network_gateway`（VPN/ER）与相应连接对象，实现与本地互联。
- 标签策略：在 `modules/core_policies` 增加“必需标签”类内置策略的分配，以强制执行标签标准。
