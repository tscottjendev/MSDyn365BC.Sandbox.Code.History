# General Journal architecture — transfer package for Jenworks (gj-04)

## Purpose and portability notice

This document is a **self-contained reference**, written to be copied into a separate repository (referred to here as **Jenworks**) that does not have access to Microsoft Dynamics 365 Business Central (BC) AL source. It synthesizes and re-verifies `gj-01-discovery.md`, `gj-02-architecture.md`, and `gj-03-approvals.md` from this repository's `.design/architecture/general-journal/` folder. Those three files are **not required to travel with this document** — every claim needed to stand alone is restated here, with source citations kept only as an audit trail back to the original evidence.

**Critical constraint for the target repository**: Jenworks cannot call BC AL objects, procedures, tables, or events directly. Nothing in this document is an API Jenworks can invoke. Every "reusable" item below is a **pattern to reimplement**, not a library to reference. Where a cited BC procedure is `local` or otherwise internal, Jenworks must not assume equivalent access exists in its own domain — it must design its own analogous internal member.

## Labels used in this artifact

- **Verified**: directly supported by re-checked repository evidence (this pass re-read the cited source lines).
- **Inference**: reasoned conclusion from verified evidence.
- **Recommendation**: design guidance for Jenworks.
- **Not located**: searched but not found in this branch snapshot.
- **Version-specific**: tied to this exact branch/commit/app version and may not hold in other BC versions.

## 1. Source, version, and scope context

- **Verified** Source repository: `StefanMaron/MSDyn365BC.Sandbox.Code.History`. Branch `gb-29-vNext`, commit `fc4c58aef01063370e19823eb0aec4e891b626ea` (re-confirmed via `git rev-parse HEAD` during this pass).
- **Verified** Primary application: **Base Application** 29.0.53300.0 (`Base Application/app.json`), platform dependency 29.0.0.0, depending on **System Application** and **Business Foundation** (both also 29.0.53300.0).
- **Verified** Secondary applications inspected: System Application (workflow engine, `System/Workflow/*`), and the first-party test app **Tests-General Journal** (29.0.53300.0), used only as behavioral evidence, not as a dependency to copy.
- **Included folders/objects** (all under `Base Application/`):
  - `Finance/GeneralLedger/Journal/*` — templates, batches, lines, all worksheet page variants.
  - `Finance/GeneralLedger/Posting/*` and `Finance/GeneralLedger/Preview/*` — posting/preview codeunits.
  - `System/Workflow/*` — workflow engine, approval response/event handling, record restriction, webhook approval stack.
  - `OtherCapabilities/Approvals/*` — `Approval Entry` table and `Approvals Mgmt.` codeunit.
  - `Inventory/Journal/*` and `Inventory/Requisition/*` — first-party analogues used only for cross-checking the pattern, not for direct reuse.
  - `Tests-General Journal/*` — behavioral evidence only; test code itself is not a transferable artifact.
- **Excluded**: all country/localization apps, all apps other than Base Application/System Application/Business Foundation, and every object not directly on the template → batch → line → check → post → approve → restrict → audit path.
- **Version-specific** All line numbers, object IDs, and behavior described are tied to the commit above. BC minor/major version changes, localization variants, or later hotfixes can change field names, event signatures, or step sequencing. Re-verify before relying on exact line numbers in a future BC version.

## 2. Verified summary of core behavior

### 2.1 Template / batch / line model

- **Verified** Three-tier record model: table 80 `Gen. Journal Template` → table 232 `Gen. Journal Batch` → table 81 `Gen. Journal Line`. Batch key is `Journal Template Name, Name` (template-scoped); line key adds a line number allocated in increments of 10000 via `GetNewLineNo` (`GenJournalLine.Table.al` lines ~8216-8231).
- **Verified** Template `Type` field validation selects the source code, worksheet page, and test/posting reports for each journal kind (General, Sales, Purchases, Cash Receipts, Payments, Assets, Intercompany, Jobs), and overrides the page to page 283 `Recurring General Journal` when `Recurring = true` (`GenJournalTemplate.Table.al` lines ~101-145).
- **Verified** Batch `SetupNewBatch` copies balancing account, no. series, posting no. series, reason code, VAT-copy policy, and copy-to-posted-lines from the template (`GenJournalBatch.Table.al` lines ~381-401).
- **Verified** Line `SetUpNewLine` copies prior-line posting/document date, peeks/simulates number series, and applies batch/template defaults (`GenJournalLine.Table.al` lines ~4253-4348).
- **Inference** The pattern is: template = policy/type selection, batch = working-context defaults, line = transaction facts. This is the most transferable structural idea in this package (see §5).

