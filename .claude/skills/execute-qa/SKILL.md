# Execute QA

## 🎯 Objective

Analyze the Easy Maintenance project based on completed sprints and finished tasks, identify all relevant system flows that require validation, and prepare structured QA outputs for both:

- manual test execution
- automated test opportunities

This skill must behave as a **QA Lead / Test Strategist**, ensuring that completed functionality is transformed into a practical and traceable testing plan.

Its responsibilities are:

1. map completed deliveries
2. identify testable business and user flows
3. generate manual test documentation where needed
4. identify flows suitable for automation
5. propose or create QA-related tasks for missing coverage

---

## 📥 Expected Input

Examples:

- "execute qa"
- "map QA for completed tasks"
- "prepare testing plan for completed sprint work"
- "identify manual and automated test coverage"

Optional:
- specific sprint
- specific module
- focus area (billing, onboarding, items, maintenances, admin, permissions)

---

## 🧠 Mandatory Context

Before starting:

1. Read `CLAUDE.md`
2. Read `roadmap/kanban.md`
3. Read relevant sprint files in `roadmap/sprints/`
4. Read completed task files in `roadmap/tasks/`
5. Identify:
   - completed features
   - completed bug fixes
   - impacted modules
   - critical product flows
   - launch-critical areas

---

## 🔍 QA Mapping Scope

This skill must inspect completed work and organize testing by **system flow**, not only by isolated task.

Examples of flows:

- authentication and login
- onboarding
- organization creation
- user creation and access initialization
- permissions and protected pages
- tenant selection / tenant context
- billing and subscriptions
- items listing and item management
- maintenances listing and maintenance registration
- dashboard
- notifications
- admin/private flows

---

## ⚙️ Execution Flow

### Step 1: Map Completed Scope

Identify all relevant completed tasks from:

- Done
- In Validation (if functionally ready)

Group them by:

- module
- business flow
- criticality
- launch relevance

---

### Step 2: Identify Test Flows

For each completed area, determine:

- what user flow exists
- what should be validated manually
- what should be validated automatically
- what still lacks coverage

Classify flows as:

- CRITICAL
- HIGH
- MEDIUM
- LOW

---

### Step 3: Prepare Manual Test Documentation

For every flow requiring manual validation, generate a structured manual test document.

This document must include:

- flow name
- objective
- preconditions
- test steps
- expected result
- negative scenarios (if applicable)
- notes / risks

⚠️ Important:
- Manual test documentation may become a task
- These tasks must clearly indicate that execution is manual

---

### Step 4: Identify Automation Candidates

Determine automation suitability based on:

- stability
- repeatability
- criticality
- regression risk

---

### Step 5: Create QA Tasks (MANDATORY LANGUAGE RULE)

Generate QA tasks in two categories:

---

### 🇧🇷 IMPORTANT LANGUAGE RULE

ALL TASKS CREATED BY THIS SKILL MUST BE WRITTEN IN PORTUGUESE (PT-BR)

This includes:
- title
- description
- steps
- expected results

The rest of the report remains in English.

---

### A. Manual QA Tasks (PT-BR)

These tasks must:

- explicitly state that the validation is manual
- describe the flow being tested
- include step-by-step instructions
- define expected results
- define evidence expected (checklist, prints, logs, etc.)

---

### B. Automated QA Tasks (PT-BR)

These tasks must:

- describe the flow to automate
- define test type:
  - unitário
  - integração
  - API
  - end-to-end
- explain why automation is valuable
- define expected coverage

---

### Step 6: Identify Gaps and Risks

Highlight:

- flows with no test coverage
- flows validated only informally
- areas risky for launch
- missing regression protection

---

## 🧪 Manual Test Document Rules

Structure:

- Flow
- Objective
- Preconditions
- Test Steps
- Expected Results
- Negative / Edge Cases
- Notes / Risks

---

## 🤖 Automation Recommendation Rules

Define:

- flow
- why automate
- level (unit / integration / API / E2E)
- regression protection
- priority (Now / Next / Later)

---

## 🚫 Important Rules

- DO NOT analyze tasks in isolation
- ALWAYS think in flows
- DO NOT recommend automating everything
- DO NOT ignore manual validation for critical flows
- CLEARLY separate manual vs automated QA

---

## 📤 Response Format (MANDATORY)

# QA Execution Report

## Scope Reviewed
- Sprints reviewed:
- Tasks reviewed:
- Modules covered:

---

## Flow Mapping

### Flow 1
- Name:
- Related tasks:
- Criticality:
- Launch relevance:
- Recommended validation:
  - Manual / Automated / Both

---

## Manual Test Documents

### Manual Test Document 1
- Flow:
- Objective:
- Preconditions:
- Test Steps:
- Expected Results:
- Negative / Edge Cases:
- Notes / Risks:

---

## QA Task Suggestions

### Manual QA Tasks (PT-BR)

1. TASK-QA-MAN-01 - [Título em português]
   - Descrição:
   - Passos:
   - Resultado esperado:

---

### Automated QA Tasks (PT-BR)

1. TASK-QA-AUTO-01 - [Título em português]
   - Tipo: (unitário / integração / API / E2E)
   - Descrição:
   - Cobertura esperada:
   - Justificativa:

---

## Coverage Gaps
- ...

---

## Launch Risks
- ...

---

## Recommended Next Action
- ...