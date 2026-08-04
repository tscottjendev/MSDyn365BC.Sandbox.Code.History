---
name: gj-discover
description: Discover the General Journal, posting, workflow, approval, restriction, and test object graph
agent: agent
model: GPT-5.3-Codex
---

# Task context

The repository already has repository-wide Copilot instructions. Follow them. These task-specific instructions supplement, but do not replace, those instructions.

This is read-only architecture research. Do not modify AL source. Write generated documents only beneath `.design/architecture/general-journal/`.

## Evidence rules
- Treat source in this repository as primary evidence.
- Do not invent objects, IDs, fields, procedures, events, subscribers, workflow definitions, or call paths.
- Cite repository-relative file path, object type/ID/name, member, and line range where available.
- Separate **Verified**, **Inference**, **Recommendation**, **Not located**, and **Version-specific** statements.
- Trace behavior beyond pages into tables, codeunits, reports, workflow code, subscribers, restrictions, posting, and tests.
- Record accessibility. Internal/local implementation may inform design but is not a supported extension API.
- Prefer concise source references over copying Microsoft code.

# Task
Inventory the source needed to understand General Journal Template, Batch, Line, worksheet pages, validation, posting/preview, workflow approvals, Approval Entry, record restrictions, notifications, and tests. Also locate first-party analogues such as item journal or worksheet batch approvals when present.

Search by concepts and symbols, not filenames alone. Follow declarations, calls, events/subscribers, table relations, actions, reports, and tests. Do not yet design Jenworks.

# Output
Create `.design/architecture/general-journal/gj-01-discovery.md` containing:
1. Repository/app/version inventory (`app.json`, branch/commit if available).
2. Object catalogue grouped by data, UI, validation, posting, workflow/approval, restrictions, notifications, first-party analogues, and tests.
3. For every object: type, ID, name, path, relevance, key members, accessibility.
4. Verified/provisional dependency map with each edge marked `Verified` or `To verify`.
5. Unresolved research questions.
6. Runtime-oriented reading order.
7. Search coverage and anything not located.
