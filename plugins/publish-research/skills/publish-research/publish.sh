#!/usr/bin/env bash
set -euo pipefail

# publish-research — publishes a local research folder to <user>/<repo> via GitHub Pages.
#
# Config (from this plugin's userConfig, exposed by Claude Code as env vars):
#   PLAYBOOK_GITHUB_USER    e.g. "vasudev-io"
#   PLAYBOOK_PUBLISH_REPO   e.g. "design-research"
#   PLAYBOOK_DISPLAY_NAME   e.g. "Vasudev Menon" (optional)
#
# Fallbacks if the env vars are not set:
#   github_user      → gh api user --jq .login
#   publish_repo     → "design-research"
#   display_name     → gh api user --jq .name  ||  github_user

REPO_OWNER="${PLAYBOOK_GITHUB_USER:-}"
REPO_NAME="${PLAYBOOK_PUBLISH_REPO:-design-research}"
DISPLAY_NAME="${PLAYBOOK_DISPLAY_NAME:-}"

if [ -z "$REPO_OWNER" ]; then
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    REPO_OWNER="$(gh api user --jq .login)"
  else
    echo "ERROR: PLAYBOOK_GITHUB_USER not set and 'gh' is not authenticated." >&2
    echo "Either re-run /plugin install to set userConfig, or run: gh auth login" >&2
    exit 1
  fi
fi

if [ -z "$DISPLAY_NAME" ]; then
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    DISPLAY_NAME="$(gh api user --jq '.name // .login')"
  else
    DISPLAY_NAME="$REPO_OWNER"
  fi
fi

BASE_URL="https://${REPO_OWNER}.github.io/${REPO_NAME}"

# Per-plugin persistent dir (survives plugin updates, scoped per plugin id).
# Falls back to ~/.cache/playbook when CLAUDE_PLUGIN_DATA isn't set (e.g. during local dev).
LOCAL_REPO="${CLAUDE_PLUGIN_DATA:-$HOME/.cache/playbook}/${REPO_NAME}"

usage() {
  echo "Usage: $0 <local-research-dir> <slug>" >&2
  echo "  e.g.  $0 .lazyweb/design-research/blog-patterns-2026-05-11 blog-editorial-patterns" >&2
  exit 1
}

