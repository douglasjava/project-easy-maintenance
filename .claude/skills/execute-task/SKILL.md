# Execute Task

## 🎯 Objective

Execute a task from the Easy Maintenance project end-to-end, following the roadmap defined in `/roadmap`, including:

- task analysis
- planning
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

## 🧾 Step 2: Planning

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

## ⚙️ Step 3: Implementation

Implement only what is necessary to fulfill the task.

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

## 🔗 Step 4: Integration Validation

When applicable:

- backend ↔ frontend contract is aligned
- request/response structure is correct
- no existing consumer is broken

---

## 🧪 Step 5: Mandatory Tests

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

## 🧪 Step 6: Test Execution / Verification

Run or validate the most relevant tests.

Objective:

- confirm main flow is not broken
- validate the changed rule
- detect obvious regressions

If a failure occurs:

- fix if within scope
- otherwise STOP and report clearly

---

## 🔍 Step 7: Initial Technical Review

Perform a self-review checking:

- adherence to scope
- code clarity
- architectural consistency
- no unnecessary duplication
- security preserved
- tenant isolation preserved
- coherence of tests

---

## 🧪 Step 8: Acceptance Criteria Validation

Compare implementation against each acceptance criterion:

### For each criterion:

- Status: Met / Partially Met / Not Met
- Evidence / observation

DO NOT consider the task complete without sufficient evidence.

---

## 🧪 Step 9: QA Validation (MANDATORY)

Validate:

- ✅ Happy path works
- ❌ Error scenarios handled
- ⚠️ Edge cases considered
- 🔁 No regression introduced
- 🔐 Security preserved

If any fails → FIX before proceeding

---

## 📦 Step 10: Kanban Update

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

---

## 🛑 When to Stop

Stop and report clearly if:

- task is poorly defined
- a dependency blocks execution
- there is unresolved high risk
- there is a critical architectural issue
- relevant tests fail and fixing is out of scope

---

## 📤 Response Format (MANDATORY)

# Execute Task - TASK-XXX

## Initial Analysis
- ...

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