---
name: gj-approvals
description: Deep trace General Journal batch workflow and approval behavior
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

Read `gj-01-discovery.md` and `gj-02-architecture.md` from `.design/architecture/general-journal/`.

# Task
Trace source-level approval behavior for General Journal batches:
1. Workflow event/response registration, combinations, templates, conditions, RecordRef handling.
2. Send for approval from UI through checks, published events, subscribers, Approval Entry creation, approver selection, restrictions, notification, refresh.
3. Enforcement during pending approval for batch/line insert, modify, delete, rename, import/programmatic change, preview, and posting.
4. Approve, reject, delegate, cancel, resubmit and resulting status/restriction/notification changes.
5. Proof of completed approval before posting; behavior when approved data changes; post-processing audit trace.
6. Empty/unbalanced batches, multiple approvers, limits/groups, concurrency, background posting, stale entries, and non-UI writes.
7. Differences by journal page/template and first-party batch approval analogues.

Do not equate a page action or status field with enforcement. Identify gaps explicitly.

# Output
Create `.design/architecture/general-journal/gj-03-approvals.md` containing object catalogue, workflow registration, sequences, Approval Entry lifecycle, restriction strategy, enforcement matrix, state transitions, approval/posting interaction, audit analysis, reusable pattern, General Journal coupling, extension requirements, edge cases, risks and open questions.

Include verified Mermaid diagrams for registration, send sequence, state transitions, and approval-to-posting lifecycle.
