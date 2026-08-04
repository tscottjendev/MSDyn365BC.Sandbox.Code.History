---
agent: 'agent'
description: 'Trace General Journal workflow event, response, relation, and template registration'
---

# Source Session 2 — Workflow registration

Read first:

`.design/architecture/general-journal-approvals/00-environment-and-reconnaissance.md`

Your sole objective is to determine how General Journal approval capabilities are registered and exposed on the Business Central Workflow page.

Do not analyse the complete runtime lifecycle, investigate posting in depth, design the target process, or modify code.

## Investigate

Trace registration of:

- workflow categories;
- workflow events;
- workflow responses;
- predecessor and successor combinations;
- workflow-table relations;
- workflow templates;
- workflow conditions and response options;
- event and response descriptions.

Identify all codeunits and event subscribers used to populate the workflow event and response libraries.

## Evidence required for every contract

Record:

- object type, ID, exact name, namespace, and owning application;
- procedure or event;
- exact event-code or response-code mechanism;
- parameters and relevant table IDs;
- predecessor/successor relationships;
- file path and narrow line range;
- public accessibility;
- whether a target AL extension can call it, subscribe to it, or reproduce the pattern;
- whether it is generic or General Journal-specific.

Classify each relevant symbol as one of:

- Public supported dependency
- Published extension point
- Accessible data contract
- Observable but inaccessible implementation
- General Journal-specific implementation
- Version-sensitive or uncertain

Do not infer accessibility from naming. Use source modifiers or symbols.

## Deliverable

Create:

`.design/architecture/general-journal-approvals/02-workflow-registration-analysis.md`

Include:

1. registration lifecycle;
2. object inventory;
3. workflow event catalogue;
4. workflow response catalogue;
5. predecessor/successor map;
6. workflow-template construction;
7. table-relation handling;
8. accessibility classifications;
9. pattern required for another AL extension;
10. unresolved findings.

Include a Mermaid diagram showing how registration objects populate standard workflow libraries.

## Session boundary

Stop when registration and discoverability are explained. Do not trace approval-entry creation beyond identifying the registered response. Do not trace posting or produce a target design.

In chat, report:

- exact event that begins General Journal approval;
- response expected to create approval requests;
- principal registration objects;
- unresolved runtime questions;
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
