# Workshop: Taking back control of your code

## Useful resources
During the workshop, and later on, the following resources might be useful:
 - [Where X=YAML](https://learnxinyminutes.com/yaml/) on [Learn X in Y minutes](https://learnxinyminutes.com/)
   explains the YAML syntax through an example YAML document with comments taht explain the YAML syntax
 - [ast-grep website](https://ast-grep.github.io/), containing:
    - [Guide](https://ast-grep.github.io/guide/introduction.html)
    - [Rule Cheat Sheet](https://ast-grep.github.io/cheatsheet/rule.html)
    - [Rule Config reference](https://ast-grep.github.io/reference/yaml.html#configuration-reference)
    - [Rule Object Reference](https://ast-grep.github.io/reference/rule.html) containing information about
      [Atomic Rules](https://ast-grep.github.io/reference/rule.html#atomic-rules),
      [Relational Rules](https://ast-grep.github.io/reference/rule.html#relational-rules) and
      [Composite Rules](https://ast-grep.github.io/reference/rule.html#composite-rules)
    - [List of Languages with Built-in Support](https://ast-grep.github.io/reference/languages.html)
    - [Using ast-grep with AI Tools](https://ast-grep.github.io/advanced/prompting.html)
    - [How ast-grep Works: A bird's-eye view](https://ast-grep.github.io/advanced/how-ast-grep-works.html) with
      underneath the following additional articles:
       - [Core Concepts in ast-grep's Pattern](https://ast-grep.github.io/advanced/core-concepts.html)
       - [Deep Dive into ast-grep's Pattern Syntax](https://ast-grep.github.io/advanced/pattern-parse.html)
       - [Deep Dive into ast-grep's Match Algorithm](https://ast-grep.github.io/advanced/match-algorithm.html)
       - [Find & Patch: A Novel Functional Programming like Code Rewrite Scheme](https://ast-grep.github.io/advanced/find-n-patch.html)
 - [codemod.com](https://codemod.com/), nowadays uses ast-grep for its code migrations
   (also known as [codemods](https://martinfowler.com/articles/codemods-api-refactoring.html)):
    - [Codemod Studio](https://app.codemod.com/studio): an online studio that's like ast-grep Playground,
      but with more features like an AI to helps you to create ast-grep rules
    - [Introducing jssg: a next-gen, multi-language codemod toolkit](https://codemod.com/blog/jssg):
      blog about the new JavaScript ast-grep (jssg) runtime for code migrations from codemod.com
    - [Docs of JavaScript ast-grep (jssg) runtime](https://docs.codemod.com/jssg)
 - Opengrep (fork of Semgrep):
    - [Opengrep GitHub repo](https://github.com/opengrep/opengrep)
    - [Opengrep Playground GitHub repo](https://github.com/opengrep/opengrep-playground)
    - [Opengrep Rules (a fork of Semgrep Rules)](https://github.com/opengrep/opengrep-rules):
      the Static Application Security Testing (SAST) rules from OpenGrep   
 - Semgrep documentation, containing:
    - [Write rules for Semgrep Code](https://semgrep.dev/docs/writing-rules/overview) (is also applicable for Opengrep)
