# Coding Style

## Immutability (CRITICAL)

ALWAYS create new objects, NEVER mutate existing ones:

```
// Pseudocode
WRONG:  modify(original, field, value) → changes original in-place
CORRECT: update(original, field, value) → returns new copy with change
```

Rationale: Immutable data prevents hidden side effects, makes debugging easier, and enables safe concurrency.

## Core Principles

### KISS (Keep It Simple)

- Prefer the simplest solution that actually works
- Avoid premature optimization
- Optimize for clarity over cleverness

### DRY (Don't Repeat Yourself)

- Extract repeated logic into shared functions or utilities
- Avoid copy-paste implementation drift
- Introduce abstractions when repetition is real, not speculative

### YAGNI (You Aren't Gonna Need It)

- Do not build features or abstractions before they are needed
- Avoid speculative generality
- Start simple, then refactor when the pressure is real

## File Organization

MANY SMALL FILES > FEW LARGE FILES:
- High cohesion, low coupling
- 200-400 lines typical, 800 max
- Extract utilities from large modules
- Organize by feature/domain, not by type

## Module Depth (Deep > Shallow)

Prefer **deep modules**: a simple interface hiding a complex implementation. A module's value
is the functionality it provides divided by the complexity of its interface — maximize the
implementation behind the interface, minimize the surface area in front of it.

- **Deep module** — few entry points, lots of capability hidden behind them. The caller
  needs to know almost nothing about the inside (e.g. a `Cache` exposing `get`/`set` over a
  complex eviction + serialization backend).
- **Shallow module** — interface nearly as complex as the implementation; it leaks detail and
  hides nothing (e.g. a wrapper whose signature mirrors the one function it forwards to).

Why this matters more with AI: code assistants default to *shallow* modules — when a new
requirement appears, the easy local move is a new file or a new thin function. Left
unchecked, the codebase fragments into many tiny coupled pieces, and the assistant then can't
trace intent through the fog. The human's leverage is to **own the interfaces and the module
boundaries**; the implementation behind a clean boundary can be delegated.

- Define the interface and the boundary first; let the implementation fill in behind it.
- Critical modules (auth, payments, money, security) — review the implementation too, not
  just the interface. Don't blindly delegate a blast-radius module.
- A clean boundary is also a clean test seam: test the interface's behavior, not the internals.

## Error Handling

ALWAYS handle errors comprehensively:
- Handle errors explicitly at every level
- Provide user-friendly error messages in UI-facing code
- Log detailed error context on the server side
- Never silently swallow errors

## Input Validation

ALWAYS validate at system boundaries:
- Validate all user input before processing
- Use schema-based validation where available
- Fail fast with clear error messages
- Never trust external data (API responses, user input, file content)

## Naming Conventions

- Variables and functions: `camelCase` with descriptive names
- Booleans: prefer `is`, `has`, `should`, or `can` prefixes
- Interfaces, types, and components: `PascalCase`
- Constants: `UPPER_SNAKE_CASE`
- Custom hooks: `camelCase` with a `use` prefix

## Code Smells to Avoid

### Deep Nesting

Prefer early returns over nested conditionals once the logic starts stacking.

### Magic Numbers

Use named constants for meaningful thresholds, delays, and limits.

### Long Functions

Split large functions into focused pieces with clear responsibilities.

## Code Quality Checklist

Before marking work complete:
- [ ] Code is readable and well-named
- [ ] Functions are small (<50 lines)
- [ ] Files are focused (<800 lines)
- [ ] No deep nesting (>4 levels)
- [ ] Proper error handling
- [ ] No hardcoded values (use constants or config)
- [ ] No mutation (immutable patterns used)
