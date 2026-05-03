# 🚫 Adding Security Exceptions

This document defines how to safely handle security findings that cannot be immediately fixed or are considered acceptable risks.

The goal is to:

* Avoid disabling security tools globally
* Maintain visibility of risks
* Ensure accountability and documentation

---

# ⚠️ When to Add an Exception

Add an exception **only if**:

* The finding is a **false positive**
* The risk is **low and acceptable**
* A fix is **not immediately feasible**
* The issue is in **test/demo code only**

---

## 🚫 Do NOT add exceptions for:

* Hardcoded secrets in production code
* Critical vulnerabilities without review
* Issues that are easily fixable

---

# 🔐 Gitleaks (Secrets)

## 📌 Use Case

Ignore known test files or dummy secrets.

---

## ⚙️ Configuration via `.gitleaks.toml`

```toml id="u7z1jj"
[allowlist]
paths = [
  '''secrets-example.txt'''
]
```

---

## 📝 Notes

* Prefer removing secrets instead of ignoring
* If used, clearly document why the file is safe
* Never allowlist real credentials

---

# 🔬 Semgrep (SAST)

## 📌 Use Case

Suppress false positives or intentional patterns

---

## ▶️ Inline Ignore

```python id="vsmh4a"
eval(user_input)  # nosemgrep
```

---

## ▶️ Rule-Level Exclusion

```yaml id="0rwhs8"
rules:
  - id: python-eval
    pattern: eval(...)
    message: "eval is dangerous"
    languages: [python]
    severity: ERROR
    paths:
      exclude:
        - tests/
```

---

## 📝 Notes

* Use inline ignores sparingly
* Always explain why it is safe
* Prefer fixing code over ignoring

---

# 📦 Trivy (Container Security)

## 📌 Use Case

Ignore vulnerabilities that:

* Have no available fix
* Are not exploitable in your context

---

## ▶️ `.trivyignore` File

```text id="9i2o0p"
CVE-2026-4878
CVE-2025-69720
```

---

## 📝 Notes

* Only ignore **specific CVEs**
* Review ignored CVEs regularly
* Combine with `ignore-unfixed: true` in CI

---

# 🌍 Checkov (Terraform Security)

## 📌 Use Case

Skip checks for intentional configurations

---

## ▶️ Inline Skip

```hcl id="ax4x9m"
resource "aws_s3_bucket" "example" {
  bucket = "my-bucket"

  # checkov:skip=CKV_AWS_21: Public access required for demo
}
```

---

## 📝 Notes

* Always include a **reason**
* Avoid skipping multiple checks blindly
* Revisit skipped checks periodically

---

# 🧾 Documentation Requirement

Every exception must include:

* ✅ Reason for exception
* ✅ Scope (file, rule, or CVE)
* ✅ Owner (who approved it)
* ✅ Review date (optional but recommended)

---

# 🔁 Review Process

* Exceptions should be reviewed:

  * During PR review
  * During periodic security audits
* Remove exceptions when no longer needed

---

# 🚨 Risk Acknowledgement

By adding an exception, you accept that:

* The risk is **known and documented**
* The issue may still be exploitable
* Responsibility lies with the team

---

# ✅ Best Practices

* Fix first, ignore only if necessary
* Keep exceptions minimal
* Be explicit and transparent
* Never ignore secrets in production

---

# 🚀 Summary

Security exceptions are a controlled mechanism to handle unavoidable findings without weakening the overall security posture.

Use them responsibly and document everything.
