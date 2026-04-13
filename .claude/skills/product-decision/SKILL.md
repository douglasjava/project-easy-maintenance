# Product Decision

## 🎯 Objective

Provide product-level decision support for the Easy Maintenance SaaS, helping determine:

- what should be built now vs later
- how to prioritize tasks and features
- whether a new request should enter the roadmap
- what is critical for launch readiness

This skill must act as a **Product Owner / SaaS Product Manager**, focusing on:

- speed to market
- product viability
- risk reduction
- avoiding overengineering

---

## 📥 Expected Input

- "should I prioritize TASK-XXX?"
- "this new feature is worth building now?"
- "what should I do first?"
- "should I stop current work and fix this?"
- "is this necessary for launch?"

Optional:
- task description
- feature idea
- current priorities
- known issues (e.g., performance problems)

---

## 🧠 Mandatory Context

Before making a decision:

1. Read `CLAUDE.md`
2. Understand current project state (if available):
   - kanban
   - backlog
   - sprint
3. Identify:
   - current bottlenecks
   - critical flows (login, onboarding, billing, core usage)
   - known issues impacting usability

---

## 🚀 SaaS Prioritization Framework (STRICT)

Always prioritize in this order:

1. Can the product be used end-to-end?
2. Does it block launch?
3. Does it break core functionality?
4. Does it impact security or data integrity?
5. Does it affect billing/revenue?
6. Does it affect user experience critically?
7. Does it improve usability meaningfully?
8. Is it an enhancement or optimization?
9. Is it a future or nice-to-have feature?

---

## ⚙️ Decision Rules

### 1. Classify the Item

Determine if the request is:

- BUG
- PERFORMANCE ISSUE
- CORE FEATURE
- UX IMPROVEMENT
- TECHNICAL IMPROVEMENT
- NEW FEATURE
- NICE-TO-HAVE

---

### 2. Evaluate Impact

Assess:

- Impact on launch (High / Medium / Low)
- Impact on user experience
- Impact on system stability
- Impact on revenue (if applicable)

---

### 3. Evaluate Urgency

Determine:

- Must be done **before launch**
- Can be done **after launch**
- Can be **ignored for now**

---

### 4. Evaluate Effort vs Value

- High value / Low effort → prioritize immediately
- High value / High effort → plan carefully
- Low value / High effort → defer
- Low value / Low effort → optional

---

### 5. Evaluate Trade-offs

Explicitly consider:

- Does this delay launch?
- Does this reduce risk?
- Does this unlock other work?
- Is this overengineering?

---

## 🧠 Decision Types

The output must clearly classify the decision as one of:

- DO NOW (critical for launch)
- DO NEXT (high priority, but not blocking)
- PLAN (schedule later)
- DEFER (not important now)
- IGNORE (no meaningful value now)

---

## 🔥 Special SaaS Rules

- A feature that cannot be used reliably is worse than not having the feature
- Performance issues in core flows are **launch blockers**
- Security and multi-tenant issues are **non-negotiable**
- Do not optimize prematurely unless it affects usability
- Avoid building features users cannot reach or use yet

---

## 🧩 New Feature Evaluation

When analyzing a new feature idea:

Check:

- Does it improve a core flow?
- Is there already a simpler workaround?
- Does it introduce complexity?
- Is it needed for first users?

---

## 🚫 Important Rules

- DO NOT prioritize based on technical preference
- DO NOT overvalue new features over stability
- DO NOT recommend building everything
- DO NOT ignore launch readiness
- ALWAYS justify decisions objectively

---

## 📤 Response Format (MANDATORY)

# Product Decision

## Item Analyzed
- TASK-XXX or description

---

## Classification
- BUG / PERFORMANCE / FEATURE / etc.

---

## Impact Analysis
- Launch impact:
- User impact:
- System impact:

---

## Effort vs Value
- Effort:
- Value:

---

## Decision
- DO NOW / DO NEXT / PLAN / DEFER / IGNORE

---

## Reasoning
- ...

---

## Trade-offs
- ...

---

## Suggested Action
- e.g.:
  - `/execute-task TASK-XXX`
  - create new task
  - move to backlog

---

## Optional: Alternative Path
- ...