#!/usr/bin/env bash
#
# publish-template.sh — publish this Flutter sandbox template to GitHub.
#
# WHAT IT DOES
#   1. Exports the committed tree of a local tag (git archive — clean, no
#      build/, no .dart_tool/, no untracked files).
#   2. Scans the export for leaked credentials (fails loudly if any).
#   3. Publishes to the GitHub repo:
#        - repo missing  → creates it (PRIVATE by default — pass --public
#          for a public template repo) via the GitHub API, fresh history,
#          commit V1 + tag v1.
#        - repo exists   → clones it, replaces the tree, commits V{n+1} +
#          tag v{n+1} (append-only, matching the versioning conventions).
#
# USAGE
#   GITHUB_TOKEN=ghp_xxx bash scripts/publish-template.sh \
#     --repo <owner>/flutter-sandbox-template \
#     [--tag vX] [--message "…"] [--public]
#
#   --repo may be given without the owner/ prefix: the owner is then derived
#   from the token's authenticated user.
#
# SECURITY
#   The token is read from the GITHUB_TOKEN env var only — never an argument,
#   never written to any file, and git pushes use a credential helper so the
#   token never appears in URLs or command output.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REPO=""
SOURCE_TAG=""
MESSAGE=""
VISIBILITY="private"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)    REPO="${2:?}"; shift 2 ;;
    --tag)     SOURCE_TAG="${2:?}"; shift 2 ;;
    --message) MESSAGE="${2:?}"; shift 2 ;;
    --public)  VISIBILITY="public"; shift ;;
    --private) VISIBILITY="private"; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

[[ -n "${GITHUB_TOKEN:-}" ]] || { echo "ERROR: GITHUB_TOKEN env var is required" >&2; exit 1; }

API="https://api.github.com"
AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"

if [[ -z "$SOURCE_TAG" ]]; then
  SOURCE_TAG="$(cd "$PROJECT_DIR" && git tag --sort=-v:refname | head -1)"
  [[ -n "$SOURCE_TAG" ]] || { echo "ERROR: no local tags found — commit and tag first" >&2; exit 1; }
  echo "[publish] No --tag given — using latest local tag: $SOURCE_TAG"
fi

