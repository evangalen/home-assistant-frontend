# Workshop ast-grep: the Swiss army knife of your code base

## Introducing ast-grep

Ever feel like you're losing the battle against _code rot_ and _tech debt_? \
As a codebase grows, keeping it clean, consistent, and maintainable can feel like an impossible task.

### It's time to fight back.

In this workshop, you'll learn to wield **[ast-grep](https://ast-grep.github.io/)**, a powerful tool that will change the way you interact with your code.
Think of it as a Swiss army knife for code transformation, but with superpowers 💪.

#### What You'll Learn to Do:

- **🔍 Find Anything, Instantly**
  Forget flaky regex! Learn to perform structural searches that understand your code's meaning. You'll use code to find code, gaining deep insights into your projects.

- **🔧 Enforce Consistency, Automatically**
  Create custom linting rules to banish inconsistencies and enforce team conventions. You can even add auto-fixes to prevent maintenance headaches before they start.

- **✈️ Automate Massive Refactors**
  Effortlessly migrate your entire codebase. Whether it's a simple search-and-replace from the CLI, a complex set of rules in YAML, or programmatic changes with [language bindings](https://ast-grep.github.io/guide/api-usage.html#language-bindings), you'll learn how to make big changes with confidence.

- **🌐 Speak Every Language**
  `ast-grep` is a true polyglot, supporting over 20 languages out-of-the-box. And if yours isn't on the list? No problem. We'll show you how its [custom language support](https://ast-grep.github.io/advanced/custom-language.html) can handle any language with a tree-sitter grammar.

By the end of this session, you'll be ready to tame any codebase, big or small.

## Pre-requisites for the workshop

First install the CLI of the most recent `ast-grep` version following the [Installation](https://ast-grep.github.io/guide/quick-start.html#installation) instructions on their website.

**NOTE**: when installing using NPM be sure to do a `npm install` of `@ast-grep/cli` and **not** `ast-grep` (which is a completely different NPM package last published 8 years ago).

Besides `ast-grep` make sure to also TODO: pre-requisites for this workshop.
On macOS make sure that `ggrep` (GNU grep) is installed:

```sh
brew install grep
```

And, on Windows make sure that you're using a Unix `sh`-like command like [Git Bash](https://git-scm.com/downloads/win) or `bash` inside the [Windows Subsystem for Linux (WSL)](https://learn.microsoft.com/en-us/windows/wsl/).

## Code base used during the workshop

To use `ast-grep` on actual code, this workshop uses a fork from the frontend code base of [Home Assistant](https://www.home-assistant.io/).

This code base was chosen for this workshop since:

- it uses `class` based UI components (using Lit and Web Components) making the code more readable for non-frontenders
- its code base is quite large scale, giving you a real experience to what it's like to being using `ast-grep` in real-life scenarios
- it turns out to contain some interesting inconsistencies that are great candidates for linting rules and massive
  automated refactoring

## Traditional way of searching code

Before we start using ast-grep, it's also good to experience the traditional way of search code and its pain-points.
For the traditional experience we'll be using Unix `grep`, but alternatively you could also do the searching using your IDE's search features.

To exercise searching code, we'll search for JavaScript `console.log` which is typically unwanted, since it clutters the Console logging in your browser.

🧪 Use the `grep` tool to search for `console.log` on the command-line:

```sh
grep -r 'console.log' src
```

Notice some of the `console.log` calls are placed on multiple lines like in the `src/common/image/extract_color.ts` file.

But, unfortunately only the first line and it opening `(` bracket is shown for the `console.log` calls.
To show multiline calls including all its arguments, we'll have to start using regex.
And to be compatible with modern regex flavors that you find in language like JavaScript, Java, C# and Rust, we'll have to be using the `-P` flag of grep to use the PCRE2 regex flavor.
Unfortunately the `grep` shipped with macOS doesn't support the `-P` flag, and therefore we'll use GNU Grep (`ggrep`) instead; see [Pre-requisites for the workshop](#pre-requisites-for-the-workshop).

To abstract away from chosing between `ggrep` (GNU Grep on macOS) and `grep` (on Linux and Unix shells on Windows),
we created the `regex-search.sh` script that uses `ggrep` in case its installed and otherwise tries to use `grep`.
Furthermore, this script only shows the code that was matched instead of showing the whole line (which grep normally does).

🧪 Let's try again but this time using a simple regular expression (aka regex) and the `regex-search.sh` script:

```sh
./regex-search.sh 'console.log\(.*\)' src
```

Unfortunately things got worse, and the `console.log` using multiple lines are no longer shown at all 😣

As it turns the `.` regex meta-character is **not** including new-lines.
To make the regex also match newlines, we have to slightly change our regex.

🧪 Try again, this time using a slightly less readable regex:

```sh
./regex-search.sh 'console.log\((.|\n)*\)' src/common/image/extract_color.ts
```

**NOTE**: the `regex-search.sh` script uses the `-z` CLI flag of `grep` / `ggrep` so regex can use `\n` to match newlines.

Jikes, the regex matching no longer stops are the closing `)` bracket but instead matches until the last `)` in the file 😱
Also notice that now the complete contents of the file is shown instead of only what is matched 😵‍💫

The incorrect matching of the closing `)` bracket should be easy fixable by adding a `?` after the `*` regex meta-character to use non-greedy regex matching.

🧪 Try again, but this time using non-gready regex matching:

```sh
./regex-search.sh 'console.log\((.|\n)*?\)' src/common/image/extract_color.ts
```

Looks like grep now matches the whole `console.log(`..`)` call 😄

🧪 Now, let's execute the regex again but on the whole `src` folder:

```sh
./regex-search.sh 'console.log\((.|\n)*?\)' src
```

Turns out that using non-gready matching did **not** complety fix our closing `)` bracket problem.  
Have a look at the matches of the `src/common/string/filter/filter.ts` file and notice the matches ends too early using the closing bracket of the nested `printTable(`..`)` call.

## Introducing structural search with ast-grep

As shown in the previous section of this workshop, searching code constructs like a function call can be troublesome using literal text and especially with regex.

This is were the tool `ast-grep` comes into play.
The `ast-grep` tool parses your code into an Abstract Syntax Tree (AST), similar to what is done by a compiler, linting tools (e.g. ESLint, CheckStyle, Ktlint) and code migration tools (jscodeshift, OpenRewrite) do.

But, unlike most linting tools and code migration tools, `ast-grep` does not neccesarily require you to have to in-depth knowledge about your source code in represented as an AST tree.

Instead we can simply use code to find code. That is called structural search, and it offers a less error prone alternative to traditional textual search that works no matter how your code is formatted (e.g. code divided on multiple lines) and that will always use the correct closing bracket.

## Searching code using structural search

Lets put `ast-grep` to the test and try it's structural search capabilities to search for `console.log(`..`)` calls in our code base.

First make sure the most recent CLI version of `ast-grep` is installed as explained in the [Installation](https://ast-grep.github.io/guide/quick-start.html#installation) instructions on their website.

**NOTE**: when installing `ast-grep` using NPM, make sure to do a `npm install` of `@ast-grep/cli` and **not** `ast-grep` (a completely different NPM package last published 8 years ago).

🧪 Lets use `ast-grep` to search for `console.log` calls:

```sh
ast-grep --pattern 'console.log()'
```

Notice that `ast-grep` only found `console.log` calls **without** arguments.

🧪 Now try the following:

```sh
ast-grep --pattern 'console.log($ARG)'
```

The search results now only includes `console.log` calls with **exactly** one argument.
But, notice that in the `src/common/string/filter/filter.ts` file the second `)` is now actually included in the search matches. Regex eat your heart out!

Additionally, the output of `ast-grep --pattern` is much nicer than `regex-search.sh` since it offer more context why showing whole line with
the matches highlighted in red.

TODO: point out the console.log in de callback function.

🧪 Now let's try the find all `console.log` calls with two arguments:

```sh
ast-grep --pattern 'console.log($ARG, $ARG)'
```

Somehow our search for `console.log` calls with two arguments does **not** seem to work 😕

### Introducing meta-variables

To understand what's causing this we must first understand what's a meta-variables are `ast-grep` and how they work.
As you might have guessed, the `$ARG` in our search pattern are meta-variables.

To distinguish meta-variables from actual code syntax in the search pattern, every meta-variable must follow distinct naming rules:

- every meta-variable must start with one, two or three expando character(s)
- for `$` is used as the expando character for most languages
- after the expando character only upper case letters (`A-Z`), underscores (`_`) or digits (`1-9`) are allowed

### Matching dynamic content

Using code to find code isn't that usefull without the ability to match dynamic world.

Seaching you code base for `console.log` calls for the two explicit arguments `"hello"` and `"world"` is not that usefull, but searching `console.log` with ...

### Capturing meta-variables

Differ

Each meta-variable is like a wildcard expression than can match a single AST node, when or zero

To distinguish meta-variables from the actual code you wan

A meta-variable like `$ARG` is like a wildcard expression that can match any **single** AST node.

Using a code snippet as a pattern to search for, is called structural search.

It parses your source code into a Abstract / Concrete Syntax Tree (AST / CST), similar to what a compiler does for languages like TypeScript, Java and C#.
After parsing your source code, ast-grep then uses the created Concrete Syntax Tree to do its searching.

**NOTE**: although it's name might make you think otherwise, ast-grep is actually using a CST (superset of an AST) under the hood.

Due to a AST / CST for searching, ast-grep has the following advantages

-
- it's aware of the syntax that its parsed
-

And ast-grep then searching through your code base, it actually searches through a Syntax Tree as opposed to search the text of your code.

By searching

Similar to a compilers / transpiler and linting tools for programming
It the Abstract Syntax Tree (AST), that's like the DOM but for source code, to do its searching.  
And, also it allows you to search on patterns that are declared in the syntax of your programming language.  
Which effectively allows you code to search code :grin:

Our closing brancket problem is a thing of the past when searching code using the Abstract Syntax Tree (AST).
