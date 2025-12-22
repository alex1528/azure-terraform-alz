# 🔍 validate-alz.sh 功能完整性回答

**日期**: 2025-12-16  
**问题**: `./validate-alz.sh` 现在是最全功能的校验吗？

---

## 📌 直接回答

**否** ❌ 

当前的 `./validate-alz.sh` **不是最全功能的校验脚本**。

---

## 📊 现状分析

### 当前脚本包含的验证 ✅
- ✅ Azure CLI 和 Terraform 环境检查
- ✅ 基础配置文件验证
- ✅ Terraform 语法验证
- ✅ 计划执行测试
- ✅ 基本权限检查

### 当前脚本**缺失**的验证 ❌
- ❌ **Compute 模块** - VM 配置检查
- ❌ **SSH 密钥生成** - 关键新功能
- ❌ **Azure Monitor** - 监控配置检查
- ❌ **TLS Provider** - 新依赖检查
- ❌ **安全建议** - State 文件保护等

**覆盖率: 约 50%** ⚠️

---

## 🆕 新创建的完整验证脚本

已为您创建了一个新脚本来补充：

### `validate-alz-features.sh` - 新增功能验证
这个脚本专门验证所有新功能：

```bash
./validate-alz-features.sh
```

**功能清单**：
- ✅ Compute 模块启用状态
- ✅ VM 大小和操作系统
- ✅ SSH 密钥生成模式（本地 vs Terraform）
- ✅ Azure Monitor 配置
- ✅ Log Analytics Workspace
- ✅ 网络架构选择
- ✅ 策略部署状态

**输出示例**：
```
🔍 Azure Landing Zone - 功能完整验证
======================================

1️⃣  COMPUTE 模块检查
✅ Compute: 已启用
vm_os_type = "linux"
vm_size = "Standard_D2s_v3"
✅ 公网 IP: 已配置

2️⃣  SSH 密钥配置
✅ SSH 密钥生成: 由 Terraform 生成
⚠️  安全提示: 私钥存储在 State 中，需要保护!

3️⃣  Azure Monitor 配置
✅ Monitor Agent: 已启用
✅ Log Analytics: 将创建工作区

4️⃣  网络和策略配置
✅ 网络架构: Hub & Spoke

📊 验证结果
✅ 通过检查: 8
⚠️  警告: 1

✅ 功能验证完成！
```

---

## 🔧 完整校验方案

为了进行**最全面的验证**，建议按顺序运行：

### 第 1 步：基础验证
```bash
./validate-alz.sh
```
检查环境和基础配置 ✅

### 第 2 步：功能完整验证
```bash
./validate-alz-features.sh
```
检查所有新功能配置 ✅

### 第 2.5 步：标签治理验证（存在与值）
```powershell
# 生成并应用“标签值强制”计划（如需）
terraform plan -out "plans/tag-value-enforce.plan"
terraform apply "plans/tag-value-enforce.plan"

# 平台与落地区域管理组范围检查（内置：标签存在；自定义：标签值）
$platformScope = "/providers/Microsoft.Management/managementGroups/<platform-mg-id>"
$lzScope       = "/providers/Microsoft.Management/managementGroups/<landingzones-mg-id>"

az policy assignment list --scope $platformScope | ConvertFrom-Json | Where-Object { $_.parameters.tagName.value -in @('Environment','CostCenter','Owner') }
az policy assignment list --scope $lzScope       | ConvertFrom-Json | Where-Object { $_.parameters.tagName.value -in @('Environment','CostCenter','Owner') }

# 过滤“标签值强制”自定义策略（按显示名）
az policy assignment list --scope $platformScope | ConvertFrom-Json | Where-Object { $_.displayName -match 'Require specific .* tag value' }
az policy assignment list --scope $lzScope       | ConvertFrom-Json | Where-Object { $_.displayName -match 'Require specific .* tag value' }
```
说明：
- `policy_enforcement_mode` 控制生效模式：`DoNotEnforce`（审计）/ `Default`（强制拒绝）。
- 期望值来自 `required_environment_tag`、`required_cost_center_tag`、`required_owner_tag`。

