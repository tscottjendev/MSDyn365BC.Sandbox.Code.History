# General Journal Approvals — Session 5: Unresolved and version-sensitive findings

Companion to [06-business-central-extension-handoff.md](06-business-central-extension-handoff.md), [01-object-and-accessibility-inventory.md](01-object-and-accessibility-inventory.md) and [07-standard-symbol-evidence-index.md](07-standard-symbol-evidence-index.md).

Scope of evidence: branch `gb-29-vNext`, commit `a74fec3ec909d`, application `29.0.53247.0`, platform `29.0.0.0`, GB localization.

Nothing in this document is presented as a fact about any other Business Central version.

---

## 1. Contradictions and corrections against earlier sessions

Earlier conclusions are **not** silently overwritten. Each item states the earlier conclusion, the evidence found in Session 5, and the corrected position.

### 1.1 `Approvals Mgmt.` object ID

| | |
| --- | --- |
| Earlier conclusion | Session 2 recorded the approvals codeunit as **`Codeunit 134 "Approvals Mgmt."`**. |
| Session 5 evidence | `ApprovalsMgmt.Codeunit.al` line 28 declares `codeunit 1535 "Approvals Mgmt."`. |
| Corrected position | The ID is **1535**. `134` does not identify this object in this snapshot. |
| Impact | Any target code written from Session 2's ID would not compile. All downstream documents use 1535. |
| Confidence | High — declaration line read directly. |

### 1.2 `Company-Initialize` object ID

| | |
| --- | --- |
| Earlier conclusion | Session 2 recorded the registration trigger as **`Codeunit 1 "Company-Initialize"`**. |
| Session 5 evidence | `CompanyInitialize.Codeunit.al` declares `codeunit 2 "Company-Initialize"`. |
| Corrected position | The ID is **2**. |
| Impact | Cosmetic for the target extension (it does not reference this object), but the inventory must be accurate. |
| Confidence | High. |

### 1.3 `BuildGeneralJournalBatchTypeConditions` is not callable

| | |
| --- | --- |
| Earlier conclusion | Session 2 §8 classified `Workflow Setup.BuildGeneralJournalBatchTypeConditions` as a **Public supported dependency**, and Session 2 §9 recommended calling it from a target extension as a condition-string example. |
| Session 5 evidence | `WorkflowSetup.Codeunit.al` line 2567 declares it as **`local procedure`**. |
| Corrected position | It is **Observable but inaccessible implementation**. A dependent extension cannot call it. |
| Contrast | `BuildGeneralJournalLineTypeConditions` at line 2579 **is** a public `procedure` — but it is General Journal-specific and takes a `Gen. Journal Line` parameter, so it is still not usable for another domain's subject table. |
| Corrected recommendation | The target builds its own condition string for its own subject table. Only `BuildNoPendingApprovalsConditions` (L2473) and `BuildPendingApprovalsConditions` (L2481) are public **and** domain-neutral. |
| Impact | High — a target following Session 2 §9 literally would fail to compile. |
| Confidence | High — declaration line read directly. |

### 1.4 `OnCheckGenJournalLinePostRestrictions` carries `[Scope('OnPrem')]`

| | |
| --- | --- |
| Earlier conclusion | Session 4 listed `Gen. Journal Line.OnCheckGenJournalLinePostRestrictions` among reusable posting-related events, without recording a scope restriction. |
| Session 5 evidence | `GenJournalLine.Table.al` lines 7578–7600: the event at line 7585 is decorated with `[IntegrationEvent(true, false)]` **and `[Scope('OnPrem')]`**. The same applies to `OnCheckGenJournalLinePrintCheckRestrictions` (L7591). `OnCheckGenJournalLineExportRestrictions` (L7596) has **no** `Scope` attribute. |
| Corrected position | The post and print-check restriction events are **Version-sensitive or uncertain**, not straightforwardly reusable. |
| Impact | Medium-to-high for a Cloud-target extension. See §2. |
| Confidence | High for the attribute's presence; the *consequence* for a Cloud-target extension is unresolved (§2). |

### 1.5 Interpretation correction — `[IntegrationEvent(true, false)]` first parameter

This is an **AL-semantics interpretation correction**, not a source contradiction. The source is the same; the earlier reading of it was wrong.

