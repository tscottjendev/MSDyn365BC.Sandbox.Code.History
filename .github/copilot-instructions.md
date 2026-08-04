# GitHub Copilot Instructions — Business Central First-Party Source Review

## Purpose

Use this repository primarily as a **read-only source corpus for reviewing and understanding Microsoft Dynamics 365 Business Central first-party AL code**.

The highest-priority application is the **Base Application**, but reviews must account for relevant code in the repository's other Microsoft first-party applications. Do not treat the Base Application as an isolated system when an interface, event, implementation, enum extension, table extension, page extension, permission set, test, or consuming workflow exists elsewhere in the checked-out branch.

The repository is a historical extraction of Microsoft-published application artifacts. The checked-out branch determines the country/region, major version, platform generation, and exact source snapshot under review. Establish that context from the local Git state and repository contents before drawing conclusions.

## Default Working Mode

When asked to review, explain, trace, compare, or assess code:

1. Inspect the workspace and current Git branch first.
2. Identify the Base Application directory by locating its `app.json`; do not assume a fixed path.
3. Inventory the other first-party applications available in the current branch from their `app.json` files.
4. Search the repository before answering. Prefer code evidence over assumptions or generic Business Central knowledge.
5. Begin with the Base Application implementation, then follow relevant dependencies, integrations, extensions, subscribers, implementations, and consumers into other first-party applications.
6. Report findings with precise file paths, object names, object IDs where available, procedure names, and line ranges or short code excerpts.
7. Clearly separate verified facts, reasoned conclusions, and unresolved questions.

Do not claim that a repository-wide search found nothing unless the relevant object names, IDs, procedure names, event names, interface names, and likely synonyms were searched.

## Repository and Version Awareness

- Treat the **currently checked-out branch and commit** as authoritative for the review.
- State the branch and commit when the result could vary by Business Central version, localization, or hotfix level.
- Infer application identity, publisher, version, dependencies, ID ranges, runtime, and platform/application compatibility from `app.json` rather than from directory names alone.
- Expect repository layout and app availability to differ between branches.
- Country/region branches may contain localized or reduced application sets. Do not assume that absence from the current branch means absence from the worldwide product.
- Do not silently mix evidence from another branch, tag, online source, artifact version, or a developer's installed symbols.
- If comparison with another version is requested, use explicit Git refs and distinguish added, removed, renamed, and behaviorally changed code.
- Generated extraction metadata, missing translations, absent build assets, or unavailable dependencies may make a full compile impossible. Do not treat this alone as a product defect.

## Application Scope and Search Strategy

### Primary scope: Base Application

Start analysis in the Base Application for core business behavior, including:

- posting and document-processing pipelines;
- master data and ledger behavior;
- setup-driven decisions;
- validation and field-trigger behavior;
- event publication;
- permissions and entitlements;
- upgrade and data-migration logic;
- integration contracts exposed through interfaces, events, APIs, and codeunits.

### Required secondary scope: other first-party applications

Use other Microsoft first-party apps whenever they can change, extend, implement, subscribe to, test, or consume the Base Application behavior being reviewed. Search especially for:

- `EventSubscriber` methods targeting relevant publishers;
- interface implementations and consumers;
- enum values and enum extensions;
- table, page, report, and permission-set extensions;
- implementations selected through `Interface`, `Implementation`, or extensible enums;
- app dependencies declared in `app.json`;
- public procedures and integration events consumed by another app;
- feature, upgrade, migration, and install codeunits;
- test apps that reveal intended contracts, edge cases, or regressions;
- localization apps that alter behavior for the checked-out country/region.

Do not broaden the review indiscriminately. Explain why each secondary application is relevant to the reviewed flow.

### Recommended discovery sequence

Use repository search tools such as `rg`, Git search/diff commands, and editor references where available. A typical investigation should proceed as follows:

1. Locate every `app.json` and build a small app/dependency map.
2. Locate the primary AL object by object type plus name, and by object ID when known.
3. Find direct calls and references to the relevant procedures, fields, tables, enums, interfaces, and events.
4. Find publishers and all in-repository subscribers.
5. Find extensions of the affected objects.
6. Find implementations of affected interfaces and extensible-enum values.
7. Inspect setup, feature flags, permissions, commits, tests, and localization code where relevant.
8. Trace data writes through validation, posting, commit boundaries, background execution, and error handling.
9. Only then summarize behavior and findings.

Account for quoted AL identifiers, overloaded procedures, similarly named objects, obsoleted symbols, and renamed symbols when searching.

## AL and Business Central Review Rules

Review AL according to the semantics of the version in the checked-out branch. Do not apply newer language or platform behavior without evidence that the branch supports it.

Pay particular attention to:

### Data integrity and transaction behavior

- `Insert`, `Modify`, `Delete`, `Rename`, and `ModifyAll`, including whether triggers run.
- `Validate` versus direct assignment and the resulting field-trigger behavior.
- `Commit`, `CommitBehavior`, `TryFunction`, rollback expectations, and partial-update risk.
- Temporary records, record copies, filters, marks, keys, `SetCurrentKey`, and isolation/locking behavior.
- Re-entrancy, idempotency, retry behavior, and duplicate-processing risk.
- Number series, dimensions, reservations, tracking, applications, posting groups, and ledger consistency when relevant.

### Event-driven extensibility

- Event publisher signature, `IncludeSender`, global-variable access, isolated events, and `var` parameters.
- Subscriber ordering assumptions; do not assume deterministic order unless the code guarantees it.
- `IsHandled` patterns, including multiple subscribers, incomplete replacement behavior, and skipped standard validation.
- Whether new logic preserves existing events and extension points.
- Whether refactoring changes event timing, transaction boundaries, parameter values, or observable side effects.
- Interface and extensible-enum contracts, including missing implementations and fallback behavior.

### Security and permissions

- `Permissions` properties and indirect permissions required by called code.
- Permission sets, permission-set extensions, entitlements, inherent permissions, and elevated operations.
- Sensitive data exposure through pages, APIs, reports, telemetry, errors, or logging.
- User-input validation, record filtering, tenant/company boundaries, and authorization assumptions.
- Avoid recommending broad permission grants when a narrower first-party pattern exists.

### Performance and scale

- Repeated database reads or writes inside loops.
- Missing or ineffective filters, keys, `SetLoadFields`, `CalcFields`, and `CalcSums` usage.
- FlowField and media/blob access costs.
- Unbounded `FindSet`, `FindFirst`, `Get`, query, report, XMLport, and API workloads.
- Lock duration, contention, background sessions, task scheduling, and job queue behavior.
- Telemetry or logging inside high-volume paths.
- Distinguish proven performance defects from optimization suggestions that require measurement.

### API and compatibility

- Public/protected procedures, events, interfaces, enum values, API pages/queries, and integration contracts.
- Obsolete attributes and state (`Pending`, `Removed`, etc.) as represented in the checked-out version.
- Schema synchronization, upgrade tags, install/upgrade codeunits, field moves, and data migration.
- Breaking behavior caused by changing captions used as data, enum ordinals, object/field IDs, signatures, visibility, or event timing.
- Compatibility with dependent first-party apps present in the branch.

### UI, reports, and background execution

- Page trigger side effects and assumptions about an interactive client.
- `GuiAllowed`, confirmations, dialogs, notifications, and error behavior in web service, job queue, test, and background contexts.
- Report request pages, processing-only reports, saved settings, filters, and preview/printing side effects.
- API delayed insert, OData keys, concurrency, validation, and discoverability.

### Tests and intended behavior

- Search first-party test applications when they are present and relevant.
- Treat tests as evidence of intended behavior, not infallible proof that production code is correct.
- For a proposed fix, identify the most appropriate existing test codeunit and style before suggesting a new test.
- Recommend tests for normal behavior, boundary cases, permissions, event subscribers, upgrade paths, and localization where applicable.

## Review Output Format

For code-review requests, organize the response as follows unless the user asks for another format.

### Context

- Current branch and commit, if available.
- Primary application and object(s).
- Relevant secondary first-party applications inspected.
- Scope limitations, missing apps, or unavailable symbols.

