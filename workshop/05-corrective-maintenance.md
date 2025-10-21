# Workshop: Taking back control of your code
(continues where [04-opengrep-advanced-structural-search.md](./04-opengrep-advanced-structural-search.md) file ended)

## Corrective Maintenance
Now that we’ve introduced both `ast-grep` and `Opengrep`, it’s time to apply `ast-grep` in a real-world scenario.

Normally, during **Corrective Maintenance**, you manually fix bugs by changing code.  
But what if a bug isn’t a one-off — what if it’s caused by something you’ve been doing wrong for a while? 🙀  
Tracing that through your Git history can become quite difficult.

To learn how `ast-grep` can help automate corrective fixes, we’ll first **introduce the bugs** ourselves into the workshop’s codebase.

💡 **NOTE** A similar rule could be built with `Opengrep`, but I ran into practical issues matching a boolean class field without selecting the whole class. Since `ast-grep` handles this elegantly, we’ll focus on it for the rest of the workshop.

### Preparing the code lab
Instead of using a separate branches for the workshop labs, we use a shell script, that internally uses `ast-grep`, to introduce the bugs 🙈:
```sh
./prep-code-lab-corrective-maintenance.sh
```

This script removes the explicit `type: Boolean` property from `@property` decorators in several files.

As a result, fields using a boolean **HTML attribute** (instead of a Lit property binding with the `.` prefix) will break.
For example, using `<ha-selector-date required>` will pass an empty string (`''`) instead of the expected boolean `true`.

✅ *Conclusion:* This small change introduces a subtle but realistic type bug we can now detect automatically.

## Using ast-grep to search for the bug
To find all places where this bug might occur, we’ll create an `ast-grep` **search rule** in YAML.

We’ll build the rule step by step — this will help you understand the structure of `ast-grep` rules from the ground up.

Our goal:
Find all boolean class fields that have a `@property` decorator but **no explicit `type` property**.

### Step 1: Create the rule file
Let’s create a minimal ast-grep YAML file **a rule** inside `./ast-grep/rules/search/find-boolean-lit-property-without-type.yml`:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/ast-grep/ast-grep/main/schemas/rule.json
id: find-boolean-lit-property-without-type
language: ts

rule:
  # ..
```

Every rule should contain:
* an optional `$schema` link for IDE autocompletion
* an `id`
* a `language` (e.g. `ts` for TypeScript)
* a `rule` definition

### Step 2: Match all class fields
Let’s make it match all class fields first:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/ast-grep/ast-grep/main/schemas/rule.json
id: find-boolean-lit-property-without-type
language: ts

rule:
  kind: public_field_definition # matches any class field, even those with JS `#` prefix or TS `private` modifier
```

💡 **NOTE** The name `public_field_definition` comes from the TypeScript Tree-Sitter grammar and also includes `#private`, `private`, and `protected` fields.

Run the rule:
```sh
ast-grep scan --rule ../ast-grep/rules/search/find-boolean-lit-property-without-type.yml ../src
```

✅ *Conclusion:* We now match all class fields — but we’ll narrow this down next.


### Step 3: Match only boolean fields
Let’s add a `has` relational rule to restrict matches to fields explicitly typed as `boolean`:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/ast-grep/ast-grep/main/schemas/rule.json
id: find-boolean-lit-property-without-type
language: ts

rule:
  kind: public_field_definition # matches any class field, even those with JS `#` prefix or TS `private` modifier
  has: # `: boolean` type annotation
    field: type
    has: { kind: predefined_type, regex: ^boolean$ }
```

💡 **NOTE** `field` refers to a child node field within the AST — for example, `type` or `value`.
Run it again:
```sh
ast-grep scan --rule ../ast-grep/rules/search/find-boolean-lit-property-without-type.yml ../src
```

✅ *Conclusion:* Only boolean-typed fields are now matched.


### Step 4: Include inferred booleans (`true` or `false`)
We should also include fields where the type is inferred from an assigned boolean value.
To do this, we can use `any` to combine two `has` rules — one for the explicit type, and one for `true`/`false` values.

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/ast-grep/ast-grep/main/schemas/rule.json
id: find-boolean-lit-property-without-type
language: ts

rule:
  kind: public_field_definition # matches any class field, even those with JS `#` prefix or TS `private` modifier
  any:
    - has: # `: boolean` type annotation
        field: type
        has: { kind: predefined_type, regex: ^boolean$ }
    - has: # literal `true` or `false` value
        field: value
        regex: ^(true|false)$
