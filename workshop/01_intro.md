# Workshop: Taking back control of your code

## Introducing ast-grep and Opengrep

Ever feel like you're losing the battle against _code rot_ and _tech debt_?\
As a codebase grows, keeping it clean, consistent, and maintainable can feel like an impossible task.

### It's time to fight back.
In this workshop, you'll learn to wield the powerful tools **[ast-grep](https://ast-grep.github.io/)** and **[opengrep](https://www.opengrep.dev/)**
(fork of [Semgrep CE](https://github.com/semgrep/semgrep/); formerly known as Semgrep OSS), to change the way you interact with your code.

Both tools are polyglot, supporting either 20+ languages (ast-grep) or 30+ languages (Opengrep).
And can be like a Swiss army knife for your code.

#### What You'll Learn to Do:

- **🔍 Find Anything, Instantly**
  Forget flaky regex! Learn to perform structural searches that understand your code's meaning.
  You'll use code to find code, gaining deep insights into your projects.

- **🔧 Enforce Consistency, Automatically**
  Create custom linting rules to banish inconsistencies and enforce team conventions.
  You can even add auto-fixes to prevent maintenance headaches before they start.

- **✈️ Automate Massive Refactors**
  Effortlessly migrate your entire codebase. Whether it's a simple search-and-replace from the CLI, a complex set of rules in YAML,
  or programmatic changes using ast-grep's [language bindings](https://ast-grep.github.io/guide/api-usage.html#language-bindings),
  you'll learn how to make big changes with confidence.

- **🌐 Speak Every Language**
  Both `ast-grep` and Opengrep are polyglot tools.
  While Opengrep supports over 30 languages, `ast-grep` supports over 20 but also has [custom language support](https://ast-grep.github.io/advanced/custom-language.html)
  that use tree-sitter grammar.

## Pre-requisites for the workshop

First, install the CLI of the most recent ast-grep version following the [Installation](https://ast-grep.github.io/guide/quick-start.html#installation) instructions on their website.

**NOTE**: when installing ast-grep using NPM be sure to do a `npm install` of `@ast-grep/cli` and **not** `ast-grep`
(which is a completely different NPM package last published 8 years ago).

Besides ast-grep make sure to also TODO: pre-requisites for this workshop.
On macOS make sure that `ggrep` (GNU grep) is installed:

```sh
brew install grep
```

And, on Windows make sure that you're using a Unix `sh`-like command like [Git Bash](https://git-scm.com/downloads/win) or `bash` inside the [Windows Subsystem for Linux (WSL)](https://learn.microsoft.com/en-us/windows/wsl/).

TODO: add instructions for installing Node v20, Yarn, Opengrep and Opengrep Playground

## Code base used during the workshop

To use ast-grep and Opengrep on a actual code, this workshop uses a fork from the frontend code base of [Home Assistant](https://www.home-assistant.io/).

This code base was chosen for this workshop since:

- it uses `class` based UI components (using Lit and Web Components) making the code less alien for non-frontenders
- its code base that is quite large, giving you a real experience to what it's like to being using ast-grep and Opengrep in real-life scenarios
- it turns out to contain some interesting inconsistencies that are great candidates for linting rules and massive
  automated refactoring

## Traditional way of searching code

⏩ View the next file to continue workshop: [02_traditional_search.md](./02_traditional_search.md)
