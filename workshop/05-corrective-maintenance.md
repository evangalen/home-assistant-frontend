# Workshop: Taking back control of your code
(continues where [04-opengrep-advanced-structural-search.md](./04-opengrep-advanced-structural-search.md) file ended)

## Corrective Maintenance
Now that we’ve introduced both ast-grep and Opengrep, it’s time to apply ast-grep in a real-world scenario.

Normally, during **Corrective Maintenance**, you manually fix bugs by changing code.  
But what if a bug isn’t a one-off — what if it’s caused by something you’ve been doing wrong for a while? 🙀  
Tracing that through your Git history can become quite difficult.

To learn how ast-grep can help automate corrective fixes, we’ll first **introduce the bugs** ourselves into the workshop’s codebase.

💡 **NOTE** A similar rule could be built with Opengrep, but I ran into practical issues matching a boolean class field
without selecting the whole class. Since ast-grep handles this elegantly, we’ll focus on it for the rest of the workshop.

### Preparing the code lab
Instead of using a separate branch for the workshop labs, we use a shell script, that internally uses ast-grep, to introduce the bugs 🙈:
```sh
./prep-code-lab-corrective-maintenance.sh
```

This script removes the explicit `type: Boolean` property from `@property` decorators in several files.

As a result, fields using a boolean **HTML attribute** (instead of a Lit property binding with the `.` prefix) will break.
For example, using `<ha-selector-date required>` will pass an empty string (`''`) instead of the expected boolean `true`.

✅ *Conclusion:* This small change introduces a subtle but realistic type bug we can now detect automatically.

### Using ast-grep to search for the bug
To find all places where this bug might occur, we’ll create an ast-grep **search rule** in YAML.

We’ll build the rule step by step — this will help you understand the structure of ast-grep rules from the ground up.

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

💡 **NOTE** Instead of using `ast-grep/rules` (or `rules`) folder for all the kinds of ast-grep YAML rules,
I personally prefer to differentiate between the kind of ast-grep rules by placing the rules of a specific kind in a specific sub-folder.

Every rule should contain:
* an optional `$schema` link for IDE autocompletion
* an `id`
* a `language` (e.g. `ts` for TypeScript)
* a `rule` definition

### Step 2: Match all class fields
Currently, the `rule` entry is empty, making the rule currently invalid.
To fix that, change our `rule` entry to search for **any** class field:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/ast-grep/ast-grep/main/schemas/rule.json
id: find-boolean-lit-property-without-type
language: ts

rule:
  kind: public_field_definition # matches any class field, even those with JS `#` prefix or TS `private` modifier
```

💡 **NOTE** The name `public_field_definition` comes from the TypeScript Tree-Sitter grammar and confusingly also matches
fields with a JS `#` prefix and fields with TS modifiers `private` and `protected`.

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

Using the `has` Relational Rule of ast-grep we specify that the class field, specified using `kind: public_field_definition`,  has a predefined type of `boolean`.

TODO: add screenshot of the AST (or CST) of a boolean class field

