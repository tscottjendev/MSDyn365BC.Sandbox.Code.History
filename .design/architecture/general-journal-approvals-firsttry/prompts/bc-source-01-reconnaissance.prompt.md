---
agent: 'agent'
description: 'Identify the Business Central environment and candidate General Journal approval objects'
---

# Source Session 1 — Environment and reconnaissance

You are analysing a Microsoft Dynamics 365 Business Central AL repository.

Your sole objective is to establish the repository environment and locate objects that may participate in General Journal approval workflows.

Do not perform the complete workflow analysis. Do not modify code. Do not propose a target solution.

## Tasks

### 1. Inspect the application environment

Inspect:

- `app.json` and dependency declarations;
- application, platform, and runtime versions;
- ID ranges and namespaces;
- `.alpackages`, if accessible;
- included application source;
- test dependencies;
- localisation dependencies.

Record:

- which Business Central version is represented;
- whether Base Application and System Application source are present;
- whether dependencies are visible only through symbols;
- whether this repository contains custom General Journal approval behaviour.

### 2. Locate candidate objects

Search for objects relating to:

- General Journal pages;
- `Gen. Journal Line` and `Gen. Journal Batch`;
- workflow event and response registration;
- approval request and cancellation actions;
- `Approval Entry`;
- record restriction;
- journal posting enforcement;
- workflow templates;
- automated tests.

Search by behaviour as well as names.

### 3. Classify discovered candidates

For each candidate, record:

- object type, ID, name, and namespace;
- owning application;
- repository-relative file path;
- likely role;
- whether source is available;
- whether public visibility is established: Yes, No, or Unknown;
- why it needs examination in a later session.

Do not claim participation in the workflow unless code evidence proves it.

## Deliverable

Create:

`.design/architecture/general-journal-approvals/00-environment-and-reconnaissance.md`

Include:

1. environment summary;
2. dependency summary;
3. source-versus-symbol availability;
4. candidate-object inventory;
5. detected customisations;
6. version risks;
7. recommended Session 2 starting points;
8. unresolved questions.

## Session boundary

Stop after reconnaissance. Do not trace the full Send Approval Request flow, design reusable components, or create production code.

In chat, report:

- analysed Business Central version;
- source availability;
- number of candidate objects found;
- three highest-value entry points for Session 2;
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
