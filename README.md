# Johnny Deps ![Build Status](https://circleci.com/gh/VividCortex/johnny-deps.png?circle-token=426f85f6d52ca0b308d1f6aab01dd219afdb4cb0)

Johnny Deps is a small tool from [VividCortex](https://vividcortex.com)
that provides minimalistic dependency versioning for Go repositories using Git.
Its primary purpose is to help create reproducible builds when many import paths in
various repositories are required to build an application.  It uses a small shell
script to fetch Git repositories and check them out to the version specified in a
file called `Godeps`.

## Getting Started

When called without arguments, `johnny_deps` reads the `Godeps` file in the CWD.
You can specify the filename as an argument if desired.

The file should be in the format `import_path version <extra>`.  Lines
beginning with a `#` are comments. The first and second fields are used; any
remaining fields are ignored. Here's a sample:

```
github.com/VividCortex/ewma       v1.0
github.com/VividCortex/robustly   426f85f6d52ca0b308d1f6aab01dd219afdb4cb0
```

Because `johnny_deps` uses `git checkout`, you can specify a branch instead of
a tag or SHA. This may be useful if you simply want to use a different branch
of a dependency, without pinning it to a specific version.  Using specific
versions instead of branch names, however, has the advantage that unlike tools
such as Ruby's Bundler, we don't need a `Godeps.lock` file.

### Installation

You can run Johnny Deps directly from the web without installing it. We do this
in our CircleCI tests in many cases. Here's an example of using version 0.2.2;
you can use the latest master if you wish, too:

```
$ curl -s https://raw.github.com/VividCortex/johnny-deps/v0.2.2/bin/johnny_deps | sh
```

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
particular revision of an application's repository and running `johnny_deps`
will result in exactly the same versions of all of the code used to build the
application, every time.

At VividCortex, we want to be able to reproduce a binary for debugging or
other purposes. We use a combination of tools for this, including some helper
scripts. The outcome is that all of our builds have a command-line flag called
`--build-version` that, when present, will result in the binary printing out
the Git revision from which it was built. Checking out that revision will restore the `Godeps`
file exactly as it was at the time of the build, and running `johnny_deps`
will then check out the versions of the dependencies used for the build. In
this way, each build contains within it the evidence needed to reproduce the
build exactly.

If you're interested in how we do this, here's the process:

1. We use the `generate_deps` file to generate the `Godeps` file's contents at the time of the build, and we commit it to Git.
1. We get the application repository's Git revision and write it to a temporary Go source file, which contains an `init()` function that sets a global variable to the revision. After building, the temporary file is deleted.
1. We make the application print out the contents of this global variable when the `--build-version` flag is specified.

## Contributing

We welcome issue reports, suggestions, and especially pull requests:

1. Fork the project
2. Write your code in a feature branch
3. Add tests (if applicable)
4. Run tests (always!)
5. Commit, push and send Pull Request

Because this is a VividCortex internal tool that we're sharing publicly, we
may not want to implement some features or fixes. One of the original authors
maintains a [fork](https://github.com/pote/johnny-deps) that might have
additional features.

### Running Tests

You can run the test suite as follows:

```
$ make test
```

## License

Copyright (c) 2013 VividCortex.
Released under the MIT License. Read the LICENSE file for details.

## Contributors

Johnny Deps is the combination of several different thought processes from
multiple authors, with inspiration from tools such as Ruby's Bundler and dep
gem, Python's pip, and others. Give credit to [@pote](https://github.com/pote)
and blame to [@xaprb](https://github.com/xaprb).

![Johnny Deps](http://i.imgur.com/MuupBVC.jpg)
