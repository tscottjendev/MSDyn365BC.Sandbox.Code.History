# General Journal Approvals — Session 5: Object and accessibility inventory

Companion to [06-business-central-extension-handoff.md](06-business-central-extension-handoff.md). Evidence index: [07-standard-symbol-evidence-index.md](07-standard-symbol-evidence-index.md). Open risks: [08-unresolved-and-version-sensitive-findings.md](08-unresolved-and-version-sensitive-findings.md).

## 0. Analysed environment and version scope

| Item | Value | Source |
| --- | --- | --- |
| Repository branch | `gb-29-vNext` | local Git state |
| Commit | `a74fec3ec909d` | local Git state |
| Application snapshot | `29.0.53247.0` | `version.txt` / app manifests, per Session 1 |
| Platform version in manifests | `29.0.0.0` | Session 1 |
| Country/region | GB | `version.txt`, app brief text |
| Apps inspected as source | Base Application, System Application, Application, Tests-General Journal, Tests-Workflow | Session 1 |

All classifications below describe **this snapshot only**. A receiving extension compiles against its own symbol set and must revalidate every symbol listed here (see [08](08-unresolved-and-version-sensitive-findings.md) §4).

## 1. Accessibility categories used

| Category | Meaning in this inventory |
| --- | --- |
| **Public supported dependency** | Non-`local`, non-`internal`, non-`OnPrem`-scoped member on a non-`Access = Internal` object. A dependent extension can call it directly. |
| **Published extension point** | `[IntegrationEvent]`/`[BusinessEvent]` publisher, or a publisher-plus-`IsHandled` pattern, intended to be subscribed to. |
| **Accessible data contract** | Table, field, key or enum that the target can read, filter, extend or reference, but that it should not write to on Microsoft's behalf. |
| **Observable but inaccessible implementation** | Readable in source but `local`, `internal`, or page-scoped; not callable from a dependent extension. |
| **General Journal-specific implementation** | Technically reachable, but hard-codes `Gen. Journal Batch` / `Gen. Journal Line` structure. Not portable to another domain. |
| **Version-sensitive or uncertain** | Accessibility, scope, or behaviour is snapshot-dependent, `[Scope('OnPrem')]`-restricted, or was not fully traced in sessions 1–4. |

## 2. Standard component inventory by object type

### 2.1 Codeunits

