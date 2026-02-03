# E2E Testing Guidelines

## Test user-visible behavior

Automated tests should verify that the application code works for the end users, and avoid relying on implementation details such as things which users will not typically use, see, or even know about such as the name of a function, whether something is an array, or the CSS class of some element. The end user will see or interact with what is rendered on the page, so your test should typically only see/interact with the same rendered output.

## General Principles

Expert-level testing with Playwright following these core principles:

- Use functional and declarative programming patterns; avoid classes
- Prefer WET over DRY, code should be easily deletable
- Keep functions small and focused

## Naming Conventions

- **Filenames**: Use kebab-case convention
- **Exports**: Favor named exports over default exports
- **Test titles**: Format as "Should [concise description]"
  - Example: "Should filter products on brand"

## TypeScript Standards

- Use TypeScript for all code
- Prefer types over interfaces for typing components and hooks
- Avoid enums and namespaces - all TypeScript code should be strippable from the codebase

## Package Structure

E2E tests are located in `packages/e2e-tests`:

```
├── playwright.config.ts    # Base Playwright configuration (shared settings)
├── environments.ts        # Environment configuration per store
├── fixtures/               # Playwright fixtures & Page Object Models
├── lib/                   # Test utilities and extensions
├── test-data/             # Centralized test data
└── tests/                 # Test files organized by feature/page
```

## Testing Scope

E2E tests should **only** cover functionality with both frontend and backend components/integration that can't be covered with unit/component tests alone.

| Test Type         | Scope                               | Speed  | Purpose                       |
| ----------------- | ----------------------------------- | ------ | ----------------------------- |
| Unit Tests        | Isolated functions/components       | Fast   | Validate internal logic       |
| Integration Tests | Interaction between modules/systems | Medium | Ensure modules work together  |
| E2E Tests         | Full application via the UI         | Slow   | Validate real user experience |

**Note:** E2E tests should be fewer in number and focused on the most critical paths that reflect how users interact with the application. It's critical to only include the main user journeys and keep tests limited to avoid slow test suites and maintenance overhead.

## Test Structure

### Gherkin Steps

Use test steps in Gherkin (Given, When, Then) structure for readability:

```typescript
await test.step("Given the user is on the product list page", async () => {
  // Given step
});

await test.step("When the user filters by brand", async () => {
  // When step
});

await test.step("Then only products from that brand are visible", async () => {
  // Then step
});
```

**IMPORTANT**: Don't create separate test steps for every command - group relevant commands together in single steps.

**IMPORTANT**: Do not use technical names or specific elements within test titles.

DO NOT USE:

```typescript
test.step("And the user clicks the add-to-cart button on a product card", async ({
  page,
}) => {
  // step implementation
});
```

USE:

```typescript
test.step("And the user adds the product to the cart", async ({ page }) => {
  // step implementation
});
```

### Test Organization

- All tests must be runnable in parallel
- All tests must be inside a `describe` block with a descriptive name

Example:

```typescript
test.describe("Product List Page", () => {
  test("Should filter products on brand", async ({ page }) => {
    // test implementation
  });
});
```

## Waiting for API Requests

Use `page.waitForResponse` to wait for API requests to complete, always use this together with the action itself inside a `Promise.all`. This ensures we properly wait for the API request to complete before proceeding with the next step. We use the helper function `checkGraphQLErrors` to check for any GraphQL errors in the response.

```typescript
const [cartLineItemsAddResponse] = await Promise.all([
  page.waitForResponse((response) =>
    response.url().includes("CartLineItemsAdd"),
  ),
  page.getByRole("button", { name: t("AddToCart.button-aria-label") }).click(),
]);
await checkGraphQLErrors(cartLineItemsAddResponse);
```

## Setting Up Initial State

**Avoid duplicate UI steps** - set up initial state via API calls:

```typescript
await api.login();
await api.addSkusToCart([defaultProducts[storeKey].sku]);
```

These API calls are available in the `api` fixture.
Extend the `api` fixture with custom methods for setting up state for the test.

## Fixtures Guidelines

- Move locators to the locators object
- **Only create reusable actions when**:
  - The same **exact** action is used very often in the codebase
  - It hides very complex logic such as specific network request waiting

## Playwright Best Practices

### What to Avoid

- ❌ `page.waitForTimeout` - Use explicit waits instead
- ❌ `waitForLoadState("networkidle")` - Unreliable and flaky
- ❌ `waitForLoadState("load")` on `page.goto()` - This is default behavior

### Locator Strategy (Priority Order)

1. **User-facing attributes**: `page.getByRole()` (highest priority)
2. **Form fields**: `page.getByLabel()` (for fields with labels)
3. **Placeholder text**: `page.getByPlaceholder()` (for fields without labels)
4. **Text locators**:
   - `page.getByText()` for non-interactive elements (div, span, p)
   - Role locators for interactive elements (button, a, input)

- Avoid the use of `page.locator` to filter specific elements, use options of the getBy methods instead.

DO NOT USE:

```typescript
const addToCartButton = page
  .getByRole("button", {
    name: t("AddToCart.button-aria-label"),
  })
  .and(page.locator(":not([disabled])"))
  .first();
```

USE:

```typescript
const addToCartButton = page
  .getByRole("button", {
    name: t("AddToCart.button-aria-label"),
    disabled: false,
  })
  .first();
```

### Test Data

- Test data should come from the `test-data` directory
- Avoid hardcoding test data directly in tests or functions

### Assertions

- Prefer assertions via `expect` for all assertions
- Avoid indirect general Playwright methods like `waitFor`

### Translations

- **Always** use `translateLocaleFn` to get translated text for a given key
- Never hardcode text strings that exist in translation files

## Monorepo File Locations

When implementing tests, check these locations for actual implementation details:

- **Translations**: `frontend/site/src/messages/nl.json`
- **GraphQL API calls**: `backend/services` directory
- **Frontend components**: `frontend/site/src/components` directory

## Accessibility

If the implementation doesn't adhere to good accessibility rules (proper labels, roles, ARIA attributes), flag this to the user and suggest updating the implementation before writing tests.
