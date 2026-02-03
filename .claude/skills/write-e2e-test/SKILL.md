---
name: write-e2e-test
description: Systematically write new Playwright E2E tests from planning through implementation. Use when the user asks to "write an e2e test", "create e2e tests", "add e2e test for [feature]", or mentions testing a feature with Playwright. Covers test planning, implementation verification and test validation.
hooks:
  PostToolUse:
    - matcher: "Edit|Write"
      statusMessage: "Running lint checks..."
      hooks:
        - type: command
          command: "$CLAUDE_PROJECT_DIR/.claude/hooks/lint-e2e.sh"
---

# Write E2E Test

Systematically create new end-to-end tests using Playwright, following the monorepo's established conventions and best practices.

## Prerequisites

Before starting, read the testing guidelines:

```bash
view packages/e2e-tests/AGENTS.md
```

## Workflow

### 1. Define Test Requirements

**Understand the feature**:

- Identify what needs to be tested
- List the specific test cases to write
- **IMPORTANT**: Always ask clarifying questions about the test scope and where to validate on

This is an important phase as aligning on the requirements will lead to a better plan.

**Example questions**:

- "Should this test be part of [spec file name] or a new spec file?"
- "This is a list of suggested tests to write, please select the ones you want to write"
- "Should I test both success and error cases?"
- "Should the test validate the product is visible on the cart page or check the backend state?"

### 2. Verify Implementation Details

**Check actual implementation** in the monorepo to understand:

**Translations** (always check first):

```bash
view frontend/src/messages/nl.json
```

- Look for button labels, form fields, error messages, success messages

**Frontend components**:

```bash
view frontend/site/src/components/[feature-path]
```

- Identify UI elements, form fields, interactive elements
- Check for proper accessibility attributes (labels, roles, ARIA)
- Note any missing accessibility features

**Accessibility check**: If implementation lacks proper labels, roles, or ARIA attributes, inform the user and suggest fixes before writing tests.

**GraphQL API calls**:

```bash
view backend/services/[service-name]
```

- Understand data flow and API endpoints
- Identify what data is sent/received
- Make sure to note down relevant GraphQL requests as these need to be waited on in the test by using `page.waitForResponse`.

**Optional: Setup initial state via API calls**:

```bash
view packages/e2e-tests/fixtures/api.ts
```

- Understand how to setup initial state via API calls
- Extend the `api` fixture with custom methods for setting up state for the test if needed. Base this on the existing GraphQL implementation.

### 3. Get User Approval

**Present test plan** to user:

- List the specific tests you'll write
- Explain what each test will cover
- Confirm approach aligns with their needs

**Wait for approval** before proceeding to implementation.

### 4. Implement the Test

**Location**: `packages/e2e-tests/tests/[feature-name]/`

- Use Gherkin steps (Given, When, Then)
- Set up initial state via API calls
- Use proper locator strategy (role > label > placeholder > text)
- Use `translateLocaleFn` for all text from translation files
- Group tests in descriptive `describe` blocks
- Keep tests parallelizable

### 5. Run Test in Isolation

**Run the test in isolation multiple times** to verify stability:

```bash
pnpm --filter e2e-tests exec playwright test -g "Should [test title]" --repeat-each=5 --reporter=line
```

**If test fails**:

- Analyze the error
- Fix the issue
- Rerun the test
- Repeat until test passes

**Common issues**:

- Incorrect locators
- Missing waits for graphql requests
- Translation key mismatches
- Timing issues (avoid `waitForTimeout`)

### 6. Final Checklist

Before completing, verify:

- [ ] Test follows Gherkin structure (Given, When, Then)
- [ ] Initial state set up via API calls
- [ ] Relevant GraphQL requests are waited on by using `page.waitForResponse`
- [ ] Locators use proper strategy (role > label > placeholder > text)
- [ ] Avoid the use of `page.locator` to filter specific elements, use options of the getBy methods instead.
- [ ] All text uses `translateLocaleFn` for translation keys
- [ ] Test runs in isolation successfully
- [ ] No `waitForTimeout` or `networkidle` usage
- [ ] Test is inside descriptive `describe` block
- [ ] Test can run in parallel with other tests
