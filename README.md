# claude-okf — Open Knowledge Format (OKF) plugin for Claude Code

> A [Claude Code](https://docs.claude.com/en/docs/claude-code) plugin that makes every
> project keep an **[Open Knowledge Format (OKF)](https://github.com/GoogleCloudPlatform/knowledge-catalog)
> knowledge catalog** — created, followed, and kept current.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code Plugin](https://img.shields.io/badge/Claude%20Code-plugin-d97757.svg)](https://docs.claude.com/en/docs/claude-code/plugins)
[![OKF v0.1](https://img.shields.io/badge/OKF-v0.1-brightgreen.svg)](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md)

**OKF (Open Knowledge Format)** is Google Cloud's vendor-neutral, agent-agnostic standard
for documenting project knowledge as plain Markdown + YAML frontmatter — no database, no
SDK. `claude-okf` packages that standard into a workflow Claude Code actually follows:
a skill that authors catalogs to spec, an agent that audits them for conformance, and a
session hook that won't let a project go undocumented.

## Contents

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [What is OKF?](#what-is-okf)
- [Configuration: tuning the hook](#configuration-tuning-the-hook)
- [Manual install (without the marketplace)](#manual-install-without-the-marketplace)
- [Repository layout](#repository-layout)
- [Versioning & updates](#versioning--updates)
- [License](#license)

## Features

| Component | Type | What it does |
|-----------|------|--------------|
| `okf-catalog` | Skill | Teaches Claude to author and maintain an OKF bundle to spec — bundle anatomy, frontmatter rules, reserved files, cross-links, continuous updates. |
| `okf-auditor` | Subagent | Audits a bundle for OKF v0.1 §9 conformance and reports concrete, fixable findings. Read-only — edits nothing. |
| OKF session reminder | SessionStart hook | Detects whether the current project has a catalog and tells Claude to create or update it. |

> [!IMPORTANT]
> **This plugin is opinionated by default.** The hook treats OKF as a *prime directive*:
> open a project with no catalog and Claude is told to create one **as the first action of
> the session, before your requested task**. That is the whole point — but if you'd rather
> it not interrupt, see [Configuration: tuning the hook](#configuration-tuning-the-hook).

## Installation

Requires Claude Code with plugin support.

```text
/plugin marketplace add theesfeld/claude-okf
/plugin install okf@theesfeld
```

1. The first command registers this repository as a plugin marketplace named `theesfeld`.
2. The second installs the `okf` plugin from it.

Start a new session so the SessionStart hook loads. To update or remove later:

```text
/plugin marketplace update theesfeld   # pull the latest version
/plugin uninstall okf@theesfeld        # remove
```

## Usage

After install, the plugin works automatically:

1. **You open a project.** At session start the hook checks whether the directory is a
   project (a git repo or a recognized manifest) and whether it already has an OKF bundle.
   - **No catalog** → Claude is told to create one first. Placement defaults to `okf/`; it
     asks if ambiguous. It seeds `index.md` + `log.md` + concept docs, then proceeds.
   - **Has a catalog** → Claude is reminded to treat it as the source of truth and keep it
     current as the project changes.
   - **Not a project** (e.g. your home directory) → the hook stays silent.
2. **You document knowledge.** Ask Claude to record a table, endpoint, metric, playbook, or
   decision and the `okf-catalog` skill applies the spec's rules: one concept per file, a
   non-empty `type`, reserved `index.md`/`log.md`, cross-links.
3. **You verify.** Before calling the work done:

   ```text
   Use the okf-auditor agent to check my okf/ catalog.
   ```

   It reports conformance failures (PASS/FAIL on §9) and quality warnings, and changes
   nothing.

## What is OKF?

A **bundle** is a directory tree. Each non-reserved `.md` file is one **concept**:

```text
okf/                     # bundle root
├── index.md             # directory listing; the ONLY index.md that may carry frontmatter
├── log.md               # newest-first change history
└── tables/
    ├── index.md
    └── orders.md        # a concept
```

A concept doc is YAML frontmatter + a Markdown body. **`type` is the only required field:**

```markdown
---
type: Postgres Table
title: Orders
description: One row per completed customer order.
tags: [sales, revenue]
timestamp: 2026-05-28T14:30:00Z
---
# Schema

| Column | Type | Description |
|--------|------|-------------|
| `order_id` | TEXT | Globally unique order identifier. |
```

Recommended (not required) fields, in priority order: `title`, `description`, `resource`,
`tags`, `timestamp`. Consumers must tolerate missing optional fields, unknown `type`
values, extra keys, broken links, and absent `index.md`. Be liberal in what you add;
strict about a parseable, UTF-8, `type`-bearing frontmatter.

**Spec:** <https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md>
(current version **v0.1 — Draft**). The standard is young; the skill and agent both fetch
the live spec before doing real work, and the live spec always wins over the copy bundled
here.

## Configuration: tuning the hook

The hook is the only intrusive part. Three ways to dial it down:

- **Disable the hook, keep the skill + agent.** Use `/hooks` in Claude Code to disable just
  the `SessionStart` hook. The `okf-catalog` skill and `okf-auditor` agent still work on
  demand.
- **Disable the whole plugin temporarily.** `/plugin` → toggle `okf` off.
- **Soften the wording.** Fork this repo and edit
  `plugins/okf/scripts/okf-session-reminder.sh` — the two here-docs near the bottom hold the
  exact text injected for the "has a catalog" and "no catalog" cases.

The hook only ever injects text for Claude to read. It never edits files and never blocks
you.

## Manual install (without the marketplace)

If you'd rather not use the marketplace, copy the three artifacts into your Claude config
(`~/.claude/` for user scope, or `.claude/` in a project):

```sh
git clone https://github.com/theesfeld/claude-okf
cd claude-okf

# Skill
mkdir -p ~/.claude/skills/okf-catalog
cp plugins/okf/skills/okf-catalog/SKILL.md ~/.claude/skills/okf-catalog/

# Agent
cp plugins/okf/agents/okf-auditor.md ~/.claude/agents/

# Hook script
mkdir -p ~/.claude/scripts
cp plugins/okf/scripts/okf-session-reminder.sh ~/.claude/scripts/
chmod +x ~/.claude/scripts/okf-session-reminder.sh
```

Then wire the hook into `~/.claude/settings.json` (manual installs don't have the plugin's
`${CLAUDE_PLUGIN_ROOT}`, so use the real path):

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          { "type": "command", "command": "~/.claude/scripts/okf-session-reminder.sh" }
        ]
      }
    ]
  }
}
```

The plugin install is the supported path and survives updates; the manual copy is a fallback
you maintain yourself.

## Repository layout

```text
claude-okf/
├── .claude-plugin/
│   └── marketplace.json          # the "theesfeld" marketplace catalog
├── plugins/
│   └── okf/                       # the installable plugin
│       ├── .claude-plugin/plugin.json
│       ├── skills/okf-catalog/SKILL.md
│       ├── agents/okf-auditor.md
│       ├── hooks/hooks.json
│       └── scripts/okf-session-reminder.sh
├── LICENSE
└── README.md
```

## Versioning & updates

`plugins/okf/.claude-plugin/plugin.json` carries a semantic `version`; bump it on every
release so installed users get updates via `/plugin marketplace update theesfeld`. The OKF
*spec* version is tracked separately by the standard itself.

## License

[MIT](LICENSE) © [theesfeld](https://github.com/theesfeld).

OKF is defined by [Google Cloud's knowledge-catalog](https://github.com/GoogleCloudPlatform/knowledge-catalog);
this plugin packages a workflow around that standard and is not affiliated with Google.
Built for [Claude Code](https://docs.claude.com/en/docs/claude-code).
```
