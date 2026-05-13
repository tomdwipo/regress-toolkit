# sanitize.sed — TEMPLATE for stripping project-specific identifiers.
#
# This file is intentionally generic so the public repo doesn't leak
# the original maintainer's company names, internal hosts, etc.
#
# To use it on your own project:
#   1. Copy this file to `.sanitize.sed.local` (gitignored).
#   2. Uncomment the section headers you need and fill in real values.
#   3. Run with EXTENDED regex (-E) for portability across GNU and BSD sed:
#        find . -type f \( -name '*.md' -o -name '*.template' \) -print0 \
#          | xargs -0 sed -Ei.bak -f .sanitize.sed.local
#        find . -name '*.bak' -delete
#
# The patterns below cover the *categories* of identifiers worth replacing.
# Real token-format scrubbers (universal) are kept here — uncomment if you
# want them. Company-specific lines stay commented as examples.

# === Generic token formats (safe, universal — recommended to keep) ===========
s|ATATT3xFfGF0[A-Za-z0-9_=-]{8,}|{{ATLASSIAN_API_TOKEN}}|g
s|figd_[A-Za-z0-9_-]{8,}|{{FIGMA_ACCESS_TOKEN}}|g
s|gho_[A-Za-z0-9]{8,}|{{GITHUB_TOKEN}}|g
s|xox[abp]-[A-Za-z0-9-]{20,}|{{SLACK_TOKEN}}|g
s|sk-[A-Za-z0-9]{20,}|{{OPENAI_API_KEY}}|g
s|AKIA[A-Z0-9]{16}|{{AWS_ACCESS_KEY_ID}}|g

# === Atlassian / Confluence hosts (fill in your own) =========================
# s|your-org\.atlassian\.net|{{JIRA_HOST}}|g
# s|atlassian\.com/wiki/spaces/YOUR_SPACE|atlassian.com/wiki/spaces/{{CONFLUENCE_SPACE}}|g

# === Org / product names (fill in your own) ==================================
# s|YourOrgName|{{ORG_NAME}}|g
# s|your-product-slug|{{PROJECT_SLUG}}|g
# s|your-android-repo|{{ANDROID_REPO}}|g

# === Workspaces / repo slugs =================================================
# s|workspace=your-workspace|workspace={{BITBUCKET_WORKSPACE}}|g

# === Jira project keys =======================================================
# s#YOURKEY-[0-9]+#{{JIRA_KEY}}#g

# === Confluence page IDs (long numeric ids) ==================================
# s|/pages/[23][0-9]{9}|/pages/{{CONFLUENCE_PAGE_ID}}|g

# === Atlassian cloudId (your tenant UUID) ====================================
# s|11111111-2222-3333-4444-555555555555|{{JIRA_CLOUD_ID}}|g

# === Package roots (Android / Java) ==========================================
# s|com\.yourorg\.product|{{PACKAGE_ROOT}}|g

# === Emails ==================================================================
# s|@your-org\.com|@{{ORG_EMAIL_DOMAIN}}|g

# === API hosts / internal services ===========================================
# s|api\.your-product\.com|api.{{API_HOST}}|g

# === VPS / infra IPs =========================================================
# s|10\.0\.0\.1|{{VPS_HOST}}|g
# s|/home/your-vps-user/|/home/{{VPS_USER}}/|g

# === User home + absolute project paths (BSD-sed-friendly) ==================
# Order matters: longest first.
# s|/Users/your-mac-user/Documents/your-android-repo|{{PROJECT_ROOT}}|g
# s|/Users/your-mac-user|{{HOME}}|g
