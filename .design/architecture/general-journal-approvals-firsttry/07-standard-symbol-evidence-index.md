# General Journal Approvals — Session 5: Standard symbol evidence index

Reverse index for [06-business-central-extension-handoff.md](06-business-central-extension-handoff.md) and [01-object-and-accessibility-inventory.md](01-object-and-accessibility-inventory.md).

Every standard symbol recommended, classified or warned about in this session appears here exactly once, keyed by evidence file. Line numbers are from branch `gb-29-vNext`, commit `a74fec3ec909d`, application `29.0.53247.0` (GB).

Verification column:

- **S5** — declaration line re-read in Session 5 (this session).
- **S2 / S3 / S4** — evidence carried from the corresponding prior-session document; not re-read here.

---

## 1. `Base Application/System/Workflow/WorkflowSetup.Codeunit.al`

| Line | Symbol | Declaration | Classification | Recommended use | Verified |
| --- | --- | --- | --- | --- | --- |
| 16 | `codeunit 1502 "Workflow Setup"` | object; no `Access` property | Public supported dependency | Use directly | S5 |
| 140 | `InitWorkflow()` | `procedure` | Public supported dependency | Use directly | S5 |
| 165–182 | `InitWorkflow` body order | — | — | Learn from | S2 |
| 232 | `OnAddWorkflowCategoriesToLibrary()` | `local` `[IntegrationEvent]` | Published extension point | Subscribe | S5 |
| 233–262 | `ResetWorkflowTemplates` body | — | — | Learn from | S2 |
| 246 | `InsertWorkflowTemplate(var Workflow; Code[17]; Text[100]; Code[20])` | `procedure` | Public supported dependency | Use directly | S5 |
| 256 | `ResetWorkflowTemplates()` | `internal procedure` | Observable but inaccessible implementation | Do not call | S5 |
| 283 | `InsertApprovalsTableRelations()` | `procedure` | Public supported dependency | Use directly (normally via the after-event) | S5 |
| 283–322 | GJ table relations to `Approval Entry` | — | Accessible data contract | Learn from | S2 |
| 1296–1305 | `InsertGeneralJournalLineApprovalWorkflowDetails` | — | General Journal-specific implementation | Reproduce | S2 |
| 1506 | `GeneralJournalBatchApprovalWorkflowCode()` | `procedure` | General Journal-specific implementation | Reproduce | S5 |
| 1511 | `GeneralJournalLineApprovalWorkflowCode()` | `procedure` | General Journal-specific implementation | Reproduce | S5 |
| 1610 | `InsertRecApprovalWorkflowSteps(...)` (9 parameters) | `procedure` | Public supported dependency | **Use directly — the generic approval skeleton** | S5 |
| 1610–1688 | line-template chain construction | — | — | Learn from | S3 |
| 1653–1655 | `SetNextStep(SendApprovalRequestResponseID2, SendApprovalRequestResponseID)` | — | — | Learn from (intermediate-approval loop-back) | S3 |
| 1657–1665 | reject-branch argument (`Notify Sender = true`) | — | — | Learn from | S3 |
| 1666–1682 | cancel branch, `RemoveRestrictionOnCancel = false` | — | — | Learn from | S3 |
| 1683–1688 | delegate-branch loop-back | — | — | Learn from | S3 |
| 1754 | `InsertGenJnlBatchApprovalWorkflowSteps(...)` | `procedure` | General Journal-specific implementation | Reproduce | S5 |
| 1811–1822 | batch reject/cancel branches | — | — | Learn from | S3 |
| 1835 | `InsertGenJnlLineApprovalWorkflowSteps(...)` | `procedure` | General Journal-specific implementation | Reproduce | S5 |
| 2205 | `InsertEntryPointEventStep(Workflow; Code[128])` | `procedure` | Public supported dependency | Use directly | S5 |
| 2215 | `InsertEventStep(Workflow; Code[128]; Integer)` | `procedure` | Public supported dependency | Use directly | S5 |
| 2226 | `InsertResponseStep(Workflow; Code[128]; Integer)` | `procedure` | Public supported dependency | Use directly | S5 |
| 2245 | `MarkWorkflowAsTemplate(var Workflow)` | `procedure` | Public supported dependency | Use directly | S5 |
| 2261 | `SetNextStep(Workflow; Integer; Integer)` | `procedure` | Public supported dependency | Use directly | S5 |
| 2270 | `InsertTableRelation(Integer; Integer; Integer; Integer)` | `procedure` | Public supported dependency | Use directly | S5 |
| 2284 | `InsertWorkflowCategory(Code[20]; Text[100])` | `procedure` | Public supported dependency | Use directly | S5 |
| 2334 | `InsertNotificationArgument(Integer; Boolean; Code[50]; Integer; Text[250])` | `procedure` | Public supported dependency | Use directly | S5 |
| 2358 | `InsertApprovalArgument(Integer; Enum 460; Enum 465; Code[20]; Code[50]; DateFormula; Boolean)` | `procedure` | Public supported dependency | Use directly | S5 |
| 2419 | `GetWorkflowTemplateCode(Code[17])` | `procedure` | Public supported dependency | Use directly | S5 |
| 2424 | `GetWorkflowTemplateToken()` | `procedure` | Public supported dependency | Use directly | S5 |
| 2473 | `BuildNoPendingApprovalsConditions()` | `procedure` | Public supported dependency (version-sensitive) | Use directly + revalidate | S5 |
| 2481 | `BuildPendingApprovalsConditions()` | `procedure` | Public supported dependency (version-sensitive) | Use directly + revalidate | S5 |
| 2567 | `BuildGeneralJournalBatchTypeConditions()` | **`local procedure`** | Observable but inaccessible implementation | **Do not call — contradicts Session 2** | S5 |
| 2579 | `BuildGeneralJournalLineTypeConditions(var Gen. Journal Line)` | `procedure` | General Journal-specific implementation | Reproduce | S5 |
| 2659 | `OnAfterInitWorkflowTemplates()` | `local` `[IntegrationEvent]` | Published extension point | Subscribe | S5 |
| 2664 | `OnAfterInsertApprovalsTableRelations()` | `local` `[IntegrationEvent]` | Published extension point | **Subscribe — registers the target subject table** | S5 |

