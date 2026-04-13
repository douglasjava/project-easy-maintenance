# Frontend Diagnosis

## 🎯 Objective

Perform a deep technical diagnosis of frontend performance issues in the Easy Maintenance project, with a focus on:

- slow page navigation
- rendering inefficiencies
- unnecessary re-renders
- excessive data fetching
- poor user-perceived performance

The goal is to **identify root causes**, not just symptoms, and provide **actionable recommendations** that can be converted into tasks.

---

## 📥 Expected Input

- General request:
  - "analyze frontend performance"
  - "diagnose slow navigation"
  - "frontend is slow between pages"

- Optional context:
  - specific page or route
  - recent changes
  - observed behavior

---

## 🧠 Mandatory Context

Before analyzing:

1. Read `CLAUDE.md`
2. Identify frontend stack:
   - Next.js
   - React
   - React Query (if used)
3. Identify:
   - main layouts
   - shared components (topbar, sidebar, providers)
   - routing structure
4. Identify affected pages/components

---

## 🔍 Diagnosis Areas (MANDATORY)

### 1. Navigation & Routing

Analyze:

- Page transitions (slow? blocking?)
- Layout structure (nested layouts, shared components)
- Route guards (auth, permission checks)
- Redirects or blocking logic
- Loading states during navigation

Check for:

- unnecessary blocking logic
- heavy components loading on every route change
- full reload behavior instead of client navigation

---

### 2. Rendering Behavior

Analyze:

- Excessive re-renders
- Components re-rendering unnecessarily
- Global components (topbar, sidebar) re-rendering on every navigation
- Overuse of `useEffect`
- Incorrect dependency arrays

Check for:

- components without memoization when needed
- large trees re-rendering due to state/context changes
- unstable props triggering re-renders

---

### 3. Data Fetching (CRITICAL)

Analyze:

- React Query usage
- Refetch behavior on navigation
- Duplicate API calls
- Waterfall requests (sequential instead of parallel)

Check for:

- `refetchOnMount` / `refetchOnWindowFocus` misuse
- missing caching strategy
- unnecessary invalidations
- API calls inside multiple components for same data

---

### 4. Next.js Structure

Analyze:

- use of `"use client"`
- server vs client component boundaries
- data fetching strategy (server vs client)
- layout usage

Check for:

- too many client components
- heavy logic inside client layouts
- lack of streaming or suspense usage
- unnecessary hydration cost

---

### 5. State & Context Management

Analyze:

- global providers
- context usage
- state lifting

Check for:

- large context providers causing global re-renders
- unnecessary global state
- frequent state updates triggering UI refresh

---

### 6. Bundle & Dependencies

Analyze:

- heavy libraries
- unnecessary imports
- bundle size impact

Check for:

- large libraries loaded globally
- components importing entire libraries instead of partial usage
- lack of lazy loading

---

### 7. User-Perceived Performance

Analyze:

- loading feedback
- UI blocking
- perceived delay vs actual delay

Check for:

- blank screens during navigation
- no loading indicators
- delayed interaction readiness

---

## ⚠️ Root Cause Identification (MANDATORY)

For each issue found, classify:

- Symptom
- Root cause
- Evidence (what indicates this is happening)

Avoid vague statements like:
- "might be slow because..."

Always prefer:
- "likely caused by X because Y behavior indicates Z"

---

## 📊 Output Requirements

Group findings by severity:

### 🔴 High Impact
- directly affects navigation speed or UX

### 🟡 Medium Impact
- noticeable inefficiencies but not critical

### 🟢 Low Impact
- optimizations or improvements

---

## 🛠️ Recommendations

For each issue, provide:

- clear description of fix
- expected improvement
- complexity (low / medium / high)
- whether it should become a task

---

## 🚀 Task Suggestions

Suggest:

- top 3–5 fixes that should become tasks immediately
- prioritize based on impact vs effort

---

## 🚫 Important Rules

- DO NOT suggest generic optimizations without evidence
- DO NOT assume performance issues without analysis
- DO NOT propose refactors without clear benefit
- FOCUS on real bottlenecks first

---

## 📤 Response Format (MANDATORY)

# Frontend Diagnosis Report

## Summary
- High-level overview of frontend performance condition

---

## Key Findings

### 🔴 High Impact Issues
- Issue:
- Root Cause:
- Evidence:
- Recommendation:

---

### 🟡 Medium Impact Issues
- Issue:
- Root Cause:
- Evidence:
- Recommendation:

---

### 🟢 Low Impact Issues
- Issue:
- Root Cause:
- Evidence:
- Recommendation:

---

## Critical Bottlenecks
- List the main causes of slow navigation

---

## Quick Wins (High Impact / Low Effort)
- ...

---

## Recommended Tasks
1. TASK-XXX - ...
2. TASK-XXX - ...
3. TASK-XXX - ...

---

## Final Assessment
- Overall frontend performance status (Poor / Acceptable / Good)
- Main limiting factor