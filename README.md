# Johnny Deps ![Build Status](https://circleci.com/gh/VividCortex/johnny-deps.png?circle-token=426f85f6d52ca0b308d1f6aab01dd219afdb4cb0)

Johnny Deps is a small tool from [VividCortex](https://vividcortex.com) that
provides minimalistic dependency versioning for Go repositories using Git. Its
primary purpose is to help create reproducible builds when many import paths in
various repositories are required to build an application. It's based on a Perl
script that provides subcommands for retrieving or building a project, or
updating a dependencies file (called `Godeps`), listing first-level imports for
a project.

## Getting started

Install Johnny Deps by cloning the project's Github repository and running the
provided scripts, like this:

```
git clone https://github.com/VividCortex/johnny-deps.git
cd johnny-deps
./configure --prefix=/your/path
make install
```

The `--prefix` option to `configure` is not mandatory; it defaults to
`/usr/local` if not provided (but you'd have to install as root in that case).
The binary will end up at the `bin` subdirectory, under the prefix you choose;
make sure you have that location specified in your `PATH`.

Note that Perl is required, although that's probably provided by your system
already. Also Go, Git and (if you're using makefiles) Make.

## Dependencies

Johnny Deps is all about project dependencies. Each project should have a file
called Godeps at its root, listing the full set of first-level dependencies;
i.e., all repositories with Go packages imported directly by this project. The
file may be omitted when empty and looks like this:

```
github.com/VividCortex/godaemon 2fdf3f9fa715a998e834f09e07a8070d9046bcfd
github.com/VividCortex/log 1ffbbe58b5cf1bcfd7a80059dd339764cc1e3bff
github.com/VividCortex/mysql f82b14f1073afd7cb41fc8eb52673d78f481922e
```

The first column identifies the dependency. The second is the commit identifier
for the exact revision the current project depends upon. You can use any
identifier Git would accept to checkout, including abbreviated commits, tags and
branches. Note, however, that the use of branches is discouraged, cause it leads
to non-reproducible builds as the tip of the branch moves forward.

## Introducing the tool

`jd` is Johnny Deps' main binary. It's a command line tool to retrieve projects
from Github, check dependencies, reposition local working copies according to
each project's settings, building and updating. It accepts subcommands much like
`go` or `git` do:

```
jd [global-options] [command] [options] [project]
```

Global options apply to all commands. Some allow you to change the external
tools that are used (go, git and make) in case you don't have them in your path,
or otherwise want to use a different version. There's also a `-v` option to
increase verbosity, that you can provide twice for extra effect. (Note that the
tool runs silently by default, only displaying errors, if any.)

It's worth noting that all parameters are optional. If you don't specify a
command, it will default to `build` (see "Building" below). If you don't specify
a project, `jd` will try to infer the project based on your current working
path, and your setting for `GOPATH`. If you're in a subdirectory of any of the
`GOPATH` components, and you're also in a Git working tree, `jd` would be happy
to fill up the project for you.

When in doubt, check `jd help`.

## Retrieving projects

Retrieving a Go application with Johnny Deps is just as easy as retrieving a
single base project. Run `jd get` and the full application, with all transitive
dependencies, will be set up in your environment. Here's what we'd type for one
of our applications:

```
jd get github.com/VividCortex/api-hosts
```

Johnny Deps will look for all required projects in your `GOPATH`, and download
those missing to the first component of `GOPATH`. It will even create the
directory stated in your `GOPATH` if it doesn't yet exist. As `jd` traverses the
graph of dependencies, it checks whether version conflicts exist. If it happens
to detect one, it will abort with a message like this:

```
Version mismatch detected for github.com/VividCortex/core
  561c9e9798307b875b8f90b89b7888eae4a983ce referenced by:
    github.com/VividCortex/api-hosts
    github.com/VividCortex/config
    github.com/VividCortex/nap
  but dfe3ff5362d778214272b56e2afcca0d96651911 referenced by github.com/VividCortex/shard
```

Here, the tool is telling you that two different versions of `core` are being
included. The first is the commit identifier at the top, that is shared as a
dependency for the three projects that follow. But `shard`, on the other hand,
is including a different commit for `core`, shown at the last line. If no
version mismatch is found, you'll end up with all projects required to build the
application you were interested in (`api-hosts` in the example above).

Besides retrieving required projects, `jd get` will reposition local copies
(whether they existed already or were just cloned) to the version stated in
`Godeps` files. Furthermore, if you're aiming at a specific commit (as
recommended), `jd` does an extra effort trying to checkout a branch whose tip
matches that commit, as opposed to leaving you in a detached HEAD state. That's
most probably what you want, cause it's probably a work in progress and you'll
be adding commits to that branch. (If you prefer a detached HEAD instead,
provide the `-d` flag to `get`.)

When choosing a branch to checkout for a given commit identifier, `jd` will
first search among all locals. If there's none whose tip matches the commit,
`jd` will try remote tracking branches instead. Among those matching, `jd`
selects one with a local branch by the same name, having the remote as an
upstream branch. If there's one available, that remote branch is merged into the
local, and the latter is checked out for use. Otherwise, `jd` keeps one of the
matching remotes with no local branch by the same name, and checks out a new
local branch with that remote set as upstream. (If local branches existed for
all candidate remotes, but none of them had the remote by the same name set as
upstream, then `jd` would abort with an appropriate message. In that case you
should either review your local branches, cause there's possibly an upstream
setting missing, or otherwise use `-d` to checkout in detached HEAD mode.) In
any case, if there's more than one choice and you're running with double `-v`,
you'd get a message displaying the other options as well.

It's worth noting that `jd` favors local operations as much as possible, to
avoid long round-trips to remote repositories. Hence, remotes won't be fetched
if the required revision is found locally. (That's particularly relevant when
including a branch name at the `Godeps` file cause, if found locally, the branch
will not be updated with remote changes.) Note also that, unless it actually
needs to move to a different release, `jd` will not insist in that your working
copy is clean. This is good from a developer's point of view, cause it allows
you to play with the application, trying modifications or fixes in the whole
code base, without `jd` complaining.

If the project you're interested in is not present in `GOPATH`, `jd get` will
clone it from the remote repository and checkout the master branch. But once you
have a local copy, `jd` will never checkout a different revision. (It will
change revisions for dependencies, but not for the main project you provide to
`jd get`.) You may reposition the working copy to your liking using Git
commands; `jd` will be happy to adjust dependencies accordingly. However, if you
want to force your main project into a specific revision, even before you have a
local copy, you can use the `-r` parameter to `jd get`, like so:

```
jd get github.com/VividCortex/api-hosts -r my-release
```

where the argument to `-r` can be anything you can checkout from Git: a commit
identifier (abbreviated or not), a branch or a tag.

After working copies for all projects in the application are set, `jd get` runs
a check on first level dependencies for the main project (i.e., the one either
you specified on the command line, or `jd` inferred from your current
directory). The check is run against the result of `go list`. `jd` will complain
if the sets don't match exactly, displaying both missing and not required
projects. If that's the case, you need to fix your `Godeps` file (see "Updating"
below).

## Building

Since building is what you'll be doing most of the time, `jd` conveniently
defaults to `build` if no command is provided. Furthermore, `jd` may be able to
retrieve the project out of your current working directory (see "Introducing the
tool" above). Hence, you'd typically be able to compile by typing only `jd` at
the command prompt. Not even your location within the project tree matters; the
tool works equally fine if run from deep inside the hierarchy.

Before the actual building process, `jd` runs the equivalent of a `jd get`
command. That's how it makes sure that you're actually using the correct
versions of all dependencies. (Keep in mind, though, that if your local copies
were already set to the correct revisions, it's okay to have local changes; even
in `Godeps` files.) The implicit `get` run by `build`, and the choice of `build`
as the default command, make the tool particularly easy to use to build projects
you don't even have. The following command retrieves the full dependencies for
the application and builds:

```
jd github.com/VividCortex/api-hosts
```

Furthermore, since the `-r` option to `build` is actually passed along to the
implicit `get`, you can readily set up a specific version by appending the
appropriate `-r` to the command above. (The same behavior goes to the `-d`
option to `build`.)

Johnny Deps calls `go build` at the project's root to build. But, in order to
accommodate special needs, `jd` first checks for specific instructions,
resorting to `go build` if there's none. The highest priority goes to the Make
utility. If there's a file called `Makefile` or `makefile` at the project root,
then `make` is run instead. If, on the other hand, there's an executable file
called `build`, then that file is run. Otherwise the default call to `go build`
takes place.

## Updating dependencies

Johnny Deps can't decide which releases to use from the project's you import.
But it can help writing the `Godeps` file. By running `jd update`, `jd` will
disregard the current dependencies in the `Godeps` file, overwriting it with the
latest master release for each project you depend upon, after pulling. Of
course, that may or may not work. Using the latest release for each dependency
could potentially lead to inconsistencies (version mismatches), that would make
`jd` complain. The dependencies file would have been changed anyway. It's your
responsibility to decide which projects to upgrade or withhold.

It's worth noting that `jd update` does not rely on the `Godeps` file to check
current dependencies; it takes them from `go list` instead. A nice consequence
is that new imports are automatically detected from the code and added to
`Godeps` with no manual intervention required. (And no longer needed imports
will be removed as well.) Note also that, although the old dependencies file is
overwritten, the new copy is not committed or even staged for commit in Git.
(Rationale: you should test that everything still works properly!) You can do
that with the rest of your changes, without leaving traces in history if you run
the update multiple times before you're done.

## Return codes

These are the return codes for `jd`:

* 0 - Success
* 1 - Error with parameters
* 2 - Bad dependencies or unable to read them
* 3 - Version mismatch detected
* 4 - External command failed
* 5 - Unable to checkout requested revision

## Workflows

Johnny Deps is intentionally agnostic about the specific workflow used. In
practice, people seem to fall into one of two camps that reflect how they think
about dependency management, and their differing goals.

The first category, roughly speaking, is those who would like to build from the
tip of their source control repositories all the time, but have a need for
pinning some things to a specific version. Those users may use branch names in
`Godeps` as opposed to commit identifiers, and change to a specific commit when
they need to pin a version. (Nevertheless, `jd` will not automatically fetch the
latest changes. See "Retrieving projects".)

The second school of thought holds that the `Godeps` file should contain
external dependencies and their exact versions, so that checking out a
particular revision of an application's repository and running `jd` will result
in exactly the same versions of all of the code used to build the application,
every time.

At VividCortex, we want to be able to reproduce a binary for debugging or other
purposes. All of our builds have a command-line flag called `--build-version`
that, when present, will result in the binary printing out the Git revision from
which it was built. We can thus easily reproduce any version by calling `jd
build` with that revision as the `-r` parameter. To embed the revision in the
binary, we use a specific shell script called `build` (see "Building" above)
that runs something like:

```
go build -ldflags "-X main.Godeps '$(git rev-parse HEAD)'"
```

At the application we set things up so that `--build-version` displays the
contents of the `main.Godeps` variable set by the compiler.

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
