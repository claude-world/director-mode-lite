---
description: Test-Driven Development (TDD: Red-Green-Refactor)
---

# Test-Driven Development

Implement TDD for: $ARGUMENTS

## Quick Steps
1. Write a failing test
2. Run test, confirm failure
3. Write minimal code to pass
4. Refactor while keeping tests green
5. Repeat

---

## Red Phase - Write Failing Test

### Test Design Principles
- **Test one specific behavior**
- **Test name describes expected result**
- **Test should fail (feature doesn't exist yet)**

### Must Test
- [ ] Normal case
- [ ] Edge cases
- [ ] Error cases
- [ ] Invalid input

### Example
```typescript
// auth/login.test.ts
it('should return JWT token for valid credentials', async () => {
  const res = await request(app)
    .post('/auth/login')
    .send({ email: 'test@example.com', password: 'password123' })

  expect(res.status).toBe(200)
  expect(res.body.token).toBeDefined()
})
```

---

## Green Phase - Minimal Implementation

### Implementation Principles
- **Write ONLY enough code to pass the test**
- **Don't optimize yet**
- **Don't worry about elegance**
- **Just make it work**

### Example
```typescript
// auth/login.ts
export async function login(email: string, password: string) {
  const user = await User.findByEmail(email)
  if (!user || !bcrypt.compareSync(password, user.password)) {
    throw new Error('Invalid credentials')
  }
  return jwt.sign({ userId: user.id }, SECRET, { expiresIn: '24h' })
}
```

---

## Refactor Phase - Clean Up

### Refactoring Checklist
- [ ] Is there code duplication?
- [ ] Are variable names clear?
- [ ] Are functions too long?
- [ ] Is the logic too complex?

### Refactoring Rules
- **Keep tests passing**
- **Change one thing at a time**
- **Run tests frequently**

---

## Test Quality Checklist

- [ ] Unit tests cover core logic
- [ ] Integration tests cover interactions
- [ ] Test names clearly describe intent
- [ ] Tests are independent and repeatable
- [ ] Tests run fast (unit tests < 100ms)
- [ ] Edge cases are covered

---

## Common Patterns

### Testing Async Code
```typescript
it('should handle async operations', async () => {
  const result = await asyncFunction()
  expect(result).toBe(expected)
})
```

### Testing Errors
```typescript
it('should throw on invalid input', async () => {
  await expect(functionThatThrows()).rejects.toThrow('Error message')
})
```

### Testing with Mocks
```typescript
jest.mock('./database')
it('should call database correctly', () => {
  functionUnderTest()
  expect(mockDb.query).toHaveBeenCalledWith(expectedQuery)
})
```

---

Follow TDD strictly. No shortcuts.
