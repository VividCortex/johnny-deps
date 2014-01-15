# Johnny Deps ![Build Status](https://circleci.com/gh/VividCortex/johnny-deps.png?circle-token=426f85f6d52ca0b308d1f6aab01dd219afdb4cb0)

Johnny Deps is a small tool from [VividCortex](https://vividcortex.com)
that provides minimalistic dependency versioning for Go repositories using Git.
Its primary purpose is to help create reproducible builds when many import paths in
various repositories are required to build an application. It's based on a Perl
script that provides subcommands for retrieving (get) or building a project, or
updating a dependencies file (called `Godeps`), listing first-level imports for
a project.

## Getting Started

To retrieve a package with its full set of (transitive) dependencies, run `jd`
with the `get` subcommand. The package is provided as an argument, like in this
example:

```
jd get github.com/VividCortex/dbcontrol
```

The `get` command will clone the project, as well as all dependencies listed in
its `Godeps` file. The process continues recursively until no new dependencies
are found. If two different versions of a project are included from the full set
of dependencies, `jd` stops and reports the offending inclusion, like so:

```
Version mismatch detected for github.com/VividCortex/ewma
  a46680db5abe56b6df709c0bd34e556424008dab referenced by:
    github.com/VividCortex/sample
  but 7394084dd6e04369a564863509c3cac2b4bead5a referenced by github.com/VividCortex/robustly
```

If you need to set up your environment for a different version of your project,
you can specify a particular branch, tag or even commit id with the `-r` option
to `get`. Here's how a `Godeps` looks like:

```
github.com/VividCortex/godaemon 2fdf3f9fa715a998e834f09e07a8070d9046bcfd
github.com/VividCortex/log 1ffbbe58b5cf1bcfd7a80059dd339764cc1e3bff
github.com/VividCortex/mysql f82b14f1073afd7cb41fc8eb52673d78f481922e
```

Depending on your workflow (see "Workflows" below) you may choose to list a
commit id (or tag), or simply a branch name. Essentially anything that Git can
checkout is legal, including abbreviated commit identifiers. Lines starting with
`#` are regarded as comments and thus ignored.

Even though you can create a `Godeps` file by hand, `jd` provides a command to
automate the task: `update`. Running `jd update` on a project triggers a pull on
all first-level dependencies, whose latest (master) releases are then written to
a new `Godeps` file. Note that this process does *not* rely on the previous
file, but uses `go list` instead. A nice consequence is that new dependencies
are automatically detected from the code and added to `Godeps`, with no manual
intervention required. Note also that, although the old dependencies file is
overwritten, the new copy is not committed or even staged for commit in Git.
(Rationale: you should test that everything still works properly!) You can do
that with the rest of your changes, without leaving traces in history if you run
the update multiple times before you're done.

Keep in mind that updating dependencies can lead to inconsistencies, like the
"Version mismatch" message shown above. Resolving that problem needs human
intervention. Someone has to decide which projects *not* to update in order to
avoid the mismatch, or eventually upgrade other projects to match. `jd` will
limit itself to reporting the inconsistency during the `update` command, and
leaving you with an updated `Godeps` that you should further tune. You won't be
able to `build` until you do.

There's also a `build` command, that builds a project after triggering an
implicit `get` to check everything's properly set up. Since building is what
you'll do most of the time, `jd` conveniently defaults to build when no command
is provided. In fact, it also treats the project as optional, using the current
directory to infer a suitable project to act upon. This implies that, when
working on a project directory, a typical build will be run by typing only `jd`.
Due to the automatic triggering of `get`, you can readily clone, set to
appropriate versions and build in a single step with something like:

```
jd github.com/VividCortex/log
```

Note that `jd build` will run `go build` at the project's root directory.
However, the `make` command will be run instead if a file called `Makefile` or
`makefile` exists in that directory; or otherwise `build`, if such an executable
file is found. In any case, `jd` will run the appropriate build command and fail
if it returns anything other than zero.

Extra logging can be added by using the global option `-v`. Otherwise the tool
is completely silent (but setting an appropriate exit code), unless errors
arise. Use `-v` twice for increased verbosity. Notice though that `-v` is a
global option, so it goes *before* the command. Other global options are
available as well, to set specific binaries for Go and Git, or to set a specific
path for Go sources, instead of using `$GOPATH`.

It's worth noting also that `jd` makes a fair effort to check out a branch whose
tip matches the required version, as opposed to leaving you in a detached HEAD
state. (It will, nevertheless, if there's no alternative.) You may turn off that
behavior by providing the `-d` switch to `get` or `build`.

Run `jd help` for details.

### Installation

To install, clone the repo and then run:

    $ cd johnny_deps
    $ ./configure --prefix=/usr/local
    $ make install

## Workflows

Johnny Deps is intentionally agnostic about the specific workflow used. In
practice, people seem to fall into one of two camps that reflect how they
think about dependency management, and their differing goals.

The first category, roughly speaking, is those who would like to build from
the tip of their source control repositories all the time, but have a need for
pinning some things to a specific version or branch. These users might have a
minimal `Godeps` file that specifies only those dependencies. Everything else
is unmanaged.

The second school of thought holds that the `Godeps` file should contain all
external dependencies and their exact versions, so that checking out a
particular revision of an application's repository and running `jd`
will result in exactly the same versions of all of the code used to build the
application, every time.

At VividCortex, we want to be able to reproduce a binary for debugging or
other purposes. We use a combination of tools for this, including some helper
scripts. The outcome is that all of our builds have a command-line flag called
`--build-version` that, when present, will result in the binary printing out
the Git revision from which it was built. Checking out that revision will
restore the `Godeps` file exactly as it was at the time of the build, and
running `jd` will then check out the versions of the dependencies used for the
build. In this way, each build contains within it the evidence needed to
reproduce the build exactly.

If you're interested in how we do this, here's the process:

1. We use `jd update` to generate the `Godeps` file's contents at the time of
   the build, and we commit it to Git.
2. We get the application repository's Git revision and write it to a temporary
   Go source file, which contains an `init()` function that sets a global
   variable to the revision. After building, the temporary file is deleted.
3. We make the application print out the contents of this global variable when
   the `--build-version` flag is specified.

## Contributing

We welcome issue reports, suggestions, and especially pull requests:

1. Fork the project
2. Write your code in a feature branch
3. Add tests (if applicable)
4. Run tests (always!)
5. Commit, push and send Pull Request

Because this is a VividCortex internal tool that we're sharing publicly, we
may not want to implement some features or fixes.

### TODO

Add tests. Those we previously had are not appropriate for the new tool.

Optionally add support for other repositories, like Mercurial. This tool is now
targeted at Git on github.com, that is what we use at VividCortex.

## License

Copyright (c) 2013 VividCortex.
Released under the MIT License. Read the LICENSE file for details.

## Contributors

Johnny Deps is the combination of several different thought processes from
multiple authors, with inspiration from tools such as Ruby's Bundler and dep
gem, Python's pip, and others. Give credit to [@xaprb](https://github.com/xaprb)
and [@gkristic](https://github.com/gkristic).

![Johnny Deps](http://i.imgur.com/MuupBVC.jpg)