[ $# -eq 2 ] || usage

SRC_DIR="$1"
SLUG="$2"

[ -d "$SRC_DIR" ] || { echo "ERROR: source dir not found: $SRC_DIR" >&2; exit 1; }
[[ "$SLUG" =~ ^[a-z0-9][a-z0-9-]*$ ]] || { echo "ERROR: slug must be kebab-case [a-z0-9-]: $SLUG" >&2; exit 1; }

if [ ! -d "$LOCAL_REPO/.git" ]; then
  echo "→ cloning ${REPO_OWNER}/${REPO_NAME} to $LOCAL_REPO"
  mkdir -p "$(dirname "$LOCAL_REPO")"
  if ! git clone "https://github.com/${REPO_OWNER}/${REPO_NAME}.git" "$LOCAL_REPO" 2>/dev/null; then
    echo "→ repo doesn't exist yet, creating ${REPO_OWNER}/${REPO_NAME}"
    gh repo create "${REPO_OWNER}/${REPO_NAME}" --public \
      --description "Research reports, published from Claude Code via playbook" \
      --confirm 2>/dev/null || gh repo create "${REPO_OWNER}/${REPO_NAME}" --public \
      --description "Research reports, published from Claude Code via playbook"
    git clone "https://github.com/${REPO_OWNER}/${REPO_NAME}.git" "$LOCAL_REPO"
  fi
fi

cd "$LOCAL_REPO"

git fetch origin --quiet || true
if git show-ref --quiet refs/remotes/origin/main; then
  git checkout main --quiet 2>/dev/null || git checkout -b main --quiet
  git reset --hard origin/main --quiet
else
  git checkout -b main --quiet 2>/dev/null || true
fi

TARGET="$LOCAL_REPO/$SLUG"
rm -rf "$TARGET"
mkdir -p "$TARGET"
rsync -a --delete "$SRC_DIR/" "$TARGET/"

if [ -f "$TARGET/report.html" ] && [ ! -f "$TARGET/index.html" ]; then
  mv "$TARGET/report.html" "$TARGET/index.html"
fi

export REPO_OWNER REPO_NAME DISPLAY_NAME LOCAL_REPO

python3 - <<'PYEOF'
import os, html, datetime, pathlib, re

ROOT = pathlib.Path(os.environ["LOCAL_REPO"])
REPO_OWNER = os.environ["REPO_OWNER"]
REPO_NAME = os.environ["REPO_NAME"]
DISPLAY_NAME = os.environ["DISPLAY_NAME"]

entries = []
for child in sorted(ROOT.iterdir()):
    if not child.is_dir() or child.name.startswith(".") or child.name == "node_modules":
        continue
    index_path = child / "index.html"
    report_md = child / "report.md"
    if not index_path.exists() and not report_md.exists():
        continue
    title = child.name.replace("-", " ").title()
    summary = ""
    if report_md.exists():
        try:
            text = report_md.read_text(encoding="utf-8", errors="ignore").splitlines()
            for line in text:
                m = re.match(r"^#\s+(.+)$", line.strip())
                if m:
                    title = m.group(1).strip()
                    break
            for line in text[1:30]:
                stripped = line.strip()
                if stripped.startswith("#") or stripped.startswith("**Date") or not stripped:
                    continue
                if stripped.startswith("**Goal:**") or stripped.startswith("**Method:**"):
                    summary = re.sub(r"\*\*([^*]+)\*\*:?\s*", r"", stripped, count=1)
                    break
                summary = stripped
                break
            summary = re.sub(r"\*\*([^*]+)\*\*", r"\1", summary)
            summary = re.sub(r"`([^`]+)`", r"\1", summary)
            summary = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", summary)
        except Exception:
            pass
    mtime = datetime.datetime.fromtimestamp(child.stat().st_mtime).strftime("%b %d, %Y")
    sort_key = child.stat().st_mtime
    entries.append({"slug": child.name, "title": title, "summary": summary, "date": mtime, "sort": sort_key})

entries.sort(key=lambda e: e["sort"], reverse=True)

def card(e):
    s = html.escape(e["summary"]) if e["summary"] else ""
    return f'''      <a class="entry" href="./{html.escape(e["slug"])}/">
        <div class="entry-row">
          <div class="entry-main">
            <div class="entry-title">{html.escape(e["title"])}</div>
            {('<div class="entry-summary">' + s + '</div>') if s else ''}
          </div>
          <div class="entry-meta">
            <span class="entry-date">{html.escape(e["date"])}</span>
            <span class="entry-arrow" aria-hidden="true">→</span>
          </div>
        </div>
      </a>'''

items = "\n".join(card(e) for e in entries) or '<p class="empty">No research published yet.</p>'

INDEX = f'''<!doctype html>
<html lang="en"><head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>Research — {html.escape(DISPLAY_NAME)}</title>
<link rel="preconnect" href="https://rsms.me/">
<link rel="stylesheet" href="https://rsms.me/inter/inter.css">
<style>
  :root {{
    --bg: #ffffff;
    --text: #18181b;
    --muted: #52525b;
    --subtle: #a1a1aa;
    --rule: #e4e4e7;
    --accent: #18181b;
    --hover: #fafafa;
  }}
  * {{ box-sizing: border-box; }}
  html, body {{ margin: 0; padding: 0; background: var(--bg); color: var(--text); }}
  body {{
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, system-ui, sans-serif;
    font-feature-settings: 'cv11', 'ss01', 'ss03';
    -webkit-font-smoothing: antialiased;
    line-height: 1.6;
  }}
  .wrap {{ max-width: 720px; margin: 0 auto; padding: 96px 24px 120px; }}
  header {{ margin-bottom: 64px; }}
  .eyebrow {{
    font-size: 12px;
    letter-spacing: 0.18em;
    text-transform: uppercase;
    color: var(--subtle);
    margin-bottom: 16px;
  }}
  h1 {{
    font-size: 44px;
    font-weight: 600;
    letter-spacing: -0.025em;
    line-height: 1.05;
    margin: 0 0 16px;
  }}
  .lead {{
    color: var(--muted);
    font-size: 17px;
    max-width: 540px;
    margin: 0;
  }}
  .entries {{
    border-top: 1px solid var(--rule);
  }}
  .entry {{
    display: block;
    text-decoration: none;
    color: inherit;
    border-bottom: 1px solid var(--rule);
    padding: 24px 16px;
    margin: 0 -16px;
    transition: background 0.15s;
    border-radius: 0;
  }}
  .entry:hover {{
    background: var(--hover);
  }}
  .entry-row {{
    display: flex;
    align-items: flex-start;
    gap: 24px;
    justify-content: space-between;
  }}
  .entry-main {{ flex: 1; min-width: 0; }}
  .entry-title {{
    font-size: 18px;
    font-weight: 500;
    letter-spacing: -0.005em;
    color: var(--text);
  }}
  .entry-summary {{
    color: var(--muted);
    font-size: 14.5px;
    margin-top: 6px;
    max-width: 540px;
  }}
  .entry-meta {{
    display: flex;
    align-items: center;
    gap: 12px;
    flex-shrink: 0;
  }}
  .entry-date {{
    color: var(--subtle);
    font-size: 13px;
    font-variant-numeric: tabular-nums;
  }}
  .entry-arrow {{
    color: var(--subtle);
    font-size: 16px;
    transition: transform 0.15s, color 0.15s;
  }}
  .entry:hover .entry-arrow {{
    color: var(--text);
    transform: translateX(2px);
  }}
  .empty {{ color: var(--muted); padding: 24px 0; }}
  footer {{
    margin-top: 80px;
    color: var(--subtle);
    font-size: 13px;
  }}
  footer a {{
    color: var(--subtle);
    text-decoration: none;
    border-bottom: 1px solid transparent;
    transition: border-color 0.15s, color 0.15s;
  }}
  footer a:hover {{ color: var(--text); border-bottom-color: var(--rule); }}
  @media (max-width: 600px) {{
    .wrap {{ padding: 56px 20px 80px; }}
    h1 {{ font-size: 36px; }}
    .entry {{ padding: 20px 12px; margin: 0 -12px; }}
    .entry-row {{ gap: 16px; }}
  }}
</style></head>
<body>
<div class="wrap">
  <header>
    <p class="eyebrow">{html.escape(DISPLAY_NAME)}</p>
    <h1>Research</h1>
    <p class="lead">UI/UX research reports — competitive analysis, pattern libraries, references.</p>
  </header>
  <section class="entries">
{items}
  </section>
  <footer>
    Source · <a href="https://github.com/{html.escape(REPO_OWNER)}/{html.escape(REPO_NAME)}">github.com/{html.escape(REPO_OWNER)}/{html.escape(REPO_NAME)}</a>
  </footer>
</div>
</body></html>
'''

(ROOT / "index.html").write_text(INDEX, encoding="utf-8")

def readme_li(e):
    return f"- [{e['title']}](./{e['slug']}/) — {e['date']}"

README = f"# {REPO_NAME}\n\nResearch reports — see [the published index](https://{REPO_OWNER}.github.io/{REPO_NAME}/).\n\n## Sessions\n\n"
README += "\n".join(readme_li(e) for e in entries) if entries else "_No research published yet._"
README += "\n"
(ROOT / "README.md").write_text(README, encoding="utf-8")
PYEOF

touch "$LOCAL_REPO/.nojekyll"

# Use whatever git identity the user already has configured locally.
git add -A
if git diff --cached --quiet; then
  echo "→ nothing to commit"
else
  git commit -m "publish: $SLUG" --quiet
  if ! git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
    git push -u origin main --quiet
  else
    git push origin main --quiet
  fi
fi

if ! gh api "repos/${REPO_OWNER}/${REPO_NAME}/pages" --silent 2>/dev/null; then
  echo "→ enabling GitHub Pages on ${REPO_OWNER}/${REPO_NAME}"
  gh api -X POST "repos/${REPO_OWNER}/${REPO_NAME}/pages" \
    -F "source[branch]=main" -F "source[path]=/" --silent || true
fi

echo
echo "Published → ${BASE_URL}/${SLUG}/"
echo "Index     → ${BASE_URL}/"
