# Workshop: Taking back control of your code

(continues where [01_intro.md](./01_intro.md) file ended)

## Traditional way of searching code

Before we start using ast-grep, it's also good to experience the traditional way of search code and its pain-points.
For the traditional experience we'll be using Unix `grep`.

**NOTE**: Alternatively, you could also do the `grep` / `./regex-search.sh` exercises below using your IDE's search features.

To exercise searching code, we'll search for JavaScript `console.log` which is typically unwanted, since it clutters the Console logging in your browser.

🧪 Use the `grep` tool to search for `console.log` on the command-line:

```sh
grep -r 'console.log' ../src
```

**NOTE**: during the workshop the current working directory in your command-line is expected to be `./workshop-taking-back-control`.
That's why supply `../src` / `../src/`.. (as opposed to `src` / `src/`..) at the end of every `grep`, `regex-search.sh`, `ast-grep` and `opengrep` command in the workshop material.

Notice that some of the `console.log` calls are placed on multiple lines like in the `src/common/image/extract_color.ts` file.

But, unfortunately only the first line and its opening `(` bracket is shown for the `console.log` calls.
To show multiline calls including all its arguments, we'll have to start using regex.
And to be compatible with modern regex flavors that you find in language like JavaScript, Java, C# and Rust, we'll have to be using the `-P` flag of grep to use the PCRE2 regex flavor.
Unfortunately the `grep` shipped with macOS doesn't support the `-P` flag, and therefore we'll use GNU Grep (`ggrep`) instead; see [Pre-requisites for the workshop](#pre-requisites-for-the-workshop).

To abstract away from having to choose between `ggrep` (GNU Grep on macOS) and `grep` (on Linux and Unix shells on Windows),
we've created the `regex-search.sh` script that uses `ggrep` in case its installed and otherwise uses `grep`.
Furthermore, this script only shows the code that was matched instead of showing the whole line (which `grep`/`ggrep` normally does).

🧪 Let's try again but this time using a simple regular expression (aka regex) and our `regex-search.sh` script:

```sh
./regex-search.sh 'console.log\(.*\)' ../src
```

Unfortunately things got worse, and the `console.log` using multiple lines are no longer shown at all 😣

Notice that our regex is actually more precise than the `console.log` text that we previously search on,
since we now also want to the opening and closing brackets and everything in between those brackets.

As it turns the `.` regex meta-character is **not** including new-lines.
To make the regex also match newlines, we have to slightly change our regex.

🧪 Try again, this time using a slightly less readable regex:

```sh
./regex-search.sh 'console.log\((.|\n)*\)' ../src/common/image/extract_color.ts
```

**NOTE**: the `regex-search.sh` script uses the `-z` CLI flag of `grep` / `ggrep` so regex can use `\n` to match newlines.

Jikes, the regex matching no longer stops are the closing `)` bracket but instead matches until the last `)` in the file 😱
Also notice that now the complete contents of the file is shown instead of only what is matched 😵‍💫

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

## Introducing structural search with ast-grep

⏩ View the next file to continue workshop: [02_traditional_search.md](./02_traditional_search.md)
