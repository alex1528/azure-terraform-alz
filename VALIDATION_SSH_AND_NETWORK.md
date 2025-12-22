# 登录与网络验证指南

本指南提供端到端验证步骤：AAD SSH 登录、VM 扩展健康、apt 出站访问与 Azure 备份健康检查。建议在部署成功后执行。

## 先决条件
- 已安装并登录 Azure CLI：
  - `az login`
  - `az account set --subscription <SUBSCRIPTION_ID>`
- 对应订阅具备 Reader/Contributor 权限
- 可选：已启用 Azure Bastion 以避免公网 SSH/RDP 暴露

> 环境变量（示例，按需替换）：
- 资源组：
  - 非生产：`bingohr-nonprod-webmysql-eastasia-rg`
  - 生产：`bingohr-prod-webmysql-eastasia-rg`
- VM 名称：
  - 非生产 Web：`bingohr-nonprod-web`
  - 非生产 MySQL：`bingohr-nonprod-mysql`
  - 生产 Web：`bingohr-prod-web`
  - 生产 MySQL：`bingohr-prod-mysql`
- AAD UPN：`stduser@gdjiuyun.onmicrosoft.com`

## 一、AAD SSH 登录（可选交互验证）
- 门户 Bastion 方式（推荐）：
  1. 打开 VM → 连接 → Bastion → 使用 AAD 或 SSH Key 登录
- CLI（AAD 交互）：
  ```powershell
  az ssh vm -g <rg> -n <vm> --auth-type AAD
  ```
- 期望：出现登录提示并能进入 shell；若失败查看“故障排查”。

## 二、VM 扩展健康
检查 AADLoginForLinux 扩展状态（应为 `Succeeded`）：
```powershell
az vm extension show -g <rg> --vm-name <vm> -n AADLoginForLinux \
  --query "{vm:name,state:provisioningState,version:typeHandlerVersion}" -o table
```

## 三、apt 与 Azure 端点连通性（Run Command）
利用 RunCommand 在 VM 内执行快速 HTTP 探测：
```powershell
az vm run-command invoke -g <rg> -n <vm> --command-id RunShellScript \
  --scripts 'set -e; for u in https://azure.archive.ubuntu.com \
  https://archive.ubuntu.com https://security.ubuntu.com \
  https://login.microsoftonline.com; do echo Testing $u; \
  curl -s --max-time 20 -o /dev/null -w "%{http_code}\n" $u || echo FAIL; done' \
  --query "value[0].message" -o tsv
```
- 期望：各 URL 返回 `200/301/302` 等 2xx/3xx 状态码；若超时为网络受限。

## 四、Azure 备份健康
查看受保护项与最近作业：
```powershell
# 受保护项
az backup item list -g <rg> -v <vaultName> \
  --query "[].{name:properties.friendlyName,health:properties.healthStatus}" -o table

# 最近作业
az backup job list -g <rg> -v <vaultName> \
  --query "[0:5].{name:entityFriendlyName,status:status,operation:operation}" -o table
```
- 示例保管库：
  - 非生产：`bingohr-nonprod-rsv`
  - 生产：`bingohr-prod-rsv`
- 期望：受保护项 `Healthy`，作业 `Completed`。

## 故障排查要点
- Firewall 应用规则需包含：
  - `azure.archive.ubuntu.com`, `archive.ubuntu.com`, `security.ubuntu.com`
  - `login.microsoftonline.com`, `management.azure.com`, `login.windows.net`
  - `*.backup.windowsazure.com`, `*.blob.core.windows.net`, `aka.ms`
- 平台 IP 通路（NSG/UDR/Firewall 一致）：
  - `168.63.129.16` TCP `80/443` 与 UDP `53`
- DNS 解析：确保 VM 能解析上述域名（必要时启用 DNS Proxy 或递归 DNS）。
- AAD 扩展：`AADLoginForLinux` 装置成功且版本最近；必要时重试或查看扩展日志。

## 快速变量模板
```powershell
$rgNP = 'bingohr-nonprod-webmysql-eastasia-rg'
$rgP  = 'bingohr-prod-webmysql-eastasia-rg'
$vmNPWeb = 'bingohr-nonprod-web'
$vmPWeb  = 'bingohr-prod-web'
```

> 建议将以上命令与输出记录到 `COMPLETION_SUMMARY.md` 以形成审计轨迹。