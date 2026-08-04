---
agent: 'agent'
description: 'Create a precise Business Central extension handoff from the General Journal approval analysis'
---

# Source Session 5 — Business Central extension handoff

Use these completed analyses as primary context:

- `.design/architecture/general-journal-approvals/00-environment-and-reconnaissance.md`
- `.design/architecture/general-journal-approvals/02-workflow-registration-analysis.md`
- `.design/architecture/general-journal-approvals/03-runtime-sequence-flows.md`
- `.design/architecture/general-journal-approvals/04-approval-subject-and-state-model.md`
- `.design/architecture/general-journal-approvals/05-restriction-and-posting-enforcement.md`

Consult source only to resolve contradictions or missing evidence. Do not restart repository-wide discovery or modify production code.

## Objective

Create a precise handoff for another Business Central AL extension. The receiving extension can use standard public objects/procedures, published events, accessible interfaces, extensible enums, and supported registration mechanisms available in its own symbols.

Preserve verified Business Central-specific symbols. Distinguish supported dependencies from inaccessible implementation and General Journal-specific glue.

## Required deliverables

Create:

- `.design/architecture/general-journal-approvals/01-object-and-accessibility-inventory.md`
- `.design/architecture/general-journal-approvals/06-business-central-extension-handoff.md`
- `.design/architecture/general-journal-approvals/07-standard-symbol-evidence-index.md`
- `.design/architecture/general-journal-approvals/08-unresolved-and-version-sensitive-findings.md`

## Handoff content requirements

The handoff must include:

1. analysed environment and version scope;
2. standard component inventory by object type;
3. member-level accessibility classification;
4. exact General Journal approval subject and `RecordId` mapping;
5. workflow registration contracts;
6. runtime workflow invocation contracts;
7. `Approval Entry` integration;
8. record restriction and edit prevention;
9. posting/processing enforcement;
10. reusable standard services matrix;
11. target-extension object blueprint;
12. suggested target workflow event catalogue;
13. suggested target workflow response catalogue;
14. approval-subject decision framework: header, line, generated standard document, and hybrid;
15. Business Central compatibility checklist;
16. sections titled `Use directly`, `Subscribe or extend`, `Reproduce in the target domain`, `Learn from, but do not call`, and `Revalidate against target symbols`;
17. focused target-repository investigation instructions;
18. evidence appendix for every recommended standard symbol.

## Accessibility categories

Use exactly:

- Public supported dependency
- Published extension point
- Accessible data contract
- Observable but inaccessible implementation
- General Journal-specific implementation
- Version-sensitive or uncertain

## Critical rules

- Do not replace exact Business Central object names with generic service names.
- Verify every recommended standard dependency and relevant member.
- Do not recommend direct writes to standard workflow/approval tables unless proven supported.
- Separate source-version evidence from cross-version assumptions.
- State how the target should revalidate every version-sensitive symbol.
- Do not assign target object IDs.
- Every recommended standard symbol must appear in the evidence index.

## Consistency check

Before finishing verify object names/IDs across documents, approval-subject consistency, line-versus-batch consistency, runtime/posting consistency, accessibility classifications, and that unknowns are not presented as facts.

In chat, report:

1. directly reusable standard components;
2. extension points to subscribe to or extend;
3. components the target must implement;
4. version-sensitive dependencies;
5. approval-subject recommendation;
6. deliverable paths.

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