| ID | Name | Namespace / app | File | Role in the General Journal approval flow |
| --- | --- | --- | --- | --- |
| 2 | `Company-Initialize` | Foundation, Base Application | [CompanyInitialize.Codeunit.al](../../../Base%20Application/Foundation/Company/CompanyInitialize.Codeunit.al) | Calls `Workflow Setup.InitWorkflow()` once during company initialisation. |
| 11 | `Gen. Jnl.-Check Line` | Base Application | [GenJnlCheckLine.Codeunit.al](../../../Base%20Application/Finance/GeneralLedger/Journal/GenJnlCheckLine.Codeunit.al) | Line validation invoked by both posting engines; **not** the restriction guard. |
| 12 | `Gen. Jnl.-Post Line` | Base Application | [GenJnlPostLine.Codeunit.al](../../../Base%20Application/Finance/GeneralLedger/Posting/GenJnlPostLine.Codeunit.al) | Low-level ledger posting engine. Publishes `OnMoveGenJournalLine`. Does not raise the post-restriction event. |
| 13 | `Gen. Jnl.-Post Batch` | Base Application | [GenJnlPostBatch.Codeunit.al](../../../Base%20Application/Finance/GeneralLedger/Posting/GenJnlPostBatch.Codeunit.al) | **Deepest shared posting guard**: `CheckLine` → `CheckRestrictions` → `OnCheckGenJournalLinePostRestrictions`. |
| 231 | `Gen. Jnl.-Post` | Base Application | [GenJnlPost.Codeunit.al](../../../Base%20Application/Finance/GeneralLedger/Posting/GenJnlPost.Codeunit.al) | UI-facing post wrapper; preview binding; job-queue dispatch. |
| 232 | `Gen. Jnl.-Post+Print` | Base Application | [GenJnlPostPrint.Codeunit.al](../../../Base%20Application/Finance/GeneralLedger/Posting/GenJnlPostPrint.Codeunit.al) | Post-and-print wrapper. |
| 233 | `Gen. Jnl.-B.Post` | Base Application | [GenJnlBPost.Codeunit.al](../../../Base%20Application/Finance/GeneralLedger/Posting/GenJnlBPost.Codeunit.al) | Multi-batch post from Page 251. |
| 234 | `Gen. Jnl.-B.Post+Print` | Base Application | [GenJnlBPostPrint.Codeunit.al](../../../Base%20Application/Finance/GeneralLedger/Posting/GenJnlBPostPrint.Codeunit.al) | Multi-batch post-and-print. |
| 250 | `Gen. Jnl.-Post via Job Queue` | Base Application | [GenJnlPostviaJobQueue.Codeunit.al](../../../Base%20Application/Finance/GeneralLedger/Posting/GenJnlPostviaJobQueue.Codeunit.al) | Background posting; runs `Gen. Jnl.-Post Batch`, so the guard still applies at execution time. |
| 1501 | `Workflow Management` | System.Automation, Base Application | [WorkflowManagement.Codeunit.al](../../../Base%20Application/System/Workflow/WorkflowManagement.Codeunit.al) | Generic engine: `HandleEvent`, `HandleEventOnKnownWorkflowInstance`, `CanExecuteWorkflow`, `EnabledWorkflowExist`, `ExecuteResponses`. |
| 1502 | `Workflow Setup` | System.Automation, Base Application | [WorkflowSetup.Codeunit.al](../../../Base%20Application/System/Workflow/WorkflowSetup.Codeunit.al) | Library/template registration and the reusable step-builder helpers. |
| 1520 | `Workflow Event Handling` | System.Automation, Base Application | [WorkflowEventHandling.Codeunit.al](../../../Base%20Application/System/Workflow/WorkflowEventHandling.Codeunit.al) | Event library, GJ event-code getters, GJ event subscribers. |
| 1521 | `Workflow Response Handling` | System.Automation, Base Application | [WorkflowResponseHandling.Codeunit.al](../../../Base%20Application/System/Workflow/WorkflowResponseHandling.Codeunit.al) | Response library, response-code getters, `ExecuteResponse` dispatch. |
| 1535 | `Approvals Mgmt.` | Base Application | [ApprovalsMgmt.Codeunit.al](../../../Base%20Application/OtherCapabilities/Approvals/ApprovalsMgmt.Codeunit.al) | Approval-entry lifecycle, GJ send/cancel/approve/reject/delegate entry points, GJ approval status helpers. |
| 1536 | `Approvals Journal Line Request` | Base Application | [ApprovalsJournalLineRequest.Codeunit.al](../../../Base%20Application/OtherCapabilities/Approvals/ApprovalsJournalLineRequest.Codeunit.al) | Per-line worker used by `Batch Processing Mgt.` for multi-line send. |
| 1540 | `Workflow Webhook Setup` | System.Automation, Base Application | [WorkflowWebhookSetup.Codeunit.al](../../../Base%20Application/System/Workflow/WorkflowWebhookSetup.Codeunit.al) | Parallel webhook (Power Automate) workflow construction. Not fully traced. |
| 1543 | `Workflow Webhook Management` | System.Automation, Base Application | [WorkflowWebhookManagement.Codeunit.al](../../../Base%20Application/System/Workflow/WorkflowWebhookManagement.Codeunit.al) | Webhook request/cancel state queries used by Page 39 and by `Approvals Mgmt.` prevent-logic. |
| 1550 | `Record Restriction Mgt.` | System.Automation, Base Application | [RecordRestrictionMgt.Codeunit.al](../../../Base%20Application/System/Workflow/RecordRestrictionMgt.Codeunit.al) | `Restricted Record` upsert/removal/check and the GJ post/print/export restriction subscribers. |
| 1804 | `Approval Workflow Setup Mgt.` | System.Automation, Base Application | [ApprovalWorkflowSetupMgt.Codeunit.al](../../../Base%20Application/System/Workflow/ApprovalWorkflowSetupMgt.Codeunit.al) | Legacy wizard. Every inspected public procedure is `[Scope('OnPrem')]`. |

### 2.2 Tables

