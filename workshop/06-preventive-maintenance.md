# Workshop: Taking back control of your code
(continues where [05-corrective-maintenance.md](./05-corrective-maintenance.md) file ended)

## Preventive Maintenance
Although creating an ast-grep search rule might seem a bit useless in hindsight, it does give us the opportunity to
improve on the Developer eXperience (DX):
- lit-analyzer is really slow (especially compared with ast-grep)
- lit-analyzer does not offer an autofix for their rules

So, maybe creating our ast-grep search rule wasn't such a bad idea after all 🤔 .

And even-though our search rule allows us to find all the places in the code that causes the bug, we didn't actually
fix the bugs due to `type` property missing from a `@property` decorators / annotations

So let us do some Preventive Maintenance and change our ast-grep search rule into a lint rule.
And to spice things up we also throw in an autofix for the lint rule.

### Creating an ast-grep lint rule
Since we already have an ast-grep search rule, changing it into an ast-grep lint rule is little effort:
- we need to come up with a new `id` and file name for the lint rule to replace the `find-`.. one of the search rule
- we need to specify a `message` that will be displayed whenever the lint rule fails
- we need to specify a `severity` like `error` or `warning`

First copy the `find-boolean-lit-property-without-type.yml` of `ast-grep/rules/search` to `ast-grep/rules/lint` and then
change the file name to `missing-boolean-lit-property-type.yml`.

Now use another `id` in the new file and also specify a `message` and `severity` :

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
```shell
ast-grep scan ../src
```

**NOTE**: through the `sgconfig.yml` file in the root of the repo, ast-grep is configured with an `ruleDirs` array with
a single entry of `ast-grep/rules/lint`. Therefore, using `ast-grep scan` without specifying the `--rule` option will
automatically use all the lint rules from the `ast-grep/rules/lint` directory.

### Creating initial autofix for the lint rule
To be able to introduce an autofix for the lint rule, we need to change the target AST node of our ast-grep rule.

Since we want to apply an autofix on the decorator of a class field, we need to change our rule to target the
`decorator` AST node that's a child of the `public_field_definition` AST node.

And, to keep things simple, we split the rule into two rules using the `---` YAML marker to create a multi-document YAML file.

But, for now let's first focus on the relatively simple part of the lint rule.

Change the contents of the `missing-boolean-lit-property-type.yml` file to be like this:
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

Now, let's run `ast-grep scan` again:
```shell
ast-grep scan ../src
```

Notice that ast-grep now shows a diff with the changes from our autofix.

For now, we'll not apply to autofix changes suggested by ast-grep, because our lint rule is still half complete.

### Changing lint rule into a multi-document YAML file 
To also support an autofix for `property` decorators / annotations that have options, we need to change our YAML file into a multi-document YAML file.

For this we need to add a `---` YAML marker after the first rul and then add an extra lint rule after that.

When also change the target AST node of the second part, the contents of the YAML file would look like this (omitting most of what's before the `---` YAML marker):
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

Now, rerun `ast-grep scan` once again:
```shell
ast-grep scan ../src
```

Notice that for `@property` without options there isn't an autofix suggested by ast-grep.
This is because we will have to add one to our lint rule.

To create a `fix` entry for the second part of our lint rule, we'll need to capture all the existing object pairs
inside the options (object) of the `@property` decorator / annotation.

To capture (zero or more) object pairs, we use a meta-variable with the `$$$` (triple `$`) prefix:
```yaml
pattern: |
  @property({ $$$PAIRS })
```

Besides the `pattern` entry above, we also still need the existing `pattern` with the `@property($PROPERTY_OPTIONS)`
code pattern.

For this we an `and` entry, of the Composite Rules of ast-grep, to combine the two patterns:
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
part of thevYAML file, we need to explicitly exclude:
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

Now that we captured the object pairs from the options (object) of the `@property` decorator / annotation, we can
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

 This makes the contents of the `missing-boolean-lit-property-type.yml` file to be this:

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

Now run our lint rule and notice that our lint rule now also offers autofix suggestions for the second part of our
lint rule:
```shell
ast-grep scan ../src
```

### Applying autofix suggestions for the lint rule
Up until now we never actually applied the autofix suggestions.

To interactively apply autofix-es, ast-grep offers a nice interactive mode enabled using the `--interactive` CLI flag:
```shell
ast-grep scan ../src --interactive
```

Notice that ast-grep shows something like this:
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

Using interactive mode, you can choose to selectively apply autofix suggestions, using [y]es and [n]o keys, or you can go yolo and use the [a]ll key to apply all autofix suggestions at once.

Since life is so short to selectively apply the autofix suggestions, lets use the [a]ll key to apply all autofix suggestions.

Besides using `--interactive`, ast-grep also supports the `--update-all` CLI flag, and its shorthand `-U`, to directly
apply all the autofix suggestions.

### Integration ast-grep into your favorite IDE or editor
TODO:

### lit-analyzer integration in your IDE
TODO:
As we've seen in the "Corrective Maintenance" section of this workshop, TODO:
