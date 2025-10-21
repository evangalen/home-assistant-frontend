# Workshop: Taking back control of your code
(continues where [05-corrective-maintenance.md](./05-corrective-maintenance.md) file ended)

## Preventive Maintenance
Although creating an ast-grep search rule might seem a bit redundant in hindsight, it gives us an excellent opportunity to improve the **Developer Experience (DX)**:
- lit-analyzer is relatively slow (especially compared with ast-grep)
- lit-analyzer doesn’t offer **autofix** support for its rules

So, maybe building our own ast-grep rule wasn’t such a bad idea after all 🤔

Even though our search rule helps us **find** all locations missing a `type` property inside a `@property` decorator, it doesn’t yet **fix** them automatically.  
Let’s perform some **Preventive Maintenance** and convert our search rule into a **lint rule** — complete with autofix support.

### Creating an ast-grep lint rule
Since we already have a search rule, turning it into a lint rule takes only a few steps:
- Use a new `id` and file name (replacing the `find-`.. prefix)
- Add a `message` that describes what went wrong
- Add a `severity` (e.g., `error` or `warning`)

First, copy the existing search rule:
```sh
cp ast-grep/rules/search/find-boolean-lit-property-without-type.yml \
   ast-grep/rules/lint/missing-boolean-lit-property-type.yml
```

Then edit the new file:
```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/ast-grep/ast-grep/main/schemas/rule.json
id: missing-boolean-lit-property-type
language: ts
severity: error
message: "Missing `type` property inside options of `@property` decorator of boolean class field."

rule:
  # ..
```

Let's run `ast-grep scan`, but this time **without** specifying the `--rule` option.
```sh
ast-grep scan ../src
```

💡 **NOTE** The `sgconfig.yml` in the project root contains a `ruleDirs` entry pointing to `ast-grep/rules/lint`,
so `ast-grep scan` automatically includes all lint rules when no `--rule` flag is given.

✅ *Conclusion:* We’ve defined the basic structure for our lint rule — next we’ll make it actually detect and fix issues.


### Adding an autofix
To make our lint rule fixable, we need to tell ast-grep which AST node should be replaced.
Therefor we'll change our rule to target the `decorator` node (the `@property(...)` part) inside a `public_field_definition`
instead of targetting the `public_field_definition` AST node

For clarity, we’ll split the YAML into two rules using the `---` document separator.
Let’s start with the simpler first rule that replaces the earlier copy rule:

```yaml
id: missing-boolean-lit-property-type
language: ts
severity: error
message: "Missing `type` property inside options of `@property` decorator of boolean class field."

rule:
  any:
    - pattern: "@property()"
    - pattern: "@property({})"
  inside:
    kind: public_field_definition # matches any class field, even those with JS `#` prefix or TS `private` modifier
    any:
      - has: # `: boolean` type annotation
          field: type
          has: { kind: predefined_type, regex: ^boolean$ }
      - has: # literal `true` or `false` value
          field: value
          regex: ^(true|false)$

fix:
  template: "@property({ type: Boolean })"
```

Run the command again:
```sh
ast-grep scan ../src
```

You’ll see a **diff preview** showing how ast-grep would autofix the code.
We’ll enhance it further before applying those fixes.

✅ *Conclusion:* The rule now identifies `@property()` and `@property({})` decorators and suggests autofixing them.


### Supporting more complex decorators
To also support decorators **with existing options**, we’ll make the rule multi-document YAML by adding another block below the first:

```yaml
id: missing-boolean-lit-property-type
severity: error
message: "Missing `type` property inside options of `@property` decorator of boolean class field."
language: ts
rule:
  # ..

---

id: missing-boolean-lit-property-type
severity: error
message: "Missing `type` property inside options of `@property` decorator of boolean class field."
language: ts
rule:
  pattern: |
    @property($PROPERTY_OPTIONS)
  inside:
    kind: public_field_definition # matches any class field, even those with JS `#` prefix or TS `private` modifier
    any:
      - has: # `: boolean` type annotation
          field: type
          has: { kind: predefined_type, regex: ^boolean$ }
      - has: # literal `true` or `false` value
          field: value
          regex: ^(true|false)$

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

Run it again:
```sh
ast-grep scan ../src
```

✅ *Conclusion:* This second rule detects missing `type: Boolean` inside decorators that already have other options.

### Capturing object pairs for autofix
Now we’ll capture all key-value pairs inside the decorator options using a meta-variable: `$$$PAIRS`.
```yaml
pattern: |
  @property({ $$$PAIRS })
```

We’ll combine it with the original `@property($PROPERTY_OPTIONS)` pattern using the `all` composite rule:

```yaml
# ..
rule:
  all:
    - pattern: |
        @property($PROPERTY_OPTIONS)
    - pattern: |
        @property({ $$$PAIRS })
  inside:
    # ..
```

To prevent that the second part of our lint rule also matches `@property({})`, which is already matched by the first
part of YAML file, we need to explicitly exclude it:
```yaml
# ..
rule:
  all:
    - pattern: |
        @property($PROPERTY_OPTIONS)
    - pattern: |
        @property({ $$$PAIRS })
    - not: # exclude `@property` with an empty options object, since `$$$PAIRS` can also be empty
        pattern: |
          @property({})        
  inside:
    # ..
```

