# Baseline Change Summary: policy

Date: 2025-12-17
Plan file: plans/baseline-policy.plan
Summary: 0 to add, 20 to change, 0 to destroy

Key highlights:
- Tag normalization: timestamp/metadata `tags` 更新（提供程序管理，无功能变化）。
- Defender for Cloud 订阅定价：`subplan` 字段归一化为 `null`（`Arm`、`KeyVaults`、`StorageAccounts`、`VirtualMachines`）。
- 无资源新增/删除，全部为就地更新。

Detailed Resource Changes (exact instances):
- module.compute.azurerm_linux_virtual_machine.vm[0]: tags 更新（CostCenter, CreatedDate, DeployedBy, Environment, Framework, LastUpdated, ManagedBy, NetworkArchitecture, Owner, Project）。
- module.compute.azurerm_network_interface.vm_nic[0]: tags 更新（同上）。
- module.compute.azurerm_network_security_group.vm_nsg[0]: tags 更新（同上）。
- module.compute.azurerm_public_ip.vm_public_ip[0]: tags 更新（同上）。
- module.compute.azurerm_resource_group.compute[0]: tags 更新（同上）。
- module.compute.azurerm_user_assigned_identity.vm_monitor_identity[0]: tags 更新（含 `LastUpdated` 字段格式归一）。
- module.compute.azurerm_virtual_network.compute_vnet[0]: tags 更新（同上）。
- module.connectivity[0].azurerm_bastion_host.main[0]: tags 更新（同上）。
- module.connectivity[0].azurerm_firewall.hub[0]: tags 更新（同上）。
- module.connectivity[0].azurerm_network_security_group.hub_subnets["snet-management"]: tags 更新（同上）。
- module.connectivity[0].azurerm_network_security_group.hub_subnets["snet-shared-services"]: tags 更新（同上）。
- module.connectivity[0].azurerm_public_ip.bastion[0]: tags 更新（同上）。
- module.connectivity[0].azurerm_public_ip.firewall[0]: tags 更新（同上）。
- module.connectivity[0].azurerm_resource_group.connectivity: tags 更新（同上）。
- module.connectivity[0].azurerm_route_table.spoke_routes[0]: tags 更新（同上）。
- module.connectivity[0].azurerm_virtual_network.hub[0]: tags 更新（同上）。
- module.optional_resources.azurerm_security_center_subscription_pricing.plan["Arm"]: subplan 由 "PerSubscription" -> null。
- module.optional_resources.azurerm_security_center_subscription_pricing.plan["KeyVaults"]: subplan 由 "PerKeyVault" -> null。
- module.optional_resources.azurerm_security_center_subscription_pricing.plan["StorageAccounts"]: subplan 由 "DefenderForStorageV2" -> null。
- module.optional_resources.azurerm_security_center_subscription_pricing.plan["VirtualMachines"]: subplan 由 "P2" -> null。

Notes:
- 以上更新为基线漂移的正常化体现，主要由提供程序管理的 `tags` 和订阅定价 `subplan` 字段导致。
- 为最小漂移，建议在下一次变更前重新生成基线并与本摘要比对。