### 2.2 Validation

- **Verified** Field-level validation lives on table 81 itself (account type/no. cross-checks, currency, posting groups, dimensions, amount/debit/credit derivation).
- **Verified** Standalone/pre-post business validation is centralized in codeunit 11 `Gen. Jnl.-Check Line` (`RunCheck`, date/account/amount/document/dimension checks), reused both for on-demand checking and for pre-post checking inside the batch posting engine.
- **Verified** Background (UX) validation is a separate, non-authoritative layer: codeunit 9081 `Check Gen. Jnl. Line. Backgr.` invokes the same `RunCheck` logic to surface errors to the user before posting is attempted, but does not gate anything itself.
- **Inference** There are three validation tiers with different authority: field triggers (always-on data integrity), background check (UX only, bypassable), and pre-post check (authoritative, runs inside the posting transaction). Only the last one is a true gate.

### 2.3 Posting and preview

- **Verified** Posting is layered: codeunit 231 `Gen. Jnl.-Post` (orchestration: template checks, confirmation, job-queue routing, preview binding) → codeunit 13 `Gen. Jnl.-Post Batch` (batch-level checks, balance/document-number handling, line loop, commit boundaries, recurring/non-recurring cleanup) → codeunit 12 `Gen. Jnl.-Post Line` (account-type-specific ledger entry creation).
- **Verified** Preview reuses the same call path but binds codeunit 231 to codeunit 19 `Gen. Jnl.-Post Preview` instead of running for real; codeunit 13's `ProcessBalanceOfLines`/restriction check paths explicitly special-case `PreviewMode` (`GenJnlPostBatch.Codeunit.al`, restriction check gated at ~lines 1495-1509 re-confirmed this pass).
- **Verified** `OnBeforeGenJnlPostBatchRun` (local event in codeunit 231, re-confirmed at `GenJnlPost.Codeunit.al` line 205 with an `IsHandled` parameter) lets a subscriber fully replace codeunit 13's batch posting run. This is a powerful but high-risk extension point: a subscriber that sets `IsHandled := true` must reproduce restriction checks, balance checks, number-series consumption, register semantics, recurring cleanup, preview handling, and commit boundaries on its own.
- **Verified** Non-recurring source lines are deleted after posting; recurring lines are advanced/reset per recurring method (`GenJnlPostBatch.Codeunit.al` lines ~1407-1465).

### 2.4 Approvals