## 2. `Base Application/System/Workflow/WorkflowEventHandling.Codeunit.al`

| Line | Symbol | Declaration | Classification | Recommended use | Verified |
| --- | --- | --- | --- | --- | --- |
| 19 | `codeunit 1520 "Workflow Event Handling"` | object; no `Access` | Public supported dependency | Use directly | S5 |
| 83 | `CreateEventsLibrary()` | `procedure` | Public supported dependency | Learn from (called by `InitWorkflow`) | S5 |
| 155–169 | GJ events added to the library | — | — | Learn from | S2 |
| 226–303 | GJ event predecessors | — | — | Learn from | S2 |
| 323 | `AddEventToLibrary(Code[128]; Integer; Text[250]; Integer; Boolean)` | `procedure` | Public supported dependency | **Use directly from the library subscriber** | S5 |
| 351 | `AddEventPredecessor(Code[128]; Code[128])` | `procedure` | Public supported dependency | **Use directly from the library subscriber** | S5 |
| 364 | `OnAddWorkflowEventsToLibrary()` | `local` `[IntegrationEvent]` | Published extension point | **Subscribe** | S5 |
| 369 | `OnAddWorkflowEventPredecessorsToLibrary(Code[128])` | `local` `[IntegrationEvent]` | Published extension point | **Subscribe** | S5 |
| 468 | `RunWorkflowOnApproveApprovalRequestCode()` | `procedure` | Public supported dependency | **Use directly — domain-neutral** | S5 |
| 473 | `RunWorkflowOnDelegateApprovalRequestCode()` | `procedure` | Public supported dependency | **Use directly — domain-neutral** | S5 |
| 478 | `RunWorkflowOnRejectApprovalRequestCode()` | `procedure` | Public supported dependency | **Use directly — domain-neutral** | S5 |
| 528 | `RunWorkflowOnSendGeneralJournalBatchForApprovalCode()` | `procedure` | General Journal-specific implementation | Reproduce | S5 |
| 533 | `RunWorkflowOnCancelGeneralJournalBatchApprovalRequestCode()` | `procedure` | General Journal-specific implementation | Reproduce | S5 |
| 538 | `RunWorkflowOnSendGeneralJournalLineForApprovalCode()` | `procedure` | General Journal-specific implementation | Reproduce | S5 |
| 543 | `RunWorkflowOnCancelGeneralJournalLineApprovalRequestCode()` | `procedure` | General Journal-specific implementation | Reproduce | S5 |
| 548 | `RunWorkflowOnGeneralJournalBatchBalancedCode()` | `procedure` | General Journal-specific implementation | Reproduce | S5 |
| 553 | `RunWorkflowOnGeneralJournalBatchNotBalancedCode()` | `procedure` | General Journal-specific implementation | Reproduce | S5 |
| 752–774 | approve/reject/delegate subscribers using `HandleEventOnKnownWorkflowInstance` | `[EventSubscriber]` | — | **Learn from — the forwarding pattern to copy** | S3 |
| 836–870 | GJ send/cancel/balanced/not-balanced subscribers | `[EventSubscriber]` | — | Learn from | S2/S3 |

## 3. `Base Application/System/Workflow/WorkflowResponseHandling.Codeunit.al`