**NOTE**: the `has` entry, as well as `inside`, `following` and `precedes`, are part of the
[Relational Rules](https://ast-grep.github.io/guide/rule-config/relational-rule.html) from ast-grep.

To specify which name / identifier / text ast-grep must match, it uses regular expressions (regex).

Typically in ast-grep, a regex is only used for a leaf AST node (e.g., `string_fragment`) or a parent AST node with single leaf AST node (e.g., `string` AST node with `string_fragment` inside).

Often the regex used in an ast-grep rule is only the literal text that needs to be matched, which in this case is text `boolean`.
Besides thay a regex is often prefixed with `^` and postfixed with `$` to ensure the regex matches the complete name / identifier / text of de AST node.

**NOTE**: regex in ast-grep uses the limited  Rust flavour of regex, lacking features like back references and look arounds that you find in other modern regex implementations like Java, JavaScript, Kotlin and Python.

Last but not least... notice the `has` entry uses a `field` property (instead of a `kind` property).
A `field` specifies the field name of a parent-child relation between a parent AST node and a child AST node.
In this case the `public_field_definition` AST node has a child AST node that can addresed using `field: type` .
More info about fields van be found in de [Kind vs Field](https://ast-grep.github.io/advanced/core-concepts.html#kind-vs-field) section of the ast-grep documentation.

Now, lets rerun our search rule:
```sh
ast-grep scan --rule ../ast-grep/rules/search/find-boolean-lit-property-without-type.yml ../src
```

Notice now only class fields with an explicitly specified `boolean` type are returned.
And, besides required fields also optional fields,using `?:`, are included in the search results.

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
      has: # `type: Boolean` property
        pattern:
          context: |
            { type: Boolean }
          selector: pair
```

Before we rerun our search rule, it's probably best to do some explaining.

Let's start with the part containing of the `@property($PROPERTY_OPTIONS)` pattern:
```yaml
rule:
  # ..
  has:
    pattern: |
      @property($PROPERTY_OPTIONS)
```

Notice the `|` and the fact that the actual pattern value is placed on the next line.
Ideally you would like to use a plain value in YAML to specify an ast-grep pattern.
But, there are restrictions to using plain values in YAML.
Like that a plain value cannot start with a reserved character like `@`.

To work around this, and other restrictions of plain values in YAML, we instead use `|` to create a literal block (see
[Where X=YAML](https://learnxinyminutes.com/yaml/) on [Learn X in Y minutes](https://learnxinyminutes.com/)).

Now let's focus on the following part:
```yaml
constraints:
  PROPERTY_OPTIONS:
    kind: object
    not:
      has: # `type` property with any value
        pattern:
          context: |
            { type: $_ }
          selector: pair
```

By placing a `constraints` entry next to our `rule` entry, we can apply constraints to one of more meta-variables.
In this case we specify the following constraints for `PROPERTY_OPTIONS`:
- it must be an object type
- containing a `type` property

Last but not least, notice that we not directly using the `pattern` entry to specify our code pattern, but use a [Pattern Object](https://ast-grep.github.io/guide/rule-config/atomic-rule.html#pattern-object) to specify more context for our code pattern with an additionally `selector` to only keep the `pair` node.
This is neccesary, because when directly using `type: Boolean` as a `pattern` entry, the pattern will be parsed as a (JavaScript) Labeled Statement; also see  [ast-grep Playground](https://ast-grep.github.io/playground.html#eyJtb2RlIjoiQ29uZmlnIiwibGFuZyI6InR5cGVzY3JpcHQiLCJxdWVyeSI6IkNvbnN0cnVjdG9yPCQkJF8+IiwicmV3cml0ZSI6IiIsInN0cmljdG5lc3MiOiJhc3QiLCJzZWxlY3RvciI6IiIsImNvbmZpZyI6IiMgeWFtbC1sYW5ndWFnZS1zZXJ2ZXI6ICRzY2hlbWE9aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL2FzdC1ncmVwL2FzdC1ncmVwL21haW4vc2NoZW1hcy9ydWxlLmpzb25cblxuaWQ6IGZpbmQtYm9vbGVhbi1saXQtcHJvcGVydHktd2l0aG91dC10eXBlXG5sYW5ndWFnZTogdHNcbnJ1bGU6XG4gIHBhdHRlcm46IHxcbiAgICB0eXBlOiBCb29sZWFuXG4iLCJzb3VyY2UiOiIvLyBMYWJlbGVkIHN0YXRlbWVudCwgd2l0aCBgdHlwZWAgbGFiZWwgYW5kIGBCb29sZWFuYCB2YWx1ZTtcbi8vIHNlZSBhbHNvOiBodHRwczovL2RldmVsb3Blci5tb3ppbGxhLm9yZy9lbi1VUy9kb2NzL1dlYi9KYXZhU2NyaXB0L1JlZmVyZW5jZS9TdGF0ZW1lbnRzL2xhYmVsXG50eXBlOiBCb29sZWFuXG5cbmNsYXNzIENscyB7XG4gIEBwcm9wZXJ0eSh7IHR5cGU6IEJvb2xlYW4gfSkgcHVibGljIG5hcnJvdyA9IGZhbHNlO1xufVxuIn0=) .

Now let's rerun out search rule:
```sh
ast-grep scan --rule ../ast-grep/rules/search/find-boolean-lit-property-without-type.yml ../src
```

Notice that the shown `@property` no longer includes decorators / annotations other than `@property` and that only
`@property` are included without a `type` property.

But notice that `@property` with `attribute: false` are still included.

### Step 7: Exclude `attribute: false`
When `attribute: false` is specified, the `type` property is not needed.
We can use an `all` composite rule to exclude both cases simultaneously:

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

✅ *Conclusion:* Only `@property` decorators that lack both `type` and `attribute: false` are now returned.


### Step 8: Support both `@property()` and `@property({...})`
Finally, include both forms of the decorator:

```yaml
# ..
rule:
  # ..
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

Let's run the search rule one more time:
```sh
ast-grep scan --rule ../ast-grep/rules/search/find-boolean-lit-property-without-type.yml ../src
```

Notice that the `@property` with `attribute: false` are no longer included in the search results 🎉

We are almost done with our search rule, but we still need to also support a `@property()` that has no options.
To fix this, place an `any` between the `has` and `pattern` entries of `@property($PROPERTY_OPTIONS)` and include an
extra `@property()` pattern:

```yaml
rule:
  # ..
  has:
    any:
      - pattern: |
          @property()
      - pattern: |
          @property($PROPERTY_OPTIONS)
```

This causes our final search rule to be like this:

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

### Always prefer off-the-shelf lint rules

As it turns out, writing this ast-grep rule was technically unnecessary 🤦 — but hopefully it was fun and educational 🤓.

The [`lit-analyzer`](https://github.com/runem/lit-analyzer/tree/master/packages/lit-analyzer) tool already provides a rule that performs this exact check — plus many others!

You can run it directly via the NPM script in `package.json`:

```sh
yarn lint:lit
```

✅ *Conclusion:* Custom ast-grep rules are powerful, but off-the-shelf lint rules like `lit-analyzer` can save time and maintenance effort.

## Preventive Maintenance
⏩ View the next file to continue workshop: [06-preventive-maintenance.md](./06-preventive-maintenance.md)

