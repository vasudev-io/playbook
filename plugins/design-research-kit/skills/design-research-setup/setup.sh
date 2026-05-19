#!/usr/bin/env bash
set -euo pipefail

# design-research-setup — one-shot, idempotent setup for the design-research-kit.
#
# Reads userConfig from publish-research plugin (exposed as env vars by Claude Code):
#   PLAYBOOK_GITHUB_USER, PLAYBOOK_PUBLISH_REPO, PLAYBOOK_DISPLAY_NAME
#
# Falls back to `gh api user` if those aren't set.
#
# Usage:
#   setup.sh            → interactive setup (default)
#   setup.sh --verify   → check only, no writes

MODE="setup"
if [ "${1:-}" = "--verify" ]; then
  MODE="verify"
fi

bold()  { printf "\033[1m%s\033[0m\n" "$1"; }
green() { printf "\033[32m%s\033[0m\n" "$1"; }
yellow(){ printf "\033[33m%s\033[0m\n" "$1"; }
red()   { printf "\033[31m%s\033[0m\n" "$1"; }
dim()   { printf "\033[2m%s\033[0m\n" "$1"; }

bold "design-research-kit · setup"
echo

# ─── 1. gh auth ────────────────────────────────────────────────────────────────

if ! command -v gh >/dev/null 2>&1; then
  red "✗ 'gh' CLI not installed."
  echo "   Install: https://cli.github.com/  (e.g. 'brew install gh')"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  red "✗ 'gh' is not authenticated."
  echo "   Run: gh auth login"
  exit 1
fi

GH_USER_FROM_API="$(gh api user --jq .login)"
GH_NAME_FROM_API="$(gh api user --jq '.name // .login')"
green "✓ gh authenticated as @${GH_USER_FROM_API}"

# ─── 2. resolve config ────────────────────────────────────────────────────────

REPO_OWNER="${PLAYBOOK_GITHUB_USER:-$GH_USER_FROM_API}"
REPO_NAME="${PLAYBOOK_PUBLISH_REPO:-design-research}"
DISPLAY_NAME="${PLAYBOOK_DISPLAY_NAME:-$GH_NAME_FROM_API}"

echo "   github_user:  $REPO_OWNER"
echo "   publish_repo: $REPO_NAME"
echo "   display_name: $DISPLAY_NAME"
echo

# ─── 3. repo existence ────────────────────────────────────────────────────────

REPO_EXISTS=false
PAGES_ENABLED=false
if gh repo view "${REPO_OWNER}/${REPO_NAME}" --json url >/dev/null 2>&1; then
  REPO_EXISTS=true
  green "✓ repo ${REPO_OWNER}/${REPO_NAME} exists"
  if gh api "repos/${REPO_OWNER}/${REPO_NAME}/pages" --silent 2>/dev/null; then
    PAGES_ENABLED=true
    green "✓ GitHub Pages enabled"
  else
    yellow "⚠ GitHub Pages not enabled on ${REPO_OWNER}/${REPO_NAME}"
  fi
else
  yellow "⚠ repo ${REPO_OWNER}/${REPO_NAME} does not exist"
fi

# ─── 4. lazyweb token ─────────────────────────────────────────────────────────

LAZYWEB_TOKEN_PATH="$HOME/.lazyweb/lazyweb_mcp_token"
LAZYWEB_OK=false
if [ -s "$LAZYWEB_TOKEN_PATH" ]; then
  LAZYWEB_OK=true
  green "✓ lazyweb MCP token present at $LAZYWEB_TOKEN_PATH"
else
  yellow "⚠ lazyweb MCP token missing"
  echo "   Get one (free) at: https://www.lazyweb.com/mcp-install"
  echo "   Save it to: $LAZYWEB_TOKEN_PATH"
fi

echo

# ─── verify-only exit ─────────────────────────────────────────────────────────

if [ "$MODE" = "verify" ]; then
  if $REPO_EXISTS && $PAGES_ENABLED && $LAZYWEB_OK; then
    bold "All good. Pages → https://${REPO_OWNER}.github.io/${REPO_NAME}/"
    exit 0
  else
    yellow "Re-run without --verify to fix what's missing."
    exit 0
  fi
fi

# ─── 5. apply fixes (interactive) ─────────────────────────────────────────────

