# Workshop: Taking back control of your code
(continues where [01_intro.md](01-intro.md) file ended)

## Traditional way of searching code

Before we start using ast-grep, it's also good to experience the traditional way of searching code and its pain-points.\
For the traditional experience we'll be using Unix `grep`.

💡 **NOTE** Alternatively, you could also do the `grep` / `./regex-search.sh` exercises below using your IDE's search features.

To exercise searching code, we'll search for JavaScript `console.log` which is typically undesired,
since it clutters up the JavaScript console with logging in your browser.

🧪 Use the `grep` tool to search for `console.log` on the command-line:
```sh
grep -r 'console.log' ../src
```

💡 **NOTE** during the workshop the current working directory in your command-line is expected to be `./workshop`.
That's why we use `../src` (as opposed to `src`) at the end of every `grep`, `regex-search.sh`, `ast-grep` and `opengrep` command in the workshop material.

Notice that some of the `console.log` calls are placed on multiple lines like in the `src/common/image/extract_color.ts` file.

But, unfortunately only the first line and its opening `(` bracket is shown for the `console.log` calls.
To show multiline calls including all its arguments, we'll have to start using regex.
And to be compatible with modern regex flavors that you find in language like JavaScript, Java, C# and Rust, we'll have to be using the `-P` flag of grep to use the PCRE2 regex flavor.
Unfortunately the `grep` shipped with macOS doesn't support the `-P` flag, and therefore we'll use GNU Grep (`ggrep`) instead; see [Pre-requisites for the workshop](#pre-requisites-for-the-workshop).

To abstract away from having to choose between `ggrep` (GNU Grep on macOS) and `grep` (on Linux and Unix shells on Windows),
we've created the `regex-search.sh` script that uses `ggrep` in case its installed and otherwise uses `grep`.
Furthermore, this script only shows the code that was matched instead of showing the whole line (which `grep`/`ggrep` normally does).

🧩 Plain grep works for quick wins, but it treats code as text. Multi-line constructs (like some console.log calls) slip through,
so you can’t trust this for anything beyond simple, single-line matches.

🧪 Let's try again but this time using a simple regular expression (aka regex) using our `regex-search.sh` script:
```sh
./regex-search.sh 'console.log\(.*\)' ../src
```

Unfortunately things got worse, and the `console.log` using multiple lines are no longer shown at all 😣

🧩 Simple regex improves intent (“match a call with parentheses”), but . doesn’t span newlines by default—so multi-line
calls disappear. You end up either missing results or writing unreadable patterns.

As it turns the `.` regex meta-character is **not** including any new-lines.
To make the regex also match newlines, we have to slightly change our regex.

🧪 Try again, this time using a slightly less readable regex:
```sh
./regex-search.sh 'console.log\((.|\n)*\)' ../src/common/image/extract_color.ts
```

💡 **NOTE** the `regex-search.sh` script uses the `-z` CLI flag of `grep` / `ggrep` so the regex can use `\n` to match newlines.

Jikes, the regex matching no longer stops are the closing `)` bracket but instead matches until the last `)` in the file 😱
Also notice that now the complete contents of the file is shown instead of only what is matched 😵‍💫

🧩 Multi-line regex works in theory but becomes brittle fast: greedy groups run past the intended closing `)` and fixes
make the pattern complex and hard to maintain.

The incorrect matching of the closing `)` bracket should be easy fixable by adding a `?` after the `*` regex meta-character to use non-greedy regex matching.

🧪 Try again, but this time using _non-gready_ regex matching:
```sh
./regex-search.sh 'console.log\((.|\n)*?\)' ../src/common/image/extract_color.ts
```

Looks like grep now matches the whole `console.log(`..`)` call 😄

🧪 Now, let's execute the regex again but on the whole `src` folder:
```sh
./regex-search.sh 'console.log\((.|\n)*?\)' ../src
```

Turns out that using non-gready matching did **not** complety fix our closing `)` bracket problem.  
Have a look at the matches of the `src/common/string/filter/filter.ts` file and notice the matches ends too early using
the closing bracket of the nested `printTable(`..`)` call.

So at it turns out non-greedy matching is not enough to fix our regex 😿

🧩 Even non-greedy regex fails reliably at scale (nested calls, mixed formatting).
For systematic code search, we need a syntax-aware approach.

### Summary: 
Across these experiments, grep/regex showed speed but no structural understanding.
That’s the core limitation we’ll address next with AST-based search using ast-grep.

## Introducing structural search with ast-grep
⏩ View the next file to continue workshop: [03-ast-grep-intro-structural-search.md](./03-ast-grep-intro-structural-search.md)
