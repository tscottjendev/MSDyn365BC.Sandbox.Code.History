---
name: gj-architecture
description: Analyze General Journal template, batch, line, validation, worksheet, and posting architecture
agent: agent
model: GPT-5.5
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

Read `.design/architecture/general-journal/gj-01-discovery.md` and verify claims against source.

# Task
Trace the General Journal runtime architecture:
- Template responsibility, types, defaults, source/number series, page/posting selection, creation/deletion.
- Batch key, defaults/inheritance, selection/creation/deletion, line relationship, approval boundary.
- Line key/numbering, accounts, amounts, currency, dates, documents, dimensions, defaults, imports/generation.
- Worksheet binding, batch switching, totals/warnings/editability, and page versus business-layer responsibility.
- Validation layers: field, cross-field, line, batch, pre-post, posting, workflow.
- Post, post batch, preview, checks, orchestration, account-specific posting, number consumption, registers, entry creation, cleanup, errors, transaction boundaries, integration events.
- Public extension surface versus internal implementation.

# Output
Create `.design/architecture/general-journal/gj-02-architecture.md` with executive summary, responsibility catalogue, data model, lifecycle, validation matrix, posting sequence, state model, extensibility map, transferable principles, General Journal-specific/non-transferable behavior, risks, and open questions.

Include verified Mermaid diagrams for data relationships, entry-to-posting, validation layers, and posting call sequence.