- **Verified** General Journal approval is not a bespoke persistence model. It is built entirely from shared BC framework: table 454 `Approval Entry` (approval records), the Workflow engine (`Workflow`, `Workflow Step Instance`), codeunit 1535 `Approvals Mgmt.` (page-facing API), codeunit 1520/1521 `Workflow Event/Response Handling` (event routing and response execution), codeunit 1502 `Workflow Setup` (standard template construction), and codeunit 1550 `Record Restriction Mgt.` (usage-restriction enforcement via table 1550 `Restricted Record`).
- **Verified** Two parallel approval mechanisms exist for GJ batches/lines: (a) standard `Approval Entry`-based workflow (chain of statuses: Created → Open → Approved/Rejected/Canceled → optionally moved to `Posted Approval Entry` at posting time), and (b) an independent webhook approval stack (table 467-469, codeunits 1540-1545) using `Workflow Webhook Entry`/`Workflow Webhook Subscription` instead of `Approval Entry`. These do not share status semantics — do not conflate them.
- **Verified** Standard batch approval workflow gates on batch balance first: `InsertGenJnlBatchApprovalWorkflowSteps` inserts `CheckGeneralJournalBatchBalanceCode` immediately after the send event, and only the "balanced" event branch proceeds to restrict usage / create / send approval requests; the "not balanced" branch shows a message and stops (re-verified directly in `WorkflowSetup.Codeunit.al`, `InsertGenJnlBatchApprovalWorkflowSteps`, this pass).
- **Verified** (re-checked this pass) The standard batch workflow's cancel branch runs `CancelAllApprovalRequestsCode` and then a `ShowMessageCode` response — it does **not** insert an `AllowRecordUsageCode` response. So canceling a standard batch approval cancels the approval entries but does not, by itself, remove the usage restriction.
- **Verified** (re-checked this pass) The standard line approval workflow is built with `InsertRecApprovalWorkflowSteps(... , false, false)` — the final two boolean arguments are `ShowConfirmationMessage = false` and `RemoveRestrictionOnCancel = false` (confirmed in `InsertGeneralJournalLineApprovalWorkflowDetails`, `WorkflowSetup.Codeunit.al`). Canceling a standard line approval therefore also leaves the restriction in place by design.
- **Verified** GJ batch approval has no amount/limit payload in its approval-entry argument (only record id/table id are populated); GJ line approval populates document type/no., salesperson/purchaser code, amount, amount (LCY), and currency, and is the only one of the two with meaningful approver-limit/chain logic (`ApprovalsMgmt.Codeunit.al`, `PopulateApprovalEntryArgument` area, and `IsSufficientApprover`).
- **Verified** Recurring journal page 283 has **no** send/cancel approval action group in this branch (re-confirmed this pass: a search for `Request Approval`, `TrySendJournal`, `SetApprovalState`, `WorkflowManagement` in `RecurringGeneralJournal.Page.al` returned no matches).

### 2.5 Restrictions

- **Verified** `Record Restriction Mgt.` (codeunit 1550) is the single enforcement point for "is this record currently unusable because of a pending/required approval." It persists rows in table 1550 `Restricted Record` keyed by `Record ID`, subscribes to `Gen. Journal Line` insert/modify to auto-restrict lines whose batch or line-level approval workflow is enabled, and exposes `CheckRecordHasUsageRestrictions` as the actual gate, called from posting, check-printing, and payment-export paths.
- **Verified** table 81 publishes three explicit restriction-check integration events consumed by codeunit 1550: post restrictions, print-check restrictions, and export restrictions. Preview posting explicitly skips the restriction check; real posting does not.
- **Risk (verified)** Restriction status is re-evaluated on every insert/modify of a line, but an existing **approved** `Approval Entry` is not proof that current field values are still approved — modifying an already-approved line re-imposes the restriction (evidenced by BC test behavior in `GeneralJournalLineApproval.Codeunit.al`).

### 2.6 Audit trail

- **Verified** At posting time, `Approvals Mgmt.` subscribes to `OnMoveGenJournalLine`/`OnMoveGenJournalBatch` events and transfers approval history from `Approval Entry` to `Posted Approval Entry`, copying record links and comments, before the source approval entries are deleted as part of source-line cleanup.
- **Inference** The audit design separates "live, enforceable approval state" (`Approval Entry` + `Restricted Record`) from "historical, read-only approval record" (`Posted Approval Entry`), and the transfer only happens at the moment of successful real posting — never during preview.

## 3. Key object/member catalogue (accessibility-checked)

Accessibility values below were re-checked in this pass by inspecting procedure declarations directly (not merely reused from prior artifacts). "Public" means the procedure has no `local`/`internal` modifier and is declared on a public object; it is still BC-internal to this application family and **not callable from Jenworks** — the accessibility column tells a *future BC extension author* what they could call, and tells Jenworks what shape of API it should design an equivalent for.

