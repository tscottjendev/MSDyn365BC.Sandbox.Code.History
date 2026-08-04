# General Journal discovery (gj-01)

## Labels used in this artifact
- **Verified**: directly supported by repository evidence.
- **Inference**: reasoned conclusion from verified evidence.
- **Recommendation**: suggested next research step.
- **Not located**: searched but not found in this branch snapshot.
- **Version-specific**: tied to this exact branch/commit/app version.

## 1) Repository/app/version inventory
- **Verified** Branch: gb-29-vNext.
- **Verified** Commit: fc4c58aef01063370e19823eb0aec4e891b626ea.
- **Verified** Base Application version 29.0.53300.0, platform dependency 29.0.0.0, depends on System Application and Business Foundation.
  - Evidence: Base Application/app.json.
- **Verified** System Application version 29.0.53300.0, platform 29.0.0.0.
  - Evidence: System Application/app.json.
- **Verified** Business Foundation version 29.0.53300.0.
  - Evidence: Business Foundation/app.json.
- **Verified** Tests-General Journal version 29.0.53300.0.
  - Evidence: Tests-General Journal/app.json.
- **Version-specific** All findings below are for this branch/commit and can differ on other country/version branches.

## 2) Object catalogue

### 2.1 Data model

| Type | ID | Name | Path | Relevance | Key members (evidence) | Accessibility | Reuse class |
|---|---:|---|---|---|---|---|---|
| table | 80 | Gen. Journal Template | Base Application/Finance/GeneralLedger/Journal/GenJournalTemplate.Table.al | Template-level defaults and page wiring for journals. | Decl L31; Page ID field L69; Type field L101 (OnValidate in this field block); Recurring field L188; No. Series L286; Posting No. Series L314. | Public table object; field triggers are implementation details. | General Journal-specific + architectural pattern |
| table | 232 | Gen. Journal Batch | Base Application/Finance/GeneralLedger/Journal/GenJournalBatch.Table.al | Batch-level behavior and approval-sensitive lifecycle. | Decl L27; Pending Approval field L248; OnDelete L325; OnModify L348; SetupNewBatch L381; CheckBalance L490; OnGeneralJournalBatchBalanced L505; OnGeneralJournalBatchNotBalanced L514. | Public table object; publishes integration events (extension surface). | Published event + General Journal-specific |
| table | 81 | Gen. Journal Line | Base Application/Finance/GeneralLedger/Journal/GenJournalLine.Table.al | Core transaction line before posting/export/print. | Decl L84; Pending Approval field L826; OnDelete L3902; OnInsert L3951; OnModify L3980; SetUpNewLine L4253; OnCheckGenJournalLinePostRestrictions L7585; OnCheckGenJournalLinePrintCheckRestrictions L7591; OnCheckGenJournalLineExportRestrictions L7596; RestrictGenJournalLine L8475. | Public table object; significant logic is internal/local; exposes events and callable checks. | General Journal-specific + architectural pattern |
| table | 454 | Approval Entry | Base Application/OtherCapabilities/Approvals/ApprovalEntry.Table.al | Shared approval persistence used by journal and non-journal records. | Decl L19; Status field L63; Record ID to Approve field L141; Workflow Step Instance ID field L171; OnDelete L237; OnModify L251. | Public automation table; generic approval framework object. | Public framework |
| table | 467 | Workflow Webhook Entry | Base Application/System/Workflow/WorkflowWebhookEntry.Table.al | Webhook approval state (Pending/Continue/Reject/Cancel) tied to Record ID. | Decl L6; Response field L27; Record ID field L54; SetDefaultFilter L94; ShowRecord L146. | Public automation table; behavior consumed by webhook workflow stack. | Public framework + architectural pattern |

### 2.2 UI surfaces

| Type | ID | Name | Path | Relevance | Key members (evidence) | Accessibility | Reuse class |
|---|---:|---|---|---|---|---|---|
| page | 39 | General Journal | Base Application/Finance/GeneralLedger/Journal/GeneralJournal.Page.al | Primary worksheet for general journals; request/cancel approvals from UI. | Decl L46; Request Approval group L1352; Send batch L1371; Send selected lines L1391; Cancel selected lines L1432; SetApprovalStateForBatch L2194; workflow-enabled checks L2210-L2211. | Public worksheet page; action logic is implementation detail. | General Journal-specific |
| page | 256 | Payment Journal | Base Application/Finance/GeneralLedger/Journal/PaymentJournal.Page.al | Worksheet variant using Gen. Journal Line with approval actions. | Decl L44; Request Approval group L1321; send/cancel batch/line L1340/L1359/L1379/L1398; SetApprovalStateForBatch L1980; workflow-enabled checks L2004-L2005. | Public worksheet page. | General Journal-specific |
| page | 255 | Cash Receipt Journal | Base Application/Finance/GeneralLedger/Journal/CashReceiptJournal.Page.al | Worksheet variant with approval actions and status visibility. | Decl L33; Request Approval group L895; send/cancel batch/line L914/L933/L953/L972; SetApprovalStateForBatch L1411; workflow-enabled checks L1435-L1436. | Public worksheet page. | General Journal-specific |
| page | 254 | Purchase Journal | Base Application/Finance/GeneralLedger/Journal/PurchaseJournal.Page.al | Worksheet variant with Gen. Journal Line and approval controls. | Decl L34; Request Approval group L1170; send/cancel actions L1189/L1230/L1250; SetApprovalStateForBatch L1709 and internal helper L1801; workflow-enabled checks L1817-L1818. | Public worksheet page; internal helper procedures present. | General Journal-specific |
| page | 253 | Sales Journal | Base Application/Finance/GeneralLedger/Journal/SalesJournal.Page.al | Worksheet variant with approval controls over journal lines/batch. | Decl L34; Request Approval group L1103; send/cancel actions L1122/L1163/L1183; SetApprovalStateForBatch L1588 and internal helper L1692; workflow-enabled checks L1708-L1709. | Public worksheet page; internal helper procedures present. | General Journal-specific |
| page | 283 | Recurring General Journal | Base Application/Finance/GeneralLedger/Journal/RecurringGeneralJournal.Page.al | Recurring worksheet using Gen. Journal Line model; part of template/type matrix. | Decl L31; Worksheet PageType/SourceTable in declaration block. | Public worksheet page. | General Journal-specific |
| page | 251 | General Journal Batches | Base Application/Finance/GeneralLedger/Journal/GeneralJournalBatches.Page.al | Batch list/admin surface over table 232. | Decl L23; PageType List; SourceTable Gen. Journal Batch. | Public list page. | General Journal-specific |
| page | 101 | General Journal Templates | Base Application/Finance/GeneralLedger/Journal/GeneralJournalTemplates.Page.al | Template admin surface over table 80. | Decl L21; SourceTable Gen. Journal Template; validates risky toggles with confirmations. | Public list page. | General Journal-specific |
| page | 250 | General Journal Template List | Base Application/Finance/GeneralLedger/Journal/GeneralJournalTemplateList.Page.al | Read-only lookup/list of templates. | Decl L19; Editable false; SourceTable Gen. Journal Template. | Public list page. | General Journal-specific |

### 2.3 Validation

| Type | ID | Name | Path | Relevance | Key members (evidence) | Accessibility | Reuse class |
|---|---:|---|---|---|---|---|---|
| codeunit | 11 | Gen. Jnl.-Check Line | Base Application/Finance/GeneralLedger/Journal/GenJnlCheckLine.Codeunit.al | Core business validation for journal lines (accounts, dates, setup, dimensions). | Decl L41; RunCheck L110; DateNotAllowed/IsDateNotAllowed family L312/L339/L353. | Public codeunit object; core validation internals. | Architectural pattern + internal detail |
| codeunit | 9081 | Check Gen. Jnl. Line. Backgr. | Base Application/Finance/GeneralLedger/Journal/CheckGenJnlLineBackgr.Codeunit.al | Background validation and error reporting for worksheet UX. | Decl L20; OnRun invokes RunCheck L30; RunCheck L54. | Public codeunit object used by background task framework. | Architectural pattern |

### 2.4 Posting and preview

| Type | ID | Name | Path | Relevance | Key members (evidence) | Accessibility | Reuse class |
|---|---:|---|---|---|---|---|---|
| codeunit | 231 | Gen. Jnl.-Post | Base Application/Finance/GeneralLedger/Posting/GenJnlPost.Codeunit.al | Posting orchestrator called from pages/actions. | Decl L23; OnRun L28; Code(...) call path L35; invokes GenJnlPostBatch.Run L133; preview entrypoint L177 and GenJnlPostPreview.Preview L183. | Public posting entrypoint; some events/internal hooks. | General Journal-specific + architectural pattern |
| codeunit | 13 | Gen. Jnl.-Post Batch | Base Application/Finance/GeneralLedger/Posting/GenJnlPostBatch.Codeunit.al | Batch posting engine: checks, process loop, commit boundaries. | Decl L37; OnRun L44; ProcessLines L194; CheckDocumentNo L857; CheckGenJnlLine L1279; ConfirmPostingUnvoidableChecks L1315; PostGenJournalLine L1532. | Public codeunit object; most processing internals are local. | Internal detail + architectural pattern |
| codeunit | 19 | Gen. Jnl.-Post Preview | Base Application/Finance/GeneralLedger/Preview/GenJnlPostPreview.Codeunit.al | Simulation path without final posting commit. | Decl L36; OnRun preview harness; Preview(...) entrypoint in declaration block. | Public preview framework object. | Public framework + architectural pattern |

### 2.5 Workflow and approval core

| Type | ID | Name | Path | Relevance | Key members (evidence) | Accessibility | Reuse class |
|---|---:|---|---|---|---|---|---|
| codeunit | 1520 | Workflow Event Handling | Base Application/System/Workflow/WorkflowEventHandling.Codeunit.al | Registers journal approval events and subscribers from approvals. | Decl L19; event code procedures L528/L533/L538/L543; approval subscribers for batch/line send/cancel L836-L857; batch balance subscribers L860/L866. | Public workflow framework codeunit; event subscription plumbing. | Public framework |
| codeunit | 1521 | Workflow Response Handling | Base Application/System/Workflow/WorkflowResponseHandling.Codeunit.al | Executes approval responses: create request, set pending status, restrict/allow. | Decl L17; SetStatusToPendingApprovalCode L494; CreateApprovalRequestsCode L504; SendApprovalRequestForApprovalCode L509; RestrictRecordUsageCode L574; AllowRecordUsageCode L579; SetStatusToPendingApproval L765; CreateApprovalRequests L779; SendApprovalRequestForApproval L812; RestrictRecordUsage L1013; AllowRecordUsage L1022. | Public framework codeunit; many execution procedures are local/internal. | Public framework + architectural pattern |
| codeunit | 1502 | Workflow Setup | Base Application/System/Workflow/WorkflowSetup.Codeunit.al | Creates standard workflows and table relations for journal approval paths. | Decl L16; InitWorkflow L140; inserts GJ batch/line templates L198-L199; InsertApprovalsTableRelations L283 (includes Gen. Journal Line/Batch relations at L303/L305); InsertGeneralJournalBatchApprovalWorkflowTemplate L1252; InsertGeneralJournalLineApprovalWorkflowTemplate L1279; InsertGenJnlBatchApprovalWorkflowSteps L1754; InsertRecApprovalWorkflowSteps L1610. | Public framework codeunit; setup internals mostly local. | Public framework |
| codeunit | 1535 | Approvals Mgmt. | Base Application/OtherCapabilities/Approvals/ApprovalsMgmt.Codeunit.al | Page-facing approval API and open/pending checks for journal objects. | Decl L28; TrySendJournalBatchApprovalRequest L2267; TrySendJournalLineApprovalRequests L2283; TryCancelJournalBatchApprovalRequest L2299; TryCancelJournalLineApprovalRequests L2309; HasOpenApprovalEntries L2136; HasOpenOrPendingApprovalEntries L2157; PreventDeletingRecordWithOpenApprovalEntry L2706; SendJournalLinesApprovalRequests L2875. | Public framework API used by pages/tables. | Public framework |

### 2.6 Restrictions

| Type | ID | Name | Path | Relevance | Key members (evidence) | Accessibility | Reuse class |
|---|---:|---|---|---|---|---|---|
| codeunit | 1550 | Record Restriction Mgt. | Base Application/System/Workflow/RecordRestrictionMgt.Codeunit.al | Enforces usage restrictions for approval-pending records during post/print/export. | Decl L16; RestrictRecordUsage L32; AllowGenJournalBatchUsage L56; CheckRecordHasUsageRestrictions L289; Gen. Journal Line restriction subscribers L360/L382/L423/L436; batch restriction check on line post L506. | Public framework codeunit; many subscribers are public procedures. | Public framework + published event consumption |

### 2.7 Notifications and webhook approvals

| Type | ID | Name | Path | Relevance | Key members (evidence) | Accessibility | Reuse class |
|---|---:|---|---|---|---|---|---|
| codeunit | 1540 | Workflow Webhook Setup | Base Application/System/Workflow/WorkflowWebhookSetup.Codeunit.al | Builds webhook approval workflow definitions including send/continue/reject/cancel branches. | Decl L5; CreateWorkflowDefinition L31; CreateApprovalWorkflow L59; response chain uses RestrictRecordUsage, SetStatusToPendingApproval, SendNotificationToWebhook, Allow/Open/Release steps at L75-L96. | Public webhook setup API; step-construction internals are local. | Public framework + architectural pattern |
| codeunit | 1541 | Workflow Webhook Events | Base Application/System/Workflow/WorkflowWebhookEvents.Codeunit.al | Registers webhook response event and routes continue/reject/cancel back into workflow engine. | Decl L14; WorkflowWebhookResponseReceivedEventCode L24; library wiring L35-L53/L64; handlers for cancel/continue/reject at L149-L170. | Public framework event bridge. | Public framework + published event consumption |
| codeunit | 1542 | Workflow Webhook Responses | Base Application/System/Workflow/WorkflowWebhookResponses.Codeunit.al | Adds SendNotificationToWebhook response and predecessor matrix for GJ/item/requisition/doc approvals. | Decl L3; SendNotificationToWebhookCode L13; predecessor registration subscriber L18; response library registration L49; execution subscriber L57; GenerateRequest call L78. | Public framework response bridge. | Public framework |
| codeunit | 1543 | Workflow Webhook Management | Base Application/System/Workflow/WorkflowWebhookManagement.Codeunit.al | Runtime state machine for pending webhook approvals and permissions. | Decl L14; CanCancel L56; CanRequestApproval L70; GetCanRequestAndCanCancelJournalBatch L89; Cancel/Continue/Reject L119/L169/L199; GenerateRequest L190; schedules notification task L232. | Public framework API; verification methods are implementation details. | Public framework + architectural pattern |
| codeunit | 1545 | Workflow Webhook Notification | Base Application/System/Workflow/WorkflowWebhookNotification.Codeunit.al | Sends HTTP webhook payload and persists notification status/failure details. | Decl L7; payload builder L165 with Row Id / Workflow Step Id / Requested By User Email at L171-L173; called from notification path L154. | Public framework codeunit; OnPrem send method and internals are not extension contract. | Internal detail + architectural pattern |
| table | 468 | Workflow Webhook Notification | Base Application/System/Workflow/WorkflowWebhookNotification.Table.al | Persistence for webhook send status and error payloads. | Decl L3; Status field L28; OnInsert L59; GetErrorDetails/SetErrorDetails/SetErrorMessage L65/L76/L84. | Public framework storage table. | Public framework |
| table | 469 | Workflow Webhook Subscription | Base Application/System/Workflow/WorkflowWebhookSubscription.Table.al | Subscription definition and lifecycle, including workflow definition creation and enable/disable. | Decl L16; Event Code field L56; OnDelete L81; OnModify L112; CreateWorkflowDefinition L187; WorkflowWebhookSetup.CreateWorkflowDefinition call L194; EnableSubscriptionAndWorkflow L232. | Public framework table; workflow lifecycle internals local. | Public framework |

### 2.8 First-party analogues

| Type | ID | Name | Path | Relevance | Key members (evidence) | Accessibility | Reuse class |
|---|---:|---|---|---|---|---|---|
| table | 233 | Item Journal Batch | Base Application/Inventory/Journal/ItemJournalBatch.Table.al | Closest batch analogue: delete protection + approval-state helper. | Decl L11; delete protection call L151; SetApprovalStateForBatch L207; workflow-enabled check L218. | Public table object with internal helper procedure. | Architectural pattern |
| page | 40 | Item Journal | Base Application/Inventory/Journal/ItemJournal.Page.al | Worksheet analogue with send/cancel batch approval actions and state refresh. | Decl L27; send/cancel batch approval actions L906/L927; SetApprovalStateForBatch usage L1221/L1413. | Public worksheet page. | Architectural pattern |
| table | 245 | Requisition Wksh. Name | Base Application/Inventory/Requisition/RequisitionWkshName.Table.al | Worksheet-batch analogue with delete protection and workflow-state helper. | Decl L10; delete protection call L74; SetApprovalStateForWkshBatch L117; workflow-enabled check L129. | Public table object with internal helper procedure. | Architectural pattern |

### 2.9 Tests

| Type | ID | Name | Path | Relevance | Key members (evidence) | Accessibility | Reuse class |
|---|---:|---|---|---|---|---|---|
| codeunit (Test) | 134321 | General Journal Batch Approval | Tests-General Journal/GeneralJournalBatchApproval.Codeunit.al | Validates batch approval behavior, posting/preview restrictions, comments, deletion behavior. | Decl L1; CanPreviewPost L37; CannotPost L75. | Test-only. | Version-specific evidence |
| codeunit (Test) | 134322 | General Journal Line Approval | Tests-General Journal/GeneralJournalLineApproval.Codeunit.al | Validates line approval lifecycle and restriction handling. | Decl L1; DeleteAfterSendingRequest L42. | Test-only. | Version-specific evidence |
| codeunit (Test) | 134219 | WFWH General Journal Batch | Tests-General Journal/WFWHGeneralJournalBatch.Codeunit.al | Validates webhook batch workflows and relation setup. | Decl L1; workflow path test L59. | Test-only. | Version-specific evidence |
| codeunit (Test) | 134220 | WFWH General Journal Line | Tests-General Journal/WFWHGeneralJournalLine.Codeunit.al | Validates webhook line workflows and pending-entry behavior. | Decl L1; HasPendingWorkflowWebhookEntryByRecordId L35. | Test-only. | Version-specific evidence |

## 3) Dependency map (verified/provisional)

### Verified edges

| From | To | Why | Status | Evidence |
|---|---|---|---|---|
| Page 39 General Journal | Codeunit 1535 Approvals Mgmt. | Request/Cancel approval actions call approvals API. | Verified | GeneralJournal.Page.al L1371/L1391/L1432 |
| Pages 255/256/254/253 | Codeunit 1535 Approvals Mgmt. | Same pattern across worksheet variants. | Verified | CashReceiptJournal.Page.al L914/L933/L953/L972; PaymentJournal.Page.al L1340/L1359/L1379/L1398; PurchaseJournal.Page.al L1189/L1230/L1250; SalesJournal.Page.al L1122/L1163/L1183 |
| Codeunit 1535 Approvals Mgmt. | Codeunit 1520 Workflow Event Handling | Approval send/cancel events are handled by workflow subscribers. | Verified | WorkflowEventHandling.Codeunit.al L836-L857 |
| Codeunit 1520 Workflow Event Handling | Codeunit 1521 Workflow Response Handling | Event/response library matrix links journal events to responses. | Verified | WorkflowEventHandling.Codeunit.al L155-L162; WorkflowResponseHandling.Codeunit.al L494/L504/L509/L574/L579 |
| Codeunit 1521 Workflow Response Handling | Codeunit 1535 Approvals Mgmt. | Responses execute approval create/send and pending status operations. | Verified | WorkflowResponseHandling.Codeunit.al L765/L779/L812 |
| Codeunit 1521 Workflow Response Handling | Codeunit 1550 Record Restriction Mgt. | Restrict/allow responses enforce approval lock semantics. | Verified | WorkflowResponseHandling.Codeunit.al L1013/L1022 |
| Table 232 Gen. Journal Batch | Codeunit 1535 Approvals Mgmt. | Modify/delete guarded by open approval checks. | Verified | GenJournalBatch.Table.al L327/L350 |
| Table 81 Gen. Journal Line | Codeunit 1535 Approvals Mgmt. | Modify/delete guarded by open approval checks. | Verified | GenJournalLine.Table.al L3914/L3922/L8422/L8424 |
| Codeunit 231 Gen. Jnl.-Post | Codeunit 13 Gen. Jnl.-Post Batch | Posting orchestration delegates to batch engine. | Verified | GenJnlPost.Codeunit.al L133 |
| Codeunit 231 Gen. Jnl.-Post | Codeunit 19 Gen. Jnl.-Post Preview | Preview path delegates to preview engine. | Verified | GenJnlPost.Codeunit.al L177/L183 |
| Codeunit 13 Gen. Jnl.-Post Batch | Table 81 Gen. Journal Line checks | Batch engine runs per-line checks and document checks. | Verified | GenJnlPostBatch.Codeunit.al L194/L857/L1279/L1532 |
| Table 81 Gen. Journal Line | Codeunit 1550 Record Restriction Mgt. | Post/print/export restriction extension points are consumed by subscribers. | Verified | GenJournalLine.Table.al L7585/L7591/L7596; RecordRestrictionMgt.Codeunit.al L360/L382/L423/L436/L506 |
| Codeunit 1502 Workflow Setup | Journal objects + Approval Entry relation model | Workflow templates and table relations include GJ batch/line. | Verified | WorkflowSetup.Codeunit.al L198-L199/L283/L303/L305/L1252/L1279 |
| Codeunit 1542 Workflow Webhook Responses | Codeunit 1543 Workflow Webhook Management | Webhook response execution generates webhook request entries. | Verified | WorkflowWebhookResponses.Codeunit.al L78 |
| Codeunit 1543 Workflow Webhook Management | Codeunit 1545 Workflow Webhook Notification | Runtime schedules notification task and starts notification. | Verified | WorkflowWebhookManagement.Codeunit.al L190/L232 |
| Codeunit 1545 Workflow Webhook Notification | Table 468 Workflow Webhook Notification | Notification status and error details persisted. | Verified | WorkflowWebhookNotification.Table.al L28/L65/L76/L84 |
| Table 469 Workflow Webhook Subscription | Codeunit 1540 Workflow Webhook Setup | Subscription creates workflow definitions for event code and conditions. | Verified | WorkflowWebhookSubscription.Table.al L187/L194 |
| Codeunit 1541 Workflow Webhook Events | Workflow engine | Continue/reject/cancel callbacks re-enter workflow event handling. | Verified | WorkflowWebhookEvents.Codeunit.al L149-L170 |
| Table 233 Item Journal Batch / Table 245 Requisition Wksh. Name | Same approval/workflow pattern | First-party analogues for batch-level approval state and workflow-enabled checks. | Verified | ItemJournalBatch.Table.al L151/L207/L218; RequisitionWkshName.Table.al L74/L117/L129 |

### Provisional edges

| From | To | Why | Status | Evidence |
|---|---|---|---|---|
| Page 283 Recurring General Journal | Approval workflow state helpers | Likely shares generic Gen. Journal Line approval checks, but direct send/cancel actions were not confirmed in this pass. | To verify | Page exists and uses Gen. Journal Line (RecurringGeneralJournal.Page.al L31) |
| Non-General-Journal pages using table 81 | Same approval APIs | Some page variants may call shared helper paths not fully enumerated here. | To verify | Pattern confirmed on pages 39/255/256/254/253 |

## 4) Unresolved research questions
- **To verify** Exact workflow-step differences between standard approval templates (Workflow Setup) and webhook-generated definitions for each journal scenario, beyond the confirmed restrict/pending/notify/allow-open-release sequence.
- **To verify** Whether any extension apps in this workspace branch add subscribers that materially alter General Journal approval behavior (current pass focused on first-party apps listed in this artifact).
- **To verify** Full behavior of recurring journal approvals in page 283 from UI perspective (explicit request approval action group not yet confirmed in this pass).

## 5) Runtime-oriented reading order
1. **Verified** Start with data model: table 80 -> table 232 -> table 81.
2. **Verified** Move to worksheet actions: page 39 (then 255/256/254/253 variants).
3. **Verified** Trace approval API entrypoints in codeunit 1535 (TrySend/TryCancel/SendJournalLines...).
4. **Verified** Follow workflow event routing in codeunit 1520.
5. **Verified** Follow workflow response execution in codeunit 1521.
6. **Verified** Inspect workflow template construction in codeunit 1502.
7. **Verified** Trace posting path: codeunit 231 -> codeunit 13; then preview via codeunit 19.
8. **Verified** Inspect restriction enforcement in codeunit 1550 plus table 81 check procedures.
9. **Verified** Inspect webhook branch: codeunits 1540/1541/1542/1543/1545 and tables 467/468/469.
10. **Verified** Validate behavior intent with tests: 134321, 134322, 134219, 134220.
11. **Inference** Use item/requisition analogues (table 233/page 40/table 245) as pattern cross-checks for batch-approval architecture.

## 6) Search coverage and not located

### Coverage performed
- **Verified** Declaration and object-ID scans for all listed objects in Base Application, System workflow stack, Inventory analogues, and Tests-General Journal.
- **Verified** Symbol-level searches for approval action groups and API calls:
  - Request approval actions on page variants.
  - TrySend/TryCancel/SendJournalLines entrypoints in Approvals Mgmt.
  - Workflow event codes and approval subscribers in Workflow Event Handling.
  - Workflow responses for set pending/restrict/allow and approval creation/sending.
  - Restriction enforcement subscribers for Gen. Journal Line post/print/export checks.
  - Webhook response setup and payload generation (Row Id, Workflow Step Id, Requested By User Email).
- **Verified** Test scenario probes for posting/preview blocks and webhook approval flows.

### Not located
- **Not located** A dedicated, separate General Journal approval data table (journal approvals use shared table 454 Approval Entry and webhook table 467 when webhook path is used).
- **Not located** A dedicated General Journal-only notification object outside the shared webhook notification stack (1540-1545, 468, 469).

### Recommendations
- **Recommendation** Add a follow-up artifact that maps each confirmed workflow template step sequence (standard and webhook) into side-by-side diagrams for batch vs line approvals.
- **Recommendation** In a second pass, enumerate all first-party subscribers to Gen. Journal Line restriction events and classify whether each can alter posting outcome for journal lines.