# SHIELD Coding Style Guidelines

## TypeScript/JavaScript (Backend)
- Use TypeScript for all backend code
- Follow Airbnb JavaScript Style Guide with TypeScript adaptations
- Use ESLint for linting
- Use Prettier for code formatting
- Use meaningful variable and function names
- Write comments only when necessary (code should be self-documenting)
- Use async/await for asynchronous operations

## Dart/Flutter (Frontend)
- Follow Effective Dart guidelines
- Use `flutter_lints` for linting
- Use `dart format` for code formatting
- Widgets should be small and focused
- Use Riverpod for state management consistently
- Prefer `const` constructors where possible
- Use proper error handling with try/catch

## Database Rules
- Use UUIDs for public identifiers
- Use BIGSERIAL for internal primary keys
- Never delete data - use soft deletes with `deleted_at` column
- Always add created_at and updated_at timestamps
- Index frequently queried columns
- Use database constraints to enforce data integrity
- Follow ledger architecture for wallet and credit transactions

## API Design Rules
- Follow RESTful conventions
- Use plural nouns for resource endpoints
- Use appropriate HTTP methods (GET, POST, PUT, DELETE, PATCH)
- Return consistent response formats
- Use proper HTTP status codes
- Implement pagination for list endpoints
- Add rate limiting to prevent abuse
- Document all APIs with Swagger/OpenAPI