| | |
| --- | --- |
| Earlier interpretation | Session 2 §8 read the first `[IntegrationEvent]` parameter as meaning "global subscription allowed". |
| Correct AL semantics | The first parameter is **`IncludeSender`** — it controls whether the publishing object instance is passed to subscribers. The second parameter is `GlobalVarAccess`. Neither controls who may subscribe. |
| Corrected position | `[IntegrationEvent(true, false)]` means *include sender, no global variable access*. It says nothing about subscription scope. Subscription eligibility is governed by object accessibility and `[Scope]`. |
| Impact | Any accessibility conclusion in Session 2 that rested on the "global subscription" reading must be re-derived from the object's `Access` property and `[Scope]` attribute instead. |
| Confidence | High. |

### 1.6 Items where Session 5 confirms rather than contradicts

Recorded so the target does not re-investigate:

- Codeunits 1501, 1502, 1520, 1521, 1535, 1550 and table 454 declare **no `Access` property**, so they are public by default. Sessions 2–4 assumed this; Session 5 verified it.
- `Enum 460 "Workflow Approver Type"` and `Enum 465 "Workflow Approver Limit Type"` are both `Extensible = true`, as Session 2 assumed.
- `Restricted Record` is table **1550**, the same numeric ID as `Record Restriction Mgt.` (a codeunit). Both IDs are correct; this is a coincidence, not an error in the earlier sessions.

---

## 2. Scope-restricted symbols

`[Scope('OnPrem')]` restricts a symbol to on-premises consumption. Whether an extension whose `app.json` declares a Cloud target can subscribe to a `[Scope('OnPrem')]` integration event **was not resolved in this session** — it depends on the compiler and symbol behaviour in the target environment, which is not observable from this source repository.

| Symbol | File | Line | Attributes | Consequence |
| --- | --- | --- | --- | --- |
| `Gen. Journal Line.OnCheckGenJournalLinePostRestrictions()` | `GenJournalLine.Table.al` | 7585 | `[IntegrationEvent(true, false)]`, `[Scope('OnPrem')]` | The **primary posting-restriction hook** may be unavailable to a Cloud-target extension |
| `Gen. Journal Line.OnCheckGenJournalLinePrintCheckRestrictions()` | `GenJournalLine.Table.al` | 7591 | `[IntegrationEvent(true, false)]`, `[Scope('OnPrem')]` | Check-printing barrier hook |
| `Gen. Journal Batch.OnMoveGenJournalBatch(RecordID)` | `GenJournalBatch.Table.al` | 526 | `[IntegrationEvent(true, false)]`, `[Scope('OnPrem')]` | The hook that drives `PostApprovalEntriesMoveGenJournalBatch`, i.e. approval-history archiving on posting |
| `Codeunit 1804 "Approval Workflow Setup Mgt."` — all inspected public procedures | `ApprovalWorkflowSetupMgt.Codeunit.al` | — | `[Scope('OnPrem')]` | Legacy approval-setup wizard; **do not depend on it under any target** |

**Contrast — not scope-restricted:**

| Symbol | File | Line | Attributes |
| --- | --- | --- | --- |
| `Gen. Journal Line.OnCheckGenJournalLineExportRestrictions()` | `GenJournalLine.Table.al` | 7596 | `[IntegrationEvent(true, false)]`, no `Scope` |
| `Gen. Journal Batch.OnCheckGenJournalLineExportRestrictions()` | `GenJournalBatch.Table.al` | 520 | `[IntegrationEvent(true, false)]`, no `Scope` |

**I** — the asymmetry within the same restriction family (export unrestricted, post and print-check restricted) suggests the scope decoration is historical rather than deliberate policy, but that is an interpretation and cannot be proved from source.

**Design consequence for the target (recommendation, not a fact):** do not build the target's enforcement on any of the scope-restricted events. Publish the target's **own** restriction-check integration event, without a `Scope` attribute, from the target's own deepest shared processing layer. See [06 §9.4](06-business-central-extension-handoff.md#94-scope-caveat-version-sensitive) and [06 §11.1](06-business-central-extension-handoff.md#111-objects-the-target-must-create).

**How the target revalidates:** in the target repository, go to definition on each symbol in the target's own symbol set, confirm whether `[Scope('OnPrem')]` is still present, and attempt to compile a throwaway `[EventSubscriber]` against it with the target's actual `target` setting in `app.json`. Record the compiler result.