### Findings

List only actionable defects or material risks. Order them by severity:

- **Critical** — data corruption, security breach, unrecoverable posting/accounting error, or widespread outage risk.
- **High** — likely incorrect business result, broken upgrade/integration, serious permission issue, or major regression.
- **Medium** — meaningful edge-case failure, concurrency issue, extensibility break, or material performance problem.
- **Low** — localized correctness, maintainability, diagnostics, or testability concern with credible impact.

For each finding include:

1. **Title and severity**.
2. **Evidence** — exact path, object/procedure, and relevant line range.
3. **Behavior** — what the code does.
4. **Impact** — the concrete user, data, accounting, integration, security, upgrade, or performance consequence.
5. **Trigger** — conditions required to reproduce it.
6. **Cross-app evidence** — relevant subscriber, extension, implementation, consumer, or test in another first-party app.
7. **Recommendation** — a minimal, Business Central-compatible remediation that preserves supported extension points.
8. **Test coverage** — focused tests that would fail before and pass after the fix.
9. **Confidence** — high, medium, or low, with the reason if not high.

### No-finding responses

If no actionable issue is found:

- say that no actionable findings were identified within the inspected scope;
- list the key objects, subscribers, extensions, implementations, tests, and apps inspected;
- state important limitations;
- do not invent style findings merely to populate the response.

## Evidence and Reasoning Standards

- Anchor each finding to a narrow, relevant code location. Do not cite an entire file when a specific procedure or trigger is responsible.
- Trace callers and downstream effects before identifying code as dead, redundant, unsafe, or unreachable.
- Verify whether an event subscriber, interface implementation, extension object, setup option, feature flag, or localization changes the apparent behavior.
- Consider error paths as well as the happy path.
- Do not report a theoretical possibility without a plausible trigger and concrete impact.
- Do not classify intentional extensibility patterns as defects merely because behavior can be altered by extensions.
- Avoid cosmetic comments unless they hide a correctness or maintenance risk.
- Prefer minimal fixes consistent with patterns already used in the same first-party version.
- Never fabricate file paths, symbols, object IDs, tests, compiler behavior, or application relationships.
- If evidence is incomplete, say exactly what is missing and provide the search or validation needed to resolve it.

## Git History and Change Review

When reviewing a commit, diff, pull request, patch, or version change:

- Review the changed lines and enough surrounding code to understand the complete execution path.
- Use `git diff`, `git show`, `git log`, `git blame`, and explicit refs as appropriate.
- Check both added behavior and behavior removed by the change.
- Search all first-party apps for callers, subscribers, implementers, extensions, tests, and duplicated patterns affected by renamed or changed symbols.
- Pay special attention to changes in event signatures/timing, validation order, transaction boundaries, permissions, object IDs, schema, upgrade logic, API contracts, and obsoletion.
- Distinguish source changes introduced by Microsoft artifacts from repository extraction or formatting changes.
- For cross-version comparisons, describe the exact source and target refs and avoid attributing intent unless supported by code, tests, commit history, or documentation.

## Suggested Improvements and Code Examples

When proposing AL changes:

- Match the AL syntax, runtime, analyzers, and patterns supported by the checked-out branch.
- Keep examples narrow and directly tied to the finding.
- Preserve event publishers, interfaces, permissions, telemetry, and transaction semantics unless changing them is the explicit goal.
- Reuse existing first-party helpers and abstractions after verifying their contract and dependencies.
- Do not introduce dependencies from the Base Application to an app that depends on the Base Application.
- Do not suggest edits to this history repository as if it were the authoritative product source unless the user explicitly asks for a local patch or experiment.
- Label pseudocode as pseudocode and state when an example has not been compiled.

## Communication Style

- Be concise, technical, and evidence-led.
- Use Business Central and AL terminology accurately.
- Lead with material findings, not a walkthrough of every file read.
- Explain cross-application interactions explicitly.
- Ask a clarifying question only when the requested Git ref, comparison target, or business scenario is essential and cannot be derived locally.
- If the request is broad, perform a bounded review, state the selected scope, and provide the highest-value findings first.
