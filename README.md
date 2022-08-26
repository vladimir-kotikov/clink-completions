
[![Build status](https://github.com/vladimir-kotikov/clink-completions/actions/workflows/code-check.yml/badge.svg?branch=master)](https://github.com/vladimir-kotikov/clink-completions/actions/workflows/code-check.yml)
[![codecov](https://codecov.io/gh/vladimir-kotikov/clink-completions/branch/master/graph/badge.svg)](https://codecov.io/gh/vladimir-kotikov/clink-completions)

clink-completions
=================

Completion files for [clink](https://github.com/chrisant996/clink) util. Bundled with [Cmder](https://github.com/cmderdev/cmder).

Notes
=====

Master branch of this repo contains all available completions. If you lack some functionality, post a feature request.

Some of completion generators in this bundle uses features from latest clink distribution. If you get an error messages in console while using these completions, consider upgrading clink to latest version.

If this doesn't help, feel free to submit an issue.

Development and contribution
============================

The new flow is single `master` branch for all more or less valuable changes. The `master` should be clean and show nice history of project. The bugfixes are made and land directly into `master`.

Feature development should be done in a separate topic branch per feature. Submit a pull request for merging the feature into the `master` branch, and include a meaning commit description for the feature changes.

Avoid reusing a topic branch after it's been merged into `master`, because reusing leads to unnecessary merge conflicts. The more the topic branch is reused, the harder it will become to accurately resolve the merge conflicts.

The `dev` branch is volatile and should not be used by contributors.

Requirements
============

These completions requires Clink v0.4.3 or newer.

# Test

You will need `busted` package to be installed locally (to `lua_modules` directory). To install it
using Luarocks call `luarocks install --tree=lua_modules busted`. You might also want to install
`luacov` to get the coverage information.

After installing call `test.bat` from repo root and watch tests passing. That's it.
