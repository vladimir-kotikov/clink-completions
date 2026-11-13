# Contributing to clink-completions

Read the repository structure and contribution sections of the [README](../README.md), then inspect similar scripts and the current CI workflow. Base changes on `master`.

- Follow the existing placement of scripts. Root scripts load at startup, `completions/` is for lazy-loaded scripts, and `modules/` is for shared helpers. Use the placement that matches the APIs the script needs. Keep details about one command in its script comments.
- When a generator calls a program from `cmd.exe`, select the intended native `.exe` explicitly. A bare name can select a BAT or CMD script that parses arguments differently. Treat the executable and every argument as separate values. Preserve any leading redirection used to prevent outer-quote stripping, and document why the launch and quoting rules work together.
- Verify what Clink provides in each callback. For example, `getword()` strips quotes during match generation and retains them during word-break callbacks. Explain any defensive checks and use readable names for protocol flags.
- Run the existing `luacheck .` and Busted checks from the repo root. Busted uses stock Lua 5.2 and primarily exercises modules. Add tests only when they are needed and fit `spec/`. Use captured output and mocks for external programs. Keep installation paths and installed applications out of the suite.
- Check completion behavior separately in real Clink. Report which checks ran, then send a focused update and reply to each review thread, including corrections on resolved threads.
