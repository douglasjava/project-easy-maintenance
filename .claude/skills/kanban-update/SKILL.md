# Kanban Update

## 🎯 Objective

Update project management files in `/roadmap` consistently, especially:

- `roadmap/kanban.md`
- and, when necessary, related sprint or backlog references

Ensure **correct task flow progression**, avoiding invalid transitions or inconsistencies.

---

## 📥 Expected Input

- Task ID (e.g., TASK-001)
- Target status
- Optional short note

Examples:
- "move TASK-001 to In Progress"
- "move TASK-002 to In Validation"
- "move TASK-003 to Done"

---

## 📊 Allowed Statuses

- Backlog
- Next Sprint
- In Analysis
- Ready to Implement
- In Progress
- In Validation
- Done

---

## 🧠 Step 1: Read Context

Before any change:

- Read `roadmap/kanban.md`
- Locate the task
- Identify current status
- Validate target status exists

---

## 🔍 Step 2: Validate Consistency

Verify:

- Task exists in the kanban
- Task is present in only one column
- Target status is valid
- Transition makes logical sense

---

## 🔁 Step 3: Validate Flow Transition (IMPORTANT)

Ensure the movement follows a logical progression:

### Expected Flow

Backlog → Next Sprint → In Analysis → Ready to Implement → In Progress → In Validation → Done

---

### ⚠️ Invalid Transitions (unless explicitly justified)

- Backlog → Done
- In Progress → Done (without validation)
- In Analysis → Done
- Skipping In Validation stage

If a transition skips steps:

- Require explicit justification
- Otherwise STOP and report

---

## ⚙️ Step 4: Update Kanban

- Remove the task from current column
- Add the task to the new column
- Preserve file structure and formatting
- Do not reorder unrelated tasks

---

## 📝 Step 5: Add Note (Optional)

If a note is provided:

- Attach it to the task or as a structured inline note
- Keep formatting consistent with existing file

---

## 🔗 Step 6: Additional Consistency (if needed)

- Reflect minimal changes in sprint/backlog if required
- Avoid unnecessary modifications

---

## 🚫 Important Rules

- NEVER duplicate the same task across columns
- NEVER modify tasks other than the requested one
- NEVER reorganize the entire file unnecessarily
- ALWAYS preserve kanban format
- DO NOT allow invalid transitions without justification

---

## 🛑 When to Stop

Stop and report clearly if:

- Task does not exist
- Status is invalid
- Kanban is inconsistent
- There is ambiguity about which task to move
- Transition violates expected flow without justification

---

## 📤 Response Format (MANDATORY)

# Kanban Update TASK-XXX

## Previous Status
- ...

## New Status
- ...

## Changes Applied
- ...

## Note Added
- ...

## Result
- Kanban successfully updated
- or Could not update