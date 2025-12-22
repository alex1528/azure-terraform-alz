# 验证与预算结果（2025-12-19）

## 端到端验证（最新）

- AAD 扩展：
  - 非生产 Web `bingohr-nonprod-web`：`AADLoginForLinux` 状态 `Succeeded`
  - 生产 Web `bingohr-prod-web`：`AADLoginForLinux` 状态 `Succeeded`
- 网络连通性（RunCommand 内部 curl）：
  - peering 与防火墙规则更新后（仅 nonprod 已与 Hub 成功对等）：
    - 非生产 Web：
      - `https://archive.ubuntu.com` → 200
      - `https://security.ubuntu.com` → 301
      - `https://login.microsoftonline.com` → 302
      - `https://azure.archive.ubuntu.com` → 超时（HTTPS）；但 apt 使用 HTTP 源可用
    - 生产 Web：未建立到 Hub 的对等连接（地址空间重叠导致 peering 失败），暂不具备通过 Hub 出站能力
- apt 更新（nonprod）：
  - `apt-get update -o Acquire::ForceIPv4=true` 成功，命中 `http://azure.archive.ubuntu.com` 源
- 备份健康：
  - 非生产保管库 `bingohr-nonprod-rsv`：`bingohr-nonprod-web` / `bingohr-nonprod-mysql` 均为 `Passed`
  - 生产保管库 `bingohr-prod-rsv`：`bingohr-prod-web` / `bingohr-prod-mysql` 均为 `Passed`

## 成本预算（Budgets）

- 操作：在 `terraform.tfvars` 启用 `enable_budgets = true` 后执行 `terraform plan/apply`
- 结果：`plan` 成功；`apply` 失败
- 错误：订阅 `offerId: MS-AZR-0036P` 的 `offerType: None` 不支持 Cost Management Budgets（仅 EA、Web Direct、MCA 支持）
- 建议：保持 `enable_budgets = false`，或在支持的订阅类型中启用

## 文档更新

- 新增验证指南：`VALIDATION_SSH_AND_NETWORK.md`
- 在 `README.md` 中增加 “Post-Deployment Validation” 章节并链接验证指南

## 后续建议

- VNet 对等与地址空间：
  - 已成功建立 Hub ↔ NonProd 的双向对等（AllowForwardedTraffic=true）
  - Hub ↔ Prod 对等失败：NonProd 与 Prod 使用相同地址空间 `10.11.0.0/16`，与 Azure 要求冲突（同一 Hub 下的多个对等 VNet 不能互相地址重叠）。
  - 方案：调整 Prod（或 NonProd）工作负载 VNet 地址（例如改为 `10.12.0.0/16`，子网 `10.12.1.0/24`），再创建 peering。
- DNS/应用规则：
  - 已在 Firewall 应用规则中放行 Ubuntu、Microsoft、Azure 常见端点；平台 IP `168.63.129.16` 的 TCP 80/443 与 UDP 53 通过网络规则放行。
  - 若仍遇到个别 HTTPS 端点问题，可在 apt 配置中临时启用 IPv4 优先（`Acquire::ForceIPv4=true`），或在 VM 内启用 `/etc/gai.conf` 调整 IPv4 优先级。
- 完成地址空间调整与 peering 后，建议在 Prod 重跑 apt / curl 探测以确认一致性。