| Object | Type/ID | Key members re-verified | Accessibility | Reuse classification |
|---|---|---|---|---|
| Gen. Journal Template | table 80 | `Type` OnValidate (source/page/report mapping); `No. Series`/`Posting No. Series` OnValidate (mutual exclusion rules) | Public table; field triggers are implementation detail | Pattern: policy/type selection tier |
| Gen. Journal Batch | table 232 | `SetupNewBatch`; `OnDelete`/`OnModify` approval guards; `CheckBalance`; published `OnGeneralJournalBatchBalanced`/`OnGeneralJournalBatchNotBalanced` | Public table; publishes integration events | Pattern: working-context tier + published event |
| Gen. Journal Line | table 81 | `OnInsert`/`OnModify`/`OnDelete` guards; `SetUpNewLine`; `GetNewLineNo`; published `OnCheckGenJournalLinePostRestrictions`/`...PrintCheckRestrictions`/`...ExportRestrictions`; local `RestrictGenJournalLine` | Public table; most logic local/internal; three restriction events are the real public extension surface | Pattern: transaction-fact tier + published restriction events |
| Gen. Jnl.-Check Line | codeunit 11 | `RunCheck` | Public codeunit; internals mostly local | Pattern: centralized pre-post validation |
| Check Gen. Jnl. Line. Backgr. | codeunit 9081 | `OnRun` → `RunCheck` | Public codeunit | Pattern: non-authoritative UX validation layer |
| Gen. Jnl.-Post | codeunit 231 | `OnRun`; `Code(...)`; `OnBeforeGenJnlPostBatchRun` (local event, `IsHandled`); `Preview(...)` | Public entrypoint; `OnBeforeGenJnlPostBatchRun` is a **posting-replacement boundary**, treat as high risk | Pattern: orchestration layer with a full-replace extension point |
| Gen. Jnl.-Post Batch | codeunit 13 | `OnRun`/`ProcessLines`; `CheckDocumentNo`; `CheckGenJnlLine`; `PostGenJournalLine`; restriction check gated on `not PreviewMode` | Public codeunit; internals mostly local; many integration events | Pattern: batch engine — checks, balance, register, cleanup, commit |
| Gen. Jnl.-Post Line | codeunit 12 | Account-type branch dispatch; entry insertion by account type | Public codeunit; account routines local | Pattern: account-specific posting dispatch |
| Approval Entry | table 454 | `Status` OnValidate; FlowFields `Pending Approvals`, `Number of Approved/Rejected Requests` | Public framework table | Framework: generic approval persistence |
| Approvals Mgmt. | codeunit 1535 | `TrySendJournalBatchApprovalRequest`; `TrySendJournalLineApprovalRequests`; `TryCancelJournalBatchApprovalRequest`; `TryCancelJournalLineApprovalRequests`; `SendJournalLinesApprovalRequests`; `HasOpenApprovalEntries`/`HasOpenOrPendingApprovalEntries`; `PreventDeletingRecordWithOpenApprovalEntry`; `CreateApprovalRequests`; `MakeApprovalEntry`; `IsSufficientApprover` — all re-confirmed public (no `local`) | Public framework API called from pages/tables | Framework: approval request lifecycle API |
| Workflow Event Handling | codeunit 1520 | Registers GJ batch/line send/cancel event codes; subscribes to `Approvals Mgmt.` send/cancel events and batch balance events | Public framework | Framework: event registration/routing |
| Workflow Response Handling | codeunit 1521 | `RestrictRecordUsageCode`/`AllowRecordUsageCode`/`CreateApprovalRequestsCode`/`SendApprovalRequestForApprovalCode`/`CheckGeneralJournalBatchBalanceCode`; execution procedures | Public framework; execution internals local | Framework: response execution |
| Workflow Setup | codeunit 1502 | `InsertGeneralJournalBatchApprovalWorkflowTemplate`; `InsertGeneralJournalLineApprovalWorkflowTemplate`; `InsertGenJnlBatchApprovalWorkflowSteps`; `InsertRecApprovalWorkflowSteps` (with `RemoveRestrictionOnCancel` parameter) | Public setup framework; step-graph builders mostly local/`local procedure` | Framework: standard template construction |
| Record Restriction Mgt. | codeunit 1550 | `RestrictRecordUsage`; `AllowGenJournalBatchUsage`; `CheckRecordHasUsageRestrictions` (all re-confirmed public); `RestrictGenJournalLine`/`CheckGenJournalBatchHasUsageRestrictions`/etc. re-confirmed **local** | Public entry points; most subscriber/helper logic is `local procedure` | Framework: restriction enforcement gate |
| Restricted Record | table 1550 | Restriction persistence by `Record ID` | Public framework table | Framework: restriction state storage |
| Workflow Webhook Setup/Management/Responses/Events/Notification | codeunits 1540/1543/1542/1541/1545 | Webhook workflow definition construction; `CanCancel`/`CanRequestApproval`; continue/reject/cancel handlers; HTTP payload send | Public framework | Framework: alternate (webhook) approval path — parallel, not interchangeable with `Approval Entry` |
| Item Journal Batch / Item Journal / Requisition Wksh. Name | table 233 / page 40 / table 245 | `SetApprovalStateForBatch` (local helper on each page/table) | Public table/page with `local` helper procedure | Pattern cross-check only — confirms batch-approval pattern generalizes across worksheet families |

## 4. Source-backed reusable architecture rules

Each rule states the BC evidence and then the Jenworks-actionable restatement.

1. **Three-tier mutable source model.** Template (type/policy) → Batch (working context + inherited defaults) → Line (transaction facts) is used consistently for General Journal and its first-party analogues (Item Journal, Requisition Worksheet). *Jenworks action*: if Jenworks has a worksheet-style entity, split policy selection, working-context defaults, and per-transaction facts into three record levels rather than one flat record.
2. **Validation has authority tiers, not one gate.** Field triggers (always-on), background/UX check (advisory only, callable independently), and pre-post check (authoritative, runs inside the transaction that commits). *Jenworks action*: do not treat a "check" or "validate" button as sufficient enforcement; the only trustworthy gate is the one that runs synchronously inside the committing operation.
3. **Approvals are a framework boundary layered on top of the record, not baked into it.** GJ has no bespoke approval table; it reuses `Approval Entry` + Workflow + a restriction table. *Jenworks action*: keep "is approval required," "is approval granted," and "is this record currently restricted from use" as three separate, explicitly-checked states, not one combined flag.
4. **Restriction state, not approval-entry status, is the actual enforcement mechanism.** Posting/printing/export code calls `CheckRecordHasUsageRestrictions` — it does not inspect `Approval Entry` directly. *Jenworks action*: gate risky operations (post/export/print-equivalent) on a dedicated restriction check, and re-evaluate/re-impose that restriction whenever the underlying record changes after approval.
5. **Cancellation does not imply "usable again" unless a workflow step explicitly allows it.** Both the standard batch and line templates omit `AllowRecordUsage` from their cancel branches. *Jenworks action*: if Jenworks builds a cancel path, decide explicitly whether cancellation should lift restrictions, and do not assume "canceled" implies "unrestricted" by default — BC's own default templates do not make that assumption.
6. **Approval payloads should carry the data needed for approver-limit decisions.** Batch-level approval in BC carries no amount, and as a result BC's own chain/first-qualified approver logic is effectively unsupported for batches (self-approves) versus fully supported for lines (real amount-based chains). *Jenworks action*: if approver limits matter, put the amount/limit-relevant fields on the entity actually being approved, at the same granularity the approval is requested for.
7. **Posting/commit boundaries are explicit and multiple, not a single atomic wrapper.** Codeunit 13 has distinct commit points around number-series state, register updates, and analysis-view updates. *Jenworks action*: document each commit boundary in a multi-step transactional process explicitly; do not assume "posting" is one atomic unit an extension can safely intercept without reproducing every boundary.
8. **Preview must be a true no-side-effect simulation, and must be tagged for every check that has side effects.** BC's restriction check code has to special-case `PreviewMode` explicitly to skip creating/consuming state. *Jenworks action*: if Jenworks adds a preview/simulate mode, every side-effecting check (not just the ledger write) needs an explicit preview bypass, not just the final commit.
9. **Audit history is a copy, made once, at the moment of the operation's success — not a live view of the working table.** `Posted Approval Entry` is populated only during the move-to-posted event, and source approval entries are deleted afterward. *Jenworks action*: keep a separate, append-only historical table populated exactly once at the success boundary, and do not rely on the live working table remaining unchanged for audit purposes.

## 5. Public integration points and limitations

