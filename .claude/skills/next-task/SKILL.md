# Next Task

## 🎯 Objective

Identify the best next task to execute in the Easy Maintenance project based on roadmap, backlog, current sprint, kanban, priorities, dependencies, and overall SaaS launch readiness.

The goal is to always move the project forward with **maximum impact and minimum risk**.

---

## 📥 Expected Input

- "what is the next task?"
- "suggest next task"
- "what is the best next task for the sprint?"

---

## 🧠 Mandatory Context

Before responding:

1. Read `CLAUDE.md`
2. Read `roadmap/kanban.md`
3. Read `roadmap/backlog.md`
4. Read current sprint in `roadmap/sprints/` (if exists)
5. Inspect relevant tasks in `roadmap/tasks/`

---

## 📊 Priority Criteria (STRICT ORDER)

Always prioritize in this order:

1. Launch blockers  
2. Security  
3. Functional bugs  
4. Multi-tenant / permissions  
5. Billing / subscriptions  
6. Performance  
7. Critical UX  
8. Product improvements  
9. Future enhancements  

---

## ⚙️ Decision Rules

### 1. Priority Level

- Critical > High > Medium > Low

---

### 2. Dependencies

- NEVER suggest a blocked task
- ALWAYS prefer unblocked tasks
- Prefer tasks that unlock others

---

### 3. Current Status

Prioritize tasks in:

1. Next Sprint  
2. Ready to Implement  
3. Backlog  

---

### 4. Product Impact

Prioritize tasks that:

- Reduce launch risk
- Fix critical failures
- Improve security
- Unlock other tasks
- Increase production readiness

---

### 5. Size and Execution

- Prefer tasks that can be executed immediately
- Avoid overly large tasks if smaller high-impact ones exist
- Balance impact vs effort

---

## 🔍 Analysis Flow

### 1. Identify Candidate Tasks

List tasks from:

- Next Sprint
- Ready to Implement
- Backlog

---

### 2. Filter Blocked Tasks

Remove tasks that:

- Depend on incomplete tasks
- Require missing prerequisites

---

### 3. Compare Candidates

Evaluate each based on:

- Priority
- Risk of not doing it
- Impact on launch
- Dependency unlocking
- Effort

---

### 4. Select Best Task

Choose ONE primary task that provides the best balance of:

- impact
- readiness
- strategic value

---

### 5. Suggest Alternatives

Also provide:

- second-best option
- third-best option

---

## 🚫 Important Rules

- DO NOT pick tasks randomly
- DO NOT ignore dependencies
- DO NOT suggest completed tasks
- DO NOT suggest tasks already in progress (unless recommending continuation explicitly)
- ALWAYS justify the decision objectively

---

## 📤 Response Format (MANDATORY)

# Next Task Recommendation

## Recommended Task
- TASK-XXX - Title

---

## Reason for Selection
- ...

---

## Priority
- ...

---

## Current Status
- ...

---

## Dependencies
- ...

---

## Expected Impact
- ...

---

## Why It Comes Before Others
- ...

---

## Suggested Next Command
- `/execute-task TASK-XXX`

---

## Other Viable Options
1. TASK-XXX - ...
2. TASK-XXX - ...

---

## Notes
- ...