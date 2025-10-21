# Workshop: Taking back control of your code
(continues where [03-ast-grep-intro-structural-search.md](./03-ast-grep-intro-structural-search.md) file ended)

## Advanced Structural Search using Opengrep
Although structural search in `ast-grep` is very powerful, it can sometimes behave in unexpected ways because of its strict AST matching rules.  
This strictness might not always be what we want when searching for certain code patterns.

Luckily, structured search isn't unique to `ast-grep` and is also available in other tools like [Opengrep](https://semgrep.dev/docs/writing-rules/pattern-syntax#structural-search) (fork from Semgrep CE).

To illustrate why using structural search with ast-grep can be problematic, let's search for `new Set()` :
```sh
ast-grep --pattern 'new Set()' --lang ts ../src
```

Now, do the same structural search with Opengrep:
```sh
opengrep --pattern 'new Set()' --lang ts ../src
```

Notice that the results of `Opengrep` also include `new Set<...>()` calls (using explicit type arguments).

✅ *Conclusion:* Opengrep uses a “less-is-more” approach — it tries to include as many applicable results as possible, unlike ast-grep’s stricter behavior.

Given its Static Application Security Testing (SAST) origins, Opengrep (and Semgrep) aims to surface **all relevant patterns**, even if that means broader matches.
For exploratory or perfective code analysis, this can be very helpful — even if it’s slower.

## Searching for functions with one argument
Let’s search for all functions that have exactly one argument:

```sh
opengrep --pattern 'function $FN($ARG)' --lang ts ../src
```

You’ll get roughly **4333 code findings**, and it might take a while.

The results include:
* `function` declarations (e.g., `export function getAllCombinations<T>(arr: T[])`)
* class methods (e.g., `willUpdate(changedProps: PropertyValues)`)
* property setters (e.g., `public set value(value: string)`)
* constructors (e.g., `constructor(auth?: Auth)`)

✅ *Conclusion:* Opengrep automatically detects a broad range of function-related constructs, not just standalone functions.

## When patterns are missed
Although structural search in Opengrep covers many syntax variations, it can still miss certain forms.
For example, in JavaScript or TypeScript, functions defined via arrow expressions (`const fn = (...) => { ... }`) might not appear in the results.

🧪 Let’s demonstrate this by searching a specific file:
```sh
opengrep --pattern 'function $FN($ARG)' --lang ts ../src/cast/cast_manager.ts
```

And now search `const $FN = (...)` in the `src/cast/cast_manager.ts` file:
```shell
opengrep --pattern 'const $FN = function($ARG) { ... }' --lang ts ../src/cast/cast_manager.ts
```

Notice that `const getCastManager = (auth?: Auth) => { ... }` now appears in the results.

✅ *Conclusion:* Opengrep’s default patterns may miss arrow-function variations; supplementing with broader patterns solves this.

**NOTE**: this example is very JavaScript / TypeScript specific and might not be indicative for incomplete search
results when Opengrep is used for other languages.

## Opengrep Playground
Like ast-grep, Opengrep also includes a Playground — but unlike ast-grep’s web version, it must be installed locally.

### 1. Installation
Install the latest Opengrep Playground following the instructions in the README of its GitHub repository:
👉 [https://github.com/opengrep/opengrep-playground](https://github.com/opengrep/opengrep-playground)

### 2. Launch the Playground
After installation, start it:
![](04-opengrep-advanced-structural-search/opengrep-playground-empty.png)

### 3. Add code to test
Copy the contents of `src/cast/cast_manager.ts` and paste them into the **Code to Test** panel.

### 4. Define a rule
Paste the following YAML rule into the **Rule** section:
```yaml
rules:
  - id: search-all-functions
    languages:
      - typescript
    message: ""
    pattern: function $FN($ARG)
    severity: INFO
```

💡 **NOTE** The `message` field is required by Opengrep / Semgrep, but since we’re only searching, an empty string is fine.

### 5. Run the rule
Press **Evaluate** in the top-right corner.
The results will appear in the **Results** section.

💡 **NOTE** The Opengrep Playground is less mature than ast-grep’s online version.
You may see `Something went wrong` popups for invalid rules, or it might freeze — simply restart it if needed.

✅ *Conclusion:* The Playground makes it easier to visually verify your rule logic and results.

## Combining multiple patterns
Let’s modify our rule so it matches both `function` declarations and `const` function assignments.
We’ll use the `pattern-either` syntax to define multiple patterns in one rule:

```yaml
rules:
  - id: search-all-functions
    languages:
      - typescript
    message: ""
    pattern-either:
      - pattern: function $FN($ARG)
      - pattern: const $FN = function($ARG) { ... }
    severity: INFO
```

Now press **Evaluate** again — the `const getCastManager = (auth?: Auth) => { ... }` function will now appear in the results.

✅ *Conclusion:* Using `pattern-either` ensures your rule covers multiple syntactic variants without duplicating logic.

## Summary
* Opengrep’s structural search is broader and more inclusive than ast-grep’s.
* It’s ideal for discovering diverse syntax structures across large codebases.
* Use the Playground to test and refine your rules.
* Combine patterns with `pattern-either` for more complete searches.

## Corrective Maintenance
⏩ View the next file to continue workshop: [05-corrective-maintenance.md](./05-corrective-maintenance.md)
