# Privacy Policy — `claude-okf` (OKF plugin for Claude Code)

_Last updated: 2026-06-18_

This privacy policy describes how the `claude-okf` Claude Code plugin (the
"Plugin") handles data. The short version: **the Plugin collects nothing,
stores nothing, and transmits nothing to its author or any third party.**

## What the Plugin does

`claude-okf` ships three artifacts that run entirely on your own machine inside
your Claude Code session:

- **A `SessionStart` hook** (`okf-session-reminder.sh`) — at session start it
  reads the current working directory path, checks whether that directory looks
  like a project (a `.git` directory or a recognized manifest such as
  `package.json`), and scans up to four directory levels for an existing OKF
  catalog. It then prints reminder text to standard output, which Claude Code
  passes to the model as session context. This runs locally and writes only to
  the session; nothing is sent off the machine.
- **The `okf-catalog` skill** — instructions Claude follows to author and update
  OKF catalog files in your project.
- **The `okf-auditor` agent** — instructions Claude follows to read and report on
  the conformance of your catalog files.

## Data collection

The Plugin performs **no telemetry, analytics, tracking, or logging** to any
remote service. It contains no code that sends your files, paths, prompts, or
any other data to the author or to a third party. The author of the Plugin
receives **no data** about your usage.

## Network activity

The Plugin's hook makes **no network requests**.

When you invoke the `okf-catalog` skill or the `okf-auditor` agent, those
instructions ask Claude to fetch the public Open Knowledge Format specification
from GitHub
(`https://raw.githubusercontent.com/GoogleCloudPlatform/knowledge-catalog/main/okf/SPEC.md`)
so that work is checked against the current spec. That request is performed by
Claude Code's own web-fetch capability, retrieves a publicly available document,
and **sends no information about you, your project, or your files**. It is a
plain read of a public file. That request is governed by the privacy policies of
GitHub and of Anthropic / Claude Code, not by this Plugin.

## Data the Plugin creates

The OKF catalog files the Plugin helps Claude write are ordinary Markdown files
created in your own repository, under your control. They live wherever you place
them (by default an `okf/` directory at your project root). You decide what to
put in them, whether to commit them, and whether to publish them. The Plugin
imposes no storage of its own.

## Your responsibility for catalog contents

Because catalog files are plain files in your repository, **you control what
information goes into them.** Do not place secrets, credentials, or personal
data you would not want shared into catalog files that you then publish. This is
the same consideration that applies to any file you commit to a repository.

## Children's privacy

The Plugin is a developer tool and is not directed at children, and it collects
no data from anyone.

## Changes to this policy

If the Plugin's data behavior ever changes, this document will be updated and the
"Last updated" date above revised. Material changes will be noted in the
repository's change history.

## Contact

Questions about this policy can be raised via the project's issue tracker:
<https://github.com/theesfeld/claude-okf/issues>.
