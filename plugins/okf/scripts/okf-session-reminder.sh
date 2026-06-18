#!/usr/bin/env bash
# SessionStart hook — OKF prime directive (okf plugin).
#
# Every project under this user must have an Open Knowledge Format (OKF)
# knowledge catalog, created, followed, and continuously updated. This hook
# fires once per session: it detects whether the current working directory is
# a project and whether that project already has an OKF bundle, then injects a
# reminder on stdout (SessionStart stdout becomes additionalContext, visible to
# Claude only). It stays SILENT when cwd is not a real project (e.g. $HOME), so
# it never nags outside of project work.
set -u

payload="$(cat 2>/dev/null || true)"

cwd=""
if command -v jq >/dev/null 2>&1; then
  cwd="$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null)"
fi
[[ -z "$cwd" ]] && cwd="$PWD"
[[ -d "$cwd" ]] || exit 0

# Never nag at (or above) the home directory — that's not a project.
[[ "$cwd" == "$HOME" ]] && exit 0

# --- Is cwd a project? git repo, or a recognized manifest at its root. -------
is_project=0
[[ -d "$cwd/.git" ]] && is_project=1
if [[ $is_project -eq 0 ]]; then
  for m in package.json pyproject.toml Cargo.toml go.mod Makefile CMakeLists.txt \
           pom.xml build.gradle composer.json Gemfile mix.exs deno.json \
           tsconfig.json setup.py CLAUDE.md '*.asd'; do
    if compgen -G "$cwd/$m" >/dev/null 2>&1; then is_project=1; break; fi
  done
fi
[[ $is_project -eq 0 ]] && exit 0

# --- Does the project already have an OKF bundle? ----------------------------
# 1) Most reliable: an index.md whose frontmatter declares okf_version.
#    Bound the walk (depth + file count) so the 5s hook timeout is never at risk.
bundle=""
hit="$(find "$cwd" -maxdepth 4 -type f -name 'index.md' 2>/dev/null \
        | head -50 | xargs -r grep -lsI 'okf_version' 2>/dev/null | head -1)"
[[ -n "$hit" ]] && bundle="$(dirname "$hit")"

# 2) Conventional bundle directory.
if [[ -z "$bundle" ]]; then
  for d in okf .okf knowledge catalog docs/okf; do
    [[ -d "$cwd/$d" ]] && { bundle="$cwd/$d"; break; }
  done
fi

project_name="$(basename "$cwd")"

if [[ -n "$bundle" ]]; then
  rel="${bundle#"$cwd"/}"
  cat <<EOF
<okf-prime-directive source="okf plugin">
This project ("$project_name") has an OKF knowledge catalog at: $rel/
PRIME DIRECTIVE: follow it as the source of truth, and KEEP IT CURRENT. Whenever
this session changes documented knowledge (tables, endpoints, metrics, services,
playbooks, decisions), update the affected concept docs (bump their timestamp),
adjust index.md, and append a dated entry to log.md. Use the 'okf-catalog' skill
to author/update, and run the 'okf-auditor' agent to confirm OKF v0.1 §9
conformance before declaring work done. A stale catalog means the work is unfinished.
</okf-prime-directive>
EOF
else
  cat <<EOF
<okf-prime-directive source="okf plugin" priority="PRIME DIRECTIVE 1">
This project ("$project_name") has NO OKF knowledge catalog yet.
PRIME DIRECTIVE 1 (session-start gate): creating one is the FIRST ACTION of this
session, before starting the user's requested task — not a deferred reminder.
Act now: invoke the 'okf-catalog' skill. If placement is ambiguous, ASK the user
where to put the bundle (the only thing allowed to precede creation); default
otherwise to an 'okf/' directory at the project root. Seed it with a bundle-root
index.md (carrying okf_version: "0.1"), a log.md, and concept docs (each with a
non-empty 'type' frontmatter field) for the project's key entities. Verify with the
'okf-auditor' agent. Only after the catalog exists, proceed with the requested work.
</okf-prime-directive>
EOF
fi
exit 0
