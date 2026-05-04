---
name: tf-provider-testing
description: Use when writing or debugging Terraform provider tests — covers acceptance test structure, provider factories, CheckDestroy, ImportState steps, force-replace scenarios, unit tests, and test helpers using terraform-plugin-testing.
---

# Skill: Terraform Provider Testing

# Covers: acceptance tests, unit tests, test helpers, CheckDestroy, mock patterns

## Testing Philosophy

- **Acceptance tests** hit the real API — they are integration tests, not mocks
- **Unit tests** test pure logic: schema validation, model mapping, helper functions
- Every resource must have acceptance tests covering: Create+Read, Update, Import, Delete
- Set `TF_ACC=1` to run acceptance tests — they are skipped otherwise
- Always clean up real resources — use `CheckDestroy`
- Run with: `TF_ACC=1 go test ./... -v -timeout 120m`

---

## Test Provider Factory (shared setup)

```go
// internal/provider/provider_test.go
package provider_test

import (
	"os"
	"testing"

	"github.com/hashicorp/terraform-plugin-framework/providerserver"
	"github.com/hashicorp/terraform-plugin-go/tfprotov6"
	"github.com/<org>/terraform-provider-<n>/internal/provider"
)

// testAccProtoV6ProviderFactories is shared across all acceptance tests
var testAccProtoV6ProviderFactories = map[string]func() (tfprotov6.ProviderServer, error){
	"<n>": providerserver.NewProtocol6WithError(provider.New("test")()),
}

// testAccPreCheck validates required env vars are set before running acc tests
func testAccPreCheck(t *testing.T) {
	t.Helper()
	if v := os.Getenv("<n>_HOST"); v == "" {
		t.Fatal("<n>_HOST must be set for acceptance tests")
	}
	if v := os.Getenv("<n>_API_KEY"); v == "" {
		t.Fatal("<n>_API_KEY must be set for acceptance tests")
	}
}
```

---

## Full Resource Acceptance Test

```go
// internal/resources/thing_resource_test.go
package resources_test

import (
	"fmt"
	"testing"

	"github.com/hashicorp/terraform-plugin-testing/helper/resource"
	"github.com/hashicorp/terraform-plugin-testing/terraform"
	"github.com/<org>/terraform-provider-<n>/internal/provider"
)

func TestAccThingResource(t *testing.T) {
	resourceName := "<n>_thing.test"

	resource.Test(t, resource.TestCase{
		PreCheck:                 func() { testAccPreCheck(t) },
		ProtoV6ProviderFactories: testAccProtoV6ProviderFactories,
		CheckDestroy:             testAccCheckThingDestroy,
		Steps: []resource.TestStep{
			// Step 1: Create and Read
			{
				Config: testAccThingConfig("test-thing", "initial description"),
				Check: resource.ComposeAggregateTestCheckFunc(
					// Verify computed fields are set
					resource.TestCheckResourceAttrSet(resourceName, "id"),
					// Verify user-supplied fields
					resource.TestCheckResourceAttr(resourceName, "name", "test-thing"),
					resource.TestCheckResourceAttr(resourceName, "description", "initial description"),
					resource.TestCheckResourceAttr(resourceName, "enabled", "true"),
				),
			},
			// Step 2: ImportState — verify import works correctly
			{
				ResourceName:      resourceName,
				ImportState:       true,
				ImportStateVerify: true,
				// Exclude fields not returned by the API on read
				// ImportStateVerifyIgnore: []string{"some_write_only_field"},
			},
			// Step 3: Update
			{
				Config: testAccThingConfig("test-thing", "updated description"),
				Check: resource.ComposeAggregateTestCheckFunc(
					resource.TestCheckResourceAttr(resourceName, "description", "updated description"),
					// ID must not change on update
					resource.TestCheckResourceAttrSet(resourceName, "id"),
				),
			},
		},
	})
}

// testAccThingConfig generates Terraform config for acceptance tests
func testAccThingConfig(name, description string) string {
	return fmt.Sprintf(`
resource "<n>_thing" "test" {
  name        = %q
  description = %q
  enabled     = true
}
`, name, description)
}

// testAccCheckThingDestroy verifies the resource was deleted from the API
func testAccCheckThingDestroy(s *terraform.State) error {
	// Get a real API client from env vars
	c := getTestClient()

	for _, rs := range s.RootModule().Resources {
		if rs.Type != "<n>_thing" {
			continue
		}
		_, err := c.GetThing(context.Background(), rs.Primary.ID)
		if err == nil {
			return fmt.Errorf("thing %s still exists", rs.Primary.ID)
		}
		if !client.IsNotFound(err) {
			return fmt.Errorf("unexpected error checking thing %s: %s", rs.Primary.ID, err)
		}
	}
	return nil
}
```

---

## Testing Immutable Fields (RequiresReplace)

```go
// Verify that changing an immutable field destroys and recreates the resource
func TestAccThingResource_ForceNew(t *testing.T) {
	resourceName := "<n>_thing.test"
	var firstID, secondID string

	resource.Test(t, resource.TestCase{
		PreCheck:                 func() { testAccPreCheck(t) },
		ProtoV6ProviderFactories: testAccProtoV6ProviderFactories,
		CheckDestroy:             testAccCheckThingDestroy,
		Steps: []resource.TestStep{
			{
				Config: testAccThingConfigWithRegion("test-thing", "us-east-1"),
				Check: resource.ComposeTestCheckFunc(
					resource.TestCheckResourceAttrSet(resourceName, "id"),
					testExtractID(resourceName, &firstID),
				),
			},
			{
				Config: testAccThingConfigWithRegion("test-thing", "eu-west-1"), // region changed
				Check: resource.ComposeTestCheckFunc(
					resource.TestCheckResourceAttrSet(resourceName, "id"),
					testExtractID(resourceName, &secondID),
					// IDs must differ — resource was replaced
					testCheckIDChanged(&firstID, &secondID),
				),
			},
		},
	})
}
```

---

## Unit Tests (no API calls)

Use unit tests for: schema validation logic, model mapping functions, helper utilities.

```go
// internal/client/errors_test.go
package client_test

import (
	"testing"
)

func TestIsNotFound(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name     string
		err      error
		expected bool
	}{
		{"not found error", &NotFoundError{ID: "abc"}, true},
		{"api error", &APIError{StatusCode: 500}, false},
		{"nil error", nil, false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			got := IsNotFound(tt.err)
			if got != tt.expected {
				t.Errorf("IsNotFound(%v) = %v, want %v", tt.err, got, tt.expected)
			}
		})
	}
}
```

---

## Common Test Helpers

```go
// internal/provider/testhelpers_test.go
package provider_test

import (
	"os"
	"github.com/<org>/terraform-provider-<n>/internal/client"
)

func getTestClient() *client.Client {
	return client.New(
		os.Getenv("<n>_HOST"),
		os.Getenv("<n>_API_KEY"),
	)
}

// testExtractID captures a resource ID during a test step for comparison later
func testExtractID(resourceName string, id *string) resource.TestCheckFunc {
	return func(s *terraform.State) error {
		rs, ok := s.RootModule().Resources[resourceName]
		if !ok {
			return fmt.Errorf("resource %s not found", resourceName)
		}
		*id = rs.Primary.ID
		return nil
	}
}
```

---

## DO / DON'T: Testing

- ✅ Always include `PreCheck` calling `testAccPreCheck(t)`
- ✅ Always include `CheckDestroy` — never leave real resources behind
- ✅ Always include an ImportState step for every resource
- ✅ Use `resource.ComposeAggregateTestCheckFunc` (stops on first failure)
- ✅ Use `t.Parallel()` in unit tests to speed up runs
- ✅ Use `%q` in config templates to safely quote string values
- ❌ Never hardcode API credentials in test files
- ❌ Never skip `CheckDestroy` — leaked resources cost real money
- ❌ Never use `resource.ComposeTestCheckFunc` when you want early failure — use Aggregate variant