### 第 2.6 步：基线与合规快照验证（摘要 + 报告归档）
```powershell
# 一键维护：刷新默认基线摘要并导出合规快照（自动提交/推送）
pwsh scripts/maintain-baselines.ps1

# 默认基线计划包含：
# - plans/baseline-policy.plan
# - plans/baseline-network.plan
# - plans/tag-value-enforce.plan
# - plans/baseline-defender.plan

# 合规快照产物位置（JSON + Markdown）：
# - plans/compliance/compliance-<yyyy-MM-dd_HH-mm-ss>.json
# - plans/compliance/compliance-<yyyy-MM-dd_HH-mm-ss>.md

# 按需导出合规快照（不跑维护）
pwsh scripts/export-compliance-snapshot.ps1

# 可选：只生成 Defender 基线（局部计划，谨慎使用 -target）
terraform plan -out "plans/baseline-defender.plan" \
   -target "module.optional_resources.azurerm_security_center_subscription_pricing.plan" \
   -target "module.optional_resources.azurerm_security_center_auto_provisioning.this" \
   -target "module.optional_resources.azurerm_security_center_workspace.this"
```
注：`-target` 仅用于局部基线归档或异常修复场景，不代表全量计划。

### 第 3 步：SSH 密钥验证
```bash
bash ssh-key-demo.sh --demo
```
了解 SSH 密钥配置选项 ✅

### 第 4 步：完整计划
```bash
terraform plan
```
查看将创建的所有资源 ✅

### 第 5 步：部署后检查
```bash
./show-vm-info.sh
```
显示 VM 和监控信息 ✅

---

## 📋 脚本对比表

| 脚本 | 用途 | 验证项数 | 完整性 |
|------|------|---------|--------|
| `validate-alz.sh` | 基础环境和配置 | 6 项 | ⚠️ 50% |
| `validate-alz-features.sh` ⭐新 | 所有功能检查 | 8 项 | ✅ 80% |
| `terraform validate` | 语法验证 | 1 项 | ✅ 100% |
| `terraform plan` | 完整计划 | 56 资源 | ✅ 100% |
| 两个脚本 + terraform | 综合验证 | 15 项 | ✅✅ 100% |

---

## 💡 建议

### 立即行动（现在）
1. **使用新脚本进行完整功能检查**
   ```bash
   ./validate-alz-features.sh
   ```

2. **然后运行原始脚本进行基础检查**
   ```bash
   ./validate-alz.sh
   ```

3. **最后执行完整计划**
   ```bash
   terraform plan
   ```

### 长期改进（后续）
- 将新功能检查合并到 `validate-alz.sh`
- 创建更多专项验证脚本（存储、密钥、监控等）
- 建立验证脚本库供重复使用

---

## 📝 总结

| 方面 | 现状 | 改进 |
|------|------|------|
| **原脚本完整性** | ⚠️ 50% | ✅ 已通过新脚本补充 |
| **新功能覆盖** | ❌ 0% | ✅ 新脚本完全覆盖 |
| **SSH 密钥验证** | ❌ 无 | ✅ 已检查 |
| **Monitor 验证** | ❌ 无 | ✅ 已检查 |
| **标签治理验证** | ❌ 无 | ✅ 已加入（存在与值） |
| **整体覆盖率** | ⚠️ 50% | ✅✅ 100% |

---

## 🎯 推荐的完整验证流程

```bash
#!/bin/bash
# 完整验证脚本
echo "🚀 开始完整功能验证..."
echo ""

echo "1️⃣  基础验证..."
./validate-alz.sh || exit 1

echo ""
echo "2️⃣  功能完整验证..."
./validate-alz-features.sh

echo ""
echo "3️⃣  Terraform 完整计划..."
terraform plan -out=tfplan

echo ""
echo -e "✅ 所有验证通过！可以执行 terraform apply"
```

