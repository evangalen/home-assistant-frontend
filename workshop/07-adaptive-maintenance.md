# Workshop: Taking back control of your code
(continues where [06-preventive-maintenance.md](./06-preventive-maintenance.md) file ended)

## Adaptive Maintenance
To experience what ast-grep can do for Adaptive Maintenance, I created a shell script to turned back the time to the
previous v2 major version of Lit:
```sh
./prep-code-lab-adaptive-maintenance.sh
```

With Lit v3 the `UpdatingElement` is removed a (finally) replaced with `ReactiveElement`;
see the [Lit 3 upgrade guide](https://lit.dev/docs/releases/upgrade/#removed-updating-element) for more details.

