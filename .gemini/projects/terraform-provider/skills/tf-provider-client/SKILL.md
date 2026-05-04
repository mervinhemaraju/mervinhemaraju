---
name: tf-provider-client
description: Use when building the API client layer of a Terraform provider — covers REST client structure, typed error handling, request helpers, pagination, authentication patterns, and Go HTTP best practices for provider development.
---

# Skill: Terraform Provider REST API Client

# Covers: HTTP client design, error types, request/response patterns, retries, auth

## Core Rules

- All HTTP logic lives in `internal/client/` — never inline in resource files
- Always pass `context.Context` into every request via `http.NewRequestWithContext()`
- Always `defer resp.Body.Close()` immediately after `http.Do()`
- Error messages must be lowercase with no trailing punctuation (Go convention)
- Return typed errors so callers can check with `errors.Is` / `errors.As`
- Wrap errors with `fmt.Errorf("doing X: %w", err)` — never discard them

---

## Client Struct

```go
// internal/client/client.go
package client

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

type Client struct {
	baseURL    string
	apiKey     string
	httpClient *http.Client
}

func New(baseURL, apiKey string) *Client {
	return &Client{
		baseURL: baseURL,
		apiKey:  apiKey,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}
```

---

## Error Types

Define typed errors so resource code can check for specific conditions
without parsing strings.

```go
// internal/client/errors.go
package client

import (
	"errors"
	"fmt"
	"net/http"
)

// NotFoundError is returned when the API responds with 404
type NotFoundError struct {
	ID string
}

func (e *NotFoundError) Error() string {
	return fmt.Sprintf("resource %q not found", e.ID)
}

// APIError is returned for non-2xx responses other than 404
type APIError struct {
	StatusCode int
	Body       string
}

func (e *APIError) Error() string {
	return fmt.Sprintf("api error %d: %s", e.StatusCode, e.Body)
}

// IsNotFound checks if an error is a NotFoundError — use this in resource Read/Delete
func IsNotFound(err error) bool {
	var nfe *NotFoundError
	return errors.As(err, &nfe)
}

func checkResponse(resp *http.Response) error {
	if resp.StatusCode >= 200 && resp.StatusCode < 300 {
		return nil
	}
	body, _ := io.ReadAll(resp.Body)
	if resp.StatusCode == http.StatusNotFound {
		return &NotFoundError{}
	}
	return &APIError{
		StatusCode: resp.StatusCode,
		Body:       string(body),
	}
}
```

---

## Request Helper

```go
// internal/client/request.go
package client

func (c *Client) do(ctx context.Context, method, path string, body any) ([]byte, error) {
	var bodyReader io.Reader
	if body != nil {
		b, err := json.Marshal(body)
		if err != nil {
			return nil, fmt.Errorf("marshaling request body: %w", err)
		}
		bodyReader = bytes.NewReader(b)
	}

	req, err := http.NewRequestWithContext(ctx, method, c.baseURL+path, bodyReader)
	if err != nil {
		return nil, fmt.Errorf("creating request: %w", err)
	}

	req.Header.Set("Authorization", "Bearer "+c.apiKey)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("executing request %s %s: %w", method, path, err)
	}
	defer resp.Body.Close()

	if err := checkResponse(resp); err != nil {
		return nil, err
	}

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("reading response body: %w", err)
	}

	return respBody, nil
}
```

---

## Resource Methods

Each API entity gets its own file with typed input/output structs.

```go
// internal/client/things.go
package client

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
)

// Thing mirrors the upstream API response — keep names matching the API
type Thing struct {
	ID          string            `json:"id"`
	Name        string            `json:"name"`
	Description string            `json:"description"`
	Enabled     bool              `json:"enabled"`
	Tags        map[string]string `json:"tags"`
	CreatedAt   string            `json:"created_at"` // RFC 3339
	UpdatedAt   string            `json:"updated_at"` // RFC 3339
}

type CreateThingInput struct {
	Name        string            `json:"name"`
	Description string            `json:"description,omitempty"`
	Enabled     bool              `json:"enabled"`
	Tags        map[string]string `json:"tags,omitempty"`
}

type UpdateThingInput struct {
	Name        string            `json:"name,omitempty"`
	Description string            `json:"description,omitempty"`
	Enabled     *bool             `json:"enabled,omitempty"` // pointer so false is sent
	Tags        map[string]string `json:"tags,omitempty"`
}

func (c *Client) CreateThing(ctx context.Context, input CreateThingInput) (*Thing, error) {
	body, err := c.do(ctx, http.MethodPost, "/things", input)
	if err != nil {
		return nil, fmt.Errorf("creating thing: %w", err)
	}

	var thing Thing
	if err := json.Unmarshal(body, &thing); err != nil {
		return nil, fmt.Errorf("parsing create thing response: %w", err)
	}
	return &thing, nil
}

func (c *Client) GetThing(ctx context.Context, id string) (*Thing, error) {
	body, err := c.do(ctx, http.MethodGet, "/things/"+id, nil)
	if err != nil {
		return nil, fmt.Errorf("getting thing %q: %w", id, err)
	}

	var thing Thing
	if err := json.Unmarshal(body, &thing); err != nil {
		return nil, fmt.Errorf("parsing get thing response: %w", err)
	}
	return &thing, nil
}

func (c *Client) UpdateThing(ctx context.Context, id string, input UpdateThingInput) (*Thing, error) {
	body, err := c.do(ctx, http.MethodPatch, "/things/"+id, input)
	if err != nil {
		return nil, fmt.Errorf("updating thing %q: %w", id, err)
	}

	var thing Thing
	if err := json.Unmarshal(body, &thing); err != nil {
		return nil, fmt.Errorf("parsing update thing response: %w", err)
	}
	return &thing, nil
}

func (c *Client) DeleteThing(ctx context.Context, id string) error {
	_, err := c.do(ctx, http.MethodDelete, "/things/"+id, nil)
	if err != nil {
		return fmt.Errorf("deleting thing %q: %w", id, err)
	}
	return nil
}
```

---

## Pagination Pattern

```go
func (c *Client) ListThings(ctx context.Context) ([]Thing, error) {
	var all []Thing
	page := 1

	for {
		body, err := c.do(ctx, http.MethodGet, fmt.Sprintf("/things?page=%d", page), nil)
		if err != nil {
			return nil, fmt.Errorf("listing things page %d: %w", page, err)
		}

		var result struct {
			Items    []Thing `json:"items"`
			HasMore  bool    `json:"has_more"`
		}
		if err := json.Unmarshal(body, &result); err != nil {
			return nil, fmt.Errorf("parsing list things response: %w", err)
		}

		all = append(all, result.Items...)
		if !result.HasMore {
			break
		}
		page++
	}

	return all, nil
}
```

---

## DO / DON'T: Client

- ✅ Use typed errors (`NotFoundError`, `APIError`) — not string matching
- ✅ Set a `Timeout` on `http.Client` — default is no timeout
- ✅ Use `http.NewRequestWithContext()` — not `http.NewRequest()`
- ✅ Error messages: lowercase, no trailing punctuation
- ✅ Use pointer fields in update inputs for optional fields (`*bool`, `*string`)
- ✅ Mirror API field names in Go structs using `json` tags
- ❌ Never inline HTTP calls in resource or provider files
- ❌ Never ignore `resp.Body.Close()`
- ❌ Never swallow errors with `_`
- ❌ Never log secrets — the API key must never appear in error messages