# Resolve owner from the token when --repo has no owner/ prefix.
if [[ "$REPO" != */* ]]; then
  LOGIN="$(curl -sf -H "$AUTH_HEADER" "$API/user" | python3 -c 'import json,sys; print(json.load(sys.stdin)["login"])')"
  REPO="${LOGIN}/${REPO:-flutter-sandbox-template}"
fi
[[ -n "$REPO" ]] || { echo "ERROR: --repo owner/name is required" >&2; exit 1; }

# ── 1. Export the committed tree of the source tag ─────────────────────────
EXPORT_DIR="$(mktemp -d /tmp/flutter-template-export.XXXXXX)"
trap 'rm -rf "$EXPORT_DIR"' EXIT
echo "[publish] Exporting $SOURCE_TAG from $PROJECT_DIR → $EXPORT_DIR"
(cd "$PROJECT_DIR" && git archive "$SOURCE_TAG") | tar -x -C "$EXPORT_DIR"

# ── 2. Secret scan ──────────────────────────────────────────────────────────
echo "[publish] Scanning export for leaked credentials…"
if grep -rIlE 'ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9]{20,}' \
     "$EXPORT_DIR" >/dev/null 2>&1; then
  echo "ERROR: potential token/secret found in the export — ABORTING." >&2
  grep -rIlE 'ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9]{20,}' "$EXPORT_DIR" >&2
  exit 1
fi
echo "[publish] Clean — no credentials found."

# ── 3. Git identity (from the token's account unless overridden) ────────────
if [[ -z "${GIT_AUTHOR_NAME:-}" ]]; then
  USER_JSON="$(curl -sf -H "$AUTH_HEADER" "$API/user")"
  GIT_AUTHOR_NAME="$(echo "$USER_JSON" | python3 -c 'import json,sys; print(json.load(sys.stdin)["login"])')"
  USER_ID="$(echo "$USER_JSON" | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])')"
  export GIT_AUTHOR_NAME
  export GIT_AUTHOR_EMAIL="${USER_ID}+${GIT_AUTHOR_NAME}@users.noreply.github.com"
fi
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
echo "[publish] Git identity: $GIT_AUTHOR_NAME <$GIT_AUTHOR_EMAIL>"

GIT_CRED_HELPER='!f() { echo "username=x-access-token"; echo "password=${GITHUB_TOKEN}"; }; f'
REMOTE_URL="https://github.com/${REPO}.git"
DESCRIPTION="Flutter sandbox template — debug-web preview loop for AI-agent sandboxes. Adaptive Material 3 UI, Android/iOS ready, zero third-party dependencies."

# ── 4. Publish ──────────────────────────────────────────────────────────────
REPO_STATUS="$(curl -s -o /dev/null -w "%{http_code}" -H "$AUTH_HEADER" "$API/repos/$REPO")"

if [[ "$REPO_STATUS" == "404" ]]; then
  echo "[publish] Repo $REPO does not exist — creating ($VISIBILITY)…"
  REPO_NAME="${REPO#*/}"
  curl -sf -X POST -H "$AUTH_HEADER" -H "Accept: application/vnd.github+json" \
    "$API/user/repos" \
    -d "{\"name\":\"${REPO_NAME}\",\"description\":\"${DESCRIPTION}\",\"private\":$([[ "$VISIBILITY" == "private" ]] && echo true || echo false),\"has_wiki\":false,\"has_projects\":false}" \
    >/dev/null
  NEW_VERSION=1
else
  echo "[publish] Repo $REPO exists (HTTP $REPO_STATUS) — preparing incremental publish…"
  NEW_VERSION=0
fi

if [[ "$NEW_VERSION" == "1" ]]; then
  INIT_DIR="$(mktemp -d /tmp/flutter-template-init.XXXXXX)"
  trap 'rm -rf "$EXPORT_DIR" "$INIT_DIR"' EXIT
  git -C "$INIT_DIR" init -q -b main
  cp -a "$EXPORT_DIR/." "$INIT_DIR/"
  git -C "$INIT_DIR" add -A
  git -C "$INIT_DIR" commit -q -m "${MESSAGE:-V1: template snapshot from source tag ${SOURCE_TAG}}"
  git -C "$INIT_DIR" tag v1
  echo "[publish] Pushing fresh history (V1 + v1) to $REPO…"
  git -C "$INIT_DIR" -c credential.helper="$GIT_CRED_HELPER" push -q -u "$REMOTE_URL" main v1
else
  CLONE_DIR="$(mktemp -d /tmp/flutter-template-clone.XXXXXX)"
  trap 'rm -rf "$EXPORT_DIR" "$CLONE_DIR"' EXIT
  git -C "$CLONE_DIR" clone -q "$REMOTE_URL" "$CLONE_DIR/repo" 2>/dev/null || \
    git -C "$CLONE_DIR" clone "$REMOTE_URL" "$CLONE_DIR/repo"
  cd "$CLONE_DIR/repo"
  if git rev-parse --verify -q HEAD >/dev/null; then
    LATEST="$(git tag --sort=-v:refname | head -1)"
    LATEST_NUM="${LATEST#v}"
    [[ "$LATEST_NUM" =~ ^[0-9]+$ ]] || LATEST_NUM=0
    NEW_VERSION=$(( LATEST_NUM + 1 ))
    git rm -rq .
  else
    echo "[publish] Template repo is empty — publishing fresh V1."
    NEW_VERSION=1
  fi
  cp -a "$EXPORT_DIR/." .
  git add -A
  if git diff --cached --quiet; then
    echo "[publish] No changes compared to the template repo — nothing to publish."
    exit 0
  fi
  git commit -q -m "${MESSAGE:-V${NEW_VERSION}: template snapshot from source tag ${SOURCE_TAG}}"
  git tag "v${NEW_VERSION}"
  echo "[publish] Pushing V${NEW_VERSION} + v${NEW_VERSION} to $REPO…"
  git -c credential.helper="$GIT_CRED_HELPER" push -q -u origin main "v${NEW_VERSION}"
fi

echo "[publish] Done → https://github.com/$REPO ($VISIBILITY, tag v${NEW_VERSION})"
echo "[publish] NOTE: if the push succeeds but the repo becomes unreachable within minutes,"
echo "[publish]       the GitHub account is auto-flagged — verify in a browser before retrying."
