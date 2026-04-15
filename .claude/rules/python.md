# Python Rules

## Style

- Python 3.11+ features preferred
- Full type hints on all functions and class attributes (mypy strict)
- Black formatting, isort imports, ruff linting
- f-strings for string formatting — no % or .format()

## Structure

- src/ layout for packages
- Domain-driven module structure
- Stateless services; state lives in DB or cache
- Repository pattern for all data access — no raw DB calls in business logic

## Error Handling

- Custom exception classes in `exceptions.py`
- Minimal use of `raise Exception("message")`. Use custom exceptions where appropriate.
- Use `structlog` for logging — never `print()` or bare `logging`

## Testing

- pytest + pytest-asyncio
- Fixtures in `conftest.py`
- Test file mirrors src/ structure under tests/
- Mock external I/O; test business logic with unit tests
- Always arrange tests as much as possible in `arrange, act and assert` principles
- Clear separation of files for each logical tests. Don't put everything in one file.