```

✅ *Conclusion:* Both explicitly and implicitly boolean fields are now captured.


### Step 5: Restrict to `@property` decorators
We only care about fields that use the Lit `@property` decorator.

Add this pattern:
```yaml
has:
  pattern: |
    @property($PROPERTY_OPTIONS)
```

Now the rule becomes:
```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/ast-grep/ast-grep/main/schemas/rule.json
id: find-boolean-lit-property-without-type
language: ts

rule:
  kind: public_field_definition # matches any class field, even those with JS `#` prefix or TS `private` modifier
  any:
    - has: # `: boolean` type annotation
        field: type
        has: { kind: predefined_type, regex: ^boolean$ }
    - has: # literal `true` or `false` value
        field: value
        regex: ^(true|false)$
  has:
    pattern: |
      @property($PROPERTY_OPTIONS)
```

✅ *Conclusion:* We’re now filtering to Lit-style properties.


### Step 6: Add constraints to exclude valid properties
We only want `@property` decorators **without** `type: Boolean` — so we’ll add constraints:

```yaml
constraints:
  PROPERTY_OPTIONS:
    kind: object
    not:
      has:
        pattern:
          context: |
            { type: Boolean }
          selector: pair
```

✅ *Conclusion:* The rule now only returns `@property` decorators missing `type: Boolean`.

### Step 7: Exclude `attribute: false`
When `attribute: false` is specified, the `type` property is not needed.
We can use an `all` composite rule to exclude both cases simultaneously:

```yaml
constraints:
  PROPERTY_OPTIONS:
    kind: object
    all:
      - not:
          has:
            pattern:
              context: |
                { type: $_ }
              selector: pair
      - not:
          has:
            pattern:
              context: |
                { attribute: false }
              selector: pair
```

✅ *Conclusion:* Only `@property` decorators that lack both `type` and `attribute: false` are now returned.


### Step 8: Support both `@property()` and `@property({...})`
Finally, include both forms of the decorator:

```yaml
has:
  any:
    - pattern: |
        @property()
    - pattern: |
        @property($PROPERTY_OPTIONS)
```

✅ *Conclusion:* Both empty and configured `@property` decorators are covered.


### ✅ Final rule
```yaml
constraints:
  PROPERTY_OPTIONS:
    kind: object
    all:
      - not:
          has: # `type` property with any value
            pattern:
              context: |
                { type: $_ }
              selector: pair
      - not:
          has: # `attribute: false` property
            pattern:
              context: |
                {attribute: false }
              selector: pair
```

This changes the contents of our search rule to be:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/ast-grep/ast-grep/main/schemas/rule.json
id: find-boolean-lit-property-without-type
language: ts

rule:
  kind: public_field_definition # matches any class field, even those with JS `#` prefix or TS `private` modifier
  any:
    - has: # `: boolean` type annotation
        field: type
        has: { kind: predefined_type, regex: ^boolean$ }
    - has: # literal `true` or `false` value
        field: value
        regex: ^(true|false)$
  has:
    any:
      - pattern: |
          @property()
      - pattern: |
          @property($PROPERTY_OPTIONS)

constraints:
  PROPERTY_OPTIONS:
    kind: object
    all:
      - not:
          has: # `type` property with any value
            pattern:
              context: |
                { type: $_ }
              selector: pair
      - not:
          has: # `attribute: false` property
            pattern:
              context: |
                { attribute: false }
              selector: pair
```

Run it one last time:

```sh
ast-grep scan --rule ../ast-grep/rules/search/find-boolean-lit-property-without-type.yml ../src
```

✅ *Conclusion:* The rule correctly identifies Lit `@property` decorators missing a `type`, excluding valid `attribute: false` cases.

## Always prefer off-the-shelf lint rules

As it turns out, writing this `ast-grep` rule was technically unnecessary 🤦 — but hopefully it was fun and educational 🤓.

The [`lit-analyzer`](https://github.com/runem/lit-analyzer/tree/master/packages/lit-analyzer) tool already provides a rule that performs this exact check — plus many others!

You can run it directly via the NPM script in `package.json`:

```sh
yarn lint:lit
```

✅ *Conclusion:* Custom `ast-grep` rules are powerful, but off-the-shelf lint rules like `lit-analyzer` can save time and maintenance effort.

