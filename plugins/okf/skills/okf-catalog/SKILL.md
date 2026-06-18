---
name: okf-catalog
description: Create, follow, and continuously update an Open Knowledge Format (OKF) knowledge catalog for a project. Use whenever starting a project, documenting project knowledge (tables, datasets, metrics, APIs, playbooks, decisions, runbooks), or when an OKF bundle needs a new/updated concept doc, index.md, or log.md entry. Covers v0.1 bundle structure, frontmatter fields, reserved files, cross-links, and §9 conformance.
---

# Maintaining an OKF knowledge catalog

**OKF (Open Knowledge Format)** is Google Cloud's vendor-neutral, agent-agnostic
standard for project knowledge: plain markdown + YAML frontmatter + files, no database,
no SDK. This plugin treats OKF as a **prime directive** — *every* project gets a catalog,
kept current. (The SessionStart hook is what enforces that; see the repo README to dial it
back or turn it off.)

- Spec (the standard is young and evolving):
  <https://raw.githubusercontent.com/GoogleCloudPlatform/knowledge-catalog/main/okf/SPEC.md>
- Current version: **v0.1**.

**Strict adherence is non-negotiable.** Before *creating* a new bundle or running a
conformance pass, **WebFetch the live spec above** and confirm the version + clauses — do
not rely on the summary in this skill, which can lag the standard. If the live spec
disagrees with anything here, **the live spec wins**; follow it and note the divergence.
The hard floor never relaxes: every non-reserved `.md` is UTF-8, opens/closes with `---`,
parses as YAML, and carries a non-empty `type`.

## Placement (do this first on a new catalog)

If the project has no bundle and placement is ambiguous, **ask the user where to put it.**
Default when unprompted: an `okf/` directory at the project root. Once chosen, that
directory is the **bundle root**.

## Bundle anatomy

A bundle is a directory tree. Each non-reserved `.md` = one **concept** (a table, dataset,
metric, API endpoint, playbook, service, architectural decision…). Group concepts into
subdirectories that mirror the domain.

```
okf/                         # bundle root
├── index.md                 # directory listing; ONLY index.md allowed to carry frontmatter
├── log.md                   # newest-first change history
├── datasets/
│   ├── index.md
│   └── orders_db.md
├── tables/
│   ├── index.md
│   ├── orders.md
│   └── customers.md
└── metrics/
    ├── index.md
    └── weekly_active_users.md
```

## Concept document = frontmatter + body

```markdown
---
type: BigQuery Table          # REQUIRED — the only mandatory field. Short string.
title: Orders                 # recommended — human-readable display name
description: One row per completed customer order.   # recommended — one sentence
resource: https://console.cloud.google.com/bigquery?p=acme&d=sales&t=orders  # recommended — canonical URI
tags: [sales, revenue]        # recommended — YAML list
timestamp: 2026-05-28T14:30:00Z   # recommended — ISO 8601 of last meaningful change
---
# Schema

| Column | Type | Description |
|--------|------|-------------|
| `order_id` | STRING | Globally unique order identifier. |
| `customer_id` | STRING | FK to [customers](/tables/customers.md). |

# Examples

...

# Citations

[1] [Source title](https://example.com)
```

**Frontmatter rules (§4.1):**
- `type` is the **only required** field and must be **non-empty**.
- Recommended, in priority order: `title`, `description`, `resource`, `tags`, `timestamp`.
- Producers MAY add any extra keys; never strip unknown keys you find — preserve them.
- Pick `type` values that are stable and meaningful to the project ("API Endpoint",
  "Metric", "Playbook", "ADR", "Service", "Postgres Table"). They are not centrally registered.

**Body:** standard markdown. Conventional section headings: `# Schema`, `# Examples`,
`# Citations`. Lead with what a reader/agent most needs.

## Cross-links

- Absolute (bundle-root relative), begins with `/`: `[customers](/tables/customers.md)`
- Relative: `[other](./other.md)`

Links are untyped; the relationship is conveyed by surrounding prose. Broken links are
tolerated by the spec but fix them when you notice them.

## Reserved files — never use these names for concepts

**`index.md`** — directory listing for the level it sits in. No frontmatter, **except**
the bundle-root `index.md`, which MAY declare the version:

```markdown
---
okf_version: "0.1"
---
# Sales knowledge catalog

* [Orders](tables/orders.md) - One row per completed customer order.
* [Customers](tables/customers.md) - One row per customer.
```

Non-root `index.md` carries no frontmatter — just headings and a bullet list of
`* [Title](relative-url) - short description`, descriptions mirroring each concept's
`description`.

**`log.md`** — chronological change history, **newest first**, dates as `## YYYY-MM-DD`:

```markdown
# Update Log

## 2026-06-13
* **Creation**: Added `tables/orders.md`.
* **Update**: Revised `metrics/weekly_active_users.md` definition.
```

## "Continuously update" — the part people forget

Whenever the project changes in a way that affects documented knowledge:
1. Edit the affected concept doc(s); bump their `timestamp`.
2. Add/adjust `index.md` entries for any new/removed concepts.
3. Append a dated entry to the bundle-root (and relevant subdirectory) `log.md`.

Before declaring project work done, the catalog must reflect the change. A stale catalog
is unfinished work.

## §9 conformance — what "fully adhere" means

A bundle conforms iff:
1. Every **non-reserved** `.md` has a parseable YAML frontmatter block.
2. Every such frontmatter has a **non-empty `type`**.
3. `index.md`/`log.md` follow the structures above when present.

Plus the spec-body MUSTs that flank §9: files are **UTF-8** (§4); reserved filenames
`index.md`/`log.md` are **never** reused for concepts (§3.1); `log.md` entries use the
`**Action**: description` convention under `## YYYY-MM-DD` headings, newest-first (§7);
cross-links prefer the absolute, `/`-prefixed bundle-root form (§5).

Consumers MUST NOT reject a bundle for: missing optional fields, unknown `type` values,
unknown extra keys, broken cross-links, or missing `index.md`. So: be liberal in what you
add, strict about `type` + parseable UTF-8 frontmatter.

Verify with the **`okf-auditor`** agent before declaring done.

## Anti-patterns / corrections

- **Do not** copy field schemas from third-party blogs. The undercodetesting.com article
  invents `id`, `links`, `references`, `updated` — these are NOT OKF. The real required
  field is `type`; the recommended set is title/description/resource/tags/timestamp.
- **Do not** put frontmatter in a non-root `index.md`.
- **Do not** give a concept doc an empty or missing `type`.
- **Do not** treat the catalog as write-once — it lives with the project.
