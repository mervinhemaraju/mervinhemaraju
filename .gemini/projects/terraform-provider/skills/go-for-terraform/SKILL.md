---
name: go-for-terraform
description: Use when writing Go code for a Terraform provider — covers idiomatic error handling, context propagation, struct and interface design, nil safety, tooling (gofmt, go vet, golangci-lint), table-driven tests, and common beginner pitfalls specific to provider development.
---

# Skill: Go for Terraform Providers

# Covers: Go idioms, error handling, code style, tooling — provider-focused

## Core Go Rules for Provider Development

### Error Handling

```go
// ALWAYS wrap errors with context using %w
body, err := c.do(ctx, "GET", "/things/"+id, nil)
if err != nil {
    return nil, fmt.Errorf("getting thing %q: %w", id, err)
}

// NEVER discard errors
data, _ := json.Marshal(input) // WRONG
data, err := json.Marshal(input) // correct
if err != nil {
    return fmt.Errorf("marshaling input: %w", err)
}

// Error messages: lowercase, no trailing punctuation (Go convention)
fmt.Errorf("creating thing: %w", err)        // correct
fmt.Errorf("Creating thing: %w", err)        // WRONG — uppercase
fmt.Errorf("creating thing: %w.", err)       // WRONG — trailing period
```

### Error Checking with errors.Is / errors.As

```go
// Check for specific error types — never parse error strings
if errors.Is(err, ErrSomeSpecificCondition) {
    // handle it
}

var apiErr *APIError
if errors.As(err, &apiErr) {
    // use apiErr.StatusCode etc.
}

// Support error chaining by implementing Unwrap()
type WrappedError struct {
    msg string
    err error
}
func (e *WrappedError) Error() string { return e.msg + ": " + e.err.Error() }
func (e *WrappedError) Unwrap() error { return e.err } // required for errors.Is/As to work
```

### Context

```go
// Context is ALWAYS the first argument in functions that do I/O
func (c *Client) GetThing(ctx context.Context, id string) (*Thing, error)

// Pass context into all HTTP requests
req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)

// Never create your own context.Background() inside a provider function
// — use the ctx passed in by the framework
func (r *ThingResource) Read(ctx context.Context, ...) {
    thing, err := r.client.GetThing(ctx, id) // pass it through
}
```

### Defer for Cleanup

```go
// Always defer Close immediately after a successful open/do
resp, err := c.httpClient.Do(req)
if err != nil {
    return nil, fmt.Errorf("executing request: %w", err)
}
defer resp.Body.Close() // immediately after the error check

file, err := os.Open(path)
if err != nil {
    return nil, fmt.Errorf("opening file: %w", err)
}
defer file.Close()
```

---

## Structs and Interfaces

```go
// Compile-time interface check — put at the top of every resource file
var _ resource.Resource = &ThingResource{}
var _ resource.ResourceWithImportState = &ThingResource{}

// If these fail to compile, you're missing a method implementation
// This is better than discovering it at runtime
```

### Struct Design

```go
// Unexported fields for implementation details, exported for API types
type Client struct {
    baseURL    string      // unexported — internal
    apiKey     string      // unexported — internal
    httpClient *http.Client // unexported — internal
}

type Thing struct {
    ID   string `json:"id"`   // exported — part of API contract
    Name string `json:"name"`
}
```

---

## Naming Conventions (Go)

```go
// Packages: short, lowercase, no underscores
package client   // correct
package apiClient // WRONG

// Variables and functions: camelCase
var apiKey string
func getThingByID(id string) (*Thing, error)

// Exported types/functions: PascalCase
type Client struct{}
func NewClient() *Client

// Acronyms: all caps
var userID string  // not userId
var apiURL string  // not apiUrl
type HTTPClient    // not HttpClient

// Interfaces: end in -er when possible
type Doer interface { Do(*http.Request) (*http.Response, error) }
type ThingCreator interface { CreateThing(ctx context.Context, ...) (*Thing, error) }
```

---

## Functions

