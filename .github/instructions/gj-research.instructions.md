---
name: General Journal architecture research
description: Source-grounded rules for General Journal research artifacts
applyTo: ".design/architecture/general-journal/**/*.md"
---

# General Journal research artifact rules

The existing repository-wide Copilot instructions remain authoritative and applicable.

When creating or updating files under `.design/architecture/general-journal/`:

- Research is read-only; do not modify Business Central AL source.
- Ground material findings in source references: relative path, AL object type/ID/name, member, and line range when available.
- Label findings as **Verified**, **Inference**, **Recommendation**, **Not located**, or **Version-specific**.
- Trace runtime behavior through pages, tables, codeunits, reports, events, subscribers, workflows, restrictions, posting, and tests.
- Record accessibility and distinguish public extension surfaces from internal Microsoft implementation.
- Classify reusable findings as: public framework, published event, architectural pattern, General Journal-specific, internal detail, or version-specific.
- Do not copy substantial Microsoft source into the artifacts.
