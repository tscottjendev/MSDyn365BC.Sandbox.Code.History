# General Journal Approvals - Session 1 Reconnaissance

## 1. Environment Summary

- Repository branch: `gb-29-vNext`
- Repository snapshot: `gb-29.0.53247.0-vNext`
- Business Central version represented by the checked-in source: `29.0.53247.0`
- Platform version in the inspected app manifests: `29.0.0.0`
- Runtime / application family: BC 29, GB snapshot
- Country/region signal: `GB` in `version.txt` and app brief text

The repository contains source for the Microsoft first-party applications needed for this session, including:

- Base Application
- System Application
- Application
- Tests-General Journal
- Tests-Workflow

I did not see a visible `.alpackages` folder in the workspace listing, so I did not rely on local package caches for this reconnaissance.

## 2. Dependency Summary

### Base Application

- `Base Application` depends on `System Application` and `Business Foundation`.
- `Base Application` source is present in the repository.

### Application

- `Application` depends on `System Application`, `Business Foundation`, and `Base Application`.
- `Application` source is present in the repository.

### Tests-General Journal

- `Tests-General Journal` depends on `Tests-TestLibraries`, `System Application Test Library`, `Library Variable Storage`, `Any`, `Library Assert`, and `Business Foundation Test Libraries`.
- The workspace includes source folders for the Microsoft test libraries visible in the repo tree, so the inspected test surface is source-backed rather than symbol-only.

### Tests-Workflow

- `Tests-Workflow` depends on `Tests-TestLibraries`, `System Application Test Library`, and `Library Variable Storage`.
- The workflow test suite is also source-present in the repository.

## 3. Source Versus Symbol Availability

Source is available for the core Microsoft apps relevant to this session. I did not identify a dependency that was only visible as a symbol package in the workspace view I inspected.

That said, I did not exhaustively verify every dependency app folder for this reconnaissance. The practical conclusion is that the General Journal approval surface can be traced from checked-in source without needing a symbol-only fallback for the obvious entry points.

## 4. Candidate Object Inventory

The table below lists the objects that appear most relevant to General Journal approval workflows, grouped by the role they play in the flow.

| Kind | ID | Name | Namespace | Owning app | File path | Source available | Public visibility | Why it needs later examination |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Page | 39 | General Journal | Microsoft.Finance.GeneralLedger.Journal | Base Application | Base Application/Finance/GeneralLedger/Journal/GeneralJournal.Page.al | Yes | Yes | Primary user-facing entry point; contains Send/Cancel/Approve actions and approval state logic. |
| Page | 251 | General Journal Batches | Microsoft.Finance.GeneralLedger.Journal | Base Application | Base Application/Finance/GeneralLedger/Journal/GeneralJournalBatches.Page.al | Yes | Yes | Batch-level navigation surface that can gate approval entry points and batch context. |
| Codeunit | 1502 | Workflow Setup | System.Automation | Base Application | Base Application/System/Workflow/WorkflowSetup.Codeunit.al | Yes | Yes | Registers workflow templates and the General Journal batch/line approval templates. |
| Codeunit | 1520 | Workflow Event Handling | System.Automation | Base Application | Base Application/System/Workflow/WorkflowEventHandling.Codeunit.al | Yes | Yes | Defines the workflow event codes for General Journal batch and line approval. |
| Codeunit | 1521 | Workflow Response Handling | System.Automation | Base Application | Base Application/System/Workflow/WorkflowResponseHandling.Codeunit.al | Yes | Yes | Defines approval-request responses and batch/line approval execution hooks. |
| Codeunit | 1540 | Workflow Webhook Setup | System.Automation | Base Application | Base Application/System/Workflow/WorkflowWebhookSetup.Codeunit.al | Yes | Yes | Builds webhook approval workflows for General Journal batch and line records. |
| Codeunit | 1543 | Workflow Webhook Management | System.Automation | Base Application | Base Application/System/Workflow/WorkflowWebhookManagement.Codeunit.al | Yes | Yes | Controls webhook request/cancel state for General Journal batch and line approval. |
| Codeunit | 134321 | General Journal Batch Approval | n/a | Tests-General Journal | Tests-General Journal/GeneralJournalBatchApproval.Codeunit.al | Yes | Unknown | Direct approval-flow test coverage for batch-level behavior, preview/post behavior, and approval entry effects. |
| Codeunit | 134322 | General Journal Line Approval | n/a | Tests-General Journal | Tests-General Journal/GeneralJournalLineApproval.Codeunit.al | Yes | Unknown | Direct approval-flow test coverage for line-level behavior, deletion, cancellation, and record restrictions. |
| Codeunit | 134219 | WFWH General Journal Batch | n/a | Tests-General Journal | Tests-General Journal/WFWHGeneralJournalBatch.Codeunit.al | Yes | Unknown | Webhook-specific batch approval test coverage; useful for request/cancel and table-relation verification. |
| Codeunit | 134220 | WFWH General Journal Line | n/a | Tests-General Journal | Tests-General Journal/WFWHGeneralJournalLine.Codeunit.al | Yes | Unknown | Webhook-specific line approval test coverage; useful for record restriction, cancel, approval, and rejection paths. |
| Codeunit | 134323 | Approval History Tests | n/a | Tests-General Journal | Tests-General Journal/ApprovalHistoryTests.Codeunit.al | Yes | Unknown | Confirms how posted General Journal approvals are persisted and cleaned up. |
| Codeunit | 134920 | ERM General Journal UT | n/a | Tests-General Journal | Tests-General Journal/ERMGeneralJournalUT.Codeunit.al | Yes | Unknown | Broad General Journal unit coverage; useful for surrounding journal behavior that can affect approval entry points. |

## 5. Detected Customisations

No repository-specific custom production General Journal approval implementation was identified in the inspected scope.

What I did find is Microsoft-standard approval plumbing in Base Application and System Application:

- General Journal page actions for send, cancel, approve, reject, and delegate.
- Workflow template registration for General Journal batch and line approvals.
- Webhook workflow support for General Journal batch and line approvals.
- Dedicated Microsoft test coverage for both direct and webhook-driven approval flows.

So the current evidence says this repository is carrying the standard first-party implementation plus tests, not a separate custom approval layer.

## 6. Version Risks

- This is a BC 29 source snapshot, so any later 29.x hotfix or platform update may change workflow action wiring, template names, or test expectations.
- The General Journal approval flow spans both classic approval management and webhook-based approval handling; a later session should keep those paths separate until the control point is confirmed.
- The checked-in source is GB-specific, so localized captions and template descriptions may differ from another country/region branch.
- `Application` and `Base Application` are source-present here, but any external environment that lacks the same source layout may expose only symbols and not the same line-level evidence.

## 7. Recommended Session 2 Starting Points

1. `Base Application/Finance/GeneralLedger/Journal/GeneralJournal.Page.al`
2. `Base Application/System/Workflow/WorkflowSetup.Codeunit.al`
3. `Tests-General Journal/WFWHGeneralJournalLine.Codeunit.al`

If Session 2 needs the direct approval path rather than webhook-specific coverage, swap in `Tests-General Journal/GeneralJournalLineApproval.Codeunit.al`.

## 8. Unresolved Questions

- Is there any non-Microsoft extension code elsewhere in the workspace that hooks General Journal approval events? I did not find one in this reconnaissance pass.
- Are batch approval and line approval both intended to be enabled in the target scenario, or only one of them? The Base Application supports both.
- Do the current tests cover all expected approval-comment and posted-approval-history transitions, or only the mainline scenarios?
- Do any symbol-only dependencies outside this repository alter the behavior of the inspected workflow path? I did not confirm that exhaustively.

### Next-session handoff

- Facts established:
  - BC 29.0.53247.0 is the checked-in snapshot.
  - Base Application, System Application, Application, and the relevant General Journal test apps are present as source.
  - General Journal batch and line approval support exists in standard Microsoft source.
- Standard symbols verified:
  - `Workflow Event Handling`
  - `Workflow Response Handling`
  - `Workflow Setup`
  - `Workflow Webhook Setup`
  - `Workflow Webhook Management`
- Target-specific symbols verified:
  - `General Journal`
  - `General Journal Batches`
  - `General Journal Batch Approval`
  - `General Journal Line Approval`
  - `WFWH General Journal Batch`
  - `WFWH General Journal Line`
  - `Approval History Tests`
  - `ERM General Journal UT`
- Important interpretations:
  - The approval experience appears to be standard first-party implementation, not a repo-specific customization.
  - Webhook approval support is part of the same standard workflow surface and deserves separate tracing.
- Unresolved questions:
  - Whether any external symbol-only dependency changes the observed flow.
  - Whether any non-Microsoft code in another app subscribes to the same approval events.
  - Whether Session 2 should prioritize direct approval or webhook approval first.
- Version-sensitive findings:
  - Workflow template names, captions, and action availability can change across BC 29 hotfixes.
  - GB localization may affect captions and test text.
- Files that provide the strongest evidence:
  - Base Application/Finance/GeneralLedger/Journal/GeneralJournal.Page.al
  - Base Application/System/Workflow/WorkflowSetup.Codeunit.al
  - Base Application/System/Workflow/WorkflowWebhookSetup.Codeunit.al
  - Base Application/System/Workflow/WorkflowWebhookManagement.Codeunit.al
  - Tests-General Journal/WFWHGeneralJournalLine.Codeunit.al
  - Tests-General Journal/GeneralJournalLineApproval.Codeunit.al
  - Tests-General Journal/ApprovalHistoryTests.Codeunit.al
- Documents created:
  - .design/architecture/general-journal-approvals/00-environment-and-reconnaissance.md
- Recommended scope for the next session:
  - Trace the user-facing General Journal approval actions into Workflow Setup and Workflow Webhook Management, then follow the direct approval and webhook-specific tests only as far as needed to confirm the exact control points.
