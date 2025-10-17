# Workshop: Taking back control of your code

(continues where [04-opengrep-advanced-structural-search.md](./04-opengrep-advanced-structural-search.md) file ended)

## Corrective Maintenance
Now that we got a basic introduction to both ast-grep and Opengrep, it's time to apply them to a real-world scenario.

Normally, Corrective Maintenance is done by manually fixing code containing bugs.
What if a bug isn't a one-off, but instead is caused by something you have been doing wrong for a while.
Making if much harding to simply trace back your changes using the Git history.

To learn how ast-grep can be used for Corrective Maintenance, we'll first have to introduce the bug into the code base
that we use for this workshop.
And instead of creating a separate branch for this, we'll use ast-grep to introduce the bug 🙈:
```shell
./prep-code-lab-corrective-maintenance.sh
```

The executed `prep-code-lab-corrective-maintenance.sh` shell script removes explicit `type: Boolean` from the options
of a `@property` decorator / annotation of boolean class fields of a few source files.

This causes the bug when the field value is specified using a (boolean) attribute in HTML.
For instance, using `required` with **no attribute value** for `ha-selector-date`
(e.g., `<ha-selector-date required></ha-selector-date required>`) causes an `''` (empty) string to be used as value
instead of the expected `true` boolean.

### Using ast-grep to search for the bug
To help localize the placed in the code that causes the bug, we could use create an ast-grep search rule to find them.
And to learn how to create a search rule with ast-grep, we'll build it one from the ground up.

In our case we would like to create a search rule that finds all the boolean class fields that have a
`@property` decorator / annotation but are missing an explicit `type` property in the options of the `@property`.

First, we'll start by creating a basic search rule.
In this case, we'll be creating a YAML rule, as opposed to using `--pattern` on the command line, since it allows us to
create much more complex rules.

Instead of using `rules` folder for all the kinds of ast-grep YAML rules, I personally prefer to differentiate between
the kind of ast-grep rules by placing all rules of a specific kind in a kind specific sub-folder.
In case of search rules, instead of placing them inside the `./ast-grep/rules` folder, I prefer to place them inside the
`./ast-grep/rules/search` folder instead.

Now create a minimal ast-grep YAML file called `find-boolean-lit-property-without-type.yml` inside the
`./ast-grep/rules/search` folder with the following contents:
```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/ast-grep/ast-grep/main/schemas/rule.json
id: find-boolean-lit-property-without-type
language: ts

rule:
  # ..
``` 

Every ast-grep YAML rule should always contain the following:
 - a link to the ast-grep YAML schema allowing IDEs and editors to provide auto-completion and validation
 - a `id`; in this case `find-boolean-lit-property-without-type`
 - a `language`; in this case `ts` since we are using TypeScript
 - a `rule` entry

Currently, the `rule` entry is empty, which also makes our rule invalid.
So, let's change our `rule` entry to search for **any** class field:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/ast-grep/ast-grep/main/schemas/rule.json
id: find-boolean-lit-property-without-type
language: ts

rule:
  kind: public_field_definition # matches any class field, even those with JS `#` prefix or TS `private` modifier
```

Using `kind: public_field_definition` the rule will match any class field, even those with JS `#` prefix or TS modifiers
like `private`.

**NOTE**: the confusing name `public_field_definition` kind comes from in the tree sitter grammar for TypeScript.

Now, let's run our search rules:
```shell
ast-grep scan --rule ../ast-grep/rules/search/find-boolean-lit-property-without-type.yml ../src
```

Notice that this returns a huge response will class fields from all the (TypeScript) source files from the 'src' folder.
But we're not interested in all class fields, so let's include only class fields that have an explicitly specified
`boolean` type:

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

