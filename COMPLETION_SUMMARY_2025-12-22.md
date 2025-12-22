# 追加完成总结（2025-12-22）

## 网络与对等
- Prod 地址空间收敛：VNet 10.12.0.0/16，工作负载子网 10.12.1.0/24。
- Hub↔Prod Peering：已恢复双向对等，状态 Connected。
  - Hub→Prod：bingohr-connectivity-eastasia-rg / bingohr-hub-eastasia-vnet / hub-to-prod
  - Prod→Hub：bingohr-prod-webmysql-eastasia-rg / bingohr-prod-webmysql-eastasia-vnet / prod-to-hub

## 防火墙与平台 IP
- 应用规则（HTTP/HTTPS）：Ubuntu APT/FQDN、Microsoft 登录与包源、Snapcraft、备份/存储。
- 网络规则（平台 IP）：168.63.129.16 的 TCP 80/443 与 UDP 53。

## 出网验证
- 执行方式：Azure RunCommand 在 Prod Web VM 内触发 curl 与 apt IPv4 强制更新，命令返回成功（ProvisioningState succeeded）。
- 推荐二次验证命令：

```powershell
# Peering 状态确认
az network vnet peering show -g bingohr-connectivity-eastasia-rg --vnet-name bingohr-hub-eastasia-vnet -n hub-to-prod --query peeringState -o tsv
az network vnet peering show -g bingohr-prod-webmysql-eastasia-rg --vnet-name bingohr-prod-webmysql-eastasia-vnet -n prod-to-hub --query peeringState -o tsv

# 在 Prod Web VM 内部执行（Azure RunCommand）
az vm run-command invoke -g bingohr-prod-webmysql-eastasia-rg -n bingohr-prod-web \
  --command-id RunShellScript \
  --scripts "sudo apt-get -o Acquire::ForceIPv4=true update -y && for h in azure.archive.ubuntu.com archive.ubuntu.com security.ubuntu.com packages.microsoft.com login.microsoftonline.com management.azure.com snapcraft.io api.snapcraft.io; do curl -I --max-time 15 https://$h || true; done && curl -I --max-time 10 http://168.63.129.16 || true"
```

## 关键 Terraform 输出
- Prod 私网 IP：workload_prod_private_ips = { mysql = 10.12.1.4, web = 10.12.1.5 }
- Prod Web 公网 IP：workload_prod_web_public_ip = 52.184.19.72