Now we can build our final autofix for this second rule:
create a `fix` entry for the **second part** of our lint rule:
```yaml
# ..
rule:
  all:
    - pattern: |
        @property($PROPERTY_OPTIONS)
    - pattern: |
        @property({ $$$PAIRS })
    - not: # exclude `@property` with an empty options object, since `$$$PAIRS` can also be empty
        pattern: |
          @property({})        
  inside:
  # ..

constraints:
  # ..

fix:
  template: "@property({ type: Boolean, $$$PAIRS })"
```

✅ *Conclusion:* The autofix now merges `type: Boolean` with any existing key-value pairs inside the decorator options.


### 🧩 Final combined lint rule
```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/ast-grep/ast-grep/main/schemas/rule.json
id: missing-boolean-lit-property-type
language: ts
severity: error
message: "Missing `type` property inside options of `@property` decorator of boolean class field."
rule:
  any:
    - pattern: "@property()"
    - pattern: "@property({})"
  inside:
    kind: public_field_definition # matches any class field, even those with JS `#` prefix or TS `private` modifier
    any:
      - has: # `: boolean` type annotation
          field: type
          has: { kind: predefined_type, regex: ^boolean$ }
      - has: # literal `true` or `false` value
          field: value
          regex: ^(true|false)$

fix:
  template: "@property({ type: Boolean })"

---

id: missing-boolean-lit-property-type
severity: error
message: "Missing `type` property inside options of `@property` decorator of boolean class field."
language: ts
rule:
  all:
    - pattern: |
        @property($PROPERTY_OPTIONS)
    - pattern: |
        @property({ $$$PAIRS })
    - not: # exclude `@property` with an empty options object, since `$$$PAIRS` can also be empty
        pattern: |
          @property({})
  inside:
    kind: public_field_definition # matches any class field, even those with JS `#` prefix or TS `private` modifier
    any:
      - has: # `: boolean` type annotation
          field: type
          has: { kind: predefined_type, regex: ^boolean$ }
      - has: # literal `true` or `false` value
          field: value
          regex: ^(true|false)$

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

fix:
  template: "@property({ type: Boolean, $$$PAIRS })"
```

✅ *Conclusion:* This final lint rule detects missing `type: Boolean` in all decorator variants and auto-fixes them safely.

### Applying autofix suggestions
We can now **apply** the autofixes interactively:
```sh
ast-grep scan ../src --interactive
```

Example output:

```
../src/state-display/state-display.ts
error[missing-boolean-lit-property-type]: Missing `type` property inside options of `@property` decorator of boolean class field.
@@ -60,7 +60,7 @@
61 61│ 
62 62│   @property({ attribute: false }) public name?: string;
63 63│ 
64   │-  @property({ attribute: "dash-unavailable" })
   64│+  @property({ type: Boolean, attribute: "dash-unavailable" })
65 65│   public dashUnavailable?: boolean;
66 66│ 
67 67│   protected createRenderRoot() {
Accept? [y]es/[↵], [n]o, [a]ll, [q]uit, [e]dit
```

💡 **NOTE**
You can press **`a`** to apply all autofixes at once, or run:

```sh
ast-grep scan ../src -U
```

(`-U` is shorthand for `--update-all`).

✅ *Conclusion:* The autofix workflow makes ast-grep not just a search tool, but a powerful code transformation engine.

### 🔧 Integrating ast-grep
To integrate ast-grep in your favorite IDE or editor, you can use its LSP (Language Server Protocol) support.

For JetBrains IDE, you can use the LSP4IJ plugin (from RedHat) to integrate any LSP servers into JetBrains IDEs
And for VSCode there is an official extension available.

For more information also see the [Editor Integration](https://ast-grep.github.io/guide/tools/editors.html) documentation
of the ast-grep website.

### 💡 Integrating lit-analyzer
To integrate lit-analyzer its best to configure the `ts-lit-plugin` TypeScript plugin inside your TSConfig file.

For our workshop you could add the following in the "plugins" section of the "compilerOptions" in the `tsconfig.json` file:
```json
    "plugins": [
      {
        "name": "ts-lit-plugin",
        "strict": true,
        "rules": {
          "no-incompatible-type-binding": "off",
          "no-unknown-property": "off",
          "no-unknown-attribute": "off",
          "no-invalid-css": "off",
          "no-unknown-tag-name": "off",
        },
      }
    ],
```

When we ran `./prep-code-lab-corrective-maintenance.sh` to introduce the bugs to of the "Corrective Maintenance" and
"Preventive Maintenance" part of the workshop, we've also removed the `ts-lit-plugin` from the `tsconfig.json` file 👿

This was done so the errors of lit-analyzer would not confuse you with the errors of ast-grep itself.

### Summary
* We converted our ast-grep search rule into a fully functional lint rule.
* We added **autofix** support for both empty and configured `@property` decorators.
* We learned to use `any`, `all`, and `and` composite rules.
* We practiced using multi-document YAML for complex linting cases.
* We explored interactive and batch autofix workflows.

✅ *Key takeaway:* ast-grep allows you not only to detect but also to **prevent** recurring bugs — an essential part of preventive maintenance.

## Adaptive Maintenance
⏩ View the next file to continue workshop: [07-adaptive-maintenance.md](./07-adaptive-maintenance.md)
