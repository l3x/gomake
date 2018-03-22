# Run make (by itself) to get a list of avaiable make commands
# Assumes your EDITOR env variable is set properly

# ------------------------------------------------
#                  Set Variables
# ------------------------------------------------
# Set your gpg signing key before running $ make sign-release
GPG_SIGNING_KEY :=

SHELL := /bin/bash
.DEFAULT_GOAL := all

PRECOMMIT_PATH := .git/hooks/pre-commit

# The name of the executable (default is current directory name)
TARGET := $(shell echo $${PWD\#\#*/})
GOBIN := $(shell echo $${GOPATH})/bin

# These will be provided to the target
VERSION := 0.0.0
@[ -f ./VERSION ] && VERSION := $(VERSION) || true
BUILD := `git rev-parse HEAD`

# Hey devops! Add other OS's when cross compiling
#OS := darwin freebsd linux openbsd
OS := darwin
ARCH := 386 amd64

# Use linker flags to provide version/build settings to the target
#LDFLAGS := -ldflags "-X=main.Version=$(VERSION) -X=main.Build=$(BUILD)"
REPO_URL := github.com/l3x
LDFLAGS := -ldflags "-X $(REPO_URL)/$(TARGET)/itamaelocal.Revision=$(REV)$(CHANGES)"

# go source files, ignore vendor directory
SRC = $(shell find . -type f -name '*.go' -not -path "./vendor/*")

# ------------------------------------------------
#          Define Heredocs and Functions
# ------------------------------------------------

define precommitScript
gofiles=$$(git diff --cached --name-only --diff-filter=ACM | grep '.go$$')
[ -z "$$gofiles" ] && exit 0

unformatted=$$(gofmt -l $$gofiles)
[ -z "$$unformatted" ] && exit 0

tput setaf 11
echo >&2 "The following files have formatting issues:"
tput sgr0
for fn in $$unformatted; do
 echo >&2 "  $$PWD/$$fn"
done
tput setaf 11
echo >&2 "Please run:  make fmt"
tput sgr0
exit 1
endef
export precommitScript

define mainGoFile
package main

import "fmt"

			func   main()    {
	fmt.Println("formatting errors above")
}
endef
export mainGoFile

# User defined functions
define echo-red
      @tput setaf 1
      @echo $1 && tput sgr0
endef

define echo-green
      @tput setaf 2
      @echo $1 && tput sgr0
endef

define echo-light-blue
      @tput setaf 12
      @echo $1 && tput sgr0
endef

define echo-blue
      @tput setaf 4
      @echo $1 && tput sgr0
endef

define echo-yellow
      tput setaf 11
      @echo $1 && tput sgr0
endef

define echo-orange
      @tput setaf 3
      @echo $1 && tput sgr0
endef

define echo-purple
      @tput setaf 5
      @echo $1 && tput sgr0
endef

define echo-white
      @tput setaf 7
      @echo $1 && tput sgr0
endef

define echo-black
      @tput setaf 16
      @echo $1 && tput sgr0
endef

# ------------------------------------------------
#               Runtime Arguments
# ------------------------------------------------

cmd: # ...
    # ...

ifeq (play-branch,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "run"
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(RUN_ARGS):;@:)
endif

ifeq (feature-branch,$(firstword $(MAKECMDGOALS)))
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(RUN_ARGS):;@:)
endif


# ------------------------------------------------
#                  Define Targets
# ------------------------------------------------
all: check install

$(TARGET): $(SRC)
	@go build $(LDFLAGS) -o $(TARGET)

color-examples:	## A few examples using echo-COLOR functions
	$(call echo-blue,"Linking with" $(LD))
	$(call echo-blue,"Linking with" "AAA")
	$(call echo-red,"ERROR")
	$(call echo-yellow,"WARNING")
	$(call echo-green,"SUCCESS")

timestamp := $(shell /bin/date "+%Y%m%d-%H%M%S")

now:	## Current timestamp
	@echo $(timestamp)

tools:	## Install tools needed by the project
	go get github.com/axw/gocov/gocov
	go get github.com/golang/lint/golint
	go get github.com/kisielk/errcheck
	go get github.com/matm/gocov-html
	go get github.com/mitchellh/gox
	go get github.com/tools/godep
	go get golang.org/x/tools/cmd/goimports

deps:	## Download and install build time dependencies (creates vendor directory and Gopkg.* files)
	@dep ensure

build:	## Build Go app
	go build $(go list ./... | grep -v '/vendor/')

build-cgo:	## Build Go app with cgo
	@echo "go build -a -installsuffix cgo -o $(GOBIN)/$(TARGET)"

build-all: deps	## Build project for all supported platforms
	mkdir -v -p $(CURDIR)/artifacts/$(VERSION)
	gox -verbose \
	    -os "$(OS)" -arch "$(ARCH)" \
	    -ldflags "$(LDFLAGS)" \
	    -output "$(CURDIR)/artifacts/$(VERSION)/{{.OS}}_{{.Arch}}/$(TARGET)" .
	cp -v -f \
	   $(CURDIR)/artifacts/$(VERSION)/$$(go env GOOS)_$$(go env GOARCH)/$(TARGET) .

install:	## Install Go app
	@go install $(LDFLAGS)

uninstall: clean	## Uninstall Go app
	@rm -f $$(which ${TARGET})

clean:	## Remove binaries, artifacts and releases
	go clean -i ./...
	rm -vf \
	$(PRECOMMIT_PATH) \
	$(CURDIR)/*.orig \
	$(CURDIR)/Gopkg.* \
	$(CURDIR)/coverage.* \
	$(CURDIR)/packer-provisioner-itamae-local_* \
	$(TARGET) VERSION CHANGES
	@echo "To see git tags, run:  git tag -n --sort=refname | sort -nr"
	@echo "To delete a tag, run:  git tag -d \$$TAG_NAME && git push origin :refs/tags/\$$TAG_NAME"

main-messy:	## Replace main.go with a messy version, i.e., with formatting issues (for check/fmt to catch)
	@cp main.go /tmp/$(timestamp)_main.go
	@echo "$$mainGoFile" > main.go
	echo "// $(timestamp)" >> main.go

precommit:	## Create pre-commit git hook
	@echo "$$precommitScript" > $(PRECOMMIT_PATH)
	chmod +x $(PRECOMMIT_PATH)

init: clean precommit  ## Initialize vendor directory and creating pre-commit git hook
	mkdir -p $(CURDIR)/_local
	dep init

init-release-env: init  ## Initialize git hooks and semver versioning
	@[ -f ./VERSION ] || nextsemver --silent

version:	## Display semver version number
	@echo "VERSION: $(VERSION)"

release-note:	## Open editor s.t. you can edit /tmp/release-message
	@echo "Product Version $(VERSION)" > /tmp/release-message
	@echo "PUT_PRODUCT_VERSION_DESCRIPION_HERE" >> /tmp/release-message
	@echo "" >> /tmp/release-message
	@cat CHANGES >> /tmp/release-message
	$(EDITOR) /tmp/release-message

fmt:	## Format Go source code using gofmt
	@gofmt -l -w $(SRC)

simplify:	## Simplify Go source code
	gofmt -s -l -w $(SRC)

imports:	## Run go imports
	goimports -l -w .

vet:	## Run go vet
	go vet -v ./...

errors:
	errcheck -ignoretests -blank ./...

check: vet errors	## Check Go source code using gofmt, golint and vet
	@test -z $(shell gofmt -l main.go | tee /dev/stderr) || $(call echo-yellow,"[WARNING] Fix formatting issues with 'make fmt'")
	@for d in $$(go list ./... | grep -v /vendor/); do golint $${d}; done

run: install	## Install and run Go app
	@$(TARGET)

test: deps
	go test -v ./...

coverage: deps
	@gocov test ./... > $(CURDIR)/coverage.out 2>/dev/null
	@gocov report $(CURDIR)/coverage.out
	@if test -z "$$CI"; then \
	  gocov-html $(CURDIR)/coverage.out > $(CURDIR)/coverage.html; \
	  if which open &>/dev/null; then \
	    open $(CURDIR)/coverage.html; \
	  fi; \
	fi

package-release:	## Package release and compress artifacts
	@test -x $(CURDIR)/artifacts/$(VERSION) || exit 1
	mkdir -v -p $(CURDIR)/releases/$(VERSION)
	for release in $$(find $(CURDIR)/artifacts/$(VERSION) -mindepth 1 -maxdepth 1 -type d 2>/dev/null); do \
	  platform=$$(basename $$release); \
	  pushd $$release &>/dev/null; \
	  zip $(CURDIR)/releases/$(VERSION)/$(TARGET)_$${platform}.zip $(TARGET); \
	  popd &>/dev/null; \
	done

sign-release:	## Sign release and generate checksums
	@test -x $(CURDIR)/releases/$(VERSION) || exit 1
	pushd $(CURDIR)/releases/$(VERSION) &>/dev/null; \
	shasum -a 256 -b $(TARGET)_* > SHA256SUMS; \
	if test -n "$(GPG_SIGNING_KEY)"; then \
	  gpg --default-key $(GPG_SIGNING_KEY) -a \
	      -o SHA256SUMS.sign -b SHA256SUMS; \
	fi; \
	popd &>/dev/null

release: package-release sign-release	## Package and sign project for release

doc:	## Start Go documentation server on port 8080
	godoc -http=:8080 -index

env:	## Display Go environment
	@go env

help:	## All documented make targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'


# ------------------------------------------------
#                  git Targets
# ------------------------------------------------

play-branch: cmd	## Create new playground branch from master
	# start with current master
	git checkout master
	# create playground branch
	git checkout -b $(RUN_ARGS)
	@echo "During day, to commit changes to local rep run:   $$ git commit -a -m 'wip'"
	@echo "At end of day, to push commits to remote rep run: $$ git push origin $(RUN_ARGS)"

feature-branch: cmd	## Create new feature branch from working directory and merge with master
	# create the feature branch!
	@echo "git checkout -b $(RUN_ARGS)"
	# update your remote-tracking branches under refs/remotes/<remote>/
	@echo "git fetch origin"
	# merge latest master and deal with any conflicts
	@echo "git merge origin/master"
	# all of our changes are now unstaged, and my-feature = origin/master
	@echo "git reset origin/master"
	@echo "Make changes to files..."
	@echo "When you're ready to commit changes in pieces, run:  $$ git commit -i"
	@echo "When you're ready to push to remote repo, run:       $$ git push origin $(RUN_ARGS)"

git-log:	## One-line-per-commit git log
	@git log --graph --all --oneline --decorate


# ------------------------------------------------
#               Export Make Commands
# ------------------------------------------------

.PHONY: \
	all \
	build \
	build-cgo \
	check \
	clean \
	color-examples \
	deps \
	doc \
	errors \
	feature-branch \
	fmt \
	git-log \
	help \
	init \
	init-with-semver \
	install \
	now \
	package-release \
	play-branch \
	precommit \
	release \
	release-note \
	run \
	sign-release \
	simplify \
	test \
	tools \
	uninstall \
	version \
	vet
