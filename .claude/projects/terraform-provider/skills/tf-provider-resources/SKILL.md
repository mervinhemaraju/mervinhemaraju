---
name: tf-provider-resources
description: Use when building or reviewing Terraform provider resources, data sources, or ephemeral resources — covers schema attributes, plan modifiers, CRUD lifecycle, state management, diagnostics, and sensitive data handling with terraform-plugin-framework.
---

# Skill: Terraform Provider Resources

# Covers: resources, data sources, ephemeral resources, schema attributes, plan modifiers, diagnostics

## Resource Template

```go
package resources

import (
	"context"
	"fmt"

	"github.com/hashicorp/terraform-plugin-framework/path"
	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/planmodifier"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/stringplanmodifier"
	"github.com/hashicorp/terraform-plugin-framework/types"
	"github.com/<org>/terraform-provider-<n>/internal/client"
)

// Compile-time interface checks — always include these
var _ resource.Resource = &ThingResource{}
var _ resource.ResourceWithImportState = &ThingResource{}

type ThingResource struct {
	client *client.Client
}

// thingModel maps schema <-> Go struct — one field per schema attribute
type thingModel struct {
	ID          types.String `tfsdk:"id"`
	Name        types.String `tfsdk:"name"`
	Description types.String `tfsdk:"description"`
	Enabled     types.Bool   `tfsdk:"enabled"`
	Tags        types.Map    `tfsdk:"tags"`
}

func NewThingResource() resource.Resource {
	return &ThingResource{}
}

func (r *ThingResource) Metadata(_ context.Context, req resource.MetadataRequest, resp *resource.MetadataResponse) {
	// TypeName = <provider_name>_<resource_name> — always provider prefix + underscore
	resp.TypeName = req.ProviderTypeName + "_thing"
}

func (r *ThingResource) Schema(_ context.Context, _ resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		Description: "Manages a Thing resource.",
		Attributes: map[string]schema.Attribute{
			"id": schema.StringAttribute{
				Computed:    true,
				Description: "Unique identifier of the thing.",
				PlanModifiers: []planmodifier.String{
					// Keeps the known state value during updates — prevents noisy diffs on computed fields
					stringplanmodifier.UseStateForUnknown(),
				},
			},
			"name": schema.StringAttribute{
				Required:    true,
				Description: "Name of the thing. Must be unique within the account.",
			},
			"description": schema.StringAttribute{
				Optional:    true,
				Computed:    true, // API may return a default value
				Description: "Human-readable description of the thing.",
			},
			"enabled": schema.BoolAttribute{
				Optional:    true,
				Computed:    true,
				Description: "Whether the thing is enabled. Defaults to true.",
				// Boolean: true = DO, false = DON'T — follow this convention always
			},
			"tags": schema.MapAttribute{
				Optional:    true,
				ElementType: types.StringType,
				Description: "Map of tags to assign to the thing.",
				// Map/list/set attributes use plural nouns
			},
			"region": schema.StringAttribute{
				Required: true,
				Description: "Region where the thing is created.",
				PlanModifiers: []planmodifier.String{
					// Forces resource replacement if this field changes (immutable field)
					stringplanmodifier.RequiresReplace(),
				},
			},
		},
	}
}

func (r *ThingResource) Configure(_ context.Context, req resource.ConfigureRequest, resp *resource.ConfigureResponse) {
	if req.ProviderData == nil {
		return
	}
	c, ok := req.ProviderData.(*client.Client)
	if !ok {
		resp.Diagnostics.AddError(
			"Unexpected Resource Configure Type",
			fmt.Sprintf("Expected *client.Client, got: %T. Report this to the provider developer.", req.ProviderData),
		)
		return
	}
	r.client = c
}

func (r *ThingResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var plan thingModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &plan)...)
	if resp.Diagnostics.HasError() {
		return
	}

	thing, err := r.client.CreateThing(ctx, client.CreateThingInput{
		Name:        plan.Name.ValueString(),
		Description: plan.Description.ValueString(),
		Enabled:     plan.Enabled.ValueBool(),
	})
	if err != nil {
		resp.Diagnostics.AddError(
			"Error Creating Thing",
			fmt.Sprintf("Could not create thing %q: %s", plan.Name.ValueString(), err),
		)
		return
	}

	// Map API response back to model
	plan.ID = types.StringValue(thing.ID)
	plan.Description = types.StringValue(thing.Description)
	plan.Enabled = types.BoolValue(thing.Enabled)

	resp.Diagnostics.Append(resp.State.Set(ctx, &plan)...)
}

func (r *ThingResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var state thingModel
	resp.Diagnostics.Append(req.State.Get(ctx, &state)...)
	if resp.Diagnostics.HasError() {
		return
	}

	thing, err := r.client.GetThing(ctx, state.ID.ValueString())
	if err != nil {
		if client.IsNotFound(err) {
			// Resource was deleted outside Terraform — remove from state
			resp.State.RemoveResource(ctx)
			return
		}
		resp.Diagnostics.AddError(
			"Error Reading Thing",
			fmt.Sprintf("Could not read thing %q: %s", state.ID.ValueString(), err),
		)
		return
	}

	state.Name = types.StringValue(thing.Name)
	state.Description = types.StringValue(thing.Description)
	state.Enabled = types.BoolValue(thing.Enabled)

	resp.Diagnostics.Append(resp.State.Set(ctx, &state)...)
}

func (r *ThingResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var plan thingModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &plan)...)
	if resp.Diagnostics.HasError() {
		return
	}

	_, err := r.client.UpdateThing(ctx, plan.ID.ValueString(), client.UpdateThingInput{
		Name:        plan.Name.ValueString(),
		Description: plan.Description.ValueString(),
		Enabled:     plan.Enabled.ValueBool(),
	})
	if err != nil {
		resp.Diagnostics.AddError(
			"Error Updating Thing",
			fmt.Sprintf("Could not update thing %q: %s", plan.ID.ValueString(), err),
		)
		return
	}

	resp.Diagnostics.Append(resp.State.Set(ctx, &plan)...)
}

func (r *ThingResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var state thingModel
	resp.Diagnostics.Append(req.State.Get(ctx, &state)...)
	if resp.Diagnostics.HasError() {
		return
	}

	err := r.client.DeleteThing(ctx, state.ID.ValueString())
	if err != nil {
		if client.IsNotFound(err) {
			return // already gone — not an error
		}
		resp.Diagnostics.AddError(
			"Error Deleting Thing",
			fmt.Sprintf("Could not delete thing %q: %s", state.ID.ValueString(), err),
		)
		return
	}
}

func (r *ThingResource) ImportState(ctx context.Context, req resource.ImportStateRequest, resp *resource.ImportStateResponse) {
	// Import by ID — the most common pattern
	resource.ImportStatePassthroughID(ctx, path.Root("id"), req, resp)
}
```

