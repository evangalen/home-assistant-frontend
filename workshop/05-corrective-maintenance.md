# Workshop: Taking back control of your code
(continues where [04-opengrep-advanced-structural-search.md](./04-opengrep-advanced-structural-search.md) file ended)

## Corrective Maintenance
Now that we got a basic introduction to both ast-grep and Opengrep, it's time to apply ast-grep in a real-world scenario.

Normally, in Corrective Maintenance you typically would manually change code to fix bugs.
But, what if a bug turns out to not be a one-off, but is caused by something you have been doing wrong for a while 🙀.
This then probably makes it much harder to trace back your changes using the Git history.

To learn how ast-grep can be used for Corrective Maintenance in situation like these, we first have to introduce the bugs into the code base of our workshop.

**NOTE**: for this part of the workshop, I also tried making a solution with a YAML rule for Opengrep. But I stumbled on practical issues on how to match a boolean class field without also including the whole class in the match (something I know how to fix with ast-grep). And therefore I decided it was time wise best to focus on using ast-grep for the rest of workshop.

Instead of using a separate branches for the workshop labs, we use a shell script, that internally uses ast-grep, to introduce the bugs 🙈:
```shell
./prep-code-lab-corrective-maintenance.sh
```

The shell script makes changes to a few files to remove the explicit `type: Boolean` of `@property` decorators / annotations from boolean class fields.

This effectively causes bugs in case a field value is specified with a boolean HTML attribute instead of using Lit property binding (using `.` prefix).
For instance, using the `required` HTML attribute **without** a value
(e.g., `<ha-selector-date required></ha-selector-date required>`) causes an `''` (empty) string to be used as value instead of the expected `true` boolean.
### Using ast-grep to search for the bug
To help localize places in the code that can cause the bug, we'll create a search rule for ast-grep using a YAML file.
And to really learn how to create a search rules with ast-grep, we'll build one from the ground up.

In our case we would like to create a search rule that finds all the boolean class fields with a `@property` decorator / annotation that is missing an explicit `type` object property its options object.

First, we'll start with creating a basic search rule using a YAML rule.
Instead of using `rules` folder for all the kinds of ast-grep YAML rules, I personally prefer to differentiate between ast-grep rules by placing the rules of a specific kind in a specific sub-folder.
In case of search rules, instead of placing them inside `./ast-grep/rules`, I prefer to placing them inside a `search`sub-folder
instead.

Now lets create a minimal ast-grep YAML file called `find-boolean-lit-property-without-type.yml` inside the
`./ast-grep/rules/search` folder with the following contents:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/ast-grep/ast-grep/main/schemas/rule.json
id: find-boolean-lit-property-without-type
language: ts

rule:
  # ..
```

Every ast-grep YAML rule should always contain the following:
- (optional) a link to ast-grep YAML schema so that IDEs and editors can provide auto-completion and validation
- a `id`; in this case `find-boolean-lit-property-without-type`
- a `language`; like `ts` for TypeScript
- a `rule` entry

Currently, the `rule` entry is empty, making the rule currently invalid.
To fix that, change our `rule` entry to search for **any** class field:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/ast-grep/ast-grep/main/schemas/rule.json
id: find-boolean-lit-property-without-type
language: ts

rule:
  kind: public_field_definition # matches any class field, even those with JS `#` prefix or TS `private` modifier
```

Using `kind: public_field_definition` the rule will match any class field, even those with JS `#` prefix or TS modifiers
like `private` and `protected`.

**NOTE**: the confusing name `public_field_definition` kind originates from the TypeScript tree sitter grammar used by ast-grep.

Now, let's run our search rules:
```shell
ast-grep scan --rule ../ast-grep/rules/search/find-boolean-lit-property-without-type.yml ../src
```

Notice that a huge response, very quickly, with the class fields of all the TypeScript (.ts) source files inside the `src` folder.
But, we're not interested in all class fields, so let's include only class fields that have an explicitly specified `boolean` type:

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
In this case the `
`public_field_definition` AST node has a child AST node that can addresed using `field: type` .
More info about fields van be found in de [Kind vs Field](https://ast-grep.github.io/advanced/core-concepts.html#kind-vs-field) section of the ast-grep documentation.

Now, lets rerun our search rule:
```shell
ast-grep scan --rule ../ast-grep/rules/search/find-boolean-lit-property-without-type.yml ../src
```

Notice now only class fields with an explicitly specified `boolean` type are returned.
And, besides required fields also optional fields,using `?:`, are included in the search results.

Currently we only search for an explicitly specified `boolean` type.
But, we also need to include class fields with a boolean type that is inferred from its boolean value.
Typically, class fields with an inferred boolean type have an explicitly assigned `true` or `false` value.

To search on class fields with a value of `true` or `false` we need another `has` entry.
```yaml
has: # literal `true` or `false` value
  field: value
  regex: ^(true|false)$
```

But, the `has` YAML is unique and therefor other `has` siblings are not allowed.
Instead, we need to combine the both `has` entries using `any` or `all` from the
[Composite Rules](https://ast-grep.github.io/reference/rule.html#composite-rules) of ast-grep.

In this case we need to wrap our `has` entries inside the `any` array, since our class field can **either** have an
explicit `boolean` type **or** have a `true` or `false` value assigned:

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

Re-run our search rule:
```shell
ast-grep scan --rule ../ast-grep/rules/search/find-boolean-lit-property-without-type.yml ../src
```

Notice the following class field of `src/panels/config/scene/ha-scene-editor.ts` is now included in the results:

```ts
@property({ type: Boolean }) public narrow = false;
```

But also notice that class fields with decorators / annotations other than `@property` are also included in the results, like the class field from the `src/panels/config/scene/ha-scene-editor.ts` file.

TODO: add code of incorrect class field

So, it's about time to change our rule to also include the `@property` decorator / annotation in search rule:

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
```shell
ast-grep scan --rule ../ast-grep/rules/search/find-boolean-lit-property-without-type.yml ../src
```

Notice that the shown `@property` no longer includes decorators / annotations other than `@property` and that only
`@property` are included without a `type` property.

But notice that `@property` with `attribute: false` are still included.

When `attribute: false` is specified for a `@property`, the `type` property is not needed.
So, we need to ensure that the `@property` does **not** have `attribute: false` in its options.

To combine the previous `not: has:` constraint with an extra `not: has:` constrain we can use the `all` Composite Rule to combine this:

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
                {attribute: false }
              selector: pair
```

Let's run the search rule one more time:
```shell
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

Rerun a final time and notice that also class fields with `@property()` are now included in the search results:

```shell
ast-grep scan --rule ../ast-grep/rules/search/find-boolean-lit-property-without-type.yml ../src
```

### Always prefer off-the-shelf lint rules

As it turns out, writing the ast-grep search rules was totally unnecessary 🤦 ...\
hut hopefully you still had lots of fun creating your own custom search rule 🤓

The [lit-analyzer](https://github.com/runem/lit-analyzer/tree/master/packages/lit-analyzer) tool offers an off-the-shelf rule that exactly does the same check 🫣 .\
And it also comes with lots of other useful lint rules for Lit 🙈 .

Let's run lit-analyzer using the "lint:lit" NPM script declared in the `package.json` file:

```shell
yarn lint:lit
```

Notice that Lit Analyzer returns exactly the same results as our ast-grep search rule 🫠