---

## 3. Unresolved questions carried forward

Attributed to the session that raised them. None of these were resolved in Session 5.

### 3.1 Untraced code paths

| # | Question | Origin | Why it matters |
| --- | --- | --- | --- |
| 3.1.1 | The webhook / Power Automate approval path is entirely untraced: `Codeunit 1540 "Workflow Webhook Setup"`, `Codeunit 1543 "Workflow Webhook Management"`, `Table 467 "Workflow Webhook Entry"`. | S1, S2 | `Gen. Journal Line.OnModify` calls `WorkflowWebhookManagement.HasPendingWorkflowWebhookEntryByRecordId`, so the webhook path **already participates in edit prevention**. A target that ignores it may produce inconsistent behaviour if Power Automate approvals are configured. |
| 3.1.2 | `Codeunit "Workflow Request Page Handling"` was never inspected, although `InitWorkflow` calls into it. | S2 | Determines whether the target's events need a request-page entity for filter configuration. |
| 3.1.3 | `Workflow Setup.InsertJobQueueData` was never inspected. | S2 | May imply background-processing infrastructure the target should mirror. |

### 3.2 Cross-path and dual-workflow interactions

| # | Question | Origin | Why it matters |
| --- | --- | --- | --- |
| 3.2.1 | When both the batch and line approval workflows are enabled, final **batch** approval calls `Record Restriction Mgt.AllowGenJournalBatchUsage`, which deletes **all** `Restricted Record` rows for the batch and for every line in it — including restrictions imposed by the **line** workflow. Is this intentional? | S3, S5 | If unintentional it is a real correctness gap: batch approval silently unlocks lines whose own approvals are still pending. **No first-party test covers the dual-enablement combination.** This is the primary reason [06 §14.5](06-business-central-extension-handoff.md#145-recommendation) recommends against replicating the hybrid model. |
| 3.2.2 | Does an intermediate approval (the `Pending Approvals > 0` loop-back to `SendApprovalRequestForApproval`) produce duplicate notifications to already-notified approvers? | S3 | Narrowed but not proven. Affects the target's notification design. |
| 3.2.3 | Can a record hold an `Approval Entry` with `Status = Approved` while simultaneously carrying a `Restricted Record` row? | S4 | **Yes** — this is the standard stale-approval behaviour (edit an approved line and the automatic subscriber re-restricts it). What is unresolved is whether any first-party UI communicates that state to the user. |

### 3.3 Authorization and guard gaps

| # | Question | Origin | Why it matters |
| --- | --- | --- | --- |
| 3.3.1 | Cancel authorization is enforced **only** by the page action's `Enabled` property calling `CanCancelApprovalForRecord`. `Approvals Mgmt.TryCancelJournalBatchApprovalRequest` (L2299) performs no sender check internally. | S3 | Any non-UI caller (API, web service, another extension) can cancel an approval it did not raise. The target must place the check inside the procedure. |
| 3.3.2 | `Confirm` and `Message` calls in `TrySendJournalBatchApprovalRequest`, `TryCancelJournalLineApprovalRequests`, `DelegateApprovalRequests` and `PreventInsertRecIfOpenApprovalEntryExist` are **not** `GuiAllowed`-guarded. What happens in job queue, web service or test contexts? | S3, S4 | Unverified. Could throw or silently take the default branch. The target must guard its own equivalents. |
| 3.3.3 | Approving an **empty** batch has no "nothing to approve" guard. | S3 | Produces an approved batch with no lines. The target should decide explicitly whether to guard this. |
| 3.3.4 | `Approvals Mgmt.OnRejectApprovalRequest` fires **before** the entry status is set to `Rejected`. | S3 | A subscriber reading `Status` at that point sees the pre-transition value. The target's own events should either fire after the write or document the ordering. |

### 3.4 Data-lifecycle questions

| # | Question | Origin | Why it matters |
| --- | --- | --- | --- |
| 3.4.1 | `Approval Entry."Related to Change"` is assumed always `false` for General Journal. Unproven. | S4 | Only matters if the target intends to use change-approval workflows. |
| 3.4.2 | Deleting a journal line deletes its approval entries outright (`DeleteApprovalEntriesAfterDeleteGenJournalLine`), destroying the approval history. No archival occurs. | S3, S4 | The target must decide whether its domain requires history retention on delete, and if so use `PostApprovalEntries` before deleting. |
| 3.4.3 | Lines created **before** a workflow was enabled may carry no restriction until they are next modified. | S4 | An enablement-time backfill may be required. The target must decide. |
| 3.4.4 | An `Approval Entry` can exist with no corresponding `Restricted Record` row, in which case posting is allowed. | S4 | Reinforces that `Restricted Record` — not `Approval Entry.Status` — is the enforceable lock. The target must not assume the two are always in step. |

### 3.5 Reusability questions for a foreign subject table

| # | Question | Origin | Why it matters |
| --- | --- | --- | --- |
| 3.5.1 | Does `Approvals Mgmt.PopulateApprovalEntryArgument` (L1188) expose a supported hook — an `OnAfterPopulateApprovalEntryArgument`-style event — allowing a foreign table to add `Document Type`, `Document No.`, `Amount`, `Currency Code`? **No such event was verified to exist in this snapshot.** | S5 | Without it, the target must populate those fields on the argument record itself before calling `MakeApprovalEntry`. See [06 §7.1](06-business-central-extension-handoff.md#7-approval-entry-integration). |
| 3.5.2 | How does `Approvals Mgmt.IsSufficientApprover` (L1450) behave for a subject table it has no case arm for? | S5 | Determines whether approver-limit chains work at all for the target's table. The `Gen. Journal Batch` arm returns `true` with `ApporvalChainIsUnsupportedMsg`; the generic path's behaviour for a foreign table is unverified. |
| 3.5.3 | `Codeunit "Batch Processing Mgt."` members were never verified. It is named in [06 §6.4](06-business-central-extension-handoff.md#64-multi-record-send-f) and [06 §11.1](06-business-central-extension-handoff.md#111-objects-the-target-must-create) as a pattern to reproduce. | S3, S5 | If the target needs multi-record send, `BatchProcess`'s signature and accessibility must be verified in the target's symbols first. |

### 3.6 Known bypasses of the posting guard

Recorded in Session 4; unchanged. Each is a real gap in the standard enforcement, and each has an equivalent the target must close in its own design.

| # | Bypass |
| --- | --- |
| 3.6.1 | A direct call to `Codeunit 12 "Gen. Jnl.-Post Line"` (`RunWithCheck` / `RunWithoutCheck`) was not observed to raise `OnCheckGenJournalLinePostRestrictions`. |
| 3.6.2 | A subscriber setting `IsHandled` on `Gen. Jnl.-Post.OnBeforeGenJnlPostBatchRun` exits before the batch engine runs. |
| 3.6.3 | A subscriber setting `IsHandled` on `Gen. Jnl.-Post Batch.OnBeforeCheckLine` exits `CheckLine` before `CheckRestrictions`. |
| 3.6.4 | A subscriber setting `IsHandled` on `Record Restriction Mgt.OnBefore…PostRestrictions` skips a specific standard restriction subscriber. |
| 3.6.5 | `Modify(false)` / `Insert(false)` / `ModifyAll` skip the table triggers, so the automatic restriction is never (re-)imposed. |
| 3.6.6 | `PreviewMode` deliberately skips `CheckRestrictions`; first-party test `CanPreviewPost` asserts this. |

---

## 4. Version-sensitive findings and revalidation guidance

Each row is true for the analysed snapshot only. The **Revalidation method** column tells the target how to re-establish the fact against its own symbols.

| # | Finding | Risk if it changes | Revalidation method |
| --- | --- | --- | --- |
| 4.1 | `[Scope('OnPrem')]` on `OnCheckGenJournalLinePostRestrictions`, `OnCheckGenJournalLinePrintCheckRestrictions`, `OnMoveGenJournalBatch` (§2) | Enforcement or history-archiving hook silently unavailable | Go to definition in the target's symbols; check the attribute; compile a throwaway subscriber under the target's `app.json` `target` setting |
| 4.2 | `BuildNoPendingApprovalsConditions` / `BuildPendingApprovalsConditions` encode a filter over `Approval Entry."Pending Approvals"`, a FlowField counting `Created`/`Open` entries for the same `Record ID to Approve` + `Workflow Step Instance ID` | **Silent** failure of final-approval detection: the workflow would never take the "release" branch | Read both procedures and the `Pending Approvals` FlowField definition side by side, then prove behaviourally with a two-approver test that asserts the record is released only after the second approval |
| 4.3 | `Enum "Approval Status"` ordinals (`0 Created`, `1 Open`, `2 Canceled`, `3 Rejected`, `4 Approved`, `5 ' '`) are consumed **positionally** by `GetApprovalEntryStatusValueName` via `AsInteger() + 1` | Inserting a value shifts every downstream index | Inspect the enum declaration and search the target's own code for `AsInteger()` arithmetic over `Approval Status`. Never index the enum positionally in target code |
| 4.4 | `Enum 460 "Workflow Approver Type"` and `Enum 465 "Workflow Approver Limit Type"` are `Extensible = true` | An enum extension fails to compile | Inspect the enum declarations in the target's symbols before adding values. Adding a value also requires matching approver-resolution logic, which standard code will not provide |
| 4.5 | `Workflow Setup.InsertRecApprovalWorkflowSteps` has a **9-parameter** signature (`Workflow`, condition string, send event code, create-requests response code, send-request response code, cancel event code, `Workflow Step Argument`, `ShowConfirmationMessage`, `RemoveRestrictionOnCancel`) | Template construction fails to compile | Compare the target symbol's signature against [06 §11.4](06-business-central-extension-handoff.md#114-template-construction-verified-pattern) before writing template code |
| 4.6 | Response option group literals `GROUP 0`, `GROUP 2`, `GROUP 4`, `GROUP 5` passed to `AddResponseToLibrary` | Response registered with the wrong argument UI, or rejected | Inspect existing `AddResponseToLibrary` callers in the target's symbols and copy an established literal |
| 4.7 | Template codes `MS-GJBAPW` / `MS-GJLAPW`, template token `MS-`, workflow category `FIN` | Hard-coded literals break across versions and localizations | Never hard-code. Derive the target's own template code via `WorkflowSetup.GetWorkflowTemplateCode`; register the target's own category |
| 4.8 | `Codeunit 1804 "Approval Workflow Setup Mgt."` is `[Scope('OnPrem')]` throughout | — | Irrelevant: do not depend on it regardless of what the target's symbols show |
| 4.9 | `Approval Entry` field numbering jumps from 23 to 26 in this snapshot | Suggests removed fields; a version-specific field layout | Do not assume field numbers. Reference fields by name in AL; verify the `Approval Entry` field list in the target's symbols before building any FlowField or table extension against it |
| 4.10 | Codeunits 1501, 1502, 1520, 1521, 1535, 1550 and table 454 declare **no `Access` property** (default public) | If a future version marks any of them `internal`, the entire recommended dependency set becomes unusable | Attempt a compile of a scratch codeunit referencing each object in the target's symbols. This is check 3 of [06 §15](06-business-central-extension-handoff.md#15-business-central-compatibility-checklist) |
| 4.11 | GB localization affects captions and label texts only; no GB-specific behavioural divergence was observed in the approval or restriction paths | Low | If the target ships to another localization, re-run the registration and restriction searches in that localization's branch. Never treat a caption or `Restricted Record."Details"` text as a contract |
| 4.12 | `Codeunit 1543 "Workflow Webhook Management"` members (§3.1.1) — entirely untraced | Unknown | Trace the webhook path in the target's version before claiming Power Automate support |

---

## 5. Statements this analysis does **not** make

Recorded to prevent later over-reading of the handoff.

- It does **not** claim that any recommended symbol is a documented, formally supported Microsoft API. It claims only that the symbol is public and accessible **in this snapshot**.
- It does **not** claim the General Journal approval design is correct or defect-free. §3.2, §3.3 and §3.6 record real gaps.
- It does **not** claim that the target's chosen subject model will work — [06 §14](06-business-central-extension-handoff.md#14-approval-subject-decision-framework) is a decision framework, and the decision requires target-repository evidence that this session did not have.
- It does **not** claim any cross-version compatibility. Every §4 row is snapshot-scoped.
- It does **not** claim the webhook path is compatible with, or irrelevant to, the recommended design.
- It does **not** assign any object IDs to the target extension.
