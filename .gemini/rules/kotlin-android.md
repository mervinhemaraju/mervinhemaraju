# Kotlin / Android Rules

## Kotlin Style

- Idiomatic Kotlin — use data classes, sealed classes, extension functions
- Coroutines + Flow for async — no raw threads or callbacks
- Prefer `val` over `var`; immutability by default
- Null safety strictly — avoid `!!` without a justifying comment

## Android Architecture

- MVVM or MVI (follow what the project uses — never mix patterns)
- ViewModel + StateFlow/SharedFlow for UI state
- Repository pattern for all data sources
- Hilt for dependency injection

## Jetpack Compose (if used)

- Stateless composables where possible — hoist state up
- No business logic inside composables
- Preview functions for all non-trivial composables

## Error Handling

- Use sealed Result/UiState classes — never expose raw exceptions to UI layer
- Handle all coroutine exceptions — no silent failures in viewModelScope

## Testing

- JUnit5 + MockK
- ViewModels tested with TestCoroutineDispatcher
- Repository tests against fake data sources
