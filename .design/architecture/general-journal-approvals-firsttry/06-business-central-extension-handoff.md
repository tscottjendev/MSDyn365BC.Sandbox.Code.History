# General Journal Approvals — Session 5: Business Central extension handoff

Purpose: hand the verified General Journal approval architecture to a **different Business Central AL extension** that will build an approval capability for its own domain, using standard public objects, published events, accessible enums and supported registration mechanisms available in its own symbol set.

Companions:

- [01-object-and-accessibility-inventory.md](01-object-and-accessibility-inventory.md) — full object and member inventory.
- [07-standard-symbol-evidence-index.md](07-standard-symbol-evidence-index.md) — evidence index.
- [08-unresolved-and-version-sensitive-findings.md](08-unresolved-and-version-sensitive-findings.md) — unresolved and version-sensitive findings, including contradictions with earlier sessions.

Prior-session inputs treated as authoritative context: `00`, `02`, `03`, `04`, `05`. Source was consulted in this session only to resolve accessibility and object-identity questions.

Legend: **F** = fact readable in the inspected source. **I** = interpretation. **?** = unresolved.

---

## 1. Analysed environment and version scope

| Item | Value |
| --- | --- |
| Branch | `gb-29-vNext` |
| Commit | `a74fec3ec909d` |
| Application snapshot | `29.0.53247.0` |
| Platform version in manifests | `29.0.0.0` |
| Localization | GB |
| Apps present as source | Base Application, System Application, Application, Business Foundation, Tests-General Journal, Tests-Workflow, test libraries |
| Dependency chain | Base Application → System Application + Business Foundation |

**Scope boundary.** Everything below is evidence from this snapshot. It is **not** a cross-version guarantee. The receiving extension compiles against its own symbols and must revalidate every symbol in §18 before use — see §15 and §16.5.

**Not analysed to conclusion in sessions 1–5:** the webhook / Power Automate path (`Codeunit 1540`, `Codeunit 1543`, `Table 467`), `Workflow Request Page Handling`, and `InsertJobQueueData`. Treat webhook approval as out of the verified surface.

---

## 2. Standard component inventory by object type