| ID | Name | File | Role |
| --- | --- | --- | --- |
| 81 | `Gen. Journal Line` | [GenJournalLine.Table.al](../../../Base%20Application/Finance/GeneralLedger/Journal/GenJournalLine.Table.al) | Line approval subject; publishes the restriction-check events. |
| 91 | `User Setup` | [UserSetup.Table.al](../../../Base%20Application/System/User/UserSetup.Table.al) | Approver resolution, substitute, approval-administrator flag, amount limits. |
| 232 | `Gen. Journal Batch` | [GenJournalBatch.Table.al](../../../Base%20Application/Finance/GeneralLedger/Journal/GenJournalBatch.Table.al) | Batch approval subject; publishes balanced/not-balanced and export/move events. |
| 454 | `Approval Entry` | [ApprovalEntry.Table.al](../../../Base%20Application/OtherCapabilities/Approvals/ApprovalEntry.Table.al) | The approval state store for both subjects. |
| 455 | `Approval Comment Line` | [ApprovalCommentLine.Table.al](../../../Base%20Application/OtherCapabilities/Approvals/ApprovalCommentLine.Table.al) | Comments keyed by `Table ID` + `Record ID to Approve` + `Workflow Step Instance ID`. |
| 456 | `Posted Approval Entry` | [PostedApprovalEntry.Table.al](../../../Base%20Application/System/Workflow/PostedApprovalEntry.Table.al) | Post-posting approval history. |
| 457 | `Posted Approval Comment Line` | [PostedApprovalCommentLine.Table.al](../../../Base%20Application/System/Workflow/PostedApprovalCommentLine.Table.al) | Post-posting comment history. |
| 467 | `Workflow Webhook Entry` | [WorkflowWebhookEntry.Table.al](../../../Base%20Application/System/Workflow/WorkflowWebhookEntry.Table.al) | Webhook approval state; participates in page enablement and prevent-logic. |
| 1501 | `Workflow` | [Workflow.Table.al](../../../Base%20Application/System/Workflow/Workflow.Table.al) | Workflow header / template record. |
| 1502 | `Workflow Step` | [WorkflowStep.Table.al](../../../Base%20Application/System/Workflow/WorkflowStep.Table.al) | Per-workflow ordered step chain. |
| 1504 | `Workflow Step Instance` | [WorkflowStepInstance.Table.al](../../../Base%20Application/System/Workflow/WorkflowStepInstance.Table.al) | Runtime instance; its `ID` is the approval correlation key. |
| 1505 | `Workflow - Table Relation` | [WorkflowTableRelation.Table.al](../../../Base%20Application/System/Workflow/WorkflowTableRelation.Table.al) | Subject-table → `Approval Entry."Record ID to Approve"` registry. |
| 1508 | `Workflow Category` | [WorkflowCategory.Table.al](../../../Base%20Application/System/Workflow/WorkflowCategory.Table.al) | `FIN` owns both GJ templates. |
| 1509 | `WF Event/Response Combination` | [WFEventResponseCombination.Table.al](../../../Base%20Application/System/Workflow/WFEventResponseCombination.Table.al) | Designer-level legality of event/response predecessors. |
| 1511 | `Notification Entry` | [NotificationEntry.Table.al](../../../Base%20Application/System/Notifications/NotificationEntry.Table.al) | Approver/sender notifications. |
| 1520 | `Workflow Event` | [WorkflowEvent.Table.al](../../../Base%20Application/System/Workflow/WorkflowEvent.Table.al) | Event library rows. |
| 1521 | `Workflow Response` | [WorkflowResponse.Table.al](../../../Base%20Application/System/Workflow/WorkflowResponse.Table.al) | Response library rows. |
| 1523 | `Workflow Step Argument` | [WorkflowStepArgument.Table.al](../../../Base%20Application/System/Workflow/WorkflowStepArgument.Table.al) | Approver type/limit, due date, conditions, messages, notification settings. |
| 1550 | `Restricted Record` | [RestrictedRecord.Table.al](../../../Base%20Application/System/Workflow/RestrictedRecord.Table.al) | **The enforceable usage lock.** |

### 2.3 Pages

| ID | Name | File | Role |
| --- | --- | --- | --- |
| 39 | `General Journal` | [GeneralJournal.Page.al](../../../Base%20Application/Finance/GeneralLedger/Journal/GeneralJournal.Page.al) | Approval action surface and derived status display. |
| 251 | `General Journal Batches` | [GeneralJournalBatches.Page.al](../../../Base%20Application/Finance/GeneralLedger/Journal/GeneralJournalBatches.Page.al) | Batch list, batch posting entry points. |

### 2.4 Enums

| ID | Name | Extensible | File |
| --- | --- | --- | --- |
| — | `Approval Status` | (declaration inspected in Session 3; ordinals `0 Created`, `1 Open`, `2 Canceled`, `3 Rejected`, `4 Approved`, `5 ' '`) | [ApprovalStatus.Enum.al](../../../Base%20Application/OtherCapabilities/Approvals/ApprovalStatus.Enum.al) |
| 460 | `Workflow Approver Type` | `Extensible = true` | [WorkflowApproverType.Enum.al](../../../Base%20Application/System/Workflow/WorkflowApproverType.Enum.al) |
| 465 | `Workflow Approver Limit Type` | `Extensible = true` | [WorkflowApproverLimitType.Enum.al](../../../Base%20Application/System/Workflow/WorkflowApproverLimitType.Enum.al) |

### 2.5 Test codeunits (behaviour contracts, not dependencies)

| ID | Name | File |
| --- | --- | --- |
| 134321 | `General Journal Batch Approval` | [GeneralJournalBatchApproval.Codeunit.al](../../../Tests-General%20Journal/GeneralJournalBatchApproval.Codeunit.al) |
| 134322 | `General Journal Line Approval` | [GeneralJournalLineApproval.Codeunit.al](../../../Tests-General%20Journal/GeneralJournalLineApproval.Codeunit.al) |
| 134323 | `Approval History Tests` | [ApprovalHistoryTests.Codeunit.al](../../../Tests-General%20Journal/ApprovalHistoryTests.Codeunit.al) |
| 134219 | `WFWH General Journal Batch` | [WFWHGeneralJournalBatch.Codeunit.al](../../../Tests-General%20Journal/WFWHGeneralJournalBatch.Codeunit.al) |
| 134220 | `WFWH General Journal Line` | [WFWHGeneralJournalLine.Codeunit.al](../../../Tests-General%20Journal/WFWHGeneralJournalLine.Codeunit.al) |

## 3. Member-level accessibility classification

Verified in this session by inspecting the declaration line of each member. `Access` / `Extensible` / `ObsoleteState` object-level properties were checked and are absent on codeunits 1501, 1502, 1520, 1521, 1535, 1550 and on table 454, so those objects default to public and extensible in this snapshot.

### 3.1 `Codeunit 1502 "Workflow Setup"`

| Member | Declaration | Category |
| --- | --- | --- |
| `InitWorkflow()` — L140 | `procedure` | Public supported dependency |
| `InsertWorkflowTemplate(var Workflow; Code[17]; Text[100]; Code[20])` — L246 | `procedure` | Public supported dependency |
| `InsertApprovalsTableRelations()` — L283 | `procedure` | Public supported dependency |
| `GeneralJournalBatchApprovalWorkflowCode()` — L1506 | `procedure` | General Journal-specific implementation (returns `'GJBAPW'`) |
| `GeneralJournalLineApprovalWorkflowCode()` — L1511 | `procedure` | General Journal-specific implementation (returns `'GJLAPW'`) |
| `InsertRecApprovalWorkflowSteps(...)` — L1610 | `procedure` | Public supported dependency |
| `InsertGenJnlBatchApprovalWorkflowSteps(...)` — L1754 | `procedure` | General Journal-specific implementation (public, but builds the GJ batch chain) |
| `InsertGenJnlLineApprovalWorkflowSteps(...)` — L1835 | `procedure` | General Journal-specific implementation (public) |
| `InsertEntryPointEventStep` / `InsertEventStep` / `InsertResponseStep` / `SetNextStep` — L2205, L2215, L2226, L2261 | `procedure` | Public supported dependency |
| `InsertNotificationArgument` — L2334, `InsertApprovalArgument` — L2358 | `procedure` | Public supported dependency |
| `MarkWorkflowAsTemplate` — L2245, `InsertTableRelation` — L2270, `InsertWorkflowCategory` — L2284 | `procedure` | Public supported dependency |
| `GetWorkflowTemplateCode` — L2419, `GetWorkflowTemplateToken` — L2424 | `procedure` | Public supported dependency |
| `BuildNoPendingApprovalsConditions()` — L2473, `BuildPendingApprovalsConditions()` — L2481 | `procedure` | Public supported dependency (**version-sensitive**: encoded `Approval Entry` views) |
| `BuildGeneralJournalLineTypeConditions(var GenJournalLine)` — L2579 | `procedure` | General Journal-specific implementation |
| `BuildGeneralJournalBatchTypeConditions()` — L2567 | **`local procedure`** | Observable but inaccessible implementation — **contradicts Session 2 §8/§9**, see [08](08-unresolved-and-version-sensitive-findings.md) §1 |
| `ResetWorkflowTemplates()` — L256 | `internal procedure` | Observable but inaccessible implementation |
| `OnAddWorkflowCategoriesToLibrary()` — L232 | `local` `[IntegrationEvent]` | Published extension point |
| `OnAfterInitWorkflowTemplates()` — L2659 | `local` `[IntegrationEvent]` | Published extension point |
| `OnAfterInsertApprovalsTableRelations()` — L2664 | `local` `[IntegrationEvent]` | Published extension point |

### 3.2 `Codeunit 1520 "Workflow Event Handling"`

| Member | Declaration | Category |
| --- | --- | --- |
| `CreateEventsLibrary()` — L83 | `procedure` | Public supported dependency (library population; normally not called by a target) |
| `AddEventToLibrary(...)` — L323, `AddEventPredecessor(...)` — L351 | `procedure` | Public supported dependency |
| `OnAddWorkflowEventsToLibrary()` — L364, `OnAddWorkflowEventPredecessorsToLibrary(Code[128])` — L369 | `local` `[IntegrationEvent]` | Published extension point |
| `RunWorkflowOnApproveApprovalRequestCode()` — L468 | `procedure` | Public supported dependency |
| `RunWorkflowOnDelegateApprovalRequestCode()` — L473 | `procedure` | Public supported dependency |
| `RunWorkflowOnRejectApprovalRequestCode()` — L478 | `procedure` | Public supported dependency |
| `RunWorkflowOnSendGeneralJournalBatchForApprovalCode()` — L528 | `procedure` | General Journal-specific implementation (public getter for a GJ event code) |
| `RunWorkflowOnCancelGeneralJournalBatchApprovalRequestCode()` — L533 | `procedure` | General Journal-specific implementation |
| `RunWorkflowOnSendGeneralJournalLineForApprovalCode()` — L538 | `procedure` | General Journal-specific implementation |
| `RunWorkflowOnCancelGeneralJournalLineApprovalRequestCode()` — L543 | `procedure` | General Journal-specific implementation |
| `RunWorkflowOnGeneralJournalBatchBalancedCode()` — L548 | `procedure` | General Journal-specific implementation |
| `RunWorkflowOnGeneralJournalBatchNotBalancedCode()` — L553 | `procedure` | General Journal-specific implementation |

### 3.3 `Codeunit 1521 "Workflow Response Handling"`

| Member | Declaration | Category |
| --- | --- | --- |
| `CreateResponsesLibrary()` — L95 | `procedure` | Public supported dependency |
| `ExecuteResponse(var Variant; Workflow Step Instance; xVariant)` — L365 | `procedure` | Public supported dependency |
| `AddResponseToLibrary(...)` — L1110, `AddResponsePredecessor(...)` — L1139 | `procedure` | Public supported dependency |
| `OnAddWorkflowResponsesToLibrary()` — L355, `OnAddWorkflowResponsePredecessorsToLibrary(Code[128])` — L360 | `local` `[IntegrationEvent]` | Published extension point |
| `OnExecuteWorkflowResponse(var Boolean; var Variant; Variant; Workflow Step Instance)` — L470 | `local` `[IntegrationEvent]` | Published extension point — **the hook for a custom response implementation** |
| `OpenDocumentCode()` — L489 | `procedure` | Public supported dependency |
| `CreateApprovalRequestsCode()` — L504 | `procedure` | Public supported dependency |
| `SendApprovalRequestForApprovalCode()` — L509 | `procedure` | Public supported dependency |
| `RejectAllApprovalRequestsCode()` — L519, `CancelAllApprovalRequestsCode()` — L524 | `procedure` | Public supported dependency |
| `ShowMessageCode()` — L569, `RestrictRecordUsageCode()` — L574, `AllowRecordUsageCode()` — L579 | `procedure` | Public supported dependency |
| `CheckGeneralJournalBatchBalanceCode()` — L559 | `procedure` | General Journal-specific implementation (only meaningful for table 232) |
| Response implementations (`CreateApprovalRequests`, `SendApprovalRequestForApproval`, `RestrictRecordUsage`, `AllowRecordUsage`, `RejectAllApprovalRequests`, `CancelAllApprovalRequests`, `CheckGeneralJournalBatchBalance`) | `local procedure` | Observable but inaccessible implementation |

### 3.4 `Codeunit 1535 "Approvals Mgmt."`

| Member | Declaration | Category |
| --- | --- | --- |
| `OnSendGeneralJournalBatchForApproval(var Gen. Journal Batch)` — L157 | `[IntegrationEvent(false,false)] procedure` (non-`local`) | Published extension point (also directly callable — bypasses the `Try...` guards) |
| `OnCancelGeneralJournalBatchApprovalRequest(...)` — L162 | same | Published extension point |
| `OnSendGeneralJournalLineForApproval(...)` — L167 | same | Published extension point |
| `OnCancelGeneralJournalLineApprovalRequest(...)` — L172 | same | Published extension point |
| `OnApproveApprovalRequest(var Approval Entry)` — L197 | `[IntegrationEvent(false,false)] local procedure` | Published extension point (subscribe only) |
| `OnRejectApprovalRequest(...)` — L202 | same | Published extension point (subscribe only) |
| `OnDelegateApprovalRequest(...)` — L207 | same | Published extension point (subscribe only) |
| `ApproveGenJournalLineRequest(Gen. Journal Line)` — L262 | `procedure` | General Journal-specific implementation (public) |
| `RejectGenJournalLineRequest(...)` — L306 | `procedure` | General Journal-specific implementation (public) |
| `DelegateGenJournalLineRequest(...)` — L350 | `procedure` | General Journal-specific implementation (public) |
| `FindOpenApprovalEntryForCurrUser(var Approval Entry; RecordID)` — L546 | `procedure` | Public supported dependency |
| `SendApprovalRequestFromRecord(RecordRef; Workflow Step Instance)` — L714 | `procedure` | Public supported dependency |
| `SendApprovalRequestFromApprovalEntry(Approval Entry; Workflow Step Instance)` — L757 | `procedure` | Public supported dependency |
| `CreateApprovalRequests(RecordRef; Workflow Step Instance)` — L794 | `procedure` | Public supported dependency |
| `MakeApprovalEntry(Approval Entry; Integer; Code[50]; Workflow Step Argument)` — L1092 | `procedure` | Public supported dependency |
| `PopulateApprovalEntryArgument(RecordRef; Workflow Step Instance; var Approval Entry)` — L1188 | `procedure` | Public supported dependency (its GJ case arms are General Journal-specific implementation) |
| `CreateApprovalEntryNotification(Approval Entry; Workflow Step Instance)` — L1290 | `procedure` | Public supported dependency |
| `IsSufficientApprover(User Setup; Approval Entry)` — L1450 | `procedure` | Public supported dependency (returns `true` with `ApporvalChainIsUnsupportedMsg` for table 232) |
| `IsGeneralJournalBatchApprovalsWorkflowEnabled(var Gen. Journal Batch)` — L1576 | `procedure` | General Journal-specific implementation (public) |
| `IsGeneralJournalLineApprovalsWorkflowEnabled(var Gen. Journal Line)` — L1589 | `procedure` | General Journal-specific implementation (public) |
| `CheckGeneralJournalBatchApprovalsWorkflowEnabled(var Gen. Journal Batch)` — L1720 | `procedure` | General Journal-specific implementation (public; errors when no workflow) |
| `CheckGeneralJournalLineApprovalsWorkflowEnabled(var Gen. Journal Line)` — L1731 | `procedure` | General Journal-specific implementation (public) |
| `PostApprovalEntries(RecordID; RecordID; Code[20])` — L1884 | `procedure` | Public supported dependency |
| `GetApprovalComment(Variant)` — L2037 | `procedure` | Public supported dependency |
| `HasOpenApprovalEntriesForCurrentUser(RecordID)` — L2117 | `procedure` | Public supported dependency |
| `HasOpenApprovalEntries(RecordID)` — L2136 | `procedure` | Public supported dependency |
| `HasApprovedApprovalEntries(RecordID)` — L2186 | `procedure` | Public supported dependency |
| `HasAnyOpenJournalLineApprovalEntries(Code[20]; Code[20])` — L2224 | `procedure` | General Journal-specific implementation (public) |
| `TrySendJournalBatchApprovalRequest(var Gen. Journal Line)` — L2267 | `procedure` | General Journal-specific implementation (public) |
| `TrySendJournalLineApprovalRequests(var Gen. Journal Line)` — L2283 | `procedure` | General Journal-specific implementation (public) |
| `TryCancelJournalBatchApprovalRequest(var Gen. Journal Line)` — L2299 | `procedure` | General Journal-specific implementation (public) |
| `TryCancelJournalLineApprovalRequests(var Gen. Journal Line)` — L2309 | `procedure` | General Journal-specific implementation (public) |
| `ShowJournalApprovalEntries(var Gen. Journal Line)` — L2321 | `procedure` | General Journal-specific implementation (public) |
| `GetGeneralJournalBatch(var Gen. Journal Batch; var Gen. Journal Line)` — L2334 | `local procedure` | Observable but inaccessible implementation |
| `RenameApprovalEntries(RecordID; RecordID)` — L2435 | `procedure` | Public supported dependency |
| `DeleteApprovalEntries(RecordID)` — L2455 | `procedure` | Public supported dependency |
| `GetLastSequenceNo(Approval Entry)` — L2515 | `procedure` | Public supported dependency |
| `CanCancelApprovalForRecord(RecordID)` — L2595 | `procedure` | Public supported dependency |
| `PreventDeletingRecordWithOpenApprovalEntry(Variant)` — L2706 | `procedure` | Public supported dependency |
| `PreventInsertRecIfOpenApprovalEntryExist(Variant)` — L2748 | `procedure` | Public supported dependency |
| `PreventModifyRecIfOpenApprovalEntryExistForCurrentUser(Variant)` — L2836 | `procedure` | Public supported dependency |
| `SendJournalLinesApprovalRequests(var Gen. Journal Line)` — L2875 | `procedure` | General Journal-specific implementation (public) |
| `GetGenJnlBatchApprovalStatus(...)` — L2900, `GetGenJnlLineApprovalStatus(...)` — L2918 | `procedure` | General Journal-specific implementation (public) |
| `GetApprovalStatusFromApprovalEntry(...)` overloads — L2987, L3017, L3035, L3059 | `local procedure` | Observable but inaccessible implementation |
| `CleanGenJournalApprovalStatus(...)` — L3101 | `procedure` | General Journal-specific implementation (public) |
| `ApproveSelectedApprovalRequest`, `RejectSelectedApprovalRequest`, `DelegateSelectedApprovalRequest`, `SubstituteUserIdForApprovalEntry`, `CheckOpenStatus`, `CheckUserAsApprovalAdministrator` | `local procedure` (Session 3 §9) | Observable but inaccessible implementation |

### 3.5 `Codeunit 1501 "Workflow Management"`

| Member | Declaration | Category |
| --- | --- | --- |
| `CanExecuteWorkflow(Variant; Code[128])` — L61 | `procedure` | Public supported dependency |
| `WorkflowExists(Variant; Variant; Code[128])` — L264 | `procedure` | Public supported dependency |
| `HandleEvent(Code[128]; Variant)` — L489 | `procedure` | Public supported dependency |
| `HandleEventWithxRec(Code[128]; Variant; Variant)` — L494 | `procedure` | Public supported dependency |
| `HandleEventOnKnownWorkflowInstance(Code[128]; Variant; Guid)` — L528 | `procedure` | Public supported dependency |
| `HandleEventWithxRecOnKnownWorkflowInstance(...)` — L533 | `procedure` | Public supported dependency |
| `ExecuteResponses(Variant; Variant; Workflow Step Instance)` — L575 | `procedure` | Public supported dependency |
| `EnabledWorkflowExist(Integer; Text)` — L748 | `procedure` | Public supported dependency |

### 3.6 `Codeunit 1550 "Record Restriction Mgt."`

| Member | Declaration | Category |
| --- | --- | --- |
| `RestrictRecordUsage(Variant; Text)` — L32 | `procedure` | Public supported dependency |
| `AllowGenJournalBatchUsage(Gen. Journal Batch)` — L56 | `procedure` | General Journal-specific implementation (public; clears the batch **and every line**) |
| `AllowRecordUsage(Variant)` — L112 | `procedure` | Public supported dependency |
| `UpdateRestriction(Variant; Variant)` — L131 | `procedure` | Public supported dependency |
| `RestrictGenJournalLine(var Gen. Journal Line)` — L166 | `local procedure` | Observable but inaccessible implementation |
| `CheckRecordHasUsageRestrictions(Variant)` — L289 | `procedure` (`[TryFunction]` per Session 4) | Public supported dependency |
| GJ post/print/export restriction subscribers with `OnBefore...(..., var IsHandled)` | `[EventSubscriber]` + publisher pattern | Published extension point (suppression hooks) |

### 3.7 `Codeunit 1543 "Workflow Webhook Management"`

| Member | Declaration | Category |
| --- | --- | --- |
| `CanCancel(Workflow Webhook Entry)` — L56 | `procedure` | Version-sensitive or uncertain |
| `CanRequestApproval(RecordID)` — L70 | `procedure` | Version-sensitive or uncertain |
| `GetCanRequestAndCanCancel(RecordID; var Boolean; var Boolean)` — L76 | `procedure` | Version-sensitive or uncertain |
| `GetCanRequestAndCanCancelJournalBatch(Gen. Journal Batch; var Boolean; var Boolean; var Boolean)` — L89 | `procedure` | General Journal-specific implementation + Version-sensitive or uncertain |
| `Cancel(...)` — L119/L124, `CancelByStepInstanceId(Guid)` — L137 | `procedure` | Version-sensitive or uncertain |
| `CanContinue` — L147, `CanReject` — L158, `Continue` — L169, `ContinueByStepInstanceId` — L180, `Reject` — L199, `RejectByStepInstanceId` — L211 | `procedure` | Version-sensitive or uncertain |
| `GenerateRequest(RecordRef; Workflow Step Instance)` — L190, `SendWebhookNotificaton(Workflow Step Instance)` — L221 | `procedure` | Version-sensitive or uncertain |
| `HasPendingWorkflowWebhookEntryByRecordId(RecordID)` — L381 | `procedure` | Version-sensitive or uncertain |
| `FindAndCancel(RecordID)` — L419 / `FindAndCancel(RecordID; Boolean)` — L424 | `procedure` | Version-sensitive or uncertain |
| `OnCancelWorkflow` — L42, `OnContinueWorkflow` — L47, `OnRejectWorkflow` — L52 | `local procedure` | Observable but inaccessible implementation |

### 3.8 Table-published events

| Publisher | Declaration | Category |
| --- | --- | --- |
| `Gen. Journal Batch.OnGeneralJournalBatchBalanced()` — L505 | `[IntegrationEvent(true,false)] local procedure` | Published extension point |
| `Gen. Journal Batch.OnGeneralJournalBatchNotBalanced()` — L514 | `[IntegrationEvent(true,false)] local procedure` | Published extension point |
| `Gen. Journal Batch.OnCheckGenJournalLineExportRestrictions()` — L520 | `[IntegrationEvent(true,false)] procedure` (non-`local`) | Published extension point (also callable) |
| `Gen. Journal Batch.OnMoveGenJournalBatch(RecordID)` — L526 | `[IntegrationEvent(true,false)] [Scope('OnPrem')] procedure` | Published extension point — **`[Scope('OnPrem')]`; Version-sensitive or uncertain for a cloud-target extension** |
| `Gen. Journal Line.OnCheckGenJournalLinePostRestrictions()` — L7585 | `[IntegrationEvent(true,false)] [Scope('OnPrem')] procedure` | Published extension point — **`[Scope('OnPrem')]`; Version-sensitive or uncertain for a cloud-target extension** |
| `Gen. Journal Line.OnCheckGenJournalLinePrintCheckRestrictions()` — L7591 | `[IntegrationEvent(true,false)] [Scope('OnPrem')] procedure` | Published extension point — **`[Scope('OnPrem')]`** |
| `Gen. Journal Line.OnCheckGenJournalLineExportRestrictions()` — L7596 | `[IntegrationEvent(true,false)] procedure` | Published extension point |
| `Gen. Jnl.-Post Line.OnMoveGenJournalLine(var Gen. Journal Line; RecordID)` | `[IntegrationEvent(false,false)] local procedure` | Published extension point (subscribe only) |

### 3.9 Data contracts

| Symbol | Category | Note |
| --- | --- | --- |
| `Table 454 "Approval Entry"` fields, `Key2`, `Key3`, `Key7`, `Status`, `Record ID to Approve`, `Workflow Step Instance ID`, `Pending Approvals` | Accessible data contract | Read and filter freely. Do **not** insert/modify directly; use `Approvals Mgmt.` |
| `Table 1550 "Restricted Record"` | Accessible data contract | Read freely. Write only via `Record Restriction Mgt.` |
| `Table 1501 Workflow`, `Table 1502 "Workflow Step"`, `Table 1523 "Workflow Step Argument"` | Accessible data contract | Write only through `Workflow Setup` builders for the target's own workflows |
| `Table 1509 "WF Event/Response Combination"`, `Table 1520 "Workflow Event"`, `Table 1521 "Workflow Response"`, `Table 1508 "Workflow Category"`, `Table 1505 "Workflow - Table Relation"` | Accessible data contract | Populate only via the `Add...ToLibrary` / `Insert...` procedures from library subscribers |
| `Table 1504 "Workflow Step Instance"` | Accessible data contract | Runtime instance; read-only for a target |
| `Table 456 "Posted Approval Entry"`, `Table 457 "Posted Approval Comment Line"` | Accessible data contract | Written by `Approvals Mgmt.PostApprovalEntries` |
| `Table 467 "Workflow Webhook Entry"` | Version-sensitive or uncertain | Webhook internals untraced |
| `Enum 460 "Workflow Approver Type"`, `Enum 465 "Workflow Approver Limit Type"` | Accessible data contract (`Extensible = true`) | Target may add values; adding a value requires implementing its resolution behaviour |
| `Enum "Approval Status"` | Accessible data contract | **Ordinals are consumed positionally** by `GetApprovalEntryStatusValueName` (Session 3) |
| `Page 39` approval variables (`OpenApprovalEntriesExistForCurrUser`, `CanCancelApprovalForJnlBatch`, …) | Observable but inaccessible implementation | Page-local; recompute via `Approvals Mgmt.` / `Workflow Webhook Management` |
| `Codeunit 1804 "Approval Workflow Setup Mgt."` public procedures | Version-sensitive or uncertain + General Journal-specific implementation | Every inspected procedure is `[Scope('OnPrem')]` |

## 4. Summary counts

| Category | Approximate member count in this inventory |
| --- | --- |
| Public supported dependency | 45 |
| Published extension point | 19 |
| Accessible data contract | 19 tables/enums |
| Observable but inaccessible implementation | 20 |
| General Journal-specific implementation | 27 |
| Version-sensitive or uncertain | 18 |
