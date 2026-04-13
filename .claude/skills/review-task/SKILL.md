# Review Task

## 🎯 Objective

Perform a technical review of a task implementation in the Easy Maintenance project, ensuring:

- code quality
- architectural alignment
- security
- business rule integrity
- regression risk control

This review must reflect a **senior/staff engineer perspective**, not just surface-level validation.

---

## 📥 Expected Input

- Task ID (e.g., TASK-001)
- or instruction like: "review TASK-001"

---

## 🧠 Mandatory Context

Before reviewing:

1. Read the task file in `/roadmap/tasks`
2. Read `CLAUDE.md`
3. Understand:
   - problem
   - impact
   - dependencies
   - acceptance criteria
4. Identify all files changed related to the task

---

## 🔍 Review Flow

### 1. Scope Review

Verify:

- Is the implementation within the task scope?
- Were unnecessary changes introduced?
- Were unrelated refactors performed?
- Is there any hidden scope expansion?

---

### 2. Architecture Review

Verify:

- Does the solution respect the current architecture?
- Is there excessive coupling?
- Is there duplicated logic?
- Are responsibilities well separated (controller/service/provider/etc)?
- Are naming and structure clear and cohesive?

---

### 3. Backend Integrity (if applicable)

Verify:

- DTO validation is correct
- Business rules are properly enforced
- Multi-tenant (`X-Org-Id`) is preserved
- Security (auth, roles, filters) is intact
- No data inconsistency risk introduced
- Queries are efficient (no performance regression)

---

### 4. Frontend Integrity (if applicable)

Verify:

- Proper state handling (loading, error, empty)
- UI consistency with existing patterns
- Responsiveness (mobile support)
- Correct API integration
- Proper error handling from backend

---

### 5. Integration Review (FULL-STACK)

If applicable:

- Backend ↔ Frontend contract is consistent
- Request/response formats are correct
- No breaking changes for consumers
- API changes are properly reflected in frontend

---

### 6. Security Review

Verify:

- Multi-tenant isolation is preserved
- Authentication/authorization is correct
- No cross-tenant data exposure risk
- Input validation is present where needed
- No sensitive data leakage

---

### 7. Business Rules Review

Verify:

- Implementation solves the intended problem
- Billing, permissions, onboarding rules are respected
- Edge cases are handled
- No critical scenario is missing

---

### 8. Code Quality Review

Verify:

- Code clarity and readability
- Proper error handling
- Consistency with project standards
- No unnecessary complexity
- No hidden side effects
- Low regression risk

---

### 9. Test Review

Verify:

- Relevant tests were created or updated
- Tests cover the main flow
- Error scenarios are covered
- Tests validate real behavior (not only happy path)
- No false sense of coverage
- Test quality matches change complexity

---

## ✅ Mandatory Checklist

- Meets task objective  
- Respects acceptance criteria  
- Preserves tenant isolation  
- Does not break security  
- Does not introduce unintended behavior  
- Does not create unnecessary duplication  
- Does not increase technical debt unnecessarily  
- Relevant tests were created/updated  
- Test coverage is minimally sufficient  
- No critical validation gaps  

---

## 📤 Response Format (MANDATORY)

# Review TASK-XXX

## Summary
Short summary of overall implementation quality.

## Strengths
- ...

## Issues Found
- ...

## Risks
- ...

## Recommended Adjustments
- ...

## Final Verdict
- Approved
- Approved with changes
- Rejected

## Suggested Next Step
- ...