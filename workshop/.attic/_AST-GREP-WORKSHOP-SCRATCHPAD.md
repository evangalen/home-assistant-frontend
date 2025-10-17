```shell
ast-grep --pattern '$A && $A.$B' --rewrite '$A?.$B' --update-all src/dialogs/voice-assistant-setup/cloud/cloud-step-signin.ts
```

```shell
ast-grep --pattern '$A?.$B && $A.$B.$C' --rewrite '$A?.$B?.$C' src/dialogs/voice-assistant-setup/cloud/cloud-step-signin.ts
```

```shell
ast-grep scan --inline-rules '
id: rewrite-simple-optional-chaining
language: ts
rule:
  pattern: $A && $A.$B
fix: $A?.$B
---
id: rewrite-nested-optional-chaining
language: ts
rule:
  pattern: $A?.$B && $A.$B.$C
fix: $A?.$B?.$C
' src/dialogs/voice-assistant-setup/cloud/cloud-step-signin.ts
```

```shell
ast-grep -p '$STRING_OR_ARRAY.indexOf($VALUE) !== -1' -r '$STRING_OR_ARRAY.includes($VALUE)' -i
```

```shell
ast-grep -p '$ARRAY[$ARRAY.length - 1]' -r '$ARRAY.at(-1)' -i
```

OPM: leid tot TS errors doordat `.at` een `undefined` kan teruggeven

```shell
ast-grep scan --inline-rules '
id: rewrite-const-original-location
language: ts
rule:
  pattern:
    context: $A && $A !== ""
    strictness: template
' src

```
