# Dart / Flutter Rules

## Dart Style

- Sound null safety enforced — avoid `!` operator without a justifying comment
- `const` constructors wherever possible
- `freezed` for data classes and sealed unions
- Named parameters for functions with > 2 arguments

## Flutter Architecture

- Clean Architecture: data / core / providers / ui layers
- Features are self-contained under lib/features/
- Shared code in lib/core/ and lib/shared/
- No business logic in widgets — ViewModels/Notifiers/Cubits only
- One widget per file; extract any widget > 50 lines

## State Management

- Riverpod for state management.
- Stateful widgets only for really necessary cases, or else Riverpod.
- No setState outside of isolated leaf widgets.

## Error Handling

- Never throw raw exceptions from repositories — return Result/Either types
- Always handle async errors — no fire-and-forget futures without .catchError
- Always check `mounted` before using BuildContext after an await

## Testing

- Unit tests for all domain logic
- Widget tests for non-trivial UI
- Test files mirror lib/ under test/