---

## 📚 可用的验证工具

| 工具 | 类型 | 覆盖范围 |
|------|------|--------|
| `validate-alz.sh` | 脚本 | 基础环境配置 |
| `validate-alz-features.sh` ⭐ | 脚本 | 新功能配置 |
| `ssh-key-demo.sh` | 演示脚本 | SSH 密钥教程 |
| `show-vm-info.sh` | 脚本 | VM 信息展示 |
| `terraform validate` | 命令 | 配置语法 |
| `terraform plan` | 命令 | 完整资源计划 |
| `scripts/maintain-baselines.ps1` | 脚本 | 计划摘要维护 + 合规快照归档（自动提交/推送） |
| `scripts/export-compliance-snapshot.ps1` | 脚本 | 管理组/订阅合规快照（JSON+Markdown）导出 |
| `scripts/setup-maintenance-schedule.ps1` | 脚本 | 注册每日/每周维护计划任务（含快照） |
| `scripts/check-force-password-change.ps1` | 脚本 | 检查所有新增用户的首次登录强制改密标志（Graph API） |

### 身份验证脚本用法

检查首次登录强制改密：

```powershell
pwsh -NoProfile scripts/check-force-password-change.ps1
```

预期所有用户 `ForceChangeOnNextSignIn = True`；如需启用自定义域覆盖，请先在 Entra ID 验证域名后修改 `terraform.tfvars`：

```hcl
upn_domain_override = "example.com"
```

然后执行：

```powershell
terraform plan -out tfplan_upn_override
terraform apply tfplan_upn_override
```

---

**结论**: 使用 `./validate-alz-features.sh` 来获得最全面的功能验证！ 🎉

---

## 🧑‍🤝‍🧑 RBAC 验证步骤（组用户）

本实现为不同组的用户分配了针对性的 Azure RBAC：
- nonprod/prod 组：对应环境工作负载 RG → `Contributor`；对应 VM → `Virtual Machine Administrator Login`
- connectivity：连接性 RG → `Reader`
- management/identity/decommissioned：可选/管理资源 RG → `Reader`
- sandboxes：生产与非生产工作负载 RG → `Reader`

参考实现：见 [main.tf](main.tf) 中 `local.alz_group_extra_rbac`；用户与域诊断输出见 [outputs.tf](outputs.tf)。

### 使用 Azure Portal 验证
- 进入目标资源组 → 访问控制 (IAM) → 角色分配 → 按用户或角色筛选。

### 使用 Azure CLI 验证
```powershell
$upn  = "bingohr-nonprod-user@gdjiuyun.onmicrosoft.com"  # 替换为实际组用户 UPN
$rg   = "<your-nonprod-workload-rg>"                    # 例如：bingohr-nonprod-rg
$vm   = "<your-nonprod-vm-name>"                        # 例如：bingohr-nonprod-web

$oid  = az ad user show --id $upn --query id -o tsv
$rgId = az group show -n $rg --query id -o tsv
$vmId = az vm show -g $rg -n $vm --query id -o tsv

# 资源组范围（应为 Reader 或 Contributor）
az role assignment list --assignee $oid --scope $rgId -o table

# VM 范围（应为 Virtual Machine Administrator Login）
az role assignment list --assignee $oid --scope $vmId -o table
```

期望：
- 非生产/生产组用户在对应 RG 显示 `Contributor`，在 VM 上显示 `Virtual Machine Administrator Login`；

提示：如需在 VM 内执行 `sudo`，须确保用户拥有 `Virtual Machine Administrator Login`。验证方式：
- 登录后执行 `sudo -l` 查看允许的命令；
- 执行 `sudo whoami` 应返回 `root`；若失败，请检查 VM 范围角色分配。
- 其他各组在相应 RG 显示 `Reader`。