```go
// Keep functions focused — if it exceeds ~50 lines, split it
// No named return values unless they genuinely improve clarity in complex functions

// Return (value, error) — error is always last
func (c *Client) GetThing(ctx context.Context, id string) (*Thing, error)

// For functions returning only an error
func (c *Client) DeleteThing(ctx context.Context, id string) error

// Pointer receivers for structs with state, value receivers for stateless
func (c *Client) GetThing(...) (*Thing, error)  // pointer — Client has state
func (e APIError) Error() string                // value — no mutation needed
```

---

## Nil Safety

```go
// Check pointer before use
if thing == nil {
    return nil, fmt.Errorf("api returned nil thing for id %q", id)
}

// Use pointer fields in update structs for optional boolean/int fields
// so the zero value (false/0) can be distinguished from "not set"
type UpdateInput struct {
    Enabled *bool   `json:"enabled,omitempty"` // nil = not set, &false = explicitly false
    Count   *int64  `json:"count,omitempty"`
}

enabled := true
input := UpdateInput{Enabled: &enabled}
```

---

## Testing Patterns

```go
// Table-driven tests — idiomatic Go
func TestIsNotFound(t *testing.T) {
    t.Parallel()

    tests := []struct {
        name     string
        err      error
        expected bool
    }{
        {"not found error", &NotFoundError{}, true},
        {"other error", fmt.Errorf("boom"), false},
        {"nil", nil, false},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel() // safe since tt is captured by value
            if got := IsNotFound(tt.err); got != tt.expected {
                t.Errorf("got %v, want %v", got, tt.expected)
            }
        })
    }
}

// Unit test naming: TestUnit<Name> so they can be run separately
// go test ./... -run "^TestUnit"
func TestUnitBuildRequestURL(t *testing.T) { ... }

// Acceptance test naming: TestAcc<ResourceName>
// TF_ACC=1 go test ./... -run "^TestAcc"
func TestAccThingResource(t *testing.T) { ... }
```

---

## Tooling

Always run before committing:

```bash
# Format code (mandatory in Go)
gofmt -s -w .

# Fix imports
goimports -w .

# Catch bugs (nil deref, unreachable code, etc.)
go vet ./...

# Lint (install golangci-lint)
golangci-lint run ./...

# Verify no broken dependencies
go mod tidy
go mod verify
```

Recommended `.golangci.yml` config for providers:

```yaml
linters:
  enable:
    - errcheck # ensure errors are checked
    - govet # go vet checks
    - staticcheck # advanced static analysis
    - unused # find unused code
    - misspell # catch typos
    - gofmt # enforce formatting
    - exhaustive # ensure switch statements cover all cases

linters-settings:
  errcheck:
    check-type-assertions: true
```

---

## Common Beginner Mistakes

```go
// MISTAKE: shadowing err in nested scope
result, err := doFirst()
if err != nil {
    result, err := doSecond() // this 'err' is a NEW variable — outer err unchanged
    _ = result
}
// FIX: use = not := for existing variables
result, err = doSecond()

// MISTAKE: ranging over nil slice (safe in Go, but easy to misread)
var items []Thing // nil
for _, item := range items { // this is fine — zero iterations
    _ = item
}

// MISTAKE: defer in a loop — defers stack until function returns, not loop end
for _, id := range ids {
    resp, _ := http.Get(url + id)
    defer resp.Body.Close() // WRONG — all defers fire at function exit
}
// FIX: use a helper function or close explicitly
for _, id := range ids {
    if err := fetchAndClose(url + id); err != nil {
        return err
    }
}

// MISTAKE: goroutine variable capture in loop (fixed in Go 1.22+, but be aware)
for _, id := range ids {
    go func() {
        fmt.Println(id) // pre-1.22: all goroutines may print the last id
    }()
}
```

---

## DO / DON'T: Go

- ✅ `gofmt` every file — non-negotiable in Go
- ✅ `go vet` before every commit — catches real bugs
- ✅ Use `errors.Is` / `errors.As` — never `err.Error() == "some string"`
- ✅ Always pass `context.Context` as the first argument in I/O functions
- ✅ Commit `go.sum` — it's a security lockfile
- ✅ Run `go mod tidy` before committing
- ❌ Never use `panic` in provider code — use diagnostics
- ❌ Never ignore returned errors with `_`
- ❌ Never use `init()` functions — pass dependencies explicitly
- ❌ Never use global mutable state
