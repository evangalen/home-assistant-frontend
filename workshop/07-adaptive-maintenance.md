# Workshop: Taking back control of your code
(continues where [06-preventive-maintenance.md](./06-preventive-maintenance.md) file ended)

## Adaptive Maintenance
To experience what ast-grep can do for Adaptive Maintenance, I created a shell script to turned back the time to the
previous v2 major version of Lit:
```sh
./prep-code-lab-adaptive-maintenance.sh
```

With Lit v3 the `UpdatingElement` is removed and is (finally) replaced with `ReactiveElement`;
see [Lit 3 upgrade guide](https://lit.dev/docs/releases/upgrade/#removed-updating-element) for more details.

### Searching for usages of `UpdatingElement`
As it turns out, ast-grep is quite effective in searching for usages of `UpdatingElement`:
```sh
ast-grep --pattern 'UpdatingElement' --lang ts ../src
```

The search results include:
* the import statements of `UpdatingElement`
* the usage of `extends UpdatingElement` for classes
* the usages of `instanceof UpdatingElement`
* the usages of `InstanceType<typeof UpdatingElement>`

### Replacing `InstanceType<typeof UpdatingElement>` usages
All the usages of `UpdatingElement` can be replaced using `--rewrite` option of ast-grep.

But in case of `InstanceType<typeof UpdatingElement>` that needs to be replaced to `ReactiveElement`, we need to add
more context to the search pattern and use the `--selectors` option to only use a part of the search pattern:
```sh
ast-grep --pattern 'type _ = InstanceType<typeof UpdatingElement>' --selector generic_type --rewrite 'ReactiveElement' --lang ts --interactive ../src
```

Choose `a` to accept all the proposed changes.

### Replacing the remaining usages of `UpdatingElement`
Now replace the remaining usages of `UpdatingElement` to `ReactiveElement`:
```sh
ast-grep --pattern 'UpdatingElement' --rewrite 'ReactiveElement' --lang ts --interactive ../src
```

Choose `a` to accept all the proposed changes.

### Migrated Lit version back to v3
To migrate back the Lit version back to v3 execute the following script:
```sh
./rewrite-lit-deps-to-v3.sh
```

### Check you Git changes for `src`
Have a look at your Git changes of the `src` directory and notice that effectively all the changes that
"turned back the time" to Lit v2 are effectively reverted.

The only remaining differences are those of `import type` statements and formatting changes

### (Way) More advanced Adaptive Maintenance
This part of the workshop is really simple, especially when compared with corrective maintenance and preventive
maintenance parts of this workshop.

But that does not mean that all Adaptive Maintenance is as easy as this.

Sometimes you will have to make much more complex changes to your code.
And might even that a code migration is too complex to be done using a YAML rule.

Luckily, ast-grep also offers [Node, Python and Rust APIs](https://ast-grep.github.io/reference/api.html).

### Always prefer using off-the-shelf code migration tools
As with Lint Rules its always better to use off-the-shelf code migration tools.

For example, for JavaScript / TypeScript there are the so-called codemods of [codemod.io](https://app.codemod.com/registry).
And for Java and Kotlin (and others) there are the [OpenRewrite Recipes](https://docs.openrewrite.org/recipes).

💡 **NOTE** codemod.io nowadays uses ast-grep under the hood, and it offers an on-line Studio that's similar to the
ast-grep Playground, but also offers additional features like an AI to help you writing the ast-grep rules.

## Perfective Maintenance
⏩ View the next file to continue workshop: [08-perfective-maintenance.md](./08-perfective-maintenance.md)
