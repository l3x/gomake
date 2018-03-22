# gomake

This project demonstrates the use of a Makefile for a Go (golang) application.

## Why Use gomake?

* It's uses make which is the standard build tool for Go and C projects
* It's a one-stop-shop for all build commands
* It helps enforce coding standards (see precommit and check targets)
* It helps devops produce repeatable, signed builds
* It comes with nextsemver.sh that helps enforce semver versioning
* It's smart about only building what's necessary, because it keeps track of dependencies
* It's is efficient, leveraging parallel processing
* There're no pre-installation dependencies 
    * All you need is the Makefile because bash and make will already be installed on your computer

## Features

These are the available make commands: 

```
$ make help
build-all            Build project for all supported platforms
build-cgo            Build Go app with cgo
build                Build Go app
check                Check Go source code using gofmt, golint and vet
clean                Remove binaries, artifacts and releases
color-examples       A few examples using echo-COLOR functions
deps                 Download and install build time dependencies (creates vendor directory and Gopkg.* files)
doc                  Start Go documentation server on port 8080
env                  Display Go environment
feature-branch       Create new feature branch from working directory and merge with master
fmt                  Format Go source code using gofmt
git-log              One-line-per-commit git log
help                 All documented make targets
imports              Run go imports
init-release-env     Initialize git hooks and semver versioning
init                 Initialize vendor directory and creating pre-commit git hook
install              Install Go app
main-messy           Replace main.go with a messy version, i.e., with formatting issues (for check/fmt to catch)
now                  Current timestamp
package-release      Package release and compress artifacts
play-branch          Create new playground branch from master
precommit            Create pre-commit git hook
release-note         Open editor s.t. you can edit /tmp/release-message
release              Package and sign project for release
run                  Install and run Go app
sign-release         Sign release and generate checksums
simplify             Simplify Go source code
tools                Install tools needed by the project
uninstall            Uninstall Go app
version              Display semver version number
vet                  Run go vet
```

## Usage

### Typical Use Case

Run `make init` once to initialize vendor directory and creating pre-commit git hook.

Run `make play-branch alice-playground` to create a playground branch.

Create source files for your application.

Run `make run` to build and run your app.

Run `make final-branch feature-xyz` to create a playground branch.

Create source files for your application.

Run `make run` to build and run your app.


### Minimal Use Case

Run `make precommit` to  pre-commit git hook which will run gofmt before each commit.


### Production Use Case

Works with the included **nextsemver.sh** script to produce [semver](https://semver.org/) version numbers to tag our releases.

It's assumed that all the development for this release is complete and code has been committed to git and has been merged into the master branch.

This production use case helps us to:
* Tag our master branch with the appropriate semver version tag.
* Package release and compress artifacts.
* Sign release and generate checksums.
* Open editor s.t. you can edit /tmp/release-message (that we can send to our team)

See the following commands:
* `package-release`
* `init-release-env`
* `release-note`
* `sign-release`

## Examples

### Use the pre-commit Hook to Format Go Code

This example demonstrates how to use **gomake** to initialize a simple Go project.

We'll create some formatting issues in main.go (Adding extra tabs and spaces) and attempt to commit main.go to our local git repository.

The pre-commit hook will kick in and prevent us from checking in code that has formatting issues.

We'll take its' advice and run `make fmt` to fix our formatting errors and then we'll commit the file.

<img align="right" width="60%" src="https://github.com/l3x/gomake/blob/master/gofmt-demo.png">

<br /><br /><br />

## Notes

**gomake** uses [dep](https://github.com/golang/dep) to manage Go's dependencies. 

### Dependencies

* make
* bash
* nextsemver.sh (included)
* dep
* tools
	* github.com/axw/gocov/gocov
	* github.com/golang/lint/golint
	* github.com/kisielk/errcheck
	* github.com/matm/gocov-html
	* github.com/mitchellh/gox
	* github.com/tools/godep
	* golang.org/x/tools/cmd/goimports

### Current status

This project is a work in progress (WIP).

Feel free to fork and/or open issues.

I am working with the typical use cases and will eventually get around to testing everything well, including the production use case.

Enjoy!

\- Lex