if ! $REPO_EXISTS; then
  bold "→ will create ${REPO_OWNER}/${REPO_NAME} (public)"
  printf "   proceed? [Y/n] "
  read -r ans
  case "${ans:-Y}" in
    [Yy]*|"")
      gh repo create "${REPO_OWNER}/${REPO_NAME}" --public \
        --description "Research reports, published from Claude Code via playbook"
      REPO_EXISTS=true
      green "  ✓ repo created"
      ;;
    *)
      yellow "  skipped — re-run setup when ready."
      exit 0
      ;;
  esac
fi

# Seed the repo if it's empty, so Pages has something to serve.
TMPCLONE="$(mktemp -d)"
if git clone --quiet "https://github.com/${REPO_OWNER}/${REPO_NAME}.git" "$TMPCLONE" 2>/dev/null; then
  if [ -z "$(ls -A "$TMPCLONE" | grep -v '^.git$' || true)" ]; then
    bold "→ seeding empty repo with a landing page"
    cd "$TMPCLONE"
    cat > index.html <<HTML
<!doctype html><meta charset="utf-8"><title>Research — ${DISPLAY_NAME}</title>
<style>body{font:16px -apple-system,system-ui;max-width:560px;margin:96px auto;padding:0 24px;color:#18181b}.eyebrow{font-size:12px;letter-spacing:.18em;text-transform:uppercase;color:#a1a1aa;margin-bottom:16px}h1{font-size:44px;font-weight:600;letter-spacing:-.025em;margin:0 0 16px}.lead{color:#52525b;font-size:17px}</style>
<p class="eyebrow">${DISPLAY_NAME}</p>
<h1>Research</h1>
<p class="lead">No research published yet. Reports will appear here when you publish them via Claude Code.</p>
HTML
    touch .nojekyll
    git -c user.email="${REPO_OWNER}@users.noreply.github.com" \
        -c user.name="${DISPLAY_NAME}" \
        add -A
    git -c user.email="${REPO_OWNER}@users.noreply.github.com" \
        -c user.name="${DISPLAY_NAME}" \
        commit --quiet -m "init: seed landing page"
    git push --quiet -u origin main 2>/dev/null || git push --quiet -u origin master 2>/dev/null || true
    green "  ✓ landing page pushed"
  fi
  cd - >/dev/null
fi
rm -rf "$TMPCLONE"

if $REPO_EXISTS && ! $PAGES_ENABLED; then
  bold "→ enabling GitHub Pages on ${REPO_OWNER}/${REPO_NAME} (main branch, /)"
  if gh api -X POST "repos/${REPO_OWNER}/${REPO_NAME}/pages" \
       -F "source[branch]=main" -F "source[path]=/" --silent 2>/dev/null; then
    PAGES_ENABLED=true
    green "  ✓ Pages enabled (initial deploy takes 30-60s)"
  else
    yellow "  ⚠ Pages enable failed — check repo Settings → Pages manually"
  fi
fi

if ! $LAZYWEB_OK; then
  echo
  bold "→ lazyweb MCP token"
  echo "   Lazyweb is the screenshot database used by the research skills."
  echo "   It needs a free token. Steps:"
  echo "     1. Visit:  https://www.lazyweb.com/mcp-install"
  echo "     2. Copy your token from the page"
  echo "     3. Save it to:  $LAZYWEB_TOKEN_PATH"
  echo
  echo "   You can also write it now via:"
  echo "     mkdir -p ~/.lazyweb && echo '<your-token>' > ~/.lazyweb/lazyweb_mcp_token"
  echo
fi

# ─── 6. final status ──────────────────────────────────────────────────────────

echo
bold "summary"
$REPO_EXISTS    && green "✓ repo:        https://github.com/${REPO_OWNER}/${REPO_NAME}"     || red "✗ repo not created"
$PAGES_ENABLED  && green "✓ Pages URL:   https://${REPO_OWNER}.github.io/${REPO_NAME}/"     || yellow "⚠ Pages not enabled"
$LAZYWEB_OK     && green "✓ Lazyweb:     token present"                                     || yellow "⚠ Lazyweb token missing (see above)"

if $REPO_EXISTS && $PAGES_ENABLED && $LAZYWEB_OK; then
  echo
  green "All set. Try a design research session and the publish step will work end-to-end."
fi
