---
name: gj-transfer
description: Produce a portable General Journal architecture package for the Jenworks repository
agent: agent
model: Claude Sonnet 5
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

Read and quality-check `gj-01-discovery.md`, `gj-02-architecture.md`, and `gj-03-approvals.md` in `.design/architecture/general-journal/`.

# Task
Create a self-contained, portable reference for a separate Jenworks repository. Recheck source where existing artifacts are ambiguous. Preserve exact source references, but do not assume the target can call internal members.

# Output
Create `.design/architecture/general-journal/gj-04-transfer-package.md` with:
- Source/version/commit context and included/excluded folders.
- Verified template/batch/line, validation, posting/preview, approval, restrictions, audit summary.
- Key object/member catalogue with accessibility and reuse classification.
- Source-backed reusable architecture rules.
- Public integration points and limitations.
- Approval implementation checklist.
- Capability decision matrix: must/should/optional/domain-dependent/do-not-copy.
- Questions the Jenworks analysis must answer.
- Source-reference appendix.

The document must stand alone after copying to another repository.
