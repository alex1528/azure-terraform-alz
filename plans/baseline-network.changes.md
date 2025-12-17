# Baseline Change Summary: network

Date: 2025-12-17
Plan file: plans/baseline-network.plan
Summary: 0 to add, 20 to change, 0 to destroy

Key highlights:
- Tag normalization across network stack (hub & compute): vnet, NSGs, NICs, public IPs, bastion, firewall, route table.
- Defender for Cloud pricing `subplan` normalization for `Arm`, `KeyVaults`, `StorageAccounts`, `VirtualMachines`.
- No topology changes (no adds/deletes); all changes are in-place.

Affected resources (representative):
- Compute:
  - azurerm_resource_group.compute (tags)
  - azurerm_virtual_network.compute_vnet (tags)
  - azurerm_network_security_group.vm_nsg (tags)
  - azurerm_network_interface.vm_nic (tags)
  - azurerm_public_ip.vm_public_ip (tags)
  - azurerm_linux_virtual_machine.vm (tags)
  - azurerm_user_assigned_identity.vm_monitor_identity (tags)
- Connectivity (hub):
  - azurerm_resource_group.connectivity (tags)
  - azurerm_virtual_network.hub (tags)
  - azurerm_network_security_group.hub_subnets["snet-management"|"snet-shared-services"] (tags)
  - azurerm_public_ip.bastion / azurerm_bastion_host.main (tags)
  - azurerm_public_ip.firewall / azurerm_firewall.hub (tags)
  - azurerm_route_table.spoke_routes (tags)
- Defender subscription pricing:
  - azurerm_security_center_subscription_pricing.plan["Arm"|"KeyVaults"|"StorageAccounts"|"VirtualMachines"] (subplan -> null)

Notes:
- This network baseline reflects provider-managed tag updates only.
- For minimal drift, re-generate the baseline before next change and compare with this summary.
