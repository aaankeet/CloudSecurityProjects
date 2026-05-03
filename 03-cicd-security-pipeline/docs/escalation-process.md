
---

# 📄 `escalation-process.md`

```md
# 🚨 Security Escalation Process

Defines what to do when security checks fail.

---

## 🔴 When Pipeline Fails

If any tool reports blocking issues:

- ❌ Secrets detected (Gitleaks)
- ❌ Critical vulnerabilities (Trivy)
- ❌ SAST issues (Semgrep)
- ❌ IaC misconfigurations (Checkov)

---

## 🧭 Step-by-Step Response

### 1. Identify the Issue
Check:
- PR comment
- GitHub Actions logs
- Uploaded artifacts

---

### 2. Classify Severity

| Severity | Action |
|----------|--------|
| LOW      | Fix later |
| MEDIUM   | Fix before merge |
| HIGH     | Must fix |
| CRITICAL | Block merge |

---

### 3. Fix or Justify

#### ✅ Fix Examples
- Remove secrets
- Replace `eval()`
- Update Docker base image
- Secure Terraform config

#### ⚠️ Justify (Exception)
- Add `.trivyignore`
- Add `# nosemgrep`
- Add Checkov skip comment

---

### 4. Re-run Pipeline

Push changes:

```bash
git add .
git commit -m "fix: security issues"
git push
