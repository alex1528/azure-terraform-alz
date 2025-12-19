# Validation Scripts

This folder contains helper scripts to validate Azure Bastion AAD SSH login enablement and NSG hardening.

## validate-bastion-aad-login.ps1

Validates that:
- `AADLoginForLinux` VM extension is present and `Succeeded` for target VMs
- NSG SSH rules allow from Bastion subnet CIDR and Azure platform IP `168.63.129.16`
- An explicit `Deny` rule exists for SSH from `Internet`

### validate-bastion-aad-login.ps1 用法

```powershell
pwsh scripts/validate-bastion-aad-login.ps1 -Prefix "bingohr" -Region "eastasia" -BastionCidr "10.100.2.0/26"
```

Exit code is `0` on PASS, `1` on FAIL.

### 门户验证（Bastion AAD）

For each VM (prod/nonprod web + mysql):
1. Azure Portal → Virtual machines → select VM
2. Click `Connect` → choose `Bastion`
3. Authentication type: select `Azure AD`
4. Username: `stduser@gdjiuyun.onmicrosoft.com`
5. Click `Connect` to initiate session
6. Confirm successful login prompt on the Bastion session

If login fails, re-run the validation script and check extension status and NSG rules.

## verify-web-connectivity.ps1

验证 Web 应用的 HTTP 连通性：
- 自动解析 `prod` 与 `nonprod` 的 web VM 公网 IP
- 对目标 `http://<ip>/` 发起请求并输出状态码与内容长度
- 无公网 IP 时给出警告并返回失败码，提示通过 Bastion Tunnel 或负载均衡健康探针方式再测

### 用法

```powershell
pwsh scripts/verify-web-connectivity.ps1 -Prefix "bingohr" -Region "eastasia" -TimeoutSec 15 -Path "/"
```

返回码：`0`（全部通过）/ `1`（存在失败或跳过项）

## verify-web-connectivity-bastion.ps1

基于 Bastion Tunnel 的内网 HTTP 探测脚本：
- 为 prod/nonprod web VM 分别建立本地端口到远端端口的隧道（默认本地 8081/8082 → 远端 80）
- 通过 `http://127.0.0.1:<localPort>/` 探测应用连通性
- 探测结束后自动关闭隧道进程

### 用法

```powershell
pwsh scripts/verify-web-connectivity-bastion.ps1 -Prefix "bingohr" -Region "eastasia" -ProdLocalPort 8081 -NonprodLocalPort 8082 -ResourcePort 80 -Path "/"
```

注意：运行前需确保 Azure CLI 已登录且 Bastion 为 Standard SKU；首次使用可能会触发设备登录或浏览器认证。