**NOTE**: the `has` entry, and also `inside`, `following` and `precedes`, is part of the
[Relational Rules](https://ast-grep.github.io/guide/rule-config/relational-rule.html) of ast-grep.

Now, rerun our search rules:
```shell
ast-grep scan --rule ../ast-grep/rules/search/find-boolean-lit-property-without-type.yml ../src
```

Notice now only class fields with an explicitly specified `boolean` type are returned.
Also notice that besides required fields / properties als optional fields / properties, using `?:` in its type
annotation, are included in the search results. 

But, only search for an explicitly specified `boolean` type is not enough.
We also need to include class fields that have a boolean type inferred from a boolean value.
Typically, class fields with an inferred boolean type use an explicit `true` or `false` (default) value that's assigned
with `=` to class field.

To search on class fields with value of `true` or `false` we'll also need to use a `has` entry.
``yaml
has: # literal `true` or `false` value
  field: value
  regex: ^(true|false)$
``

But, the `has` YAML is unique and therefor does not allow any siblings.
Therefore, we'll need to combine new `has` entry with the existing `has` entry either `any` or `all` of the
[Relational Rules](https://ast-grep.github.io/guide/rule-config/relational-rule.html) of ast-grep.

In this case we need to wrap our `has` entries inside the `any` array, since our class field can **either** have an
explicitly specified `boolean` type **or** have a `true` / `false` value:

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

Notice the following class field of `src/panels/config/scene/ha-scene-editor.ts` in now included in the results:
```ts
@property({ type: Boolean }) public narrow = false;
```

Also notice that class fields with decorators / annotations other than `@property` are still included in the results,
like the class field from the `src/panels/config/scene/ha-scene-editor.ts` file.

So, it's about time that we also include the `@property` decorator / annotation in our search rule:

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

Before we'll rerun our search rule, if probably best to do some explaining.

Let's start with the part containing of the `@property($PROPERTY_OPTIONS)` pattern: 
```yaml
rule:
  # ..
  has:
    pattern: |
      @property($PROPERTY_OPTIONS)
```

There are various restrictions when using plain values in YAML.
Like the fact that a plain value cannot start with a reserved character like `$`.

To work around, and other restrictions to plain values in YAML, we'll instead use `|` to create a literal block (see
[Where X=YAML](https://learnxinyminutes.com/yaml/) on [Learn X in Y minutes](https://learnxinyminutes.com/) for more
information).

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

By placing a `constraints` entry next to our `rule` entry, we can apply constraints on one of more meta-variables.
In this case we specify the following constraints that `PROPERTY_OPTIONS`:
 - must be an object type
 - must have a `type` property with a `Boolean` value

Last but not least, notice that we're not directly using the `pattern` entry to specify our code pattern, but instead
we use a [Pattern Object](https://ast-grep.github.io/guide/rule-config/atomic-rule.html#pattern-object) to specify more
context for our code pattern and to additionally specify a `selector` to only keep the `pair` node to the specified code
pattern.
This is because when directly specifying `type: Boolean` as a `pattern` entry (using a YAML code block), the code
pattern will be parsed as a (JavaScript) Labeled Statement; see the following ast-grep Playground for a demonstration:
https://ast-grep.github.io/playground.html#eyJtb2RlIjoiQ29uZmlnIiwibGFuZyI6InR5cGVzY3JpcHQiLCJxdWVyeSI6IkNvbnN0cnVjdG9yPCQkJF8+IiwicmV3cml0ZSI6IiIsInN0cmljdG5lc3MiOiJhc3QiLCJzZWxlY3RvciI6IiIsImNvbmZpZyI6IiMgeWFtbC1sYW5ndWFnZS1zZXJ2ZXI6ICRzY2hlbWE9aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL2FzdC1ncmVwL2FzdC1ncmVwL21haW4vc2NoZW1hcy9ydWxlLmpzb25cblxuaWQ6IGZpbmQtYm9vbGVhbi1saXQtcHJvcGVydHktd2l0aG91dC10eXBlXG5sYW5ndWFnZTogdHNcbnJ1bGU6XG4gIHBhdHRlcm46IHxcbiAgICB0eXBlOiBCb29sZWFuXG4iLCJzb3VyY2UiOiIvLyBMYWJlbGVkIHN0YXRlbWVudCwgd2l0aCBgdHlwZWAgbGFiZWwgYW5kIGBCb29sZWFuYCB2YWx1ZTtcbi8vIHNlZSBhbHNvOiBodHRwczovL2RldmVsb3Blci5tb3ppbGxhLm9yZy9lbi1VUy9kb2NzL1dlYi9KYXZhU2NyaXB0L1JlZmVyZW5jZS9TdGF0ZW1lbnRzL2xhYmVsXG50eXBlOiBCb29sZWFuXG5cbmNsYXNzIENscyB7XG4gIEBwcm9wZXJ0eSh7IHR5cGU6IEJvb2xlYW4gfSkgcHVibGljIG5hcnJvdyA9IGZhbHNlO1xufVxuIn0=

Now let's rerun out search rule:
```shell
ast-grep scan --rule ../ast-grep/rules/search/find-boolean-lit-property-without-type.yml ../src
```

Notice that the shown `@property` no longer include decorators / annotations other than `@property` and that only
`@property` are included without a `type` property.

But notice that `@property` with `attribute: false` are included.

When `attribute: false` is specified for a `@property`, then a `type` property is not required.
So, we need to ensure that the `@property` does **not** have `attribute: false` in its options.

To combine the previous `not: has:` constraint with an extra `not: has:` constrain we can use the `all` Rational Rule
to combine this:
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

Let's run the search rule a final time:
```shell
ast-grep scan --rule ../ast-grep/rules/search/find-boolean-lit-property-without-type.yml ../src
```

Notice that the `@property` with `attribute: false` are no longer included in the search results 🎉

We are almost done with our search rule, but we still need to also support `@property()` that has no options. 
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
As it turns out, writing the ast-grep search rules is totally unnecessary 🤦 ...\
although it (hopefully) was still lots of fun to create our own search rule 🤓

The [lit-analyzer](https://github.com/runem/lit-analyzer/tree/master/packages/lit-analyzer) tool offers an off-the-shelf
rule that exactly does the same check 🫣 .\
And it also comes with lots of other useful lint rules 🙈 .

Let's run lit-analyzer via the "lint:lit" NPM script defined in the `package.json` file:
```shell
npm run lint:lit
```

Notice that Lit Analyzer returns exactly the same results as our ast-grep search rule 🫠
