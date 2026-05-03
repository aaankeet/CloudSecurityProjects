# Project 3: CI/CD Pipelines With Security Built In

## Overview

Modern cloud security lives inside pipelines, not after deployment. This project demonstrates how to build a CI/CD pipeline that embeds security checks early in the development process—catching issues before they reach production.

## Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                         SECURE CI/CD PIPELINE                                   │
└─────────────────────────────────────────────────────────────────────────────────┘

 Developer                                                              Production
    │                                                                       │
    ▼                                                                       │
┌────────┐   ┌────────┐   ┌────────┐   ┌────────┐   ┌────────┐   ┌────────┐│
│  Code  │──▶│  Build │──▶│Security│──▶│  Test  │──▶│ Deploy │──▶│  Prod  ││
│ Commit │   │        │   │ Checks │   │        │   │Staging │   │        ││
└────────┘   └────────┘   └────────┘   └────────┘   └────────┘   └────────┘│
    │            │            │            │            │            │      │
    │            │            │            │            │            │      │
    ▼            ▼            ▼            ▼            ▼            ▼      │
┌────────────────────────────────────────────────────────────────────────────┐
│                        SECURITY GATES AT EACH STAGE                       │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  Pre-Commit    Build         Security       Test          Deploy    Prod  │
│  ──────────    ─────         ────────       ────          ──────    ────  │
│  • Secrets     • SAST        • IaC Scan     • DAST        • Approval • WAF│
│    scanning    • Dep scan    • Policy       • Pen test    • Canary   • IDS│
│  • Linting     • Container   • Compliance   • Fuzzing     • Rollback │    │
│  • Hooks         scan        • Threat                                │    │
│                                model                                 │    │
│                                                                      │    │
└──────────────────────────────────────────────────────────────────────┴────┘
```

## Shift-Left Security Model

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                      COST OF FIXING SECURITY ISSUES                             │
└─────────────────────────────────────────────────────────────────────────────────┘

                                                                           ┌───┐
                                                                           │   │
                                                                     ┌───┐ │   │
                                                               ┌───┐ │   │ │   │
                                                         ┌───┐ │   │ │   │ │   │
  Cost to                                          ┌───┐ │   │ │   │ │   │ │   │
   Fix ($)                                   ┌───┐ │   │ │   │ │   │ │   │ │   │
                                       ┌───┐ │   │ │   │ │   │ │   │ │   │ │   │
                                 ┌───┐ │   │ │   │ │   │ │   │ │   │ │   │ │   │
                           ┌───┐ │   │ │   │ │   │ │   │ │   │ │   │ │   │ │   │
                     ┌───┐ │   │ │   │ │   │ │   │ │   │ │   │ │   │ │   │ │   │
    ─────────────────┴───┴─┴───┴─┴───┴─┴───┴─┴───┴─┴───┴─┴───┴─┴───┴─┴───┴─┴───┴────▶
                     Code   Build  Test  Deploy  Staging  Prod  Incident  Breach
                    ◀───────────────────────────────────────────────────────────▶
                              Time in Development Lifecycle

    ═══════════════════════════════════════════════════════════════════════════
    │                                                                         │
    │   Catching issues HERE (left)         vs    HERE (right)                │
    │   $100 to fix                               $1,000,000+ to fix          │
    │                                                                         │
    ═══════════════════════════════════════════════════════════════════════════
```

### Security Checks Implemented

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                          SECURITY CHECK TYPES                                   │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  1. SECRET SCANNING                                                             │
│     ┌─────────────────────────────────────────────────────────────────────┐     │
│     │  Tool:  Gitleaks                                                    │     │
│     │  When: Pre-commit hook + CI                                         │     │
│     │  Block: Yes - never allow secrets in repo                           │     │
│     └─────────────────────────────────────────────────────────────────────┘     │
│                                                                                 │
│  2. STATIC ANALYSIS (SAST)                                                      │
│     ┌─────────────────────────────────────────────────────────────────────┐     │
│     │  Tool: Semgrep                                                      │     │
│     │  When: On every PR                                                  │     │
│     │  Block: High/Critical findings                                      │     │
│     └─────────────────────────────────────────────────────────────────────┘     │
│                                                                                 │
│  3. INFRASTRUCTURE AS CODE SCANNING                                             │
│     ┌─────────────────────────────────────────────────────────────────────┐     │
│     │  Tool: Checkov                                                      │     │
│     │  When: On PR for infrastructure changes                             │     │
│     │  Block: S3 public, security group 0.0.0.0/0, etc.                   │     │
│     └─────────────────────────────────────────────────────────────────────┘     │
│                                                                                 │
│  4. CONTAINER SCANNING                                                          │
│     ┌─────────────────────────────────────────────────────────────────────┐     │
│     │  Tool: Trivy,                                                       │     │
│     │  When: On image build                                               │     │
│     │  Block: Critical OS vulnerabilities, root user                      │     │
│     └─────────────────────────────────────────────────────────────────────┘     │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Pipeline Flow

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                         GITHUB ACTIONS PIPELINE FLOW                            │
└─────────────────────────────────────────────────────────────────────────────────┘

                    ┌──────────────────────────────────────┐
                    │         on: [push, pull_request]     │
                    └──────────────────┬───────────────────┘
                                       │
                    ┌──────────────────▼───────────────────┐
                    │         JOB: Security Scan           │
                    ├──────────────────────────────────────┤
                    │  ┌────────────────────────────────┐  │
                    │  │ Step 1: Checkout code          │  │
                    │  └────────────────────────────────┘  │
                    │  ┌────────────────────────────────┐  │
                    │  │ Step 2: Secret scanning        │──┼──▶ FAIL = Block PR
                    │  └────────────────────────────────┘  │
                    │  ┌────────────────────────────────┐  │
                    │  │ Step 3: SAST (Semgrep)         │──┼──▶ High = Block PR
                    │  └────────────────────────────────┘  │
                    │  ┌────────────────────────────────┐  │
                    │  │ Step 5: IaC scan (Checkov)     │──┼──▶ Failed checks
                    │  └────────────────────────────────┘  │       = Block PR
                    └──────────────────┬───────────────────┘
                                       │
                    ┌──────────────────▼───────────────────┐
                    │    All Checks Pass?                  │
                    └──────────────────┬───────────────────┘
                              ┌────────┴────────┐
                              │                 │
                         ┌────▼────┐       ┌────▼────┐
                         │   YES   │       │   NO    │
                         └────┬────┘       └────┬────┘
                              │                 │
                    ┌─────────▼─────────┐  ┌────▼─────────────────┐
                    │ Continue to       │  │ Block merge         │
                    │ Build & Deploy    │  │ Show findings in PR │
                    └───────────────────┘  └──────────────────────┘
```

## Block vs Warn Decision Matrix

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                    WHEN TO BLOCK vs WARN                                        │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│                        BLOCK (Pipeline Fails)                                   │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │  • Secrets in code (API keys, passwords, tokens)                        │   │
│  │  • SQL injection vulnerabilities                                        │   │
│  │  • Command injection vulnerabilities                                    │   │
│  │  • S3 bucket public access                                              │   │
│  │  • Security group open to 0.0.0.0/0 on sensitive ports                  │   │
│  │  • Critical CVE with known exploit                                      │   │
│  │  • Container running as root with sensitive mounts                      │   │
│  │  • Missing encryption on data stores                                    │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│                        WARN (Let Pipeline Continue)                             │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │  • Medium-severity dependency vulnerabilities                           │   │
│  │  • Code quality issues (complexity, duplication)                        │   │
│  │  • Missing security headers (can be added at ALB/CDN)                   │   │
│  │  • Informational findings                                               │   │
│  │  • Known false positives (with documented exception)                    │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│                        CONTEXT MATTERS                                          │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │  • Internal tool vs customer-facing: different thresholds               │   │
│  │  • Regulated industry: stricter controls                                │   │
│  │  • Emergency fix: may need exception process                            │   │
│  │  • New repo vs established: different baseline expectations             │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Project Structure

```
03-cicd-security-pipeline/
├── README.md
├── .github/
│   └── workflows/
│       ├── security-scan.yml       # Main security scanning workflow
│       ├── terraform-check.yml     # IaC-specific checks
│       └── container-scan.yml      # Container image scanning
├── app
│   └── app.py
├── policies/
│   ├── semgrep-rules/              # Custom SAST rules
│   ├── checkov-config/             # IaC policy configuration
│   └── exceptions/                 # Documented false positive exceptions
├── scripts/
│   ├── pre-commit-hook.sh          # Local pre-commit security checks
│   └── scan-results-parser.sh      # Parse and format scan results
├── terraform
│   └── main.tf
└── docs/
    ├── adding-exceptions.md        # How to add security exceptions
    ├── tool-configuration.md       # How each tool is configured
    └── escalation-process.md       # What to do when blocked
```

## Trade-off Discussions

### What happens if a security check is too strict?

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                    STRICTNESS TRADE-OFF ANALYSIS                                │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  TOO STRICT                              TOO LENIENT                            │
│  ══════════                              ════════════                           │
│                                                                                 │
│  ┌────────────────────────┐              ┌────────────────────────┐             │
│  │ • Developers bypass    │              │ • Real vulnerabilities │             │
│  │   the process          │              │   reach production     │             │
│  │ • False positives      │              │ • Security debt grows  │             │
│  │   cause alert fatigue  │              │ • Trust in tools       │             │
│  │ • Productivity drops   │              │   diminishes           │             │
│  │ • Security becomes     │              │ • Incidents more       │             │
│  │   "the enemy"          │              │   likely               │             │
│  └────────────────────────┘              └────────────────────────┘             │
│                                                                                 │
│                          BALANCED APPROACH                                      │
│                          ═════════════════                                      │
│                                                                                 │
│  ┌──────────────────────────────────────────────────────────────────────────┐  │
│  │  1. Start with high-confidence rules only                                │  │
│  │  2. Track false positive rate - if > 10%, tune the rule                  │  │
│  │  3. Make exceptions easy to request (but require justification)          │  │
│  │  4. Review exceptions quarterly                                          │  │
│  │  5. Gradually increase coverage as developers trust the system           │  │
│  └──────────────────────────────────────────────────────────────────────────┘  │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## 🔁 How It Works
1. Developer Pushes Code<br>   
     - Trigger: `push` or `pull_request`
2. Security Scans Run<br> 
    - 🔐 Gitleaks
    -  Scans repo + history for secrets
🔬 Semgrep<br>
     - Runs custom + community rules
📦 Trivy<br>
     - Scans Docker image for vulnerabilities
🌍 Checkov
     - Validates Terraform security

3. Results Processing<br>
     - Parser script aggregates findings
     - Generates clean PR comment
     - Uploads reports as artifacts
4. Merge Decision<br>
  - ❌ Block if:
      - Secrets detected
      - HIGH/CRITICAL vulnerabilities
      - SAST violations
      - Terraform misconfigurations
  - ✅Allow if:
      - All checks pass
      - OR approved exceptions exist

## 📊 Example PR Output
🛡️ Security Scan Results<br>

🔑 Secrets Detection<br>
✅ No secrets detected

🔬 Static Analysis<br>
✅ No findings detected

📦 Container Scan<br>
✅ No HIGH/CRITICAL vulnerabilities

🌍 Terraform Security<br>
✅ No misconfigurations

✅ Overall Status: PASSED

## 📚 Documentation

Detailed documentation is available in the" /docs" directory:

⚙️ Tool Configuration<br>
→ `docs/tool-configuration.md`<br>
Explains how each security tool is configured and executed<br>
🚫 Adding Exceptions<br>
→ `docs/adding-exceptions.md`<br>
Guidelines for safely ignoring findings<br>
🚨 Escalation Process<br>
→ `docs/escalation-process.md`<br>
What to do when security checks fail<br>

## 🧪 Testing the Pipeline

**simulate failures:**<br>

- Add a fake AWS key → triggers Gitleaks<br>
- Use `eval()` → triggers Semgrep<br>
- Use vulnerable base image → triggers Trivy<br>
- Misconfigure S3 bucket → triggers Checkov<br>

## 🔐 Security Best Practices<br>
Never commit secrets<br>
Use `.env` + `.gitignore`<br>
Keep base images updated<br>
Avoid unsafe functions `(eval)`<br>
Follow least privilege principle<br>
Review all exceptions carefully<br>

## 🎯 Key Features<br>
✅ Automated PR security comments<br>
✅ Multi-layer security scanning<br>
✅ Custom Semgrep rules<br>
✅ Terraform security validation<br>
✅ Container vulnerability scanning<br>
✅ Clean reporting & artifacts<br>

## 🧠 Key Learnings<br>
- Security must be integrated early in CI/CD<br>
- Not all vulnerabilities are fixable → risk-based filtering is required<br>
- Combining multiple tools gives better coverage<br>
- Automation ensures consistent security enforcement<br>

## 🏁 Final Status<br>

✅ Secrets Scan: Passed<br>
✅ SAST Scan: Passed<br>
✅ Container Scan: Passed<br>
✅ Terraform Check: Passed<br>

🎯 Pipeline Status: SECURE & PRODUCTION-READY<br>

## 👨‍💻 Author<br>

Built as a hands-on DevSecOps learning project to demonstrate secure CI/CD practices.<br>

---
