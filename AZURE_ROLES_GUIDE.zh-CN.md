**概览**
- 本指南汇总当前实现中使用的 Azure RBAC 角色、作用范围、典型用法与验证示例，帮助团队理解“谁在什么范围拥有什么权限”，并提供 az CLI 的可复制命令。

**角色清单与用途**
- **Reader**: 只读访问，适合审计、验证、浏览资源属性；在多个资源组范围用于非运维组的日常查看。
- **Contributor**: 可管理资源但无法授予权限；用于工作负载资源组的运维与日常管理（nonprod/prod 组）。
- **Virtual Machine Administrator Login**: 允许使用 Entra ID 账号登录 VM 并具备管理员权限（支持 `sudo`）；用于工作负载 VM 的 AAD SSH 管理登录。
- 已弃用（历史）: **Virtual Machine User Login**（不含管理员权限，无法 `sudo`）。现已在生产/非生产 VM 范围统一替换为管理员登录角色。
- **Monitoring Metrics Publisher**: 允许向 Azure Monitor 发布指标（通常赋予 VM 的托管标识或扩展关联标识）。

**实现位置与结构**
- RBAC 汇总说明与验证步骤见：[README.zh-CN.md](README.zh-CN.md) 与 [VALIDATION_SCRIPTS_GUIDE.md](VALIDATION_SCRIPTS_GUIDE.md)。
- 主要 RBAC 分配逻辑位于根模块：[main.tf](main.tf)
  - 工作负载（nonprod/prod）资源组 → `Contributor`
  - 工作负载（nonprod/prod）VM 范围 → `Virtual Machine Administrator Login`
  - 连接性/管理/身份/退役/沙盒等资源组 → `Reader`
- 监控相关角色分配示例位于：[modules/compute/main.tf](modules/compute/main.tf)（`Monitoring Metrics Publisher`）。

**作用范围（Scope）模型**
- **资源组（RG）范围**: 用于 `Reader` 与 `Contributor` 的大多数分配，遵循最小权限原则，避免在订阅范围直接授予 `Contributor`。
- **VM 资源范围**: 用于 `Virtual Machine Administrator Login`，以便 Entra ID 账号 AAD SSH 登录并执行 `sudo`。
- **管理组范围**: 保留基础 `Reader` 能力（用于门户浏览与审计）；如需平台层角色分配，按 [modules/core_policies](modules/core_policies) 中的参数进行控制。

**az CLI 用法示例**
- 查看某用户在指定资源组的角色分配
```powershell
# 以 UPN 或对象 ID 查询用户在 RG 的角色
$subId="<subscriptionId>"
$rg="bingohr-nonprod-webmysql-eastasia-rg"
$assignee="<user_upn_or_objectId>"
az role assignment list --assignee $assignee --scope "/subscriptions/$subId/resourceGroups/$rg" --query "[].{Role:roleDefinitionName,Scope:scope}" -o table
```

- 为资源组授予 `Reader` 或 `Contributor`
```powershell
$subId="<subscriptionId>"
$rg="bingohr-prod-webmysql-eastasia-rg"
$assignee="<user_upn_or_objectId>"
# 授予 Reader
az role assignment create --assignee $assignee --role "Reader" --scope "/subscriptions/$subId/resourceGroups/$rg"
# 授予 Contributor
az role assignment create --assignee $assignee --role "Contributor" --scope "/subscriptions/$subId/resourceGroups/$rg"
```

- 为 VM 授予 `Virtual Machine Administrator Login`
```powershell
$subId="<subscriptionId>"
$rg="bingohr-nonprod-webmysql-eastasia-rg"
$vmName="bingohr-nonprod-web"
$assignee="<user_upn_or_objectId>"
az role assignment create --assignee $assignee --role "Virtual Machine Administrator Login" --scope "/subscriptions/$subId/resourceGroups/$rg/providers/Microsoft.Compute/virtualMachines/$vmName"
```

- 查询角色定义与角色 ID（避免硬编码）
```powershell
# 查询内置角色的定义（示例：VM 管理员登录）
az role definition list --name "Virtual Machine Administrator Login" -o json
# 查询并显示所有内置角色名称与 ID
az role definition list --query "[].{Name:roleName,Id:name}" -o table
```

**验证与运维准则**
- **门户验证**: 进入目标资源 → 访问控制 (IAM) → 角色分配 → 按用户或角色筛选，确认是否存在对应的 `Reader`/`Contributor`/`Virtual Machine Administrator Login`。[README.zh-CN.md](README.zh-CN.md)
- **CLI 验证**: 使用上述 `az role assignment list` 的示例命令按 `assignee` 与 `scope` 核对。
- **SSH 与 sudo 验证**: AAD SSH 登录后执行 `sudo -l` 与 `sudo whoami` 应成功（期望 `root`）。详见 [README.zh-CN.md](README.zh-CN.md) 与 [VALIDATION_SCRIPTS_GUIDE.md](VALIDATION_SCRIPTS_GUIDE.md)。
- **最小权限**: 优先在 RG 范围授权；仅在必要时使用更高范围。避免将 `Contributor` 赋予订阅或管理组范围。
- **角色变更记录**: 建议使用计划快照与提交记录（例如 `plan-summary-YYYYMMDD-HHMMSS.txt`）以便审计与回溯。

**注意事项**
- `Virtual Machine Administrator Login` 与 `Virtual Machine User Login` 的差异：前者支持管理员提权与 `sudo`，后者不支持；本实现已在工作负载 VM 上统一使用管理员登录角色。
- 监控与扩展：如需由托管标识发布指标或访问资源，请为相关标识分配相应角色（例如 `Monitoring Metrics Publisher`），并结合 [modules/compute/main.tf](modules/compute/main.tf) 的实现。
- 存储访问：场景需要 AAD 访问 Blob 时，请在存储账户上授予 `Storage Blob Data Contributor`，并在承载存储的资源组至少拥有 `Reader`（参见 [README.md](README.md) 的使用说明）。

**参考文件**
- 主实现与 RBAC 分配：[main.tf](main.tf)
- 计算模块与监控角色：[modules/compute/main.tf](modules/compute/main.tf)
- 组 RBAC 模型与验证：[README.zh-CN.md](README.zh-CN.md) / [README.md](README.md)
- 验证脚本指南与 CLI 检查：[VALIDATION_SCRIPTS_GUIDE.md](VALIDATION_SCRIPTS_GUIDE.md)