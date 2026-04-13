# Run Sprint

## 🎯 Objective

Execute the current sprint in a controlled and consistent way, one task at a time, using the project skills already defined for:

- task prioritization
- product decision
- implementation
- technical review
- acceptance validation
- kanban update

This skill must behave like a **Sprint Orchestrator**, not a blind task runner.

Its goal is to accelerate sprint delivery while preserving:

- task priority
- dependency order
- quality
- launch readiness
- process consistency

---

## 📥 Expected Input

Examples:

- "run sprint"
- "execute current sprint"
- "run current sprint tasks"
- "start sprint execution"

Optional:
- sprint name
- max number of tasks to process
- focus area (frontend, backend, billing, launch blockers)

---

## 🧠 Mandatory Context

Before starting:

1. Read `CLAUDE.md`
2. Read `roadmap/kanban.md`
3. Read `roadmap/backlog.md`
4. Read current sprint file in `roadmap/sprints/` (if applicable)
5. Read relevant task files in `roadmap/tasks/`

---

## 🔍 Execution Principles

This skill must:

- execute **one task at a time**
- never execute blocked tasks
- never ignore task dependencies
- never continue after a failed validation
- prioritize based on launch readiness and sprint impact
- prefer smaller executable tasks when impact is high

This skill must NOT:

- execute all tasks blindly
- skip review or acceptance
- move tasks incorrectly in kanban
- continue after critical failure
- prioritize technical preference over product impact

---

## ⚙️ Sprint Execution Flow

### Step 1: Identify Candidate Tasks

Map all candidate tasks from the current sprint and related kanban columns, prioritizing:

- Next Sprint
- Ready to Implement
- In Progress (only if explicit continuation is needed)

Do not consider:
- Done
- blocked tasks
- duplicate tasks
- irrelevant backlog items outside sprint scope unless they became urgent

---

### Step 2: Prioritize the Next Task

For each cycle:

1. Use sprint context
2. Evaluate dependencies
3. Evaluate product impact
4. Select the best next executable task

Priority order:

1. Launch blockers
2. Security
3. Functional bugs
4. Multi-tenant / permissions
5. Billing / subscriptions
6. Performance
7. Critical UX
8. Product improvements
9. Future enhancements

If necessary, apply `/product-decision` logic before proceeding.

---

### Step 3: Execute One Task

For the selected task:

1. Run `/execute-task TASK-XXX`
2. Ensure implementation is completed within scope
3. Ensure relevant tests are created/updated
4. Ensure validation has been performed

---

### Step 4: Review the Task

After execution:

1. Run `/review-task TASK-XXX`
2. Check verdict:
   - Approved
   - Approved with changes
   - Rejected

If rejected:
- STOP sprint execution
- report the blocking issue clearly

If approved with changes:
- apply changes before proceeding

---

### Step 5: Run Acceptance Validation

Then:

1. Run `/acceptance-check TASK-XXX`
2. Check verdict:
   - Ready for In Validation
   - Ready for Done
   - Requires Adjustments

If adjustments are required:
- STOP sprint execution
- report clearly what is missing

---

### Step 6: Update Kanban

After passing execution, review, and acceptance:

- move task to `In Validation` or `Done`
- use `/kanban-update`

Never skip kanban update.

---

### Step 7: Decide Whether to Continue

Only continue to the next task if:

- current task is stable
- no blocking issue remains
- no critical new issue appeared
- sprint context still supports continuation

If a critical issue appears during execution, re-prioritize before continuing.

---

## 🛑 Mandatory Stop Conditions

Stop sprint execution immediately if:

- a task is poorly defined
- a dependency is unresolved
- execution fails critically
- tests fail and cannot be fixed within scope
- review verdict is `Rejected`
- acceptance verdict is `Requires Adjustments`
- a new critical issue becomes higher priority than current sprint flow
- kanban state is inconsistent

---

## 🔁 Controlled Continuation Rules

This skill may continue task-by-task only when each completed cycle has passed:

- implementation
- review
- acceptance
- kanban update

Never batch multiple tasks into a single uncontrolled execution.

---

## 📊 Output Requirements

For each sprint execution cycle, report:

- selected task
- reason for priority
- execution result
- review result
- acceptance result
- kanban result
- whether sprint execution will continue or stop

At the end, provide a sprint summary.

---

## 📤 Response Format (MANDATORY)

# Sprint Execution Report

## Sprint Context
- Current sprint:
- Focus:
- Constraints:

---

## Task Execution Sequence

### Task 1
- Task: TASK-XXX - Title
- Reason for selection:
- Execution result:
- Review result:
- Acceptance result:
- Kanban update:
- Final status:
- Continue sprint: Yes / No

### Task 2
- Task: TASK-XXX - Title
- Reason for selection:
- Execution result:
- Review result:
- Acceptance result:
- Kanban update:
- Final status:
- Continue sprint: Yes / No

[repeat as needed]

---

## Stopped Because
- ...

---

## Completed in This Run
- TASK-XXX
- TASK-XXX

---

## Pending Next Recommended Task
- TASK-XXX - Title

---

## Overall Sprint Status
- On Track / At Risk / Blocked

---

## Suggested Next Command
- `/run-sprint`
- or `/execute-task TASK-XXX`
- or `/product-decision ...`