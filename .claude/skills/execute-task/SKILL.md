# Execute Task

## 🎯 Objective

Execute a task from the Easy Maintenance project end-to-end, following the roadmap defined in `/roadmap`, including:

- task analysis
- planning
- **git branch setup**
- implementation
- creation/adjustment of relevant tests
- initial technical review
- validation of acceptance criteria
- kanban update

This skill is the **main execution flow**, ensuring consistency, quality, and minimal rework.

---

## 📥 Expected Input

- Task ID (e.g., TASK-001)
- or instruction like: "execute TASK-001"

---

## 🧠 Mandatory Context

Before taking any action:

1. Read the task file in `/roadmap/tasks`
2. Understand:
    - problem
    - impact
    - dependencies
    - acceptance criteria
    - task type
3. Read `CLAUDE.md`
4. Check `/roadmap/kanban.md` for current status
5. Identify impacted files and layers

---

## 🔍 Step 1: Initial Analysis

Verify:

- if the task is clear
- if there are pending dependencies
- if it is ready for execution

### 🧩 Task Classification (MANDATORY)

Classify the task as:

- BACKEND
- FRONTEND
- FULL_STACK
- INFRA / CONFIG
- BUGFIX

Also determine:

- Impact level: low / medium / high
- QA attention required: YES (default)

If there is relevant ambiguity:
- STOP and report before implementing

---

## 🌿 Step 2: Git Branch Setup (MANDATORY)

**Before any planning or implementation**, always create a dedicated branch for the task, starting from `staging` (homologação).

### Branch naming convention

```
feature/TASK-XXX-short-kebab-case-description
```

- `TASK-XXX` = exact task ID from `/roadmap/tasks` (uppercase, matches kanban)
- `short-kebab-case-description` = 3–6 words max, lowercase, hyphen-separated, derived from the task title
- Use `bugfix/TASK-XXX-...` instead of `feature/...` when the task is classified as BUGFIX (Step 1)
- Use `chore/TASK-XXX-...` for INFRA / CONFIG tasks that don't ship user-facing behavior

Examples:
- `feature/TASK-042-photo-evidence-upload`
- `bugfix/TASK-051-fix-next-due-at-recalc`
- `chore/TASK-066-pix-automatico-config`

### Required commands (always executed in this order)

```bash
git fetch origin
git checkout staging
git pull origin staging
git checkout -b feature/TASK-XXX-short-description
```

### Rules

- ALWAYS branch from `staging`, never from `main`, `production`, or another feature branch — unless the task explicitly declares a dependency on an unmerged branch (then STOP and report before proceeding, per Step 1 ambiguity rule).
- If a branch with the same name already exists locally or remotely:
    - if it belongs to this same task and is unmerged, check it out and continue from there instead of recreating it
    - if it looks stale/unrelated, STOP and report before overwriting or deleting anything
- NEVER commit directly to `staging`, `main`, or `production`.
- Confirm the branch was created successfully (`git branch --show-current`) before moving to Step 3 (Planning).
- Record the branch name — it must be reported in the final output (see Response Format) and referenced in the eventual PR title/description.

---

## 🧾 Step 3: Planning

Before editing any file, describe briefly:

- what will be changed
- which files will be impacted
- chosen approach
- main risks:
    - regression
    - security
    - data inconsistency
    - API contract break
- which tests should be created or updated

---

## ⚙️ Step 4: Implementation

Implement only what is necessary to fulfill the task, on the branch created in Step 2.

### 🔹 Backend / Full-stack rules

Ensure:

- DTO validation is correct
- business rules are preserved
- multi-tenant (`X-Org-Id`) is respected
- security is not broken (auth, roles, filters)
- no data inconsistency is introduced
- queries are efficient (avoid regressions)
- proper exception handling (`ProblemDetail`)

---

### 🔹 Frontend / Full-stack rules

Ensure:

- proper state handling (loading, error, empty)
- UI consistency with existing patterns
- responsiveness (mobile required)
- correct API integration
- proper error handling from backend responses

---

### 🔹 Infra / Config rules

Ensure:

- environment variables are correct
- deployment is not broken
- backward compatibility is preserved

---

## 🔗 Step 5: Integration Validation

When applicable:

- backend ↔ frontend contract is aligned
- request/response structure is correct
- no existing consumer is broken

---

## 🧪 Step 6: Mandatory Tests

Create, adjust, or complement relevant tests whenever applicable.

Validate:

- unit tests
- business/service tests
- integration tests (if relevant)
- happy path
- error scenarios
- regressions directly related to the change

If tests cannot be created or executed:

- clearly explain why
- list risks
- describe what is pending

---

## 🧪 Step 7: Test Execution / Verification

Run or validate the most relevant tests.

Objective:

- confirm main flow is not broken
- validate the changed rule
- detect obvious regressions

If a failure occurs:

- fix if within scope
- otherwise STOP and report clearly

---

## 🔍 Step 8: Initial Technical Review

Perform a self-review checking:

- adherence to scope
- code clarity
- architectural consistency
- no unnecessary duplication
- security preserved
- tenant isolation preserved
- coherence of tests

---

## 🧪 Step 9: Acceptance Criteria Validation

Compare implementation against each acceptance criterion:

### For each criterion:

- Status: Met / Partially Met / Not Met
- Evidence / observation

DO NOT consider the task complete without sufficient evidence.

---

## 🧪 Step 10: QA Validation (MANDATORY)

Validate:

- ✅ Happy path works
- ❌ Error scenarios handled
- ⚠️ Edge cases considered
- 🔁 No regression introduced
- 🔐 Security preserved

If any fails → FIX before proceeding

---

## 📦 Step 11: Kanban Update

If implementation is consistent:

- move to `In Validation`

If fully complete and stable:

- suggest or move to `Done`

If pending issues exist:

- keep in `In Progress` and explain why

Never duplicate tasks across columns.

---

## 📊 Status Decision Rules

### Move to `In Validation` when:
- implementation completed
- relevant tests created/adjusted
- main tests verified
- acceptance criteria mostly satisfied
- still requires final human review

---

### Move to `Done` when:
- fully delivered
- no relevant pending issues
- acceptance criteria satisfied
- tests validated
- no open risk

---

### Keep in `In Progress` when:
- blockers exist
- tests failed
- criteria not met
- dependencies unresolved

---

## 🚫 Important Rules

- DO NOT execute multiple tasks at once
- DO NOT ignore acceptance criteria
- DO NOT ignore multi-tenant
- DO NOT assume behavior without validation
- DO NOT skip tests when business rules are affected
- DO NOT change contracts outside scope unnecessarily
- DO NOT start implementing before creating the branch in Step 2
- DO NOT commit directly to `staging`, `main`, or `production`

---

## 🛑 When to Stop

Stop and report clearly if:

- task is poorly defined
- a dependency blocks execution
- there is unresolved high risk
- there is a critical architectural issue
- relevant tests fail and fixing is out of scope
- the branch cannot be created cleanly from `staging` (conflicts, diverged history, naming collision with an unrelated branch)

---

## 📤 Response Format (MANDATORY)

# Execute Task - TASK-XXX

## Initial Analysis
- ...

## Git Branch
- Base branch: staging
- Branch created: feature/TASK-XXX-...

## Execution Plan
- ...

## Implementation Performed
- ...

## Tests Created/Updated
- ...

## Test Results
- ...

## Initial Technical Review
- ...

## Acceptance Criteria Validation

### Criterion 1
- Status: Met / Partial / Not Met
- Observation: ...

### Criterion 2
- Status: Met / Partial / Not Met
- Observation: ...

## Final Task Status
- In Progress / In Validation / Done

## Kanban Update
- describe movement

## Risks or Pending Items
- ...

## Suggested Next Step
- ...
