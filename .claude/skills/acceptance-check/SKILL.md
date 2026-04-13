# Acceptance Check

## 🎯 Objective

Validate whether a completed task objectively meets the acceptance criteria defined in `/roadmap/tasks`.

This validation must focus on **functional correctness and business expectations**, not code quality (covered by `/review-task`).

---

## 📥 Expected Input

- Task ID (e.g., TASK-001)
- or instruction like: "acceptance-check TASK-001"

---

## 🧠 Mandatory Context

Before validating:

1. Read the task file in `/roadmap/tasks`
2. Extract all acceptance criteria
3. Identify the related implementation
4. Consider the rules defined in `CLAUDE.md`

---

## 🔍 Validation Flow

### 1. Extract Acceptance Criteria

- List all criteria explicitly defined in the task
- Do not assume or invent missing criteria

---

### 2. Compare Against Implementation

For each criterion:

- Verify if it is fully met
- Verify if it is partially met
- Verify if it is not met

Each evaluation must be based on **clear evidence**.

---

### 3. Validate Side Effects

Check if the implementation introduced unintended issues:

- Any broken flow?
- Security preserved?
- Multi-tenant isolation preserved?
- Any missing validation?
- Any behavior inconsistent with expectations?

---

### 4. Validate Readiness

Determine if the task is ready for:

- In Validation
- Done
- Or requires adjustments

---

## ⚠️ Important Rules

- DO NOT assume compliance without evidence
- DO NOT consider "almost done" as complete
- Be objective and traceable
- If something critical is missing → clearly flag it
- Focus on behavior, not internal implementation

---

## 📤 Response Format (MANDATORY)

# Acceptance Check TASK-XXX

## Overall Summary
Short summary of how well the task meets acceptance criteria.

---

## Acceptance Criteria

### Criterion 1
- Status: Met / Partial / Not Met
- Evidence: ...

### Criterion 2
- Status: Met / Partial / Not Met
- Evidence: ...

[repeat for all criteria]

---

## Risks or Gaps
- ...

---

## Final Verdict
- Ready for In Validation
- Ready for Done
- Requires Adjustments

---

## Required Adjustments Before Completion
- ...