- **Verified public extension points (BC side)**: table 81 restriction events (`OnCheckGenJournalLinePostRestrictions`, `...PrintCheckRestrictions`, `...ExportRestrictions`); table 232 balance events (`OnGeneralJournalBatchBalanced`/`NotBalanced`); codeunit 231's `OnBeforeGenJnlPostBatchRun`/`OnBeforeShowPostResultMessage`/`OnCodeOnBeforeConfirmPostJournalLinesResponse`; `Approvals Mgmt.` published send/cancel events (`OnSendGeneralJournalBatchForApproval`, etc.).
- **Limitation**: none of these are usable by Jenworks directly — they are BC AL event publishers on BC objects. Their value here is purely as a **design catalogue** of *where* a mature approval/posting system exposes extension seams: pre-check, balance-gate, restriction-gate, pre-run-replacement, and post-result-suppression.
- **Limitation**: several of the most consequential behaviors (batch cancel not restoring usage, line workflow's `RemoveRestrictionOnCancel = false`, batch approval having no amount payload) are **default-template choices**, not framework limitations — BC itself allows different behavior via different workflow step construction. Do not treat these as fixed constraints; treat them as the specific default BC ships, which Jenworks may choose to follow or deliberately diverge from.
- **Limitation**: the webhook approval stack and the standard `Approval Entry` stack are both "public framework" but are **not interoperable** — a record restricted via one path is not automatically visible to code that only understands the other's status model. If Jenworks builds a single approval feature, it should not replicate this split unless it has a specific need for both a synchronous internal approval flow and an asynchronous external (e.g., webhook/Teams/email) approval flow.

## 6. Approval implementation checklist (for Jenworks' own approval feature)

Use this checklist when Jenworks designs an equivalent "requires approval before risky operation" feature, based on verified BC behavior:

1. [ ] Separate the "approval requested/pending/approved/rejected" status from the "is currently restricted from use" state. Do not merge them into a single boolean.
2. [ ] Gate every risky operation (not just the primary one) — e.g., BC gates post, check-print, and payment-export separately, each with its own restriction-check event.
3. [ ] Make restriction re-evaluation automatic on insert/modify of the record being protected, not only at explicit send-for-approval time.
4. [ ] Decide explicitly, per cancel/reject branch, whether restriction is lifted. Do not assume a default; BC's own defaults leave restrictions in place after cancel.
5. [ ] If approving at a coarse granularity (e.g., a batch/group) but line items carry amounts, decide whether the approval payload needs the aggregate amount, and add an explicit balance/aggregate check before allowing an approval request — BC does this for batches (balance check) but not with amount-based approver limits.
6. [ ] If approving at a fine granularity (line/item), carry amount/limit-relevant fields into the approval request payload so chain/limit-based approver selection is meaningful.
7. [ ] Make preview/simulate modes skip every side-effecting check explicitly; do not assume skipping the final write is sufficient.
8. [ ] Copy to an audit/history record exactly once, at the success boundary of the risky operation, and do so before/alongside cleanup of the live approval state.
9. [ ] If supporting more than one approval channel (e.g., in-app plus an external/webhook channel), keep their state models explicitly separate and document that a restriction/approval in one channel is not automatically known to the other, unless you deliberately unify them.
10. [ ] Treat "an approval entry is Approved" as necessary but not sufficient proof of current validity — always re-check restriction state at the moment of the risky operation, not just at approval time.

## 7. Capability decision matrix

| Capability | Decision | Rationale |
|---|---|---|
| Three-tier template/batch/line-equivalent record split | **Must** | Directly supports defaulting, reuse across variants, and clean ownership boundaries (§4.1). Required if Jenworks has any worksheet-like, multi-line entity with shared batch context. |
| Separate restriction-state table/flag distinct from approval-status field | **Must** | This is the actual enforcement mechanism in BC, not the approval status (§4.4). Skipping this collapses "requested" and "enforced" into one unreliable flag. |
| Multiple independent authoritative gates per risky operation (post/print/export-equivalent) | **Must** | BC enforces restrictions separately for post, print, and export; a single shared gate would miss export-only or print-only scenarios (§4.4, §6.2). |
| Pre-post/pre-commit authoritative validation distinct from advisory background validation | **Must** | Prevents advisory-only checks from being mistaken for enforcement (§4.2). |
| Explicit per-branch decision on whether cancel/reject lifts restriction | **Must** | BC's own default is "no" for both batch and line; an unconsidered default risks user confusion either way (§4.5, §6.4). |
| Re-evaluating/re-imposing restriction on modify of an already-approved record | **Should** | Prevents stale-approval bypass; BC does this via insert/modify subscribers (§2.5 risk note). |
| Amount/limit-aware approval payload at whatever granularity approval is requested | **Should** | Needed for meaningful approver-limit/chain logic; BC's own batch-level approval is weaker for lacking this (§4.6). |
| Explicit, multiple commit/transaction boundaries documented for any multi-step "post"-like operation | **Should** | Supports safe partial extension without corrupting state (§4.7). |
| Preview/simulate mode with explicit bypass on every side-effecting check | **Should**, if Jenworks has a preview feature | Only needed if a non-committing simulation mode exists; otherwise not applicable. |
| Append-only audit/history record populated once at success boundary | **Should** | Matches BC's `Posted Approval Entry` pattern; needed if Jenworks requires an audit trail independent of the live working record. |
| Dual approval channels (synchronous in-app + asynchronous external/webhook) with separate state models | **Domain-dependent** | Only justified if Jenworks genuinely needs an external-system approval channel in addition to in-app approval; otherwise adds real complexity (parallel status models) for no benefit. |
| Approver chain / first-qualified-approver traversal logic | **Optional** | Useful if Jenworks needs multi-level approver escalation; BC's own implementation is inconsistent (works for lines, effectively self-approves for batches) so copy the concept, not the exact algorithm. |
| Copying BC's exact object IDs, table/field names, or workflow step-graph builder API shape | **Do-not-copy** | These are BC-specific implementation identifiers with no meaning outside BC; only the structural patterns above are transferable. |
| Relying on an existing "Approved" approval-entry as sufficient proof of current validity without a live restriction re-check | **Do-not-copy** | Explicitly identified as a risk in the source system itself (§2.5, §6.10); do not carry this weakness into Jenworks. |
| Treating page/UI action-enabled state as an enforcement boundary | **Do-not-copy** | BC's own pages only reflect state; enforcement is table/codeunit-level. Any UI-only gate in Jenworks would be bypassable by APIs/imports/background jobs, exactly as flagged as a risk in the source material. |

## 8. Questions the Jenworks analysis must answer

- What is Jenworks' equivalent of "batch" — is there a natural grouping level above the individual approved/restricted entity, and if so, does group-level approval need an aggregate check analogous to BC's batch-balance gate?
- Does Jenworks need more than one approval channel (in-app vs. external/webhook-style), or is a single synchronous approval model sufficient? (Determines whether §7's "dual approval channels" row applies.)
- At what granularity should amount/limit-aware approver selection operate in Jenworks — the group level, the item level, or both? BC's inconsistency between batch and line approval should inform this rather than be copied.
- Does Jenworks have a genuine need for a preview/simulate mode for its risky operation, or is that BC-specific to a heavyweight, hard-to-reverse posting process?
- What should "cancel" mean for Jenworks specifically — should it default to restoring usability (diverging from BC's default) or leaving it restricted (matching BC's default)? This must be a deliberate product decision, not an accidental inheritance from this reference.
- Does Jenworks need a distinct historical/audit record type, or can its existing history/logging mechanism absorb the "copy once at success" pattern without a dedicated table?
- Which of Jenworks' operations are structurally analogous to BC's post/print/export triad (i.e., multiple distinct risky operations against the same restricted entity), and does each need its own restriction-check gate?

## 9. Source-reference appendix

All references below are to `Base Application/` unless otherwise noted, at commit `fc4c58aef01063370e19823eb0aec4e891b626ea` on branch `gb-29-vNext`. Line numbers are approximate anchors re-verified during this pass or inherited from `gj-01`/`gj-02`/`gj-03`; re-check exact numbers before quoting in a compiled-code context, since this repository is an extracted source snapshot.

| Area | Path | Object |
|---|---|---|
| Template | `Finance/GeneralLedger/Journal/GenJournalTemplate.Table.al` | table 80 Gen. Journal Template |
| Batch | `Finance/GeneralLedger/Journal/GenJournalBatch.Table.al` | table 232 Gen. Journal Batch |
| Line | `Finance/GeneralLedger/Journal/GenJournalLine.Table.al` | table 81 Gen. Journal Line |
| Worksheet UI | `Finance/GeneralLedger/Journal/GeneralJournal.Page.al` | page 39 General Journal |
| Worksheet variants | `Finance/GeneralLedger/Journal/{SalesJournal,PurchaseJournal,CashReceiptJournal,PaymentJournal}.Page.al` | pages 253/254/255/256 |
| Recurring worksheet | `Finance/GeneralLedger/Journal/RecurringGeneralJournal.Page.al` | page 283 Recurring General Journal (re-confirmed no approval actions this pass) |
| IC worksheet | `Finance/Intercompany/Journal/ICGeneralJournal.Page.al` | IC General Journal |
| Validation | `Finance/GeneralLedger/Journal/GenJnlCheckLine.Codeunit.al` | codeunit 11 Gen. Jnl.-Check Line |
| Background validation | `Finance/GeneralLedger/Journal/CheckGenJnlLineBackgr.Codeunit.al` | codeunit 9081 |
| Posting orchestration | `Finance/GeneralLedger/Posting/GenJnlPost.Codeunit.al` | codeunit 231 Gen. Jnl.-Post (`OnBeforeGenJnlPostBatchRun` re-confirmed line ~205 this pass) |
| Batch posting engine | `Finance/GeneralLedger/Posting/GenJnlPostBatch.Codeunit.al` | codeunit 13 Gen. Jnl.-Post Batch |
| Account posting | `Finance/GeneralLedger/Posting/GenJnlPostLine.Codeunit.al` | codeunit 12 Gen. Jnl.-Post Line |
| Preview | `Finance/GeneralLedger/Preview/GenJnlPostPreview.Codeunit.al` | codeunit 19 Gen. Jnl.-Post Preview |
| Approval persistence | `OtherCapabilities/Approvals/ApprovalEntry.Table.al` | table 454 Approval Entry |
| Approval API | `OtherCapabilities/Approvals/ApprovalsMgmt.Codeunit.al` | codeunit 1535 (all cited procedures re-confirmed public this pass) |
| Workflow event routing | `System/Workflow/WorkflowEventHandling.Codeunit.al` | codeunit 1520 |
| Workflow responses | `System/Workflow/WorkflowResponseHandling.Codeunit.al` | codeunit 1521 |
| Workflow templates | `System/Workflow/WorkflowSetup.Codeunit.al` | codeunit 1502 (`InsertGenJnlBatchApprovalWorkflowSteps` cancel branch and `InsertGeneralJournalLineApprovalWorkflowDetails` `(false, false)` args re-confirmed this pass around lines 1754-1833 and 1273-1306) |
| Restriction enforcement | `System/Workflow/RecordRestrictionMgt.Codeunit.al` | codeunit 1550 (public vs. local procedures re-confirmed this pass) |
| Restriction storage | `System/Workflow/RestrictedRecord.Table.al` (referenced as table 1550 in prior artifacts) | table 1550 Restricted Record |
| Webhook stack | `System/Workflow/WorkflowWebhook{Setup,Events,Responses,Management,Notification}.Codeunit.al`, `WorkflowWebhook{Entry,Notification,Subscription}.Table.al` | codeunits 1540-1545, tables 467-469 |
| Item Journal analogue | `Inventory/Journal/ItemJournalBatch.Table.al`, `Inventory/Journal/ItemJournal.Page.al` | table 233, page 40 |
| Requisition analogue | `Inventory/Requisition/RequisitionWkshName.Table.al` | table 245 |
| Tests (behavioral evidence only) | `Tests-General Journal/{GeneralJournalBatchApproval,GeneralJournalLineApproval,WFWHGeneralJournalBatch,WFWHGeneralJournalLine}.Codeunit.al` | codeunits 134321/134322/134219/134220 |

## 10. Provenance note

This artifact was produced by re-reading source at the commit above (branch/commit re-confirmed via `git rev-parse`), re-checking the following specific claims that were flagged as consequential or previously unverified against exact source text: page 283's absence of approval actions, the standard batch-approval cancel branch's omission of `AllowRecordUsage`, the standard line-approval template's `RemoveRestrictionOnCancel = false` argument, the existence and `IsHandled` shape of `OnBeforeGenJnlPostBatchRun`, and the public/local accessibility of the key `Approvals Mgmt.` and `Record Restriction Mgt.` procedures listed in §3. All other statements are carried forward from `gj-01-discovery.md`, `gj-02-architecture.md`, and `gj-03-approvals.md`, which contain the full line-level citation detail if deeper verification is needed in this source repository.
