# ⚙️ Tool Configuration Guide

This document explains how each security tool is configured and used in the CI/CD pipeline.

The goal is to ensure:

* Early detection of vulnerabilities
* Consistent security enforcement
* Clear reporting and traceability

---

# 🔐 Gitleaks (Secrets Detection)

## 📌 Purpose

Detect hardcoded secrets such as:

* API keys
* Tokens
* Passwords
* Cloud credentials

---

## ⚙️ Configuration

* Version: `8.x`
* Scan Mode: Git history + working directory
* Config File: Default (or `.gitleaks.toml` if added)
* Output Format: JSON

---

## ▶️ Execution

```bash
./gitleaks detect \
  --source . \
  --report-format json \
  --report-path gitleaks-report.json \
  --exit-code 0
```

---

## 📊 Output

* File: `gitleaks-report.json`
* Parsed by: `scan-results-parser.sh`
* Used for:

  * PR comments
  * Artifact uploads

---

## 🔑 Notes

* Scans **entire commit history**, not just latest changes
* Findings remain even after deletion unless history is cleaned
* Use `.gitleaks.toml` to allowlist safe cases

---

# 🔬 Semgrep (Static Application Security Testing)

## 📌 Purpose

Analyze source code for:

* Insecure patterns (e.g., `eval`)
* Hardcoded credentials
* Bad coding practices

---

## ⚙️ Configuration

* Rule Sources:

  * Custom rules → `policies/semgrep-rules/`
  * Community rules → `p/default`
* Output Format: SARIF (for GitHub integration)

---

## ▶️ Execution

```bash
semgrep \
  --config policies/semgrep-rules \
  --config p/default \
  --include "*.py" \
  --sarif \
  --output semgrep-results.sarif \
  --error
```

---

## 📊 Output

* File: `semgrep-results.sarif`
* Used for:

  * PR parsing
  * GitHub Security tab (optional)

---

## ⚠️ Notes

* `--error` makes the pipeline fail on findings
* `|| true` can be used to prevent hard failure
* Inline ignores supported:

```python
eval(user_input)  # nosemgrep
```

---

# 📦 Trivy (Container Security Scanning)

## 📌 Purpose

Scan Docker images for:

* OS vulnerabilities
* Package vulnerabilities
* Misconfigurations

---

## ⚙️ Configuration

* Scan Target: Built Docker image (`secure-app`)
* Severity Filter: `HIGH, CRITICAL`
* Ignore Unfixed: Enabled
* Exit Code: `1` (fail pipeline on issues)

---

## ▶️ GitHub Action

```yaml
- name: Run Trivy scan
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: secure-app
    format: table
    severity: CRITICAL,HIGH
    ignore-unfixed: true
    exit-code: 1
```

---

## 📊 Output

* Format: Table (CLI output)
* Visible in: GitHub Actions logs

---

## ⚠️ Notes

* Base image vulnerabilities are common
* Use:

  * Updated images
  * `ignore-unfixed` to reduce noise
* `.trivyignore` can suppress specific CVEs

---

# 🌍 Checkov (Terraform Security)

## 📌 Purpose

Scan Infrastructure-as-Code (IaC) for:

* Misconfigurations
* Insecure cloud resources
* Compliance violations

---

## ⚙️ Configuration

* Target: Terraform (`.tf`) files
* Framework: Terraform
* Policy Source: Built-in Checkov rules

---

## ▶️ Execution

```bash
checkov -d . --framework terraform
```

---

## 📊 Output

* Format: CLI table
* Used in:

  * CI logs
  * Pipeline pass/fail logic

---

## ⚠️ Notes

* Supports inline skip:

```hcl
# checkov:skip=CKV_AWS_21: Reason for skipping
```

* Should not skip without justification

---

# 🔁 CI/CD Integration

## 📌 Workflow Behavior

| Tool     | Stage          | Fail Condition            |
| -------- | -------------- | ------------------------- |
| Gitleaks | Secrets Scan   | Optional (parser decides) |
| Semgrep  | Code Analysis  | Yes (`--error`)           |
| Trivy    | Container Scan | Yes (HIGH/CRITICAL)       |
| Checkov  | Terraform Scan | Yes                       |

---

## 📊 Reporting

* PR Comment → Summary of findings
* Artifacts → Full reports
* Logs → Detailed scan output

---

## 📁 Generated Files

| File                  | Tool     | Purpose                   |
| --------------------- | -------- | ------------------------- |
| gitleaks-report.json  | Gitleaks | Secrets parsing           |
| semgrep-results.sarif | Semgrep  | SAST results              |
| Trivy output          | Trivy    | Container vulnerabilities |
| Checkov output        | Checkov  | IaC validation            |

---

# ✅ Best Practices

* Never commit secrets
* Keep dependencies updated
* Use minimal base images
* Avoid unsafe functions (`eval`, etc.)
* Document all exceptions

---

# 🚀 Summary

This pipeline ensures:

* 🔍 Early detection of vulnerabilities
* 🔐 Secure coding practices
* 📦 Hardened container images
* 🌍 Secure infrastructure configuration

All checks must pass before code is merged into the main branch.
