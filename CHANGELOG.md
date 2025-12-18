# 变更日志

## 最近更新 [2025-12-18]

### 🆕 能力增强（文档 + 脚本）

#### 维护与合规快照流水线
- **维护脚本增强**: `scripts/maintain-baselines.ps1`
	- 默认基线计划新增 `plans/baseline-defender.plan`
	- 维护末尾自动导出合规快照（JSON+Markdown）并 `git add/commit/push`
	- 提供 `-SkipComplianceSnapshot` 参数跳过快照导出
- **新增脚本**:
	- `scripts/export-compliance-snapshot.ps1`（管理组/订阅合规快照导出）
	- `scripts/setup-maintenance-schedule.ps1`（注册每日/每周计划任务，执行维护+快照）

#### 文档更新
- `README.md`、`README.zh-CN.md`、`usage.md`
	- 默认基线列表新增 Defender 基线
	- 增加合规快照导出与计划任务用法示例
- `VALIDATION_SCRIPTS_GUIDE.md`
	- 新增“第 2.6 步：基线与合规快照验证（摘要 + 报告归档）”
	- 扩展“可用的验证工具”表，纳入维护、快照、计划任务脚本

### 🗂️ 产物与基线
- 新增并维护：`plans/baseline-defender.plan` 与 `plans/baseline-defender.changes.md`
- 合规快照归档路径：`plans/compliance/compliance-<yyyy-MM-dd_HH-mm-ss>.json|.md`

### ✅ 验证状态
- ✅ 维护脚本执行：摘要刷新与快照导出均成功，变更已提交并推送
- ✅ 文档引用与命令示例可用（README/usage/VALIDATION 指南）

### 🚀 快速使用
```powershell
# 一键维护（刷新摘要 + 导出合规快照 + 自动提交/推送）
pwsh scripts/maintain-baselines.ps1

# 按需导出合规快照（产物保存至 plans/compliance）
pwsh scripts/export-compliance-snapshot.ps1

# 注册计划任务（每日/每周维护 + 快照）
pwsh scripts/setup-maintenance-schedule.ps1 -CreateDaily
pwsh scripts/setup-maintenance-schedule.ps1 -CreateWeekly -WeeklyDay Sunday -WeeklyTime 02:30
```

### 🔄 向后兼容性
- ✅ 默认行为为自动维护与快照归档；可通过 `-SkipComplianceSnapshot` 跳过快照步骤

---

## 最近更新 [2025-09-26]

### 🆕 新增功能

#### SSH 密钥自动生成
- **功能**: Terraform 现在支持自动生成 SSH 密钥对，无需预先准备本地密钥
- **变量**: 新增 `generate_ssh_key` 布尔变量（默认: `false`）
- **提供程序**: 添加了 `hashicorp/tls` provider (~> 4.0)
- **资源**: 新增 `tls_private_key.vm_key` 资源用于密钥生成

#### 使用场景
- **场景 1 - 生产环境（推荐）**: `generate_ssh_key = false`，使用本地 SSH 密钥
- **场景 2 - 开发环境**: `generate_ssh_key = true`，让 Terraform 生成密钥

#### 新增文档
- `SSH_KEY_GENERATION_GUIDE.md` - 详细的 SSH 密钥生成使用指南
- `SSH_KEY_QUICKSTART.md` - 快速开始指南
- `SSH_KEY_GENERATION_IMPLEMENTATION.md` - 实现技术细节
- `ssh-key-demo.sh` - 交互式演示脚本

### 📝 文件修改

**核心模块文件**:
- `modules/compute/main.tf` - 添加 tls provider 和 tls_private_key 资源
- `modules/compute/variables.tf` - 新增 generate_ssh_key 变量
- `modules/compute/outputs.tf` - 新增 SSH 密钥相关输出

**根级文件**:
- `variables.tf` - 新增 generate_ssh_key 变量声明
- `main.tf` - 在 compute 模块中传递 generate_ssh_key 变量
- `outputs.tf` - 新增根级 SSH 密钥输出
- `terraform.tfvars` - 新增 generate_ssh_key 配置示例

### ✅ 验证状态
- ✅ `terraform validate`: Success
- ✅ `terraform plan`: 56 resources to add (no errors)
- ✅ 向后兼容: 默认行为保持不变
- ✅ 条件逻辑: 工作正常

### 🔐 安全特性
- 敏感数据保护: 私钥输出标记为 sensitive
- 警告消息: 包含关于 state 文件安全的明确警告
- 文档: 完整的安全最佳实践指南
- 条件创建: 密钥资源仅在需要时创建

### 🔄 向后兼容性
- ✅ 完全向后兼容
- ✅ 默认值保持现有行为
- ✅ 现有用户无需任何更改
- ✅ 可选升级到新功能

### 📚 使用指南

**快速开始（推荐方式 - 生产）**:
```bash
# 方式 1: 使用本地 SSH 密钥（推荐）
generate_ssh_key = false
ssh_public_key_path = "~/.ssh/id_rsa.pub"
terraform apply
ssh -i ~/.ssh/id_rsa azureuser@<vm_public_ip>
```

**快速开始（开发方式）**:
```bash
# 方式 2: 让 Terraform 生成密钥（开发/测试仅用）
generate_ssh_key = true
terraform apply
terraform output -raw ssh_private_key_pem > key.pem && chmod 600 key.pem
ssh -i key.pem azureuser@<vm_public_ip>
```

### 💡 要点
- 🔒 **生产环境**: 使用本地 SSH 密钥（generate_ssh_key = false）
- 🧪 **开发环境**: 可使用 Terraform 生成（generate_ssh_key = true）
- ⚠️ **重要**: 保护 Terraform state 文件，不要提交到 Git
- 📖 详见 `SSH_KEY_GENERATION_GUIDE.md` 获取更多信息

### 📋 下一步
1. 查看 `SSH_KEY_QUICKSTART.md` 快速开始
2. 运行 `bash ssh-key-demo.sh --demo` 查看演示
3. 选择适合您的方式（本地密钥或 Terraform 生成）
4. 配置 `terraform.tfvars` 中的 `generate_ssh_key` 变量
5. 运行 `terraform plan` 和 `terraform apply`

---

## 功能完整性检查表

| 项目 | 状态 | 说明 |
|------|------|------|
| SSH 密钥生成资源 | ✅ | `tls_private_key` 资源已实现 |
| 变量支持 | ✅ | 根级和模块级变量已定义 |
| 条件逻辑 | ✅ | 正确处理 generate_ssh_key 切换 |
| 输出暴露 | ✅ | 私钥、公钥和配置信息已暴露 |
| 文档 | ✅ | 创建了 4 个文档文件 |
| 演示脚本 | ✅ | 交互式演示脚本已创建 |
| 向后兼容 | ✅ | 默认行为保持不变 |
| 验证测试 | ✅ | terraform validate 和 plan 通过 |
| 安全检查 | ✅ | 敏感数据保护和警告已实现 |

---

**更新时间**: 2025-09-26  
**状态**: ✅ 发布就绪
