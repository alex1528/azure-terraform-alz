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
- 建议：统一的命名与标签标准，并在平台/着陆区强制实施（Azure Policy）。
- 本仓库映射：
  - 命名：统一前缀 `bingohr-` + 组件 + 区域 + 后缀（例如 `bingohr-connectivity-eastasia-rg`）。
  - 标签：为资源与资源组附加 `CostCenter`、`Environment`、`ManagedBy`、`Owner`、`Project` 等常用键。
  - 建议补充：在管理组范围启用内置策略 “Require a tag and its value” 系列，保障强制合规。

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
