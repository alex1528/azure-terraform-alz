# 🔐 身份验证与首次登录改密指南

## 目标
- 修正/验证 UPN 域选择，避免“此用户名可能不正确”。
- 验证新建用户是否开启 `forcePasswordChangeOnNextSignIn` 并在门户首次登录提示改密。

## 前置
- 已运行 Terraform，`outputs.tf` 暴露 `resolved_upn_domain` 与 `tenant_domain_candidates`。

## 步骤

### 1. 查看 Terraform 输出
```powershell
terraform -chdir "d:\azure-terraform-alz" output resolved_upn_domain
terraform -chdir "d:\azure-terraform-alz" output tenant_domain_candidates
terraform -chdir "d:\azure-terraform-alz" output iam_user_upn
terraform -chdir "d:\azure-terraform-alz" output alz_group_user_upns
```

### 2. 验证“首次登录强制改密”状态
```powershell
pwsh scripts/check-force-password-change.ps1
```

### 3. 如域不正确（未选到已验证自定义域）
在 `terraform.tfvars` 设置覆盖并重新部署：
```hcl
upn_domain_override = "your-verified-custom-domain.com"
```
```powershell
terraform -chdir "d:\azure-terraform-alz" plan -out tfplan_upn_override
terraform -chdir "d:\azure-terraform-alz" apply tfplan_upn_override
```

### 4. 登录验证建议
- 使用 `resolved_upn_domain` 对应 UPN 登录 `https://portal.azure.com`。
- 若门户未弹出改密界面，打开 `https://aka.ms/sspr` 执行首次密码更改。
