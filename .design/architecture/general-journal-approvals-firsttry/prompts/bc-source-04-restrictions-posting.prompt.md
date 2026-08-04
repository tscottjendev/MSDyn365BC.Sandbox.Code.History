---
agent: 'agent'
description: 'Analyse General Journal approval restrictions and posting enforcement'
---

# Source Session 4 — Restrictions and posting enforcement

Read first:

- `.design/architecture/general-journal-approvals/00-environment-and-reconnaissance.md`
- `.design/architecture/general-journal-approvals/03-runtime-sequence-flows.md`
- `.design/architecture/general-journal-approvals/04-approval-subject-and-state-model.md`

Your sole objective is to determine how pending approval prevents modification and posting of General Journals.

Do not reanalyse workflow registration, create the target design, or modify code.

## Part 1 — Record restrictions

Trace:

- how and which record becomes restricted;
- line versus batch scope;
- restriction checks;
- UI editability effects;
- whether direct AL modification is protected;
- removal after approval, rejection, or cancellation;
- separate material-change detection, if any.

Distinguish record restriction infrastructure, page editability, table validation, domain validation, approval status, and workflow status.

## Part 2 — Posting enforcement

Trace all discoverable posting routes:

- page posting and preview actions;
- batch posting;
- posting reports;
- direct posting codeunits;
- job queue/background posting;
- APIs or service routes;
- extension events surrounding posting.

Find the deepest shared enforcement point.

For every guard, identify object/member, file path and lines, check performed, record checked, error produced, transaction timing, direct-AL coverage, and bypass possibilities.

## State-specific behaviour

Determine posting behaviour for:

- no workflow configured;
- workflow configured but no request sent;
- pending or partially approved;
- approved;
- rejected;
- canceled;
- stale open `Approval Entry`;
- restriction without an open approval entry;
- approval entry without a restriction.

## Business Central extension relevance

Extract:

- reusable public restriction APIs;
- reusable posting-related events;
- standard checks another extension may call;
- journal-specific checks requiring a target-domain equivalent;
- inaccessible behaviour that must not be copied directly.

## Deliverable

Create:

`.design/architecture/general-journal-approvals/05-restriction-and-posting-enforcement.md`

Include restriction lifecycle, UI-versus-domain enforcement, posting entry-point inventory, deepest shared guard, bypass analysis, state-specific behaviour, accessible APIs/events, journal-specific mechanisms, target implications, and unresolved risks.

Include Mermaid sequences for attempted edit while pending, attempted posting while pending, posting after final approval, and direct codeunit posting.

## Session boundary

Stop after restriction and posting enforcement are established.

In chat, report:

- restricted record;
- deepest posting enforcement point;
- whether direct AL posting is protected;
- public APIs/events available to another extension;
- highest bypass risk;
- deliverable path.

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