| Line | Symbol | Declaration | Classification | Recommended use | Verified |
| --- | --- | --- | --- | --- | --- |
| 17 | `codeunit 1521 "Workflow Response Handling"` | object; no `Access` | Public supported dependency | Use directly | S5 |
| 95 | `CreateResponsesLibrary()` | `procedure` | Public supported dependency | Learn from | S5 |
| 95–133 | GJ-relevant responses added to the library | — | — | Learn from | S2 |
| 165–330 | response predecessors | — | — | Learn from | S2 |
| 355 | `OnAddWorkflowResponsesToLibrary()` | `local` `[IntegrationEvent]` | Published extension point | **Subscribe** | S5 |
| 360 | `OnAddWorkflowResponsePredecessorsToLibrary(Code[128])` | `local` `[IntegrationEvent]` | Published extension point | **Subscribe** | S5 |
| 365 | `ExecuteResponse(var Variant; Workflow Step Instance; Variant)` | `procedure` | Public supported dependency | Learn from (dispatcher) | S5 |
| 470 | `OnExecuteWorkflowResponse(var Boolean; var Variant; Variant; Workflow Step Instance)` | `local` `[IntegrationEvent]` | Published extension point | **Subscribe — implement custom responses here** | S5 |
| 489 | `OpenDocumentCode()` | `procedure` | Public supported dependency | Use directly | S5 |
| 504 | `CreateApprovalRequestsCode()` | `procedure` | Public supported dependency | **Use directly** | S5 |
| 509 | `SendApprovalRequestForApprovalCode()` | `procedure` | Public supported dependency | **Use directly** | S5 |
| 519 | `RejectAllApprovalRequestsCode()` | `procedure` | Public supported dependency | Use directly | S5 |
| 524 | `CancelAllApprovalRequestsCode()` | `procedure` | Public supported dependency | Use directly | S5 |
| 559 | `CheckGeneralJournalBatchBalanceCode()` | `procedure` | General Journal-specific implementation | Reproduce | S5 |
| 569 | `ShowMessageCode()` | `procedure` | Public supported dependency | Use directly | S5 |
| 574 | `RestrictRecordUsageCode()` | `procedure` | Public supported dependency | **Use directly** | S5 |
| 579 | `AllowRecordUsageCode()` | `procedure` | Public supported dependency | **Use directly** | S5 |
| 779–786 | `CreateApprovalRequests` response body | `local procedure` | Observable but inaccessible implementation | Learn from | S3 |
| 812–826 | `SendApprovalRequestForApproval` response body | `local procedure` | Observable but inaccessible implementation | Learn from | S3 |
| 847–865 | `RejectAllApprovalRequests` response body | `local procedure` | Observable but inaccessible implementation | Learn from | S3 |
| 867–885 | `CancelAllApprovalRequests` response body | `local procedure` | Observable but inaccessible implementation | Learn from | S3 |
| 969–982 | `CheckGeneralJournalBatchBalance` response body | `local procedure` | General Journal-specific implementation | Reproduce | S3 |
| 1013–1020 | `RestrictRecordUsage` response body | `local procedure` | Observable but inaccessible implementation | Learn from | S3 |
| 1022–1074 | `AllowRecordUsage` response body (batch vs line branch) | `local procedure` | Observable but inaccessible implementation | Learn from | S3 |
| 1110 | `AddResponseToLibrary(Code[128]; Integer; Text[250]; Code[20])` | `procedure` | Public supported dependency | **Use directly from the library subscriber** | S5 |
| 1139 | `AddResponsePredecessor(Code[128]; Code[128])` | `procedure` | Public supported dependency | **Use directly from the library subscriber** | S5 |

## 4. `Base Application/System/Workflow/WorkflowManagement.Codeunit.al`

| Line | Symbol | Declaration | Classification | Recommended use | Verified |
| --- | --- | --- | --- | --- | --- |
| 7 | `codeunit 1501 "Workflow Management"` | object; no `Access` | Public supported dependency | Use directly | S5 |
| 61 | `CanExecuteWorkflow(Variant; Code[128])` | `procedure` | Public supported dependency | **Use directly** | S5 |
| 264 | `WorkflowExists(Variant; Variant; Code[128])` | `procedure` | Public supported dependency | Use directly | S5 |
| 489 | `HandleEvent(Code[128]; Variant)` | `procedure` | Public supported dependency | **Use directly** | S5 |
| 489–525 | `HandleEvent` / `HandleEventWithxRec` body (upgrade + temporary exits) | — | — | Learn from | S3 |
| 494 | `HandleEventWithxRec(Code[128]; Variant; Variant)` | `procedure` | Public supported dependency | Use directly | S5 |
| 528 | `HandleEventOnKnownWorkflowInstance(Code[128]; Variant; Guid)` | `procedure` | Public supported dependency | **Use directly** | S5 |
| 533 | `HandleEventWithxRecOnKnownWorkflowInstance(...)` | `procedure` | Public supported dependency | Use directly | S5 |
| 533–570 | condition evaluation, first matching step | — | — | Learn from | S3 |
| 575 | `ExecuteResponses(Variant; Variant; Workflow Step Instance)` | `procedure` | Public supported dependency | Use directly | S5 |
| 574–620 | response walk + instance archiving | — | — | Learn from | S3 |
| 748 | `EnabledWorkflowExist(Integer; Text)` | `procedure` | Public supported dependency | **Use directly** | S5 |

## 5. `Base Application/OtherCapabilities/Approvals/ApprovalsMgmt.Codeunit.al`

| Line | Symbol | Declaration | Classification | Recommended use | Verified |
| --- | --- | --- | --- | --- | --- |
| 28 | `codeunit 1535 "Approvals Mgmt."` | object; no `Access` | Public supported dependency | Use directly | S5 |
| 157 | `OnSendGeneralJournalBatchForApproval(var Gen. Journal Batch)` | `[IntegrationEvent(false,false)] procedure` | Published extension point | Subscribe (GJ only) / reproduce pattern | S5 |
| 162 | `OnCancelGeneralJournalBatchApprovalRequest(...)` | same | Published extension point | Subscribe / reproduce | S5 |
| 167 | `OnSendGeneralJournalLineForApproval(...)` | same | Published extension point | Subscribe / reproduce | S5 |
| 172 | `OnCancelGeneralJournalLineApprovalRequest(...)` | same | Published extension point | Subscribe / reproduce | S5 |
| 197 | `OnApproveApprovalRequest(var Approval Entry)` | `[IntegrationEvent(false,false)] local procedure` | Published extension point | **Subscribe — domain-neutral** | S5 |
| 202 | `OnRejectApprovalRequest(...)` | same | Published extension point | **Subscribe — domain-neutral** | S5 |
| 207 | `OnDelegateApprovalRequest(...)` | same | Published extension point | **Subscribe — domain-neutral** | S5 |
| 251–273 | `ApproveRecordApprovalRequest` / `ApproveGenJournalLineRequest` bodies | — | — | Learn from | S3 |
| 262 | `ApproveGenJournalLineRequest(Gen. Journal Line)` | `procedure` | General Journal-specific implementation | Reproduce | S5 |
| 306 | `RejectGenJournalLineRequest(...)` | `procedure` | General Journal-specific implementation | Reproduce | S5 |
| 339–361 | delegate chain bodies | — | — | Learn from | S3 |
| 350 | `DelegateGenJournalLineRequest(...)` | `procedure` | General Journal-specific implementation | Reproduce | S5 |
| 417–498 | `DelegateApprovalRequests`, `ApproveSelectedApprovalRequest`, `RejectSelectedApprovalRequest`, `DelegateSelectedApprovalRequest` | `local` | Observable but inaccessible implementation | Learn from | S3 |
| 513–544 | `SubstituteUserIdForApprovalEntry` | `local` | Observable but inaccessible implementation | Learn from | S3 |
| 546 | `FindOpenApprovalEntryForCurrUser(var Approval Entry; RecordID)` | `procedure` | Public supported dependency | **Use directly** | S5 |
| 659–712 | `CancelApprovalRequestsForRecord`, `RejectApprovalRequestsForRecord` | — | — | Learn from | S3 |
| 714 | `SendApprovalRequestFromRecord(RecordRef; Workflow Step Instance)` | `procedure` | Public supported dependency | **Use directly** | S5 |
| 757 | `SendApprovalRequestFromApprovalEntry(Approval Entry; Workflow Step Instance)` | `procedure` | Public supported dependency | **Use directly** | S5 |
| 794 | `CreateApprovalRequests(RecordRef; Workflow Step Instance)` | `procedure` | Public supported dependency | **Use directly** | S5 |
| 1007–1033 | `CreateApprovalRequestForApprover` | `local` | Observable but inaccessible implementation | Learn from | S3 |
| 1092 | `MakeApprovalEntry(Approval Entry; Integer; Code[50]; Workflow Step Argument)` | `procedure` | Public supported dependency | **Use directly** | S5 |
| 1118–1144 | `MakeApprovalEntry` body (self-approval → `Approved`, delegation formula) | — | — | Learn from | S3 |
| 1188 | `PopulateApprovalEntryArgument(RecordRef; Workflow Step Instance; var Approval Entry)` | `procedure` | Public supported dependency | **Use directly** | S5 |
| 1245–1266 | `Gen. Journal Line` case arm | — | General Journal-specific implementation | Reproduce for the target table | S3 |
| 1290 | `CreateApprovalEntryNotification(Approval Entry; Workflow Step Instance)` | `procedure` | Public supported dependency | **Use directly** | S5 |
| 1450 | `IsSufficientApprover(User Setup; Approval Entry)` | `procedure` | Public supported dependency | Use directly + revalidate for a foreign table | S5 |
| 1450–1476 | batch chain unsupported (`ApporvalChainIsUnsupportedMsg`) | — | — | Learn from | S3 |
| 1576 | `IsGeneralJournalBatchApprovalsWorkflowEnabled(var Gen. Journal Batch)` | `procedure` | General Journal-specific implementation | Reproduce | S5 |
| 1589 | `IsGeneralJournalLineApprovalsWorkflowEnabled(var Gen. Journal Line)` | `procedure` | General Journal-specific implementation | Reproduce | S5 |
| 1720 | `CheckGeneralJournalBatchApprovalsWorkflowEnabled(...)` | `procedure` | General Journal-specific implementation | Reproduce | S5 |
| 1731 | `CheckGeneralJournalLineApprovalsWorkflowEnabled(...)` | `procedure` | General Journal-specific implementation | Reproduce | S5 |
| 1771–1782 | `PostApprovalEntriesMoveGenJournalLine`, `DeleteApprovalEntriesAfterDeleteGenJournalLine` | `[EventSubscriber]` | General Journal-specific implementation | Reproduce | S3/S4 |
| 1784–1806 | `PostApprovalEntriesMoveGenJournalBatch`, `DeleteApprovalEntriesAfterDeleteGenJournalBatch` | `[EventSubscriber]` | General Journal-specific implementation | Reproduce | S3/S4 |
| 1884 | `PostApprovalEntries(RecordID; RecordID; Code[20])` | `procedure` | Public supported dependency | **Use directly** | S5 |
| 2037 | `GetApprovalComment(Variant)` | `procedure` | Public supported dependency | Use directly | S5 |
| 2117 | `HasOpenApprovalEntriesForCurrentUser(RecordID)` | `procedure` | Public supported dependency | **Use directly** | S5 |
| 2136 | `HasOpenApprovalEntries(RecordID)` | `procedure` | Public supported dependency | **Use directly** | S5 |
| 2186 | `HasApprovedApprovalEntries(RecordID)` | `procedure` | Public supported dependency | Use directly | S5 |
| 2224 | `HasAnyOpenJournalLineApprovalEntries(Code[20]; Code[20])` | `procedure` | General Journal-specific implementation | Reproduce | S5 |
| 2267 | `TrySendJournalBatchApprovalRequest(var Gen. Journal Line)` | `procedure` | General Journal-specific implementation | Reproduce | S5 |
| 2283 | `TrySendJournalLineApprovalRequests(var Gen. Journal Line)` | `procedure` | General Journal-specific implementation | Reproduce | S5 |
| 2299 | `TryCancelJournalBatchApprovalRequest(var Gen. Journal Line)` | `procedure` | General Journal-specific implementation | Reproduce **with an added sender check** | S5 |
| 2309 | `TryCancelJournalLineApprovalRequests(var Gen. Journal Line)` | `procedure` | General Journal-specific implementation | Reproduce | S5 |
| 2321 | `ShowJournalApprovalEntries(var Gen. Journal Line)` | `procedure` | General Journal-specific implementation | Reproduce | S5 |
| 2334 | `GetGeneralJournalBatch(var Gen. Journal Batch; var Gen. Journal Line)` | **`local procedure`** | Observable but inaccessible implementation | Learn from | S5 |
| 2435 | `RenameApprovalEntries(RecordID; RecordID)` | `procedure` | Public supported dependency | **Use directly** | S5 |
| 2455 | `DeleteApprovalEntries(RecordID)` | `procedure` | Public supported dependency | **Use directly** | S5 |
| 2515 | `GetLastSequenceNo(Approval Entry)` | `procedure` | Public supported dependency | Use directly | S5 |
| 2595 | `CanCancelApprovalForRecord(RecordID)` | `procedure` | Public supported dependency | **Use directly** | S5 |
| 2706 | `PreventDeletingRecordWithOpenApprovalEntry(Variant)` | `procedure` | Public supported dependency | **Use directly** | S5 |
| 2748 | `PreventInsertRecIfOpenApprovalEntryExist(Variant)` | `procedure` | Public supported dependency | **Use directly** | S5 |
| 2836 | `PreventModifyRecIfOpenApprovalEntryExistForCurrentUser(Variant)` | `procedure` | Public supported dependency | **Use directly** | S5 |
| 2875 | `SendJournalLinesApprovalRequests(var Gen. Journal Line)` | `procedure` | General Journal-specific implementation | Reproduce | S5 |
| 2875–2898 | multi-line fan-out via `Batch Processing Mgt.` | — | — | Learn from | S3 |
| 2900 | `GetGenJnlBatchApprovalStatus(...)` | `procedure` | General Journal-specific implementation | Reproduce | S5 |
| 2918 | `GetGenJnlLineApprovalStatus(...)` | `procedure` | General Journal-specific implementation | Reproduce | S5 |
| 2987 / 3017 / 3035 / 3059 | `GetApprovalStatusFromApprovalEntry(...)` overloads | **`local procedure`** | Observable but inaccessible implementation | Learn from | S5 |
| 3101 | `CleanGenJournalApprovalStatus(...)` | `procedure` | General Journal-specific implementation | Reproduce | S5 |

## 6. `Base Application/System/Workflow/RecordRestrictionMgt.Codeunit.al`

| Line | Symbol | Declaration | Classification | Recommended use | Verified |
| --- | --- | --- | --- | --- | --- |
| 16 | `codeunit 1550 "Record Restriction Mgt."` | object; no `Access` | Public supported dependency | Use directly | S5 |
| 32 | `RestrictRecordUsage(Variant; Text)` | `procedure` | Public supported dependency | **Use directly** | S5 |
| 56 | `AllowGenJournalBatchUsage(Gen. Journal Batch)` | `procedure` | General Journal-specific implementation | Reproduce as a target cascade | S5 |
| 112 | `AllowRecordUsage(Variant)` | `procedure` | Public supported dependency | **Use directly** | S5 |
| 112–129 | deletes all rows regardless of `Details` | — | — | Learn from (cross-path risk) | S3 |
| 131 | `UpdateRestriction(Variant; Variant)` | `procedure` | Public supported dependency | **Use directly on rename** | S5 |
| 153–180 | `RestrictGenJournalLineAfterInsert` / `AfterModify` subscribers | `[EventSubscriber]` | General Journal-specific implementation | Reproduce | S3/S4 |
| 166 | `RestrictGenJournalLine(var Gen. Journal Line)` | **`local procedure`** | Observable but inaccessible implementation | Learn from | S5 |
| 289 | `CheckRecordHasUsageRestrictions(Variant)` | `procedure` (`TryFunction`) | Public supported dependency | **Use directly** | S5 |
| 360–436 | `OnCheckGenJournalLinePostRestrictions` subscribers (line, batch, customer, vendor) + `OnBefore…(var IsHandled)` | `[EventSubscriber]` + publisher | Published extension point | Reproduce; subscribe only for GJ | S4 |
| 436–556 | export / print-check restriction subscribers | `[EventSubscriber]` | General Journal-specific implementation | Reproduce | S4 |
| 646–654 | restriction removal on delete | — | — | Learn from | S4 |

## 7. `Base Application/System/Workflow/WorkflowWebhookManagement.Codeunit.al`

All entries are **Version-sensitive or uncertain** — untraced in sessions 1–5. Recommended use: **revalidate before depending on any of them**.

| Line | Symbol | Declaration | Verified |
| --- | --- | --- | --- |
| 14 | `codeunit 1543 "Workflow Webhook Management"` | object | S5 |
| 42 / 47 / 52 | `OnCancelWorkflow` / `OnContinueWorkflow` / `OnRejectWorkflow` | `local procedure` | S5 |
| 56 | `CanCancel(Workflow Webhook Entry)` | `procedure` | S5 |
| 70 | `CanRequestApproval(RecordID)` | `procedure` | S5 |
| 76 | `GetCanRequestAndCanCancel(RecordID; var Boolean; var Boolean)` | `procedure` | S5 |
| 89 | `GetCanRequestAndCanCancelJournalBatch(Gen. Journal Batch; var Boolean; var Boolean; var Boolean)` | `procedure` | S5 |
| 119 / 124 / 137 | `Cancel(...)` / `CancelByStepInstanceId(Guid)` | `procedure` | S5 |
| 147 / 158 | `CanContinue` / `CanReject` | `procedure` | S5 |
| 169 / 180 | `Continue` / `ContinueByStepInstanceId` | `procedure` | S5 |
| 190 | `GenerateRequest(RecordRef; Workflow Step Instance)` | `procedure` | S5 |
| 199 / 211 | `Reject` / `RejectByStepInstanceId` | `procedure` | S5 |
| 221 | `SendWebhookNotificaton(Workflow Step Instance)` | `procedure` | S5 |
| 381 | `HasPendingWorkflowWebhookEntryByRecordId(RecordID)` | `procedure` | S5 |
| 419 / 424 | `FindAndCancel(RecordID)` / `FindAndCancel(RecordID; Boolean)` | `procedure` | S5 |

## 8. `Base Application/Finance/GeneralLedger/Journal/GenJournalLine.Table.al`

| Line | Symbol | Declaration | Classification | Recommended use | Verified |
| --- | --- | --- | --- | --- | --- |
| 3902–3949 | `OnDelete` approval hooks | — | General Journal-specific implementation | Reproduce | S3 |
| 3951–3979 | `OnInsert` approval hooks | — | General Journal-specific implementation | Reproduce | S3 |
| 4000–4006 | `OnRename` → `OnRenameRecordInApprovalRequest` | — | General Journal-specific implementation | Reproduce | S4 |
| 7585 | `OnCheckGenJournalLinePostRestrictions()` | `[IntegrationEvent(true,false)]` **+ `[Scope('OnPrem')]`** | Published extension point / Version-sensitive or uncertain | **Revalidate; reproduce a non-scoped equivalent** | S5 |
| 7591 | `OnCheckGenJournalLinePrintCheckRestrictions()` | `[IntegrationEvent(true,false)]` **+ `[Scope('OnPrem')]`** | Published extension point / Version-sensitive or uncertain | **Revalidate** | S5 |
| 7596 | `OnCheckGenJournalLineExportRestrictions()` | `[IntegrationEvent(true,false)]`, no `Scope` | Published extension point | Subscribe (GJ only) | S5 |
| 8418–8426 | `OnModify` → `CheckOpenApprovalEntryExistForCurrentUser` | — | General Journal-specific implementation | Reproduce | S3 |

## 9. `Base Application/Finance/GeneralLedger/Journal/GenJournalBatch.Table.al`

| Line | Symbol | Declaration | Classification | Recommended use | Verified |
| --- | --- | --- | --- | --- | --- |
| 325–358 | `OnModify` / `OnDelete` / `OnRename` approval hooks | — | General Journal-specific implementation | Reproduce | S3/S4 |
| 490–497 | `CheckBalance()` raising the balanced/not-balanced events | — | General Journal-specific implementation | Reproduce as a pre-check | S2 |
| 505 | `OnGeneralJournalBatchBalanced()` | `[IntegrationEvent(true,false)] local procedure` | Published extension point | Reproduce | S5 |
| 514 | `OnGeneralJournalBatchNotBalanced()` | `[IntegrationEvent(true,false)] local procedure` | Published extension point | Reproduce | S5 |
| 520 | `OnCheckGenJournalLineExportRestrictions()` | `[IntegrationEvent(true,false)] procedure`, no `Scope` | Published extension point | Subscribe (GJ only) | S5 |
| 526 | `OnMoveGenJournalBatch(RecordID)` | `[IntegrationEvent(true,false)]` **+ `[Scope('OnPrem')]`** | Published extension point / Version-sensitive or uncertain | **Revalidate** | S5 |

## 10. Posting objects

| File | Symbol | Line | Classification | Recommended use | Verified |
| --- | --- | --- | --- | --- | --- |
| [GenJnlPostBatch.Codeunit.al](../../../Base%20Application/Finance/GeneralLedger/Posting/GenJnlPostBatch.Codeunit.al) | `codeunit 13 "Gen. Jnl.-Post Batch"` | 37 | General Journal-specific implementation | **Reproduce the guard placement** | S5 |
| same | `CheckLine` → `CheckRestrictions` (skips in `PreviewMode`) | — | — | Learn from | S4 |
| same | `OnBeforeCheckLine`, `OnBeforePostGenJnlLine`, `OnAfterPostGenJournalLine` | — | Published extension point | Learn from (bypass risk) | S4 |
| [GenJnlPostLine.Codeunit.al](../../../Base%20Application/Finance/GeneralLedger/Posting/GenJnlPostLine.Codeunit.al) | `codeunit 12 "Gen. Jnl.-Post Line"` | 74 | General Journal-specific implementation | Learn from (bypass) | S5 |
| same | `OnMoveGenJournalLine(var Gen. Journal Line; RecordID)` | — | `[IntegrationEvent(false,false)] local procedure` — Published extension point | Revalidate before subscribing | S5 |
| [GenJnlCheckLine.Codeunit.al](../../../Base%20Application/Finance/GeneralLedger/Journal/GenJnlCheckLine.Codeunit.al) | `codeunit 11 "Gen. Jnl.-Check Line"` | 11 | General Journal-specific implementation | Learn from | S5 |
| [GenJnlPost.Codeunit.al](../../../Base%20Application/Finance/GeneralLedger/Posting/GenJnlPost.Codeunit.al) | `codeunit 231 "Gen. Jnl.-Post"` | — | General Journal-specific implementation | Learn from | S5 |
| [GenJnlPostPrint.Codeunit.al](../../../Base%20Application/Finance/GeneralLedger/Posting/GenJnlPostPrint.Codeunit.al) | `codeunit 232 "Gen. Jnl.-Post+Print"` | — | General Journal-specific implementation | Learn from | S5 |
| [GenJnlBPost.Codeunit.al](../../../Base%20Application/Finance/GeneralLedger/Posting/GenJnlBPost.Codeunit.al) | `codeunit 233 "Gen. Jnl.-B.Post"` | — | General Journal-specific implementation | Learn from | S5 |
| [GenJnlBPostPrint.Codeunit.al](../../../Base%20Application/Finance/GeneralLedger/Posting/GenJnlBPostPrint.Codeunit.al) | `codeunit 234 "Gen. Jnl.-B.Post+Print"` | — | General Journal-specific implementation | Learn from | S5 |
| [GenJnlPostviaJobQueue.Codeunit.al](../../../Base%20Application/Finance/GeneralLedger/Posting/GenJnlPostviaJobQueue.Codeunit.al) | `codeunit 250 "Gen. Jnl.-Post via Job Queue"` | — | General Journal-specific implementation | Learn from | S5 |

## 11. Other codeunits

| File | Symbol | Line | Classification | Recommended use | Verified |
| --- | --- | --- | --- | --- | --- |
| [CompanyInitialize.Codeunit.al](../../../Base%20Application/Foundation/Company/CompanyInitialize.Codeunit.al) | `codeunit 2 "Company-Initialize"` | 2 | Observable but inaccessible implementation (for a target) | Learn from — **ID is 2, not 1** | S5 |
| [ApprovalsJournalLineRequest.Codeunit.al](../../../Base%20Application/OtherCapabilities/Approvals/ApprovalsJournalLineRequest.Codeunit.al) | `codeunit 1536 "Approvals Journal Line Request"` | 9 | General Journal-specific implementation | **Reproduce — the batch-worker pattern** | S5 |
| [WorkflowWebhookSetup.Codeunit.al](../../../Base%20Application/System/Workflow/WorkflowWebhookSetup.Codeunit.al) | `codeunit 1540 "Workflow Webhook Setup"` | 5 | Version-sensitive or uncertain | Do not depend on | S5 |
| [ApprovalWorkflowSetupMgt.Codeunit.al](../../../Base%20Application/System/Workflow/ApprovalWorkflowSetupMgt.Codeunit.al) | `codeunit 1804 "Approval Workflow Setup Mgt."` | — | Version-sensitive / `[Scope('OnPrem')]` | **Do not call** | S2 |

## 12. Tables and enums

| File | Symbol | Classification | Recommended use | Verified |
| --- | --- | --- | --- | --- |
| [ApprovalEntry.Table.al](../../../Base%20Application/OtherCapabilities/Approvals/ApprovalEntry.Table.al) | `table 454 "Approval Entry"` (no `Access` property; keys `Key2`/`Key3`/`Key7`; fields `Record ID to Approve`, `Workflow Step Instance ID`, `Status`, `Pending Approvals` — field **numbers** not verified, see [08 §4.9](08-unresolved-and-version-sensitive-findings.md#4-version-sensitive-findings-and-revalidation-guidance)) | Accessible data contract | **Use directly; do not write directly** | S5 (object) / S3 (fields) |
| [ApprovalCommentLine.Table.al](../../../Base%20Application/OtherCapabilities/Approvals/ApprovalCommentLine.Table.al) | `table 455 "Approval Comment Line"` | Accessible data contract | Use directly | S5 |
| [PostedApprovalEntry.Table.al](../../../Base%20Application/System/Workflow/PostedApprovalEntry.Table.al) | `table 456 "Posted Approval Entry"` | Accessible data contract | Use directly via `PostApprovalEntries` | S5 |
| [PostedApprovalCommentLine.Table.al](../../../Base%20Application/System/Workflow/PostedApprovalCommentLine.Table.al) | `table 457 "Posted Approval Comment Line"` | Accessible data contract | Use directly via `PostApprovalEntries` | S5 |
| [WorkflowWebhookEntry.Table.al](../../../Base%20Application/System/Workflow/WorkflowWebhookEntry.Table.al) | `table 467 "Workflow Webhook Entry"` | Version-sensitive or uncertain | Revalidate | S5 |
| [UserSetup.Table.al](../../../Base%20Application/System/User/UserSetup.Table.al) | `table 91 "User Setup"` | Accessible data contract | Use directly (read) | S5 |
| [Workflow.Table.al](../../../Base%20Application/System/Workflow/Workflow.Table.al) | `table 1501 Workflow` | Accessible data contract | Write via `Workflow Setup` builders | S5 |
| [WorkflowStep.Table.al](../../../Base%20Application/System/Workflow/WorkflowStep.Table.al) | `table 1502 "Workflow Step"` | Accessible data contract | Write via `Workflow Setup` builders | S5 |
| [WorkflowStepInstance.Table.al](../../../Base%20Application/System/Workflow/WorkflowStepInstance.Table.al) | `table 1504 "Workflow Step Instance"` | Accessible data contract | Read only | S5 |
| [WorkflowTableRelation.Table.al](../../../Base%20Application/System/Workflow/WorkflowTableRelation.Table.al) | `table 1505 "Workflow - Table Relation"` | Accessible data contract | Write via `InsertTableRelation` | S5 |
| [WorkflowCategory.Table.al](../../../Base%20Application/System/Workflow/WorkflowCategory.Table.al) | `table 1508 "Workflow Category"` | Accessible data contract | Write via `InsertWorkflowCategory` | S5 |
| [WFEventResponseCombination.Table.al](../../../Base%20Application/System/Workflow/WFEventResponseCombination.Table.al) | `table 1509 "WF Event/Response Combination"` | Accessible data contract | Write via `AddEventPredecessor` / `AddResponsePredecessor` only | S5 |
| [NotificationEntry.Table.al](../../../Base%20Application/System/Notifications/NotificationEntry.Table.al) | `table 1511 "Notification Entry"` | Accessible data contract | Write via `CreateApprovalEntryNotification` | S5 |
| [WorkflowEvent.Table.al](../../../Base%20Application/System/Workflow/WorkflowEvent.Table.al) | `table 1520 "Workflow Event"` | Accessible data contract | Write via `AddEventToLibrary` only | S5 |
| [WorkflowResponse.Table.al](../../../Base%20Application/System/Workflow/WorkflowResponse.Table.al) | `table 1521 "Workflow Response"` | Accessible data contract | Write via `AddResponseToLibrary` only | S5 |
| [WorkflowStepArgument.Table.al](../../../Base%20Application/System/Workflow/WorkflowStepArgument.Table.al) | `table 1523 "Workflow Step Argument"` | Accessible data contract | Populate for the target's own steps | S5 |
| [RestrictedRecord.Table.al](../../../Base%20Application/System/Workflow/RestrictedRecord.Table.al) | `table 1550 "Restricted Record"` | Accessible data contract | Read; write via `Record Restriction Mgt.` | S5 |
| [WorkflowApproverType.Enum.al](../../../Base%20Application/System/Workflow/WorkflowApproverType.Enum.al) | `enum 460 "Workflow Approver Type"`, `Extensible = true` | Accessible data contract | Use directly; extend with care | S5 |
| [WorkflowApproverLimitType.Enum.al](../../../Base%20Application/System/Workflow/WorkflowApproverLimitType.Enum.al) | `enum 465 "Workflow Approver Limit Type"`, `Extensible = true` | Accessible data contract | Use directly; extend with care | S5 |
| [ApprovalStatus.Enum.al](../../../Base%20Application/OtherCapabilities/Approvals/ApprovalStatus.Enum.al) | `Enum "Approval Status"` (ordinals 0–5) | Accessible data contract | Use directly; ordinals are version-sensitive | S3 |

## 13. Pages

| File | Symbol | Classification | Recommended use | Verified |
| --- | --- | --- | --- | --- |
| [GeneralJournal.Page.al](../../../Base%20Application/Finance/GeneralLedger/Journal/GeneralJournal.Page.al) | `page 39 "General Journal"` — approval actions L1359–L1520; `SetApprovalState` / `SetApprovalStateForBatch` L2180–L2212 | General Journal-specific implementation; page variables are Observable but inaccessible implementation | Reproduce | S5 (object) / S3 (members) |
| [GeneralJournalBatches.Page.al](../../../Base%20Application/Finance/GeneralLedger/Journal/GeneralJournalBatches.Page.al) | `page 251 "General Journal Batches"` | General Journal-specific implementation | Reproduce | S5 |

## 14. First-party test evidence

Behaviour contracts, not dependencies. Used to justify the target test baseline in [06 §17.5](06-business-central-extension-handoff.md#17-focused-target-repository-investigation-instructions).

| File | Evidence | Verified |
| --- | --- | --- |
| [GeneralJournalLineApproval.Codeunit.al](../../../Tests-General%20Journal/GeneralJournalLineApproval.Codeunit.al) | `Assert.AreEqual(1, ApprovalEntry.Count, …)` for direct approver; `3` for chain scenarios (L71–L75, L361–L362); `CancelGenJnlLineForApprovalDoesNotAllowsUsage` | S3/S4 |
| [GeneralJournalBatchApproval.Codeunit.al](../../../Tests-General%20Journal/GeneralJournalBatchApproval.Codeunit.al) | `CanPreviewPost` — preview allowed with a pending batch approval, no G/L entries; `RestrictGenJournalLinePostingAfterInsertWithApprovalEnabled`; `InsertTempGenJnlLineDoesNotRestrictUsage` | S4 |
| [ApprovalHistoryTests.Codeunit.al](../../../Tests-General%20Journal/ApprovalHistoryTests.Codeunit.al) | Posted approval history persistence and cleanup | S1/S4 |
| [WFWHGeneralJournalBatch.Codeunit.al](../../../Tests-General%20Journal/WFWHGeneralJournalBatch.Codeunit.al) | Webhook batch request/cancel and table relations | S1 |
| [WFWHGeneralJournalLine.Codeunit.al](../../../Tests-General%20Journal/WFWHGeneralJournalLine.Codeunit.al) | Webhook line restriction, cancel, approve, reject | S1 |

---

## 15. Coverage check

Every symbol recommended in [06 §16.1](06-business-central-extension-handoff.md#161-use-directly), [§16.2](06-business-central-extension-handoff.md#162-subscribe-or-extend), [§16.3](06-business-central-extension-handoff.md#163-reproduce-in-the-target-domain), [§16.4](06-business-central-extension-handoff.md#164-learn-from-but-do-not-call) and [§16.5](06-business-central-extension-handoff.md#165-revalidate-against-target-symbols) appears in §1–§14 above.

Symbols named in the handoff that are **not** in this index, and why:

| Symbol | Reason |
| --- | --- |
| `Codeunit "Batch Processing Mgt."` | Named as a pattern to reproduce; its members were not verified in any session. Treat as **Version-sensitive or uncertain** until revalidated. |
| `Report "Check"` restriction call | Named only as corroborating evidence for the print/export barrier (Session 4); not recommended for reuse. |
| `Codeunit "Workflow Request Page Handling"` | Called from `InitWorkflow` but never inspected; explicitly out of the verified surface. |
| `OnAfterPopulateApprovalEntryArgument` | Hypothesised in [06 §7.1](06-business-central-extension-handoff.md#7-approval-entry-integration) and flagged for revalidation; **not verified to exist** in this snapshot. |