Full table in [01 §2](01-object-and-accessibility-inventory.md#2-standard-component-inventory-by-object-type). Condensed:

| Object type | Objects relevant to a target approval design |
| --- | --- |
| Codeunit — generic workflow engine | `1501 "Workflow Management"`, `1502 "Workflow Setup"`, `1520 "Workflow Event Handling"`, `1521 "Workflow Response Handling"` |
| Codeunit — approvals | `1535 "Approvals Mgmt."`, `1536 "Approvals Journal Line Request"` |
| Codeunit — restriction | `1550 "Record Restriction Mgt."` |
| Codeunit — General Journal posting | `13 "Gen. Jnl.-Post Batch"` (guard), `12 "Gen. Jnl.-Post Line"`, `231`, `232`, `233`, `234`, `250`, `11 "Gen. Jnl.-Check Line"` |
| Codeunit — registration trigger | `2 "Company-Initialize"` |
| Codeunit — legacy / restricted | `1804 "Approval Workflow Setup Mgt."` (all inspected procedures `[Scope('OnPrem')]`) |
| Codeunit — webhook (unverified) | `1540 "Workflow Webhook Setup"`, `1543 "Workflow Webhook Management"` |
| Table — approval state | `454 "Approval Entry"`, `455 "Approval Comment Line"`, `456 "Posted Approval Entry"`, `457 "Posted Approval Comment Line"` |
| Table — workflow library | `1501 Workflow`, `1502 "Workflow Step"`, `1504 "Workflow Step Instance"`, `1505 "Workflow - Table Relation"`, `1508 "Workflow Category"`, `1509 "WF Event/Response Combination"`, `1520 "Workflow Event"`, `1521 "Workflow Response"`, `1523 "Workflow Step Argument"` |
| Table — enforcement / notification | `1550 "Restricted Record"`, `1511 "Notification Entry"`, `91 "User Setup"` |
| Table — General Journal subjects | `232 "Gen. Journal Batch"`, `81 "Gen. Journal Line"` |
| Page | `39 "General Journal"`, `251 "General Journal Batches"` |
| Enum | `460 "Workflow Approver Type"` (`Extensible = true`), `465 "Workflow Approver Limit Type"` (`Extensible = true`), `"Approval Status"` |

---

## 3. Member-level accessibility classification

Full classification in [01 §3](01-object-and-accessibility-inventory.md#3-member-level-accessibility-classification). Decision-relevant summary:

| Classification | What the target may do | Representative members |
| --- | --- | --- |
| **Public supported dependency** | Call directly | `Workflow Setup.InitWorkflow`, `InsertWorkflowTemplate`, `InsertEntryPointEventStep`, `InsertEventStep`, `InsertResponseStep`, `SetNextStep`, `InsertApprovalArgument`, `InsertNotificationArgument`, `InsertTableRelation`, `InsertWorkflowCategory`, `MarkWorkflowAsTemplate`, `GetWorkflowTemplateCode`, `BuildNoPendingApprovalsConditions`, `BuildPendingApprovalsConditions`, `InsertRecApprovalWorkflowSteps`; `Workflow Event Handling.AddEventToLibrary`, `AddEventPredecessor`, `RunWorkflowOnApprove/Reject/DelegateApprovalRequestCode`; `Workflow Response Handling.AddResponseToLibrary`, `AddResponsePredecessor`, `CreateApprovalRequestsCode`, `SendApprovalRequestForApprovalCode`, `RestrictRecordUsageCode`, `AllowRecordUsageCode`, `RejectAllApprovalRequestsCode`, `CancelAllApprovalRequestsCode`, `ShowMessageCode`, `OpenDocumentCode`; `Workflow Management.HandleEvent`, `HandleEventOnKnownWorkflowInstance`, `CanExecuteWorkflow`, `EnabledWorkflowExist`; `Approvals Mgmt.CreateApprovalRequests`, `MakeApprovalEntry`, `PopulateApprovalEntryArgument`, `SendApprovalRequestFromRecord`, `SendApprovalRequestFromApprovalEntry`, `CreateApprovalEntryNotification`, `GetLastSequenceNo`, `HasOpenApprovalEntries`, `HasOpenApprovalEntriesForCurrentUser`, `HasApprovedApprovalEntries`, `CanCancelApprovalForRecord`, `FindOpenApprovalEntryForCurrUser`, `PreventModifyRecIfOpenApprovalEntryExistForCurrentUser`, `PreventInsertRecIfOpenApprovalEntryExist`, `PreventDeletingRecordWithOpenApprovalEntry`, `RenameApprovalEntries`, `DeleteApprovalEntries`, `PostApprovalEntries`, `GetApprovalComment`, `IsSufficientApprover`; `Record Restriction Mgt.RestrictRecordUsage`, `AllowRecordUsage`, `UpdateRestriction`, `CheckRecordHasUsageRestrictions` |
| **Published extension point** | Subscribe (and, where non-`local`, optionally call) | `Workflow Event Handling.OnAddWorkflowEventsToLibrary`, `OnAddWorkflowEventPredecessorsToLibrary`; `Workflow Response Handling.OnAddWorkflowResponsesToLibrary`, `OnAddWorkflowResponsePredecessorsToLibrary`, `OnExecuteWorkflowResponse`; `Workflow Setup.OnAddWorkflowCategoriesToLibrary`, `OnAfterInsertApprovalsTableRelations`, `OnAfterInitWorkflowTemplates`; `Approvals Mgmt.OnApproveApprovalRequest`, `OnRejectApprovalRequest`, `OnDelegateApprovalRequest`; `Record Restriction Mgt.OnBefore…Restrictions(var IsHandled)` |
| **Accessible data contract** | Read, filter, extend | `Approval Entry` fields/keys, `Restricted Record`, `Workflow Step Argument`, `Workflow Step Instance`, `Enum 460`, `Enum 465` |
| **Observable but inaccessible implementation** | Learn from only | `Workflow Setup.BuildGeneralJournalBatchTypeConditions` (`local`), `ResetWorkflowTemplates` (`internal`), all `Workflow Response Handling` response bodies (`local`), `Approvals Mgmt.GetGeneralJournalBatch`/`ApproveSelectedApprovalRequest`/`RejectSelectedApprovalRequest`/`SubstituteUserIdForApprovalEntry`/`GetApprovalStatusFromApprovalEntry` (`local`), `Record Restriction Mgt.RestrictGenJournalLine` (`local`), Page 39 approval variables |
| **General Journal-specific implementation** | Reproduce the pattern, do not call for another domain | `Approvals Mgmt.TrySend/TryCancel/Approve/Reject/DelegateGenJournalLineRequest`, `SendJournalLinesApprovalRequests`, `HasAnyOpenJournalLineApprovalEntries`, `Get/CleanGenJnl*ApprovalStatus`, `IsGeneralJournal*ApprovalsWorkflowEnabled`, `CheckGeneralJournal*ApprovalsWorkflowEnabled`; `Workflow Setup.GeneralJournal*ApprovalWorkflowCode`, `InsertGenJnlBatch/LineApprovalWorkflowSteps`, `BuildGeneralJournalLineTypeConditions`; `Workflow Response Handling.CheckGeneralJournalBatchBalanceCode`; `Record Restriction Mgt.AllowGenJournalBatchUsage`; `Codeunit 1536` |
| **Version-sensitive or uncertain** | Revalidate before depending on | `Gen. Journal Line.OnCheckGenJournalLinePostRestrictions` and `OnCheckGenJournalLinePrintCheckRestrictions` (both `[Scope('OnPrem')]`), `Gen. Journal Batch.OnMoveGenJournalBatch` (`[Scope('OnPrem')]`), all of `Codeunit 1543 "Workflow Webhook Management"`, `Codeunit 1540`, `Codeunit 1804`, template codes `MS-GJBAPW`/`MS-GJLAPW`, category `FIN`, response option groups `GROUP 0/2/4/5`, `Approval Status` ordinals |

---

## 4. Exact General Journal approval subject and `RecordId` mapping

General Journal approval is **hybrid**: two independent subjects, two templates, both simultaneously enableable. **F**

| | Batch approval | Line approval |
| --- | --- | --- |
| Subject table | `Gen. Journal Batch` | `Gen. Journal Line` |
| Table ID | **232** | **81** |
| Primary key | `Journal Template Name`, `Name` | `Journal Template Name`, `Journal Batch Name`, `Line No.` |
| `Approval Entry."Record ID to Approve"` | `Gen. Journal Batch: <Journal Template Name>, <Name>` | `Gen. Journal Line: <Journal Template Name>, <Journal Batch Name>, <Line No.>` |
| `Approval Entry."Table ID"` | 232 | 81 |
| Template code | `MS-GJBAPW` (`GJBAPW`) | `MS-GJLAPW` (`GJLAPW`) |
| Entry-point event | `RUNWORKFLOWONSENDGENERALJOURNALBATCHFORAPPROVAL` | `RUNWORKFLOWONSENDGENERALJOURNALLINEFORAPPROVAL` |
| Granularity | one request per batch | one request per line |
| Approver-limit chain | **unsupported** (`ApporvalChainIsUnsupportedMsg`, `IsSufficientApprover` returns `true`) | supported (purchase / sales / G-L-account limits) |
| Amount / document data on the entry | none — the batch case arm of `PopulateApprovalEntryArgument` only does `RecRef.SetTable(GenJournalBatch)` | `Document Type`, `Document No.`, `Amount`, `Amount (LCY)`, `Currency Code`, `Salespers./Purch. Code` |
| Balance pre-check | yes (`CheckGeneralJournalBatchBalance`) | no |
| Confirmation message on send | yes (`Show Confirmation Message = true`) | no |

**F** — Both subjects are registered in `Workflow Setup.InsertApprovalsTableRelations` as `(table, 0) → ("Approval Entry", "Record ID to Approve")`.

**F** — `Gen. Journal Template` is never an approval subject. There is **no header record and no persisted approval status field** on either subject table; Page 39's `GenJnlBatchApprovalStatus` / `GenJnlLineApprovalStatus` are page variables computed on the fly.

**I** — the batch subject is a *container* subject, not a document header. It carries no amount, so amount-based approval policy is line-only in standard General Journal.

**RecordId stability (F/I):** `Gen. Journal Line` RecordId is unstable across the journal lifecycle — rename (`Line No.` change), delete, and posting all move or destroy it. Three separate compensating mechanisms exist: `Approvals Mgmt.RenameApprovalEntries` + `Record Restriction Mgt.UpdateGenJournalLineRestrictionsAfterRename` on rename; `DeleteApprovalEntriesAfterDeleteGenJournalLine` on delete; `PostApprovalEntries` via the `OnMove…` events on posting.

---

## 5. Workflow registration contracts

### 5.1 When registration runs (F)

| Trigger | Call |
| --- | --- |
| `Codeunit 2 "Company-Initialize".OnRun` | `Workflow Setup.InitWorkflow()` (once per company) |
| `Page "Workflows".OnOpenPage`, `Page "Workflow Templates".OnOpenPage` | `Workflow Setup.InitWorkflow()` (every open) |

`InitWorkflow` order: `CreateEventsLibrary` → request-page entities → `CreateResponsesLibrary` → `InsertWorkflowCategories` → `InsertJobQueueData` → template insertion (only when no `MS-`-prefixed template workflow exists) → `OnAfterInitWorkflowTemplates`. Every `Add…ToLibrary` does a `Get`/existence check, so the whole call is idempotent.

**I** — a target extension therefore does **not** need its own install/upgrade codeunit merely to make its events/responses appear; subscribing to the library-population events is sufficient, because `InitWorkflow` is re-asserted whenever a user opens the Workflows page. A target that also wants a *template workflow* must accept that templates are only created when the template set is empty, so an install/upgrade codeunit calling its own template-insert routine is the reliable option.

### 5.2 Registration contracts a target extension uses

| Contract | Mechanism | Category |
| --- | --- | --- |
| Add workflow events | Subscribe to `Codeunit 1520.OnAddWorkflowEventsToLibrary`, call `AddEventToLibrary(FunctionName; TableID; Description; RequestPageID; UsedForRecordChange)` | Published extension point + Public supported dependency |
| Declare event predecessors | Subscribe to `Codeunit 1520.OnAddWorkflowEventPredecessorsToLibrary(EventFunctionName)`, call `AddEventPredecessor(FunctionName; PredecessorFunctionName)` | Published extension point + Public supported dependency |
| Add workflow responses | Subscribe to `Codeunit 1521.OnAddWorkflowResponsesToLibrary`, call `AddResponseToLibrary(FunctionName; TableID; Description; ResponseOptionGroup)` | Published extension point + Public supported dependency |
| Declare response predecessors | Subscribe to `Codeunit 1521.OnAddWorkflowResponsePredecessorsToLibrary(ResponseFunctionName)`, call `AddResponsePredecessor(...)` | Published extension point + Public supported dependency |
| Implement a custom response | Subscribe to `Codeunit 1521.OnExecuteWorkflowResponse(var ResponseExecuted; var Variant; xVariant; ResponseWorkflowStepInstance)`; match on the response function name, do the work, set `ResponseExecuted := true` | Published extension point |
| Add a workflow category | Subscribe to `Codeunit 1502.OnAddWorkflowCategoriesToLibrary`, call `InsertWorkflowCategory(Code; Description)` | Published extension point + Public supported dependency |
| Register a subject-table → `Approval Entry` relation | Subscribe to `Codeunit 1502.OnAfterInsertApprovalsTableRelations`, call `InsertTableRelation(TableId; 0; Database::"Approval Entry"; <field no. of "Record ID to Approve">)` | Published extension point + Public supported dependency |
| Insert a template workflow | `InsertWorkflowTemplate(var Workflow; WorkflowCode: Code[17]; Description: Text[100]; CategoryCode: Code[20])` then `MarkWorkflowAsTemplate(var Workflow)`; optionally hook `OnAfterInitWorkflowTemplates` | Public supported dependency |
| Build the step chain | `InsertEntryPointEventStep`, `InsertEventStep`, `InsertResponseStep`, `SetNextStep`, `InsertApprovalArgument`, `InsertNotificationArgument` — or the whole standard approval skeleton in one call via `InsertRecApprovalWorkflowSteps(Workflow; ConditionString; RecSendForApprovalEventCode; RecCreateApprovalRequestsCode; RecSendApprovalRequestForApprovalCode; RecCanceledEventCode; WorkflowStepArgument; ShowConfirmationMessage; RemoveRestrictionOnCancel)` | Public supported dependency |
| Build a condition string | Encode a record view for the subject table. `BuildNoPendingApprovalsConditions()` / `BuildPendingApprovalsConditions()` supply the standard `Approval Entry` conditions for the approve branches | Public supported dependency (version-sensitive) |

**Do not use** `Codeunit 1804 "Approval Workflow Setup Mgt."`. Every inspected public procedure carries `[Scope('OnPrem')]`. **F**

**Do not call** `Workflow Setup.ResetWorkflowTemplates` — `internal`. **F**

### 5.3 The two distinct predecessor mechanisms (do not conflate) (F)

1. **Library legality** — `WF Event/Response Combination` (table 1509), populated by `AddEventPredecessor` / `AddResponsePredecessor`. Controls what the Workflow designer lets a user pick.
2. **Instance chain** — `Workflow Step."Previous Workflow Step ID"` / `"Next Workflow Step ID"`, built by the `Insert…Step` / `SetNextStep` helpers. Controls actual execution order.

A target must populate both: legality so the flow is configurable, chain so a shipped template works.

---

## 6. Runtime workflow invocation contracts

### 6.1 Send

| Step | Contract |
| --- | --- |
| 1 | Domain code validates eligibility and raises a **domain integration event** carrying the subject record (standard equivalent: `Approvals Mgmt.OnSendGeneralJournalBatchForApproval` / `OnSendGeneralJournalLineForApproval`, `[IntegrationEvent(false,false)]`, non-`local`) |
| 2 | An `[EventSubscriber]` forwards it: `WorkflowManagement.HandleEvent(<EventCode>, <SubjectRecord>)` |
| 3 | `Workflow Management` finds the actionable `Workflow Step Instance` and calls `ExecuteResponses`, which dispatches each response through `Workflow Response Handling.ExecuteResponse` |
| 4 | Standard responses run in the template's order: (optional domain pre-check) → `RestrictRecordUsageCode` → `CreateApprovalRequestsCode` → `SendApprovalRequestForApprovalCode` |

**F** — `HandleEvent` exits silently for temporary records and in `Upgrade` execution context.

**F** — `CreateApprovalRequestsCode` calls `Approvals Mgmt.CreateApprovalRequests(RecRef; WorkflowStepInstance)`, which runs `PopulateApprovalEntryArgument` and then dispatches on `Workflow Step Argument."Approver Type"`, ultimately calling `MakeApprovalEntry`.

**F** — `SendApprovalRequestForApprovalCode` promotes the **lowest `Sequence No.` group only** from `Created` to `Open` and creates `Notification Entry` rows.

### 6.2 Approve / Reject / Delegate

**F** — These do **not** use `HandleEvent`. They use `WorkflowManagement.HandleEventOnKnownWorkflowInstance(<EventCode>, ApprovalEntry, ApprovalEntry."Workflow Step Instance ID")`, with the **`Approval Entry` itself as the event record**. The standard event codes are returned by `Workflow Event Handling.RunWorkflowOnApproveApprovalRequestCode()`, `RunWorkflowOnRejectApprovalRequestCode()`, `RunWorkflowOnDelegateApprovalRequestCode()` — these are **domain-neutral and directly reusable**.

**F** — Final-approval detection is a **workflow step condition** on `Approval Entry."Pending Approvals"` (FlowField counting `Created|Open` entries for the same `Record ID to Approve` + `Workflow Step Instance ID`), encoded by `BuildNoPendingApprovalsConditions()` (`= 0`) and `BuildPendingApprovalsConditions()` (`> 0`).

**F** — The intermediate branches (`Pending Approvals > 0`, and the delegate branch) use `SetNextStep` to loop back to the send-request response, keeping the approve/reject/cancel/delegate event steps armed.

### 6.3 Cancel

**F** — Cancel raises a domain event with the **subject record** (not the approval entry): `OnCancelGeneralJournal*ApprovalRequest` → `HandleEvent(cancel code, subject)` → `CancelAllApprovalRequestsCode` → `Approvals Mgmt.CancelApprovalRequestsForRecord`.

**Risk (carried forward)** — requester authorisation for cancel is enforced only by the page action's `Enabled` property (`CanCancelApprovalForRecord`). `TryCancelJournalBatchApprovalRequest` performs no sender check internally. A target must place that check **inside** its cancel procedure, not only in the UI.

### 6.4 Multi-record send (F)

One record → inline. Two or more → `Batch Processing Mgt.BatchProcess(..., Codeunit::"Approvals Journal Line Request", "Error Handling Options"::"Show Error", NoOfSelected, NoOfSkipped)`, one workflow instance per record. Records with existing open entries are skipped. There is **no** multi-record approve action; approve/reject/delegate act on the current record only.

---

## 7. `Approval Entry` integration

`Table 454 "Approval Entry"` is the state store for both subjects. A target extension **must not insert or modify it directly**; the supported writers are `Approvals Mgmt.MakeApprovalEntry` (insert) and the `…ApprovalRequestsForRecord` / `Approve|Reject|DelegateSelectedApprovalRequest` paths (status change).

### 7.1 Fields the target must supply through `Approval Entry` as an *argument record*

`Approvals Mgmt.PopulateApprovalEntryArgument(RecRef; WorkflowStepInstance; var ApprovalEntryArgument)` fills the generic fields for any table:

| Field | Value | Who fills it |
| --- | --- | --- |
| `Table ID` | `RecRef.Number` | generic |
| `Record ID to Approve` | `RecRef.RecordId` | generic |
| `Approval Code` | `WorkflowStepInstance."Workflow Code"` | generic |
| `Workflow Step Instance ID` | `WorkflowStepInstance.ID` — **the correlation key for every later event** | generic |
| `Sender ID`, `Date-Time Sent for Approval`, `Last Date-Time Modified`, `Last Modified By User ID` | `MakeApprovalEntry` | generic |
| `Sequence No.` | `GetLastSequenceNo + 1` per approver | generic |
| `Approver ID`, `Status` (`Created`, or `Approved` when approver = sender) | `MakeApprovalEntry` | generic |
| `Approval Type`, `Limit Type`, `Due Date`, `Delegation Date Formula` | from `Workflow Step Argument` | generic |
| `Document Type`, `Document No.`, `Amount`, `Amount (LCY)`, `Currency Code`, `Salespers./Purch. Code`, `Available Credit Limit (LCY)` | **per-table case arm** | **the target must provide these for its own table** |

**The target's integration obligation:** `PopulateApprovalEntryArgument` has no case arm for a foreign table, so a target that wants amount/document data on its entries must set those fields on the argument record itself before calling `MakeApprovalEntry`, or subscribe to whatever `OnAfterPopulateApprovalEntryArgument`-style event its own symbol set exposes (**revalidate — not verified in this session**).

### 7.2 Fields the target reads

| Field | Use |
| --- | --- |
| `Status` (`Enum "Approval Status"`: `0 Created`, `1 Open`, `2 Canceled`, `3 Rejected`, `4 Approved`, `5 ' '`) | state display and guards |
| `Pending Approvals` (FlowField) | **final-approval discriminator**; consumed by the workflow step condition, not by AL code |
| `Number of Approved Requests`, `Number of Rejected Requests` (FlowFields) | reporting |
| `Comment` (FlowField over `Approval Comment Line`) | comment indicator |
| `Related to Change` (FlowField) | always false for GJ; relevant only for change-approval workflows |

Keys the standard code relies on: `Key2` (`Record ID to Approve`, `Workflow Step Instance ID`, `Sequence No.`), `Key3` (`Table ID`, `Document Type`, `Document No.`, `Sequence No.`, `Record ID to Approve`), `Key7` (`Table ID`, `Record ID to Approve`, `Status`, `Workflow Step Instance ID`, `Sequence No.`).

### 7.3 Related records

| Record | Linkage |
| --- | --- |
| `Approval Comment Line` (455) | `Table ID` + `Record ID to Approve` + `Workflow Step Instance ID`; surfaced via `Approvals Mgmt.GetApprovalComment(Variant)` |
| `Notification Entry` (1511) | `Triggered By Record` = the approval entry's RecordId; created by `CreateApprovalEntryNotification`; deleted by `Approval Entry.OnDelete` |
| `Restricted Record` (1550) | `Record ID` = subject RecordId |
| `Workflow Step Instance` (1504) | `ID` = `Approval Entry."Workflow Step Instance ID"` |
| `Posted Approval Entry` (456) / `Posted Approval Comment Line` (457) | written by `Approvals Mgmt.PostApprovalEntries(ApprovedRecordID; PostedRecordID; PostedDocNo)` |

### 7.4 Lifecycle obligations the target inherits

| Domain event | Required call |
| --- | --- |
| Subject record renamed | `Approvals Mgmt.RenameApprovalEntries(OldRecordId; NewRecordId)` **and** re-point `Restricted Record` rows |
| Subject record deleted | `Approvals Mgmt.DeleteApprovalEntries(RecordIDToApprove)` and `Record Restriction Mgt.AllowRecordUsage(record)` before delete |
| Subject record posted/archived | `Approvals Mgmt.PostApprovalEntries(approvedRecordId; postedRecordId; postedDocNo)` |

---

## 8. Record restriction and edit prevention

### 8.1 The enforceable lock (F)

`Table 1550 "Restricted Record"` is the domain lock. `Approval Entry.Status` is **not** the lock — posting never inspects it.

| API | Signature | Use |
| --- | --- | --- |
| `Record Restriction Mgt.RestrictRecordUsage(RecVar: Variant; RestrictionDetails: Text)` | public | upsert a restriction (exits for temporary records) |
| `Record Restriction Mgt.AllowRecordUsage(RecVar: Variant)` | public | delete **all** restriction rows for that record, regardless of which `Details` imposed them |
| `Record Restriction Mgt.UpdateRestriction(RecVar: Variant; xRecVar: Variant)` | public | re-point restrictions after rename |
| `Record Restriction Mgt.CheckRecordHasUsageRestrictions(RecVar: Variant)` | public `TryFunction` | raise `You cannot use %1 for this action.\<Details>` |
| `Record Restriction Mgt.AllowGenJournalBatchUsage(GenJournalBatch)` | public but **General Journal-specific** | clears the batch and every line in it |

### 8.2 Two independent restriction sources (F)

1. **Workflow response** `RestrictRecordUsageCode` restricts the *approval subject* with `Details` = `'<workflow code> <description>'`.
2. **Table-event subscribers** (`Gen. Journal Line.OnAfterInsertEvent` / `OnAfterModifyEvent` → `RestrictGenJournalLine`, `local`) restrict **every** non-temporary, non-`System-Created Entry` line whenever a line or batch approval workflow *can execute* — with no open approval entry required. `RestrictGenJournalLineAfterModify` exits when `Format(Rec) = Format(xRec)`.

**I** — restriction presence is therefore **not** equivalent to "approval pending". Source 2 is the standard *stale-approval detector*: edit an approved line and it becomes restricted again while its `Approval Entry` stays `Approved`. This "approved entry, restricted record" divergence is the central subtlety.

### 8.3 Restriction removal (F)

| Event | Restriction |
| --- | --- |
| Final approval, line subject | removed for that line (`AllowRecordUsage`) |
| Final approval, batch subject | removed for the batch **and every line in it** (`AllowGenJournalBatchUsage`) |
| Reject | **not** removed |
| Cancel | **not** removed (line template has `RemoveRestrictionOnCancel = false`) |
| Posting | removed via `PostApprovalEntriesMoveGenJournalBatch` / line delete |
| Delete | removed before delete |

### 8.4 Edit prevention (F)

| Operation | Guard | Who is blocked |
| --- | --- | --- |
| Modify | `Gen. Journal Line.OnModify` → `Approvals Mgmt.PreventModifyRecIfOpenApprovalEntryExistForCurrentUser(line)` then `(batch)` | **the current approver only** (or when a pending webhook entry exists); raises an actionable `ErrorInfo` with "Reject approval" / "Show comments" |
| Insert | `OnInsert` → `PreventInsertRecIfOpenApprovalEntryExist(batch)` | approver blocked; sender/administrator gets a `Confirm` offering to cancel the batch approval |
| Delete | `OnDelete` → `PreventDeletingRecordWithOpenApprovalEntry(line)`, and `(batch)` when it is the last line | line: hard error; batch: `Confirm` to cancel first |
| Rename | `OnRename` → `OnRenameRecordInApprovalRequest` + restriction update | allowed, identity re-pointed |

**I** — the requester is deliberately *not* blocked from editing. The requester-facing control is the restriction at posting time.

**F** — `Modify(false)` / `Insert(false)` / `ModifyAll` skip both the table guards and the automatic restriction subscribers. Existing restriction rows still block standard posting.

---

## 9. Posting / processing enforcement

### 9.1 The deepest shared guard (F)

```
posting wrapper (231 / 232 / 233 / 234 / 250)
  → Codeunit 13 "Gen. Jnl.-Post Batch"
      → ProcessLines → CheckLine(line)
          → Gen. Jnl.-Check Line.RunCheck
          → CheckRestrictions(line)
              → if not PreviewMode:
                    Gen. Journal Line.OnCheckGenJournalLinePostRestrictions()
                      → Record Restriction Mgt. subscribers:
                          GenJournalLineCheckGenJournalLinePostRestrictions   (line)
                          GenJournalBatchCheckGenJournalLinePostRestrictions  (batch)
                          CustomerCheckGenJournalLinePostRestrictions
                          VendorCheckGenJournalLinePostRestrictions
```

**F** — the check runs in the initial "Checking lines" loop, **before** any ledger write and before the batch commit points. A restriction error therefore aborts with no ledger entries.

**F** — `PreviewMode` skips `CheckRestrictions`. First-party test `CanPreviewPost` asserts that preview is allowed while a batch approval is pending and produces no G/L entries.

### 9.2 Adjacent enforcement (F)

| Route | Event |
| --- | --- |
| Check printing | `Gen. Journal Line.OnCheckGenJournalLinePrintCheckRestrictions()`; `Report "Check"` also calls `CheckRecordHasUsageRestrictions` directly |
| Payment export | `Gen. Journal Line.OnCheckGenJournalLineExportRestrictions()` and `Gen. Journal Batch.OnCheckGenJournalLineExportRestrictions()` |

### 9.3 Known bypasses (Risk)

| Bypass | Cause |
| --- | --- |
| Direct call to `Codeunit 12 "Gen. Jnl.-Post Line"` | `RunWithCheck`/`RunWithoutCheck` were not observed to raise `OnCheckGenJournalLinePostRestrictions` |
| `Gen. Jnl.-Post.OnBeforeGenJnlPostBatchRun` handled | wrapper exits before the batch engine |
| `Gen. Jnl.-Post Batch.OnBeforeCheckLine` handled | `CheckLine` exits before `CheckRestrictions` |
| `Record Restriction Mgt.OnBefore…PostRestrictions` sets `IsHandled` | a specific standard subscriber is skipped |
| `Modify(false)` / `Insert(false)` / `ModifyAll` | restriction is never (re-)imposed |
| Preview mode | check deliberately skipped |
| Approval entry exists but no restriction row | posting checks restrictions, not entries |

### 9.4 Scope caveat (Version-sensitive)

`OnCheckGenJournalLinePostRestrictions` and `OnCheckGenJournalLinePrintCheckRestrictions` are declared `[IntegrationEvent(true, false)]` **and `[Scope('OnPrem')]`** in this snapshot. `Gen. Journal Batch.OnMoveGenJournalBatch` is likewise `[Scope('OnPrem')]`. `OnCheckGenJournalLineExportRestrictions` is **not** scope-restricted. A cloud-target extension must revalidate whether these events are usable from its own symbols. See [08 §2](08-unresolved-and-version-sensitive-findings.md#2-scope-restricted-symbols).

**I — target design rule:** put the target's own restriction check in the target's own domain-processing engine, at the last shared layer before any ledger/state write, and publish the target's **own** non-scope-restricted integration event so its extensions can participate. Do not depend on the General Journal events.

---

## 10. Reusable standard services matrix

| Standard service | Object.Member | Classification | Reusable for another domain? | Condition |
| --- | --- | --- | --- | --- |
| Workflow event dispatch | `Workflow Management.HandleEvent` | Public supported dependency | **Yes, directly** | Event code must be registered |
| Instance-scoped dispatch | `Workflow Management.HandleEventOnKnownWorkflowInstance` | Public supported dependency | **Yes, directly** | Requires `Approval Entry."Workflow Step Instance ID"` |
| Workflow-enabled probe | `Workflow Management.CanExecuteWorkflow`, `EnabledWorkflowExist` | Public supported dependency | **Yes, directly** | — |
| Event library registration | `Workflow Event Handling.AddEventToLibrary` / `AddEventPredecessor` | Public supported dependency | **Yes, from the library subscribers** | Call only from `OnAddWorkflowEvents…` subscribers |
| Response library registration | `Workflow Response Handling.AddResponseToLibrary` / `AddResponsePredecessor` | Public supported dependency | **Yes, from the library subscribers** | — |
| Custom response execution | `Workflow Response Handling.OnExecuteWorkflowResponse` | Published extension point | **Yes** | Set `ResponseExecuted := true` |
| Generic approval responses | `CreateApprovalRequestsCode`, `SendApprovalRequestForApprovalCode`, `RejectAllApprovalRequestsCode`, `CancelAllApprovalRequestsCode`, `RestrictRecordUsageCode`, `AllowRecordUsageCode`, `ShowMessageCode`, `OpenDocumentCode` | Public supported dependency | **Yes, directly** — these are domain-neutral | Subject table must have a `Workflow - Table Relation` row to `Approval Entry` |
| Approve/Reject/Delegate events | `RunWorkflowOnApprove/Reject/DelegateApprovalRequestCode` | Public supported dependency | **Yes, directly** — domain-neutral | Target must raise them via `HandleEventOnKnownWorkflowInstance` |
| Approval-entry creation | `Approvals Mgmt.CreateApprovalRequests`, `MakeApprovalEntry`, `PopulateApprovalEntryArgument`, `GetLastSequenceNo` | Public supported dependency | **Yes** | Target must fill its own document/amount fields |
| Approval-entry promotion | `Approvals Mgmt.SendApprovalRequestFromRecord`, `SendApprovalRequestFromApprovalEntry` | Public supported dependency | **Yes** | — |
| Notifications | `Approvals Mgmt.CreateApprovalEntryNotification` | Public supported dependency | **Yes** | — |
| Approval-state probes | `HasOpenApprovalEntries`, `HasOpenApprovalEntriesForCurrentUser`, `HasApprovedApprovalEntries`, `FindOpenApprovalEntryForCurrUser`, `CanCancelApprovalForRecord` | Public supported dependency | **Yes, directly** — RecordId-based, domain-neutral | — |
| Edit prevention | `PreventModifyRecIfOpenApprovalEntryExistForCurrentUser`, `PreventInsertRecIfOpenApprovalEntryExist`, `PreventDeletingRecordWithOpenApprovalEntry` | Public supported dependency | **Yes, directly** — `Variant`-based | Call from the target table's `OnModify`/`OnInsert`/`OnDelete` |
| Identity maintenance | `RenameApprovalEntries`, `DeleteApprovalEntries` | Public supported dependency | **Yes, directly** | — |
| Posted history | `PostApprovalEntries` | Public supported dependency | **Yes, directly** | Target supplies both RecordIds and the posted document no. |
| Comments | `GetApprovalComment` | Public supported dependency | **Yes, directly** | — |
| Approver sufficiency | `IsSufficientApprover` | Public supported dependency | **Partially** | Contains per-table logic; a foreign table hits the generic path — revalidate |
| Restriction lock | `Record Restriction Mgt.RestrictRecordUsage`, `AllowRecordUsage`, `UpdateRestriction`, `CheckRecordHasUsageRestrictions` | Public supported dependency | **Yes, directly** | — |
| Template/step construction | `Workflow Setup.InsertWorkflowTemplate`, `MarkWorkflowAsTemplate`, `InsertEntryPointEventStep`, `InsertEventStep`, `InsertResponseStep`, `SetNextStep`, `InsertApprovalArgument`, `InsertNotificationArgument`, `InsertTableRelation`, `InsertWorkflowCategory`, `GetWorkflowTemplateCode` | Public supported dependency | **Yes, directly** | — |
| Whole approval skeleton | `Workflow Setup.InsertRecApprovalWorkflowSteps` | Public supported dependency | **Yes, directly** — this is the generic, non-GJ skeleton | Supply the target's own event codes and condition string |
| Approve-branch conditions | `BuildNoPendingApprovalsConditions`, `BuildPendingApprovalsConditions` | Public supported dependency (version-sensitive) | **Yes** | Coupled to the `Pending Approvals` FlowField definition |
| Batch fan-out | `Batch Processing Mgt.BatchProcess` + a per-record worker codeunit | Public supported dependency | **Yes** | Target supplies its own worker codeunit |
| Balance pre-check | `CheckGeneralJournalBatchBalanceCode` | General Journal-specific implementation | **No** | Reproduce as the target's own pre-check response |
| Batch release | `AllowGenJournalBatchUsage` | General Journal-specific implementation | **No** | Reproduce as a target-specific cascade |
| Journal action entry points | `TrySend…`, `TryCancel…`, `Approve/Reject/DelegateGenJournalLineRequest`, `SendJournalLinesApprovalRequests`, `ShowJournalApprovalEntries`, `Get/CleanGenJnl*ApprovalStatus` | General Journal-specific implementation | **No** | Reproduce the pattern for the target's records |
| Legacy setup wizard | `Codeunit 1804` | Version-sensitive / OnPrem | **No** | `[Scope('OnPrem')]` |
| Webhook approval | `Codeunit 1540`, `Codeunit 1543` | Version-sensitive or uncertain | **Unknown** | Not traced; do not design against it yet |

---

## 11. Target-extension object blueprint

Object IDs are **not** assigned here — the target repository owns its own ranges. Names are placeholders in `<>`.

### 11.1 Objects the target must create

| Kind | Placeholder name | Purpose | Standard analogue |
| --- | --- | --- | --- |
| Table (existing target table) | `<Target Subject>` | The approval subject. Must have a stable primary key and a `RecordId` that survives its own lifecycle. | `Gen. Journal Batch` / `Gen. Journal Line` |
| Codeunit | `<Target> Approvals Mgmt.` | Domain entry points: `Send…ForApproval`, `Cancel…ApprovalRequest`, `Approve…Request`, `Reject…Request`, `Delegate…Request`, `Show…ApprovalEntries`, plus the four `[IntegrationEvent]` publishers `OnSend…ForApproval` / `OnCancel…ApprovalRequest`. Performs eligibility checks **inside** the procedures, not only in the UI. | `Codeunit 1535 "Approvals Mgmt."` GJ region |
| Codeunit | `<Target> Workflow Event Handling` | Event-code getter procedures; `[EventSubscriber]` on `Codeunit 1520.OnAddWorkflowEventsToLibrary` / `OnAddWorkflowEventPredecessorsToLibrary`; `[EventSubscriber]` on the target's own `OnSend…`/`OnCancel…` publishers forwarding to `WorkflowManagement.HandleEvent`. | `Codeunit 1520` GJ region |
| Codeunit | `<Target> Workflow Response Handling` | Response-code getters for target-specific responses; `[EventSubscriber]` on `Codeunit 1521.OnAddWorkflowResponsesToLibrary` / `OnAddWorkflowResponsePredecessorsToLibrary`; `[EventSubscriber]` on `Codeunit 1521.OnExecuteWorkflowResponse` implementing each target response and setting `ResponseExecuted := true`. | `Codeunit 1521` |
| Codeunit | `<Target> Workflow Setup` | `[EventSubscriber]` on `Codeunit 1502.OnAfterInsertApprovalsTableRelations` → `InsertTableRelation(<subject table>; 0; Database::"Approval Entry"; <"Record ID to Approve" field no.>)`; optional `[EventSubscriber]` on `OnAddWorkflowCategoriesToLibrary`; a public `Insert<Target>ApprovalWorkflowTemplate` procedure building the template with `InsertWorkflowTemplate` + `InsertRecApprovalWorkflowSteps` + `MarkWorkflowAsTemplate`. | `Codeunit 1502` GJ region |
| Codeunit | `<Target> Restriction Mgt.` | `[EventSubscriber]` on the subject table's `OnAfterInsertEvent` / `OnAfterModifyEvent` re-imposing restrictions while a target workflow can execute (skip temporary and system-created records; skip when `Format(Rec) = Format(xRec)`); `[EventSubscriber]` on the target's own post-restriction event calling `CheckRecordHasUsageRestrictions`; a cascade equivalent of `AllowGenJournalBatchUsage` if the target has a container subject. | `Codeunit 1550` GJ region |
| Codeunit | `<Target> Approval Request Worker` | `TableNo = <Target Subject>`; `OnRun` sends one record, for `Batch Processing Mgt.BatchProcess` multi-record fan-out. | `Codeunit 1536` |
| Codeunit | `<Target> Install`/`Upgrade` | Calls `<Target> Workflow Setup.Insert<Target>ApprovalWorkflowTemplate` and (optionally) `WorkflowSetup.InitWorkflow()`. | (General Journal has none; it relies on `Company-Initialize`) |
| Page extension / Page | `<Target Document/List>` approval actions | Send, Cancel, Approve, Reject, Delegate, Comments, Approvals; plus derived status fields computed on the fly. Enablement is UI convenience only. | `Page 39` |
| Integration event on the subject table | `OnCheck<Target>PostRestrictions()` | The target's **own**, non-`OnPrem`-scoped restriction-check publisher, raised from the target's deepest shared processing engine before any state write. | `Gen. Journal Line.OnCheckGenJournalLinePostRestrictions` (but that one is `[Scope('OnPrem')]`) |
| Permission set | `<Target> Approvals` | Read/insert/modify on `Approval Entry`, `Approval Comment Line`, `Restricted Record`, `Notification Entry`, and the target subject. | standard approval permission sets |

### 11.2 Objects the target must **not** create

- No copy of `Approval Entry`, `Restricted Record`, `Workflow`, `Workflow Step`, `Workflow Step Argument`, `Workflow Step Instance` or `Notification Entry`. Reuse the standard tables.
- No copy of the approval status enum. Reuse `Enum "Approval Status"`.
- No copy of the approver-type enums. Extend `Enum 460` / `Enum 465` only if genuinely new approver semantics are needed.

### 11.3 Registration wiring (verified pattern)

```
<Target> Workflow Event Handling
  [EventSubscriber] Codeunit 1520 :: OnAddWorkflowEventsToLibrary
      WorkflowEventHandling.AddEventToLibrary(RunWorkflowOnSend<Target>ForApprovalCode(), Database::"<Target Subject>", <desc>, 0, false);
      WorkflowEventHandling.AddEventToLibrary(RunWorkflowOnCancel<Target>ApprovalRequestCode(), Database::"<Target Subject>", <desc>, 0, false);
  [EventSubscriber] Codeunit 1520 :: OnAddWorkflowEventPredecessorsToLibrary
      case EventFunctionName of
        RunWorkflowOnCancel<Target>ApprovalRequestCode():
            AddEventPredecessor(EventFunctionName, RunWorkflowOnSend<Target>ForApprovalCode());
        WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(),
        WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode(),
        WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode():
            AddEventPredecessor(EventFunctionName, RunWorkflowOnSend<Target>ForApprovalCode());
      end;

<Target> Workflow Response Handling
  [EventSubscriber] Codeunit 1521 :: OnAddWorkflowResponsePredecessorsToLibrary
      case ResponseFunctionName of
        WorkflowResponseHandling.CreateApprovalRequestsCode(),
        WorkflowResponseHandling.SendApprovalRequestForApprovalCode():
            AddResponsePredecessor(ResponseFunctionName, RunWorkflowOnSend<Target>ForApprovalCode());
        WorkflowResponseHandling.CancelAllApprovalRequestsCode(),
        WorkflowResponseHandling.OpenDocumentCode():
            AddResponsePredecessor(ResponseFunctionName, RunWorkflowOnCancel<Target>ApprovalRequestCode());
      end;

<Target> Workflow Setup
  [EventSubscriber] Codeunit 1502 :: OnAfterInsertApprovalsTableRelations
      WorkflowSetup.InsertTableRelation(Database::"<Target Subject>", 0,
                                        Database::"Approval Entry", <field no. of "Record ID to Approve">);
```

*Pseudocode — not compiled. Field and object references must be resolved against the target's own symbols.*

### 11.4 Template construction (verified pattern)

```
WorkflowSetup.InsertWorkflowTemplate(Workflow, <Target>ApprovalWorkflowCode(), <description>, <CategoryCode>);
WorkflowStepArgument.Init();
WorkflowStepArgument."Approver Type"       := WorkflowStepArgument."Approver Type"::Approver;
WorkflowStepArgument."Approver Limit Type" := WorkflowStepArgument."Approver Limit Type"::"Direct Approver";
WorkflowSetup.InsertRecApprovalWorkflowSteps(
    Workflow,
    <condition string for the subject table>,
    <Target>EventHandling.RunWorkflowOnSend<Target>ForApprovalCode(),
    WorkflowResponseHandling.CreateApprovalRequestsCode(),
    WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
    <Target>EventHandling.RunWorkflowOnCancel<Target>ApprovalRequestCode(),
    WorkflowStepArgument,
    <ShowConfirmationMessage>,
    <RemoveRestrictionOnCancel>);
WorkflowSetup.MarkWorkflowAsTemplate(Workflow);
```

*Pseudocode — not compiled.* `InsertRecApprovalWorkflowSteps` builds: entry event → `RestrictRecordUsage` → `CreateApprovalRequests` → `SendApprovalRequestForApproval`, plus the approved-with-no-pending → `AllowRecordUsage` branch, the approved-with-pending / delegate loop-backs, the reject branch and the cancel branch.

**Decision the target must make explicitly:** `RemoveRestrictionOnCancel`. General Journal sets it to `false` for the line template, so cancel leaves the record restricted. If the target's cancel is meant to fully release the record, set it to `true`.

---

## 12. Suggested target workflow event catalogue

Domain events the target should publish and register. Codes are `Code[128]`, uppercase, no spaces, matching the `RUNWORKFLOWON…` convention.

| Suggested code | Getter | Subject table | Raised from | Reuses standard? |
| --- | --- | --- | --- | --- |
| `RUNWORKFLOWONSEND<TARGET>FORAPPROVAL` | `RunWorkflowOnSend<Target>ForApprovalCode()` | `<Target Subject>` | `<Target> Approvals Mgmt.OnSend<Target>ForApproval` subscriber | New — target-owned |
| `RUNWORKFLOWONCANCEL<TARGET>APPROVALREQUEST` | `RunWorkflowOnCancel<Target>ApprovalRequestCode()` | `<Target Subject>` | `OnCancel<Target>ApprovalRequest` subscriber | New — target-owned |
| *(optional)* `RUNWORKFLOWON<TARGET><PRECONDITIONMET>` / `…NOTMET` | getters | `<Target Subject>` | the target's pre-check response, mirroring `OnGeneralJournalBatchBalanced` / `NotBalanced` | New — only if a pre-check branch is needed |
| `RUNWORKFLOWONAPPROVEAPPROVALREQUEST` | `WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode()` | `Approval Entry` | standard | **Reuse standard** |
| `RUNWORKFLOWONREJECTAPPROVALREQUEST` | `WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode()` | `Approval Entry` | standard | **Reuse standard** |
| `RUNWORKFLOWONDELEGATEAPPROVALREQUEST` | `WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode()` | `Approval Entry` | standard | **Reuse standard** |

Predecessor registration required (library legality):

- cancel event ← send event;
- optional pre-check events ← send event;
- standard approve / reject / delegate events ← send event (and ← the optional pre-check "met" event, if used).

---

## 13. Suggested target workflow response catalogue

| Response | Source | Notes |
| --- | --- | --- |
| `CreateApprovalRequestsCode()` | **Standard, reuse** | Creates `Approval Entry` rows for whatever table is passed. Requires the `Workflow - Table Relation` row from §11.3. |
| `SendApprovalRequestForApprovalCode()` | **Standard, reuse** | Promotes the lowest sequence group to `Open` and notifies. |
| `RestrictRecordUsageCode()` | **Standard, reuse** | Restricts the subject. |
| `AllowRecordUsageCode()` | **Standard, reuse** | Releases the subject on final approval. If the target has a container subject that must cascade to children, implement a **target-specific** response instead (see below). |
| `RejectAllApprovalRequestsCode()` | **Standard, reuse** | — |
| `CancelAllApprovalRequestsCode()` | **Standard, reuse** | — |
| `ShowMessageCode()` | **Standard, reuse** | Used with `Workflow Step Argument.Message`. |
| `OpenDocumentCode()` | **Standard, reuse** | Only if the target has a released/open document status concept. |
| `<TARGET>CHECKPRECONDITION` | **New, target-owned** | Analogue of `CheckGeneralJournalBatchBalanceCode`. Implemented in `OnExecuteWorkflowResponse`; must raise the target's "met"/"not met" events. Register with `AddResponseToLibrary(code, 0, <desc>, 'GROUP 0')` and `AddResponsePredecessor(code, RunWorkflowOnSend<Target>ForApprovalCode())`. |
| `<TARGET>ALLOWCONTAINERUSAGE` | **New, target-owned** | Analogue of `AllowGenJournalBatchUsage`: releases the container and its children. Only if §14 selects the container or hybrid subject. |

Response option groups observed in this snapshot: `GROUP 0` (no options), `GROUP 2` (notification), `GROUP 4` (message), `GROUP 5` (approval arguments). These are literal constants — **revalidate against target symbols**.

---

## 14. Approval-subject decision framework

Four candidate subject models, each mapped to what General Journal actually proves.

### 14.1 Header subject

- **Model:** one approval per parent/header record; children inherit the outcome.
- **General Journal evidence:** the `Gen. Journal Batch` template is the closest analogue, but the batch is a *container*, not a document header — it carries no amount, document number, currency or salesperson.
- **Consequences proven here:** `IsSufficientApprover` explicitly does **not** support approver chains for a subject that carries no amount (`ApporvalChainIsUnsupportedMsg`); release cascades to all children (`AllowGenJournalBatchUsage`).
- **Choose when:** the header carries the business amount and identity, one decision covers all children, and approver limits should be evaluated against header totals.
- **Then the target must:** populate document/amount fields on the approval-entry argument for the header; implement a cascade release; decide whether child edits invalidate the header approval (General Journal solves this with automatic child restriction).

### 14.2 Line subject

- **Model:** one approval per child record.
- **General Journal evidence:** `MS-GJLAPW`, subject `Gen. Journal Line` (table 81). Fully supported approver limits. Multi-record send fans out via `Batch Processing Mgt.` + `Codeunit 1536`; **there is no multi-record approve**.
- **Consequences proven here:** *N* lines = *N* workflow instances = *N*+ approval entries and *N* approve interactions. Line `RecordId` is unstable across renumbering, delete and posting, requiring rename/delete/move compensation.
- **Choose when:** approval decisions genuinely differ per line and per-line amounts drive approver limits.
- **Then the target must:** accept the interaction cost, or provide its own multi-record approve action (standard does not).

### 14.3 Generated standard document subject

- **Model:** the target generates a standard BC document (e.g. a purchase or sales document) and lets the existing first-party approval workflow for that document govern it.
- **General Journal evidence:** none — General Journal does **not** do this. This option is included because it is the only model that gets a fully supported approval experience with zero new workflow registration.
- **Choose when:** the target's records naturally become a standard document, and the approval decision is genuinely about that document.
- **Then the target must:** accept that approval happens on the generated document, not on the target record; map the outcome back; and handle the window between target-record creation and document generation. **Not verified in this session — revalidate against the target's symbols.**

### 14.4 Hybrid (container + child)

- **Model:** both a container-level and a child-level approval, simultaneously enableable.
- **General Journal evidence:** this is exactly what General Journal does. **F**
- **Consequences proven here:** two independent workflow libraries, two templates, two restriction sources, and a real cross-path interaction — final *container* approval calls `AllowRecordUsage`, which deletes **all** `Restricted Record` rows for the record regardless of which `Details` imposed them, so final batch approval clears line restrictions imposed by the line workflow. No inspected first-party test covers that combination. **Risk, unresolved.**
- **Choose when:** both granularities are genuinely required by the business.
- **Then the target must:** define and test the interaction explicitly, and consider making the two mutually exclusive by configuration.

### 14.5 Recommendation

**Default to the child/line subject, and add the container subject only if the business requires container-level sign-off — in which case make the two mutually exclusive by setup rather than replicating the standard General Journal overlap.**

Reasons, from evidence:

1. The line subject is the only General Journal subject for which approver limits, amounts and document data actually work. **F**
2. The container subject's approval entries carry no monetary data, which makes amount-based policy and approval-list columns meaningless. **F**
3. The dual-subject overlap has a proven cross-path restriction-clearing interaction with no first-party test coverage. **Risk**
4. Hybrid adds a second complete registration, template, restriction source and status-derivation path for behaviour that a container-level condition on a single workflow can often express.

If the target's records are inherently container-scoped and have no meaningful per-child decision, invert this and use the container subject alone — accepting the loss of approver-chain support unless the target populates amount data on the container's approval-entry argument itself.

---

## 15. Business Central compatibility checklist

| # | Check | Why |
| --- | --- | --- |
| 1 | Confirm the target app's `runtime`, `platform`, `application` and `target` (Cloud vs OnPrem) in `app.json` | Determines whether `[Scope('OnPrem')]` members are usable at all |
| 2 | Confirm `Base Application` is a declared dependency | `Approvals Mgmt.`, `Record Restriction Mgt.`, `Workflow Setup` and the workflow tables all live there |
| 3 | Verify every symbol in §18 resolves in the target's own symbols, with the same signature | Signatures and scopes change across versions |
| 4 | Verify `Workflow Setup.InsertRecApprovalWorkflowSteps` still has the 9-parameter signature used in §11.4 | Parameter list changed shape historically |
| 5 | Verify `Approval Entry."Pending Approvals"` FlowField definition matches what `BuildNoPendingApprovalsConditions` encodes | Silent final-approval-detection failure otherwise |
| 6 | Verify `Enum "Approval Status"` ordinals if any code indexes them positionally | `GetApprovalEntryStatusValueName` uses `AsInteger() + 1` |
| 7 | Verify `Enum 460`/`465` are still `Extensible = true` before adding values | — |
| 8 | Verify the response option group literals (`GROUP 0/2/4/5`) accepted by `AddResponseToLibrary` | Literal constants |
| 9 | Do not depend on template code literals (`MS-GJBAPW`, `MS-GJLAPW`) or category `FIN` | Snapshot literals |
| 10 | Do not write directly to `Approval Entry`, `Restricted Record`, `Workflow Event`, `Workflow Response`, or `WF Event/Response Combination` | Not a supported contract |
| 11 | Confirm required permissions: `Approval Entry`, `Approval Comment Line`, `Restricted Record`, `Notification Entry`, `Workflow*`, `User Setup` (read) | Indirect permissions are needed by the called standard code |
| 12 | Ensure `Confirm`/`Message` calls in the target's send/cancel paths are `GuiAllowed`-guarded | Standard General Journal is **not**, and its behaviour in job-queue/web-service contexts is unverified |
| 13 | Ensure eligibility and authorisation checks are inside the AL procedures, not only in page `Enabled`/`Visible` | Standard cancel relies on the page property alone |
| 14 | Ensure the restriction check runs before any state write and before commit | Matches `Gen. Jnl.-Post Batch.CheckLine` timing |
| 15 | Decide preview/simulation behaviour explicitly | Standard General Journal **allows** preview while pending |
| 16 | Exclude temporary and system-generated records from automatic restriction | `RestrictGenJournalLine` excludes `IsTemporary` and `System-Created Entry` |
| 17 | Handle rename, delete and archive of the subject record | `RenameApprovalEntries`, `DeleteApprovalEntries`, `PostApprovalEntries`, restriction re-point/removal |
| 18 | Verify webhook/Power Automate interaction before claiming support | `Codeunit 1543` untraced |
| 19 | Add tests mirroring the first-party General Journal approval tests | See §17.5 |

---

## 16. Reuse decision by category

### 16.1 Use directly

Call these standard members from the target extension without modification.

| Symbol | Why |
| --- | --- |
| `Codeunit 1501 "Workflow Management"` — `HandleEvent`, `HandleEventWithxRec`, `HandleEventOnKnownWorkflowInstance`, `HandleEventWithxRecOnKnownWorkflowInstance`, `CanExecuteWorkflow`, `EnabledWorkflowExist`, `WorkflowExists`, `ExecuteResponses` | Domain-neutral engine |
| `Codeunit 1502 "Workflow Setup"` — `InitWorkflow`, `InsertWorkflowTemplate`, `MarkWorkflowAsTemplate`, `InsertEntryPointEventStep`, `InsertEventStep`, `InsertResponseStep`, `SetNextStep`, `InsertApprovalArgument`, `InsertNotificationArgument`, `InsertTableRelation`, `InsertWorkflowCategory`, `GetWorkflowTemplateCode`, `GetWorkflowTemplateToken`, `InsertRecApprovalWorkflowSteps`, `BuildNoPendingApprovalsConditions`, `BuildPendingApprovalsConditions` | Generic builders |
| `Codeunit 1520 "Workflow Event Handling"` — `AddEventToLibrary`, `AddEventPredecessor`, `RunWorkflowOnApproveApprovalRequestCode`, `RunWorkflowOnRejectApprovalRequestCode`, `RunWorkflowOnDelegateApprovalRequestCode` | Generic |
| `Codeunit 1521 "Workflow Response Handling"` — `AddResponseToLibrary`, `AddResponsePredecessor`, `CreateApprovalRequestsCode`, `SendApprovalRequestForApprovalCode`, `RejectAllApprovalRequestsCode`, `CancelAllApprovalRequestsCode`, `RestrictRecordUsageCode`, `AllowRecordUsageCode`, `ShowMessageCode`, `OpenDocumentCode` | Generic |
| `Codeunit 1535 "Approvals Mgmt."` — `CreateApprovalRequests`, `MakeApprovalEntry`, `PopulateApprovalEntryArgument`, `GetLastSequenceNo`, `SendApprovalRequestFromRecord`, `SendApprovalRequestFromApprovalEntry`, `CreateApprovalEntryNotification`, `FindOpenApprovalEntryForCurrUser`, `HasOpenApprovalEntries`, `HasOpenApprovalEntriesForCurrentUser`, `HasApprovedApprovalEntries`, `CanCancelApprovalForRecord`, `PreventModifyRecIfOpenApprovalEntryExistForCurrentUser`, `PreventInsertRecIfOpenApprovalEntryExist`, `PreventDeletingRecordWithOpenApprovalEntry`, `RenameApprovalEntries`, `DeleteApprovalEntries`, `PostApprovalEntries`, `GetApprovalComment` | RecordId/Variant-based, domain-neutral |
| `Codeunit 1550 "Record Restriction Mgt."` — `RestrictRecordUsage`, `AllowRecordUsage`, `UpdateRestriction`, `CheckRecordHasUsageRestrictions` | Generic lock API |
| `Table 454 "Approval Entry"`, `Table 455 "Approval Comment Line"`, `Table 456 "Posted Approval Entry"`, `Table 457 "Posted Approval Comment Line"`, `Table 1550 "Restricted Record"`, `Table 1523 "Workflow Step Argument"`, `Table 1504 "Workflow Step Instance"` | Reuse; do not clone |
| `Enum "Approval Status"`, `Enum 460 "Workflow Approver Type"`, `Enum 465 "Workflow Approver Limit Type"` | Reuse |

### 16.2 Subscribe or extend

| Extension point | Purpose |
| --- | --- |
| `Codeunit 1520.OnAddWorkflowEventsToLibrary` | Register the target's events |
| `Codeunit 1520.OnAddWorkflowEventPredecessorsToLibrary` | Register the target's event legality |
| `Codeunit 1521.OnAddWorkflowResponsesToLibrary` | Register target-specific responses |
| `Codeunit 1521.OnAddWorkflowResponsePredecessorsToLibrary` | Wire standard and target responses to the target's events |
| `Codeunit 1521.OnExecuteWorkflowResponse` | Implement target-specific responses |
| `Codeunit 1502.OnAfterInsertApprovalsTableRelations` | Register `<Target Subject>` → `Approval Entry` |
| `Codeunit 1502.OnAddWorkflowCategoriesToLibrary` | Add a target workflow category |
| `Codeunit 1502.OnAfterInitWorkflowTemplates` | Insert the target's template after standard templates |
| `Codeunit 1535.OnApproveApprovalRequest` / `OnRejectApprovalRequest` / `OnDelegateApprovalRequest` | Observe approval-entry transitions (subscribe-only, `local` publishers) |
| The target subject table's `OnAfterInsertEvent` / `OnAfterModifyEvent` / `OnAfterDeleteEvent` / `OnAfterRenameEvent` | Restriction re-imposition and identity maintenance |
| `Enum 460` / `Enum 465` enum extensions | Only if new approver semantics are required, and only with matching resolution logic |

### 16.3 Reproduce in the target domain

These are General Journal-specific and must be re-implemented, not called.

| Standard symbol | What to reproduce |
| --- | --- |
| `Approvals Mgmt.TrySendJournalBatchApprovalRequest` / `TrySendJournalLineApprovalRequests` | Send entry points **with the eligibility checks inside the procedure** |
| `Approvals Mgmt.SendJournalLinesApprovalRequests` + `Codeunit 1536` | Multi-record fan-out via `Batch Processing Mgt.` |
| `Approvals Mgmt.TryCancelJournalBatchApprovalRequest` / `TryCancelJournalLineApprovalRequests` | Cancel entry points — **add the `CanCancelApprovalForRecord` check that standard omits** |
| `Approvals Mgmt.ApproveGenJournalLineRequest` / `RejectGenJournalLineRequest` / `DelegateGenJournalLineRequest` | Approve/reject/delegate entry points |
| `Approvals Mgmt.ShowJournalApprovalEntries` | Navigation filtered to the target's table IDs and RecordIds |
| `Approvals Mgmt.HasAnyOpenJournalLineApprovalEntries` | Container-wide "any child pending" probe |
| `Approvals Mgmt.GetGenJnlBatchApprovalStatus` / `GetGenJnlLineApprovalStatus` / `CleanGenJournalApprovalStatus` | Derived status text |
| `Approvals Mgmt.IsGeneralJournal*ApprovalsWorkflowEnabled` / `CheckGeneralJournal*ApprovalsWorkflowEnabled` | Workflow-enabled probe and hard check |
| `Workflow Setup.GeneralJournal*ApprovalWorkflowCode` | Target workflow code getters |
| `Workflow Setup.InsertGenJnlBatchApprovalWorkflowSteps` | A pre-check branch, only if §13's `<TARGET>CHECKPRECONDITION` is needed |
| `Workflow Setup.BuildGeneralJournalLineTypeConditions` | Target condition-string builder |
| `Workflow Response Handling.CheckGeneralJournalBatchBalanceCode` | Target pre-check response |
| `Record Restriction Mgt.AllowGenJournalBatchUsage` | Container cascade release |
| `Record Restriction Mgt.RestrictGenJournalLine` behaviour | Automatic restriction on insert/modify, with temporary/system-created exclusions |
| `Gen. Jnl.-Post Batch.CheckRestrictions` | The target's deepest shared processing guard |
| `Gen. Journal Line.OnCheckGenJournalLinePostRestrictions` | The target's **own** restriction-check integration event, without `[Scope('OnPrem')]` |
| `Page 39` approval action block and derived status fields | Target UI |

### 16.4 Learn from, but do not call

| Symbol | Reason |
| --- | --- |
| `Workflow Setup.BuildGeneralJournalBatchTypeConditions` | `local` |
| `Workflow Setup.ResetWorkflowTemplates` | `internal` |
| All `Workflow Response Handling` response bodies (`CreateApprovalRequests`, `SendApprovalRequestForApproval`, `RestrictRecordUsage`, `AllowRecordUsage`, `RejectAllApprovalRequests`, `CancelAllApprovalRequests`, `CheckGeneralJournalBatchBalance`) | `local`; reached only through `ExecuteResponse` |
| `Approvals Mgmt.ApproveSelectedApprovalRequest`, `RejectSelectedApprovalRequest`, `DelegateSelectedApprovalRequest`, `SubstituteUserIdForApprovalEntry`, `CheckOpenStatus`, `CheckUserAsApprovalAdministrator`, `GetGeneralJournalBatch`, `GetApprovalStatusFromApprovalEntry` | `local` |
| `Record Restriction Mgt.RestrictGenJournalLine` | `local` |
| `Codeunit 1804 "Approval Workflow Setup Mgt."` | `[Scope('OnPrem')]` throughout |
| `Page 39` approval variables and internal procedures | Page-scoped |
| Standard `Details` label texts on `Restricted Record` | Display text, not a contract |
| `Codeunit 1540 "Workflow Webhook Setup"` GJ builders | Untraced parallel path |

### 16.5 Revalidate against target symbols

| Symbol | What to revalidate | How |
| --- | --- | --- |
| `Gen. Journal Line.OnCheckGenJournalLinePostRestrictions` | `[Scope('OnPrem')]` — usable from a Cloud-target extension? | Go to definition in the target's symbols; check the attribute; attempt a compile in a scratch object |
| `Gen. Journal Line.OnCheckGenJournalLinePrintCheckRestrictions` | same | same |
| `Gen. Journal Batch.OnMoveGenJournalBatch` | same | same |
| `Gen. Jnl.-Post Line.OnMoveGenJournalLine` | `local` publisher; subscriber signature | Verify the signature before subscribing |
| `Workflow Setup.InsertRecApprovalWorkflowSteps` | Parameter list and order | Compare the target symbol's signature against §11.4 |
| `Workflow Setup.BuildNoPendingApprovalsConditions` / `BuildPendingApprovalsConditions` | Encoded view still matches `Approval Entry."Pending Approvals"` | Inspect both, then prove with a two-approver test |
| `Approvals Mgmt.PopulateApprovalEntryArgument` | Whether an `OnAfterPopulateApprovalEntryArgument`-style event exists for foreign tables | Search the target's symbols for `OnAfterPopulateApprovalEntryArgument` |
| `Approvals Mgmt.IsSufficientApprover` | Behaviour for a foreign table | Read the case statement in the target's symbols |
| `Enum "Approval Status"` ordinals | Positional use | Inspect the enum and any `AsInteger()` arithmetic |
| `Enum 460` / `Enum 465` | `Extensible = true` and value set | Inspect the enum declarations |
| Response option groups `GROUP 0/2/4/5` | Accepted literals | Inspect `AddResponseToLibrary` callers in the target's symbols |
| `Codeunit 1543 "Workflow Webhook Management"` | Everything | Not traced in sessions 1–5 |
| `Codeunit 1804 "Approval Workflow Setup Mgt."` | `[Scope('OnPrem')]` still present? | Inspect the symbols; do not depend on it regardless |
| Template codes `MS-GJBAPW`, `MS-GJLAPW`, category `FIN` | Literals | Do not hard-code; derive via `GetWorkflowTemplateCode` for the target's own codes |

---

## 17. Focused target-repository investigation instructions

Run these in the **target** repository, not here. Each is bounded and has a defined output.

1. **Manifest scope.** Read the target `app.json`: `runtime`, `platform`, `application`, `target`, `dependencies`. Output: whether `[Scope('OnPrem')]` members are usable and whether `Base Application` is a dependency.
2. **Subject candidate analysis.** For each candidate subject table: primary key stability, whether `RecordId` survives rename/delete/archive, whether the table carries an amount and a document number, and whether a container/child relationship exists. Output: the §14 decision with evidence.
3. **Deepest shared processing guard.** Trace every route that mutates the target's protected state (page actions, batch actions, reports, job queue, API pages, web services, direct codeunit calls) down to the last shared layer before any state write. Output: one named object.procedure, plus a list of routes that bypass it.
4. **Existing extension points.** Search the target for existing integration events on the subject table's `OnInsert`/`OnModify`/`OnDelete`/`OnRename` and on the processing engine. Output: which hooks already exist versus which must be added.
5. **Test baseline.** Locate the target's existing test codeunits for the subject table and its processing engine. Mirror the first-party General Journal coverage: send creates the expected entry count; restriction blocks processing; cancel does **not** release; reject does **not** release; final approval releases; temporary records are excluded; system-generated records are excluded; multi-record send fans out; rename/delete maintain entries and restrictions; approver-limit behaviour; and — if hybrid is chosen — the container-release-clears-child-restrictions interaction.
6. **Symbol revalidation.** Work through §16.5 and record pass/fail per symbol.
7. **Permission surface.** Confirm the target's permission sets grant the indirect permissions needed by `Approvals Mgmt.`, `Record Restriction Mgt.` and `Workflow Management`.
8. **Non-interactive contexts.** Confirm every `Confirm`/`Message` in the target's approval paths is `GuiAllowed`-guarded, and test the send/cancel/approve paths under job queue and web-service execution.

---

## 18. Evidence appendix — recommended standard symbols

Every symbol recommended above, with the file and line that proves its existence and accessibility in this snapshot. Cross-referenced in [07-standard-symbol-evidence-index.md](07-standard-symbol-evidence-index.md).

### 18.1 `Codeunit 1502 "Workflow Setup"` — [WorkflowSetup.Codeunit.al](../../../Base%20Application/System/Workflow/WorkflowSetup.Codeunit.al)

| Member | Line | Evidence proves |
| --- | --- | --- |
| object declaration `codeunit 1502 "Workflow Setup"` | L16 | ID and name; no `Access` property |
| `InitWorkflow()` | L140 | public |
| `InsertWorkflowTemplate(var Workflow; Code[17]; Text[100]; Code[20])` | L246 | public + signature |
| `ResetWorkflowTemplates()` | L256 | `internal` — do not call |
| `InsertApprovalsTableRelations()` | L283 | public |
| `OnAddWorkflowCategoriesToLibrary()` | L232 | `local` `[IntegrationEvent]` |
| `GeneralJournalBatchApprovalWorkflowCode()` | L1506 | public, GJ-specific |
| `GeneralJournalLineApprovalWorkflowCode()` | L1511 | public, GJ-specific |
| `InsertRecApprovalWorkflowSteps(...)` | L1610 | public + 9-parameter signature |
| `InsertGenJnlBatchApprovalWorkflowSteps(...)` | L1754 | public, GJ-specific |
| `InsertGenJnlLineApprovalWorkflowSteps(...)` | L1835 | public, GJ-specific |
| `InsertEntryPointEventStep` / `InsertEventStep` / `InsertResponseStep` | L2205 / L2215 / L2226 | public |
| `MarkWorkflowAsTemplate` | L2245 | public |
| `SetNextStep` | L2261 | public |
| `InsertTableRelation` | L2270 | public |
| `InsertWorkflowCategory` | L2284 | public |
| `InsertNotificationArgument` | L2334 | public |
| `InsertApprovalArgument` | L2358 | public + enum parameter types |
| `GetWorkflowTemplateCode` / `GetWorkflowTemplateToken` | L2419 / L2424 | public |
| `BuildNoPendingApprovalsConditions` / `BuildPendingApprovalsConditions` | L2473 / L2481 | public |
| `BuildGeneralJournalBatchTypeConditions()` | L2567 | **`local`** |
| `BuildGeneralJournalLineTypeConditions(var GenJournalLine)` | L2579 | public, GJ-specific |
| `OnAfterInitWorkflowTemplates()` | L2659 | `local` `[IntegrationEvent]` |
| `OnAfterInsertApprovalsTableRelations()` | L2664 | `local` `[IntegrationEvent]` |

### 18.2 `Codeunit 1520 "Workflow Event Handling"` — [WorkflowEventHandling.Codeunit.al](../../../Base%20Application/System/Workflow/WorkflowEventHandling.Codeunit.al)

| Member | Line | Evidence proves |
| --- | --- | --- |
| object declaration | L19 | ID and name |
| `CreateEventsLibrary()` | L83 | public |
| `AddEventToLibrary(Code[128]; Integer; Text[250]; Integer; Boolean)` | L323 | public + signature |
| `AddEventPredecessor(Code[128]; Code[128])` | L351 | public + signature |
| `OnAddWorkflowEventsToLibrary()` | L364 | `local` `[IntegrationEvent]` |
| `OnAddWorkflowEventPredecessorsToLibrary(Code[128])` | L369 | `local` `[IntegrationEvent]` |
| `RunWorkflowOnApproveApprovalRequestCode()` | L468 | public, domain-neutral |
| `RunWorkflowOnDelegateApprovalRequestCode()` | L473 | public, domain-neutral |
| `RunWorkflowOnRejectApprovalRequestCode()` | L478 | public, domain-neutral |
| `RunWorkflowOnSendGeneralJournalBatchForApprovalCode()` | L528 | public, GJ-specific |
| `RunWorkflowOnCancelGeneralJournalBatchApprovalRequestCode()` | L533 | public, GJ-specific |
| `RunWorkflowOnSendGeneralJournalLineForApprovalCode()` | L538 | public, GJ-specific |
| `RunWorkflowOnCancelGeneralJournalLineApprovalRequestCode()` | L543 | public, GJ-specific |
| `RunWorkflowOnGeneralJournalBatchBalancedCode()` | L548 | public, GJ-specific |
| `RunWorkflowOnGeneralJournalBatchNotBalancedCode()` | L553 | public, GJ-specific |
| GJ event subscribers | L836–L870 (Session 2/3) | forwarding pattern to `HandleEvent` |

### 18.3 `Codeunit 1521 "Workflow Response Handling"` — [WorkflowResponseHandling.Codeunit.al](../../../Base%20Application/System/Workflow/WorkflowResponseHandling.Codeunit.al)

| Member | Line | Evidence proves |
| --- | --- | --- |
| object declaration | L17 | ID and name |
| `CreateResponsesLibrary()` | L95 | public |
| `OnAddWorkflowResponsesToLibrary()` | L355 | `local` `[IntegrationEvent]` |
| `OnAddWorkflowResponsePredecessorsToLibrary(Code[128])` | L360 | `local` `[IntegrationEvent]` |
| `ExecuteResponse(var Variant; Workflow Step Instance; Variant)` | L365 | public dispatcher |
| `OnExecuteWorkflowResponse(var Boolean; var Variant; Variant; Workflow Step Instance)` | L470 | `local` `[IntegrationEvent]` — custom-response hook |
| `OpenDocumentCode()` | L489 | public |
| `CreateApprovalRequestsCode()` | L504 | public |
| `SendApprovalRequestForApprovalCode()` | L509 | public |
| `RejectAllApprovalRequestsCode()` | L519 | public |
| `CancelAllApprovalRequestsCode()` | L524 | public |
| `CheckGeneralJournalBatchBalanceCode()` | L559 | public, GJ-specific |
| `ShowMessageCode()` | L569 | public |
| `RestrictRecordUsageCode()` | L574 | public |
| `AllowRecordUsageCode()` | L579 | public |
| `AddResponseToLibrary(Code[128]; Integer; Text[250]; Code[20])` | L1110 | public + signature |
| `AddResponsePredecessor(Code[128]; Code[128])` | L1139 | public + signature |

### 18.4 `Codeunit 1501 "Workflow Management"` — [WorkflowManagement.Codeunit.al](../../../Base%20Application/System/Workflow/WorkflowManagement.Codeunit.al)

| Member | Line |
| --- | --- |
| object declaration | L7 |
| `CanExecuteWorkflow(Variant; Code[128])` | L61 |
| `WorkflowExists(Variant; Variant; Code[128])` | L264 |
| `HandleEvent(Code[128]; Variant)` | L489 |
| `HandleEventWithxRec(Code[128]; Variant; Variant)` | L494 |
| `HandleEventOnKnownWorkflowInstance(Code[128]; Variant; Guid)` | L528 |
| `HandleEventWithxRecOnKnownWorkflowInstance(...)` | L533 |
| `ExecuteResponses(Variant; Variant; Workflow Step Instance)` | L575 |
| `EnabledWorkflowExist(Integer; Text)` | L748 |

### 18.5 `Codeunit 1535 "Approvals Mgmt."` — [ApprovalsMgmt.Codeunit.al](../../../Base%20Application/OtherCapabilities/Approvals/ApprovalsMgmt.Codeunit.al)

| Member | Line | Evidence proves |
| --- | --- | --- |
| object declaration `codeunit 1535 "Approvals Mgmt."` | L28 | **ID 1535** (corrects Session 2's `134`) |
| `OnSendGeneralJournalBatchForApproval` | L157 | `[IntegrationEvent(false,false)]`, non-`local` |
| `OnCancelGeneralJournalBatchApprovalRequest` | L162 | same |
| `OnSendGeneralJournalLineForApproval` | L167 | same |
| `OnCancelGeneralJournalLineApprovalRequest` | L172 | same |
| `OnApproveApprovalRequest` | L197 | `local` `[IntegrationEvent]` |
| `OnRejectApprovalRequest` | L202 | `local` `[IntegrationEvent]` |
| `OnDelegateApprovalRequest` | L207 | `local` `[IntegrationEvent]` |
| `ApproveGenJournalLineRequest` | L262 | public, GJ-specific |
| `RejectGenJournalLineRequest` | L306 | public, GJ-specific |
| `DelegateGenJournalLineRequest` | L350 | public, GJ-specific |
| `FindOpenApprovalEntryForCurrUser` | L546 | public |
| `SendApprovalRequestFromRecord` | L714 | public |
| `SendApprovalRequestFromApprovalEntry` | L757 | public |
| `CreateApprovalRequests` | L794 | public |
| `MakeApprovalEntry` | L1092 | public |
| `PopulateApprovalEntryArgument` | L1188 | public; GJ case arms at L1245–L1266 |
| `CreateApprovalEntryNotification` | L1290 | public |
| `IsSufficientApprover` | L1450 | public; batch chain unsupported |
| `IsGeneralJournalBatchApprovalsWorkflowEnabled` | L1576 | public, GJ-specific |
| `IsGeneralJournalLineApprovalsWorkflowEnabled` | L1589 | public, GJ-specific |
| `CheckGeneralJournalBatchApprovalsWorkflowEnabled` | L1720 | public, GJ-specific |
| `CheckGeneralJournalLineApprovalsWorkflowEnabled` | L1731 | public, GJ-specific |
| `PostApprovalEntries(RecordID; RecordID; Code[20])` | L1884 | public |
| `GetApprovalComment(Variant)` | L2037 | public |
| `HasOpenApprovalEntriesForCurrentUser(RecordID)` | L2117 | public |
| `HasOpenApprovalEntries(RecordID)` | L2136 | public |
| `HasApprovedApprovalEntries(RecordID)` | L2186 | public |
| `HasAnyOpenJournalLineApprovalEntries(Code[20]; Code[20])` | L2224 | public, GJ-specific |
| `TrySendJournalBatchApprovalRequest(var Gen. Journal Line)` | L2267 | public, GJ-specific |
| `TrySendJournalLineApprovalRequests` | L2283 | public, GJ-specific |
| `TryCancelJournalBatchApprovalRequest` | L2299 | public, GJ-specific; **no sender check inside** |
| `TryCancelJournalLineApprovalRequests` | L2309 | public, GJ-specific |
| `ShowJournalApprovalEntries` | L2321 | public, GJ-specific |
| `GetGeneralJournalBatch` | L2334 | **`local`** |
| `RenameApprovalEntries(RecordID; RecordID)` | L2435 | public |
| `DeleteApprovalEntries(RecordID)` | L2455 | public |
| `GetLastSequenceNo(Approval Entry)` | L2515 | public |
| `CanCancelApprovalForRecord(RecordID)` | L2595 | public |
| `PreventDeletingRecordWithOpenApprovalEntry(Variant)` | L2706 | public, `Variant`-based |
| `PreventInsertRecIfOpenApprovalEntryExist(Variant)` | L2748 | public, `Variant`-based |
| `PreventModifyRecIfOpenApprovalEntryExistForCurrentUser(Variant)` | L2836 | public, `Variant`-based |
| `SendJournalLinesApprovalRequests` | L2875 | public, GJ-specific |
| `GetGenJnlBatchApprovalStatus` / `GetGenJnlLineApprovalStatus` | L2900 / L2918 | public, GJ-specific |
| `GetApprovalStatusFromApprovalEntry` overloads | L2987, L3017, L3035, L3059 | **`local`** |
| `CleanGenJournalApprovalStatus` | L3101 | public, GJ-specific |

### 18.6 `Codeunit 1550 "Record Restriction Mgt."` — [RecordRestrictionMgt.Codeunit.al](../../../Base%20Application/System/Workflow/RecordRestrictionMgt.Codeunit.al)

| Member | Line | Evidence proves |
| --- | --- | --- |
| object declaration | L16 | ID 1550 |
| `RestrictRecordUsage(Variant; Text)` | L32 | public |
| `AllowGenJournalBatchUsage(Gen. Journal Batch)` | L56 | public, GJ-specific cascade |
| `AllowRecordUsage(Variant)` | L112 | public; deletes all rows for the record |
| `UpdateRestriction(Variant; Variant)` | L131 | public |
| `RestrictGenJournalLine(var Gen. Journal Line)` | L166 | **`local`** |
| `CheckRecordHasUsageRestrictions(Variant)` | L289 | public `TryFunction` |
| GJ post/print/export restriction subscribers | L360–L556 (Session 3/4) | the four post-restriction subscribers and their `IsHandled` hooks |

### 18.7 `Codeunit 1543 "Workflow Webhook Management"` — [WorkflowWebhookManagement.Codeunit.al](../../../Base%20Application/System/Workflow/WorkflowWebhookManagement.Codeunit.al)

| Member | Line | Evidence proves |
| --- | --- | --- |
| object declaration | L14 | ID 1543 |
| `GetCanRequestAndCanCancel(RecordID; var Boolean; var Boolean)` | L76 | public, untraced |
| `GetCanRequestAndCanCancelJournalBatch(...)` | L89 | public, GJ-specific, untraced |
| `HasPendingWorkflowWebhookEntryByRecordId(RecordID)` | L381 | public, untraced |
| `FindAndCancel(RecordID)` / `FindAndCancel(RecordID; Boolean)` | L419 / L424 | public, untraced |

### 18.8 Table-published events

| Symbol | File | Line | Evidence proves |
| --- | --- | --- | --- |
| `Gen. Journal Batch.OnGeneralJournalBatchBalanced` | [GenJournalBatch.Table.al](../../../Base%20Application/Finance/GeneralLedger/Journal/GenJournalBatch.Table.al) | L505 | `[IntegrationEvent(true,false)] local` |
| `Gen. Journal Batch.OnGeneralJournalBatchNotBalanced` | same | L514 | `[IntegrationEvent(true,false)] local` |
| `Gen. Journal Batch.OnCheckGenJournalLineExportRestrictions` | same | L520 | `[IntegrationEvent(true,false)]`, non-`local`, **no `Scope`** |
| `Gen. Journal Batch.OnMoveGenJournalBatch(RecordID)` | same | L526 | `[IntegrationEvent(true,false)]` **+ `[Scope('OnPrem')]`** |
| `Gen. Journal Line.OnCheckGenJournalLinePostRestrictions` | [GenJournalLine.Table.al](../../../Base%20Application/Finance/GeneralLedger/Journal/GenJournalLine.Table.al) | L7585 | `[IntegrationEvent(true,false)]` **+ `[Scope('OnPrem')]`** |
| `Gen. Journal Line.OnCheckGenJournalLinePrintCheckRestrictions` | same | L7591 | `[IntegrationEvent(true,false)]` **+ `[Scope('OnPrem')]`** |
| `Gen. Journal Line.OnCheckGenJournalLineExportRestrictions` | same | L7596 | `[IntegrationEvent(true,false)]`, **no `Scope`** |
| `Gen. Jnl.-Post Line.OnMoveGenJournalLine` | [GenJnlPostLine.Codeunit.al](../../../Base%20Application/Finance/GeneralLedger/Posting/GenJnlPostLine.Codeunit.al) | (declaration inspected) | `[IntegrationEvent(false,false)] local` |

### 18.9 Tables and enums

| Symbol | File | Evidence proves |
| --- | --- | --- |
| `table 454 "Approval Entry"` | [ApprovalEntry.Table.al](../../../Base%20Application/OtherCapabilities/Approvals/ApprovalEntry.Table.al) | ID/name; no `Access` property; fields and `Key2`/`Key3`/`Key7` per Session 3 |
| `table 455 "Approval Comment Line"` | [ApprovalCommentLine.Table.al](../../../Base%20Application/OtherCapabilities/Approvals/ApprovalCommentLine.Table.al) | ID/name |
| `table 456 "Posted Approval Entry"` | [PostedApprovalEntry.Table.al](../../../Base%20Application/System/Workflow/PostedApprovalEntry.Table.al) | ID/name |
| `table 457 "Posted Approval Comment Line"` | [PostedApprovalCommentLine.Table.al](../../../Base%20Application/System/Workflow/PostedApprovalCommentLine.Table.al) | ID/name |
| `table 467 "Workflow Webhook Entry"` | [WorkflowWebhookEntry.Table.al](../../../Base%20Application/System/Workflow/WorkflowWebhookEntry.Table.al) | ID/name |
| `table 1501 Workflow` | [Workflow.Table.al](../../../Base%20Application/System/Workflow/Workflow.Table.al) | ID/name (unquoted) |
| `table 1502 "Workflow Step"` | [WorkflowStep.Table.al](../../../Base%20Application/System/Workflow/WorkflowStep.Table.al) | ID/name |
| `table 1504 "Workflow Step Instance"` | [WorkflowStepInstance.Table.al](../../../Base%20Application/System/Workflow/WorkflowStepInstance.Table.al) | ID/name |
| `table 1505 "Workflow - Table Relation"` | [WorkflowTableRelation.Table.al](../../../Base%20Application/System/Workflow/WorkflowTableRelation.Table.al) | ID/name |
| `table 1508 "Workflow Category"` | [WorkflowCategory.Table.al](../../../Base%20Application/System/Workflow/WorkflowCategory.Table.al) | ID/name |
| `table 1509 "WF Event/Response Combination"` | [WFEventResponseCombination.Table.al](../../../Base%20Application/System/Workflow/WFEventResponseCombination.Table.al) | ID/name |
| `table 1511 "Notification Entry"` | [NotificationEntry.Table.al](../../../Base%20Application/System/Notifications/NotificationEntry.Table.al) | ID/name |
| `table 1520 "Workflow Event"` | [WorkflowEvent.Table.al](../../../Base%20Application/System/Workflow/WorkflowEvent.Table.al) | ID/name |
| `table 1521 "Workflow Response"` | [WorkflowResponse.Table.al](../../../Base%20Application/System/Workflow/WorkflowResponse.Table.al) | ID/name |
| `table 1523 "Workflow Step Argument"` | [WorkflowStepArgument.Table.al](../../../Base%20Application/System/Workflow/WorkflowStepArgument.Table.al) | ID/name |
| `table 1550 "Restricted Record"` | [RestrictedRecord.Table.al](../../../Base%20Application/System/Workflow/RestrictedRecord.Table.al) | **ID 1550** |
| `table 91 "User Setup"` | [UserSetup.Table.al](../../../Base%20Application/System/User/UserSetup.Table.al) | ID/name |
| `enum 460 "Workflow Approver Type"` | [WorkflowApproverType.Enum.al](../../../Base%20Application/System/Workflow/WorkflowApproverType.Enum.al) | `Extensible = true`; values 0–2 |
| `enum 465 "Workflow Approver Limit Type"` | [WorkflowApproverLimitType.Enum.al](../../../Base%20Application/System/Workflow/WorkflowApproverLimitType.Enum.al) | `Extensible = true`; values 0–3 |
| `Enum "Approval Status"` | [ApprovalStatus.Enum.al](../../../Base%20Application/OtherCapabilities/Approvals/ApprovalStatus.Enum.al) | ordinals per Session 3 |

### 18.10 Posting objects

| Symbol | File | Line |
| --- | --- | --- |
| `codeunit 11 "Gen. Jnl.-Check Line"` | [GenJnlCheckLine.Codeunit.al](../../../Base%20Application/Finance/GeneralLedger/Journal/GenJnlCheckLine.Codeunit.al) | L11 region |
| `codeunit 12 "Gen. Jnl.-Post Line"` | [GenJnlPostLine.Codeunit.al](../../../Base%20Application/Finance/GeneralLedger/Posting/GenJnlPostLine.Codeunit.al) | L74 |
| `codeunit 13 "Gen. Jnl.-Post Batch"` | [GenJnlPostBatch.Codeunit.al](../../../Base%20Application/Finance/GeneralLedger/Posting/GenJnlPostBatch.Codeunit.al) | L37 |
| `codeunit 231 "Gen. Jnl.-Post"` | [GenJnlPost.Codeunit.al](../../../Base%20Application/Finance/GeneralLedger/Posting/GenJnlPost.Codeunit.al) | — |
| `codeunit 232 "Gen. Jnl.-Post+Print"` | [GenJnlPostPrint.Codeunit.al](../../../Base%20Application/Finance/GeneralLedger/Posting/GenJnlPostPrint.Codeunit.al) | — |
| `codeunit 233 "Gen. Jnl.-B.Post"` | [GenJnlBPost.Codeunit.al](../../../Base%20Application/Finance/GeneralLedger/Posting/GenJnlBPost.Codeunit.al) | — |
| `codeunit 234 "Gen. Jnl.-B.Post+Print"` | [GenJnlBPostPrint.Codeunit.al](../../../Base%20Application/Finance/GeneralLedger/Posting/GenJnlBPostPrint.Codeunit.al) | — |
| `codeunit 250 "Gen. Jnl.-Post via Job Queue"` | [GenJnlPostviaJobQueue.Codeunit.al](../../../Base%20Application/Finance/GeneralLedger/Posting/GenJnlPostviaJobQueue.Codeunit.al) | — |
| `codeunit 2 "Company-Initialize"` | [CompanyInitialize.Codeunit.al](../../../Base%20Application/Foundation/Company/CompanyInitialize.Codeunit.al) | **ID 2** (corrects Session 2's `1`) |
| `codeunit 1536 "Approvals Journal Line Request"` | [ApprovalsJournalLineRequest.Codeunit.al](../../../Base%20Application/OtherCapabilities/Approvals/ApprovalsJournalLineRequest.Codeunit.al) | L9 |
| `codeunit 1540 "Workflow Webhook Setup"` | [WorkflowWebhookSetup.Codeunit.al](../../../Base%20Application/System/Workflow/WorkflowWebhookSetup.Codeunit.al) | L5 |
| `codeunit 1804 "Approval Workflow Setup Mgt."` | [ApprovalWorkflowSetupMgt.Codeunit.al](../../../Base%20Application/System/Workflow/ApprovalWorkflowSetupMgt.Codeunit.al) | — |
| `page 39 "General Journal"` | [GeneralJournal.Page.al](../../../Base%20Application/Finance/GeneralLedger/Journal/GeneralJournal.Page.al) | — |
| `page 251 "General Journal Batches"` | [GeneralJournalBatches.Page.al](../../../Base%20Application/Finance/GeneralLedger/Journal/GeneralJournalBatches.Page.al) | — |

---

### Next-session handoff

- Facts established:
  - `Approvals Mgmt.` is **codeunit 1535** and `Company-Initialize` is **codeunit 2**; Session 2 recorded `134` and `1` respectively.
  - `Workflow Setup.BuildGeneralJournalBatchTypeConditions` is `local`, so Session 2's recommendation to call it from a target extension is not executable.
  - `Gen. Journal Line.OnCheckGenJournalLinePostRestrictions`, `OnCheckGenJournalLinePrintCheckRestrictions` and `Gen. Journal Batch.OnMoveGenJournalBatch` carry `[Scope('OnPrem')]`; `OnCheckGenJournalLineExportRestrictions` does not.
  - Codeunits 1501, 1502, 1520, 1521, 1535, 1550 and table 454 declare no `Access` property, so they default to public in this snapshot.
  - `Enum 460 "Workflow Approver Type"` and `Enum 465 "Workflow Approver Limit Type"` are `Extensible = true`.
  - The generic approval skeleton (`InsertRecApprovalWorkflowSteps`), the generic responses, the approve/reject/delegate event codes, the `RecordId`-based approval probes, the prevent-modify/insert/delete guards and the whole `Record Restriction Mgt.` lock API are domain-neutral and directly reusable.
  - Everything named `…GeneralJournal…` / `…GenJnl…` on those same codeunits is General Journal-specific and must be reproduced, not called.
- Standard symbols verified: see §18 — codeunits 2, 11, 12, 13, 231, 232, 233, 234, 250, 1501, 1502, 1520, 1521, 1535, 1536, 1540, 1543, 1550, 1804; tables 81, 91, 232, 454, 455, 456, 457, 467, 1501, 1502, 1504, 1505, 1508, 1509, 1511, 1520, 1521, 1523, 1550; pages 39, 251; enums 460, 465, `Approval Status`.
- Target-specific symbols verified: none. No target repository was in scope this session; the blueprint in §11 uses placeholders and assigns no object IDs.
- Important interpretations:
  - The child/line subject is the recommended default; hybrid should be avoided unless the business demands it, because of the unresolved container-release-clears-child-restrictions interaction.
  - The enforceable lock is `Restricted Record`, not `Approval Entry.Status`.
  - Standard General Journal places authorisation for cancel in page `Enabled` rather than in AL; a target should not copy that.
  - Because `InitWorkflow` is re-asserted on every Workflows page open, library registration needs no install codeunit, but shipping a template does.
- Unresolved questions:
  - Webhook path (`Codeunit 1540`, `Codeunit 1543`, `Table 467`) — still untraced.
  - Whether a cloud-target extension can subscribe to the `[Scope('OnPrem')]` restriction/move events.
  - Whether `Approvals Mgmt.PopulateApprovalEntryArgument` exposes a supported hook for foreign tables to add document/amount data.
  - `IsSufficientApprover` behaviour for a foreign subject table.
  - Whether final container approval clearing child restrictions is intentional.
  - Non-`GuiAllowed`-guarded `Confirm`/`Message` behaviour in background contexts.
- Version-sensitive findings:
  - `[Scope('OnPrem')]` on three General Journal events.
  - `BuildNoPendingApprovalsConditions` / `BuildPendingApprovalsConditions` are coupled to the `Approval Entry."Pending Approvals"` FlowField definition.
  - `Approval Status` ordinals are consumed positionally.
  - Template codes `MS-GJBAPW` / `MS-GJLAPW`, category `FIN`, response option groups `GROUP 0/2/4/5` are snapshot literals.
  - `Codeunit 1804` is `[Scope('OnPrem')]` throughout in this snapshot.
  - `Approval Entry` field numbering jumps 23 → 26 in this version.
- Files that provide the strongest evidence:
  - Base Application/System/Workflow/WorkflowSetup.Codeunit.al
  - Base Application/System/Workflow/WorkflowEventHandling.Codeunit.al
  - Base Application/System/Workflow/WorkflowResponseHandling.Codeunit.al
  - Base Application/System/Workflow/WorkflowManagement.Codeunit.al
  - Base Application/System/Workflow/RecordRestrictionMgt.Codeunit.al
  - Base Application/OtherCapabilities/Approvals/ApprovalsMgmt.Codeunit.al
  - Base Application/OtherCapabilities/Approvals/ApprovalEntry.Table.al
  - Base Application/Finance/GeneralLedger/Journal/GenJournalLine.Table.al
  - Base Application/Finance/GeneralLedger/Journal/GenJournalBatch.Table.al
  - Base Application/Finance/GeneralLedger/Posting/GenJnlPostBatch.Codeunit.al
  - Base Application/Finance/GeneralLedger/Journal/GeneralJournal.Page.al
  - Tests-General Journal/GeneralJournalLineApproval.Codeunit.al
  - Tests-General Journal/GeneralJournalBatchApproval.Codeunit.al
- Documents created:
  - .design/architecture/general-journal-approvals/01-object-and-accessibility-inventory.md
  - .design/architecture/general-journal-approvals/06-business-central-extension-handoff.md
  - .design/architecture/general-journal-approvals/07-standard-symbol-evidence-index.md
  - .design/architecture/general-journal-approvals/08-unresolved-and-version-sensitive-findings.md
- Recommended scope for the next session:
  - Move to the **target repository** and execute §17 items 1–3: manifest scope, subject-candidate analysis against §14, and identification of the target's deepest shared processing guard. Produce a target-side design document that names concrete target objects and answers the approval-subject decision. Do not resume Base Application discovery unless §16.5 revalidation fails.