---

## Data Source Template

```go
package datasources

var _ datasource.DataSource = &ThingDataSource{}

type ThingDataSource struct {
	client *client.Client
}

// Data source names can be plural if they return lists (e.g. <provider>_things)
func NewThingDataSource() datasource.DataSource {
	return &ThingDataSource{}
}

func (d *ThingDataSource) Metadata(_ context.Context, req datasource.MetadataRequest, resp *datasource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_thing" // singular — returns one object
}
```

---

## Ephemeral Resource Template (for sensitive objects like tokens)

Use for API tokens, secrets, or credentials that must NOT be stored in Terraform state.

```go
package ephemeral

import (
	"context"
	"github.com/hashicorp/terraform-plugin-framework/ephemeral"
	"github.com/hashicorp/terraform-plugin-framework/ephemeral/schema"
)

var _ ephemeral.EphemeralResource = &TokenEphemeral{}

type TokenEphemeral struct {
	client *client.Client
}

type tokenEphemeralModel struct {
	RoleID types.String `tfsdk:"role_id"`
	Token  types.String `tfsdk:"token"` // never stored in state
}

func NewTokenEphemeral() ephemeral.EphemeralResource {
	return &TokenEphemeral{}
}

func (e *TokenEphemeral) Metadata(_ context.Context, req ephemeral.MetadataRequest, resp *ephemeral.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_token"
}

func (e *TokenEphemeral) Schema(_ context.Context, _ ephemeral.SchemaRequest, resp *ephemeral.SchemaResponse) {
	resp.Schema = schema.Schema{
		Description: "Retrieves a short-lived API token. Not stored in state.",
		Attributes: map[string]schema.Attribute{
			"role_id": schema.StringAttribute{
				Required:    true,
				Description: "ID of the role to generate a token for.",
			},
			"token": schema.StringAttribute{
				Computed:    true,
				Sensitive:   true,
				Description: "The generated token value.",
			},
		},
	}
}

func (e *TokenEphemeral) Open(ctx context.Context, req ephemeral.OpenRequest, resp *ephemeral.OpenResponse) {
	var config tokenEphemeralModel
	resp.Diagnostics.Append(req.Config.Get(ctx, &config)...)
	if resp.Diagnostics.HasError() {
		return
	}

	token, err := e.client.CreateToken(ctx, config.RoleID.ValueString())
	if err != nil {
		resp.Diagnostics.AddError("Error Creating Token", err.Error())
		return
	}

	config.Token = types.StringValue(token)
	resp.Diagnostics.Append(resp.Result.Set(ctx, &config)...)
}
```

---

## Schema Attribute Quick Reference

| Need                 | Use                                                   |
| -------------------- | ----------------------------------------------------- |
| Simple string        | `schema.StringAttribute{}`                            |
| Integer              | `schema.Int64Attribute{}`                             |
| Float                | `schema.Float64Attribute{}`                           |
| Boolean              | `schema.BoolAttribute{}`                              |
| List of strings      | `schema.ListAttribute{ElementType: types.StringType}` |
| Set of strings       | `schema.SetAttribute{ElementType: types.StringType}`  |
| Map of strings       | `schema.MapAttribute{ElementType: types.StringType}`  |
| Nested single object | `schema.SingleNestedAttribute{Attributes: ...}`       |
| List of objects      | `schema.ListNestedAttribute{NestedObject: ...}`       |
| Secret / password    | Any type + `Sensitive: true`                          |
| Write-only field     | Any type + suffix name with `_wo` e.g. `password_wo`  |

## Setting Values in State

```go
types.StringValue("hello")         // known string
types.StringNull()                  // null (optional field not set)
types.StringUnknown()               // unknown (will be known after apply)
types.BoolValue(true)
types.Int64Value(42)
types.Float64Value(3.14)
```

---

## Plan Modifiers Reference

```go
// On Computed fields (ID, timestamps): prevent unnecessary unknown diffs during updates
stringplanmodifier.UseStateForUnknown()

// On immutable fields: force replacement if the value changes
stringplanmodifier.RequiresReplace()
stringplanmodifier.RequiresReplaceIfConfigured() // only if user explicitly set it

// Equivalents exist for Bool, Int64, Float64, List, Set, Map:
boolplanmodifier.UseStateForUnknown()
int64planmodifier.RequiresReplace()
```

---

## Diagnostics Rules

```go
// Error — use for failures, stops Terraform after the current operation
resp.Diagnostics.AddError(
    "Short Summary Title",           // shown as header — Title Case
    "Detailed message for the user", // shown as body — full sentence
)

// Warning — non-fatal
resp.Diagnostics.AddWarning("Summary", "Detail")

// Propagate from another diagnostics result
resp.Diagnostics.Append(someFunc()...)

// ALWAYS check after reading plan or state
if resp.Diagnostics.HasError() {
    return
}
```

---

## DO / DON'T: Resources

- ✅ Every resource must implement `ImportState`
- ✅ Always call `resp.State.RemoveResource(ctx)` in Read on 404 — do not error
- ✅ Always set state at end of Create, Read, Update — even on partial success
- ✅ Use `Optional + Computed` for fields the API may set a default on
- ✅ Use `Sensitive: true` for any field containing secrets
- ✅ Model tokens/secrets as ephemeral resources — not regular resources
- ❌ Never use `Required + Computed` together
- ❌ Never leave state partially written after an error without returning
- ❌ Never panic — always use `resp.Diagnostics.AddError()`
- ❌ Never make HTTP calls directly in resource files — use `internal/client`
