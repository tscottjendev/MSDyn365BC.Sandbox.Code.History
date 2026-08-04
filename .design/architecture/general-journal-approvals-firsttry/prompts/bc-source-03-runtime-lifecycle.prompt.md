---
agent: 'agent'
description: 'Trace the General Journal approval runtime lifecycle and approval subject'
---

# Source Session 3 — Runtime approval lifecycle

Read first:

- `.design/architecture/general-journal-approvals/00-environment-and-reconnaissance.md`
- `.design/architecture/general-journal-approvals/02-workflow-registration-analysis.md`

Your sole objective is to trace the runtime approval lifecycle for General Journals.

Do not perform detailed posting-enforcement analysis, design the target repository, or modify code.

## Trace these scenarios independently

### A. Send approval request

Trace the page action, eligibility validation, applicable-workflow check, workflow-event publication, workflow execution, response execution, approval-entry creation, approver resolution, restriction/state change, and notification initiation.

### B. Approve

Trace the approval action, permission and approver validation, approval-entry update, sequence handling, workflow continuation, intermediate versus final approval, and restriction/state effects.

### C. Reject

Trace the rejection action, approval-entry update, source-record effect, restriction effect, and resubmission consequences.

### D. Cancel

Trace the cancellation action, requester validation, open-entry cancellation, workflow cancellation, restriction removal, and resulting source-record state.

### E. Delegate

Trace delegation if supported by the implementation.

## Determine the exact approval subject

Establish conclusively:

- source table and table ID;
- exact `RecordId` used;
- line-, batch-, or hybrid-level approval;
- relationship among journal template, batch, and line;
- number of approval entries created;
- multiple-line behaviour;
- stability of the source-record identity.

## Approval Entry integration

Document relevant fields and behaviour, including source linkage, sender, approver, sequence, status, workflow step instance, amount fields where relevant, due date, delegation, comments, and navigation.

Identify whether data is populated by generic workflow handling, General Journal-specific code, event subscribers, or inaccessible dependency behaviour.

## Evidence rules

For each significant step provide object, procedure/trigger/action/event, path, line range, inputs, outputs, side effects, accessibility, and whether the conclusion is fact or interpretation.

## Deliverables

Create:

- `.design/architecture/general-journal-approvals/03-runtime-sequence-flows.md`
- `.design/architecture/general-journal-approvals/04-approval-subject-and-state-model.md`

The sequence document must contain Mermaid diagrams for send, approve, reject, cancel, and delegate where supported.

The state document must contain the exact approval subject, `RecordId` mapping, Approval Entry mapping, effective state model, transition table, Mermaid state diagram, editability implications, and unresolved questions.

## Session boundary

Do not deeply trace journal posting. Record encountered posting checks only as pointers for Session 4.

In chat, report:

- approval subject and scope;
- approval-entry creation mechanism;
- final-approval detection mechanism;
- principal unknown;
- deliverable paths.

## Context management

- Treat the listed input documents as authoritative context from prior sessions.
- Do not repeat repository-wide searches already completed unless resolving a contradiction.
- Read only source files relevant to this session's objective.
- If a prior conclusion is contradicted by source evidence, record the contradiction explicitly.
- Do not silently replace prior conclusions.
- Do not treat interpretations from prior sessions as proven facts.
- Carry unresolved findings forward rather than inventing an answer.
- Keep this session within its stated boundary.
- Do not modify production AL files.

## Required next-session handoff

End the generated document with this block:

### Next-session handoff

- Facts established:
- Standard symbols verified:
- Target-specific symbols verified:
- Important interpretations:
- Unresolved questions:
- Version-sensitive findings:
- Files that provide the strongest evidence:
- Documents created:
- Recommended scope for the next session:
