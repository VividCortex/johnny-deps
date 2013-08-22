. assert.sh

# Set the dependency package version to v5.0
echo "github.com/pote/johnny-deps-testing-package v5.0" > Godeps
../bin/johnny_deps

# Generate a source file with an init() that
# contains the current state
../bin/generate_deps > helper.go

# Change the state by updating the package to v5.1
echo "github.com/pote/johnny-deps-testing-package v5.1" > Godeps
../bin/johnny_deps

# Remove any existing precompiled package files
rm -rf $GOPATH/pkg/github.com/pote/johnny-deps-testing-package

# Confirm that the dependency state has changed
assert "go run go_code.go" "v5.1"

# Run the helper Go program and generate a new
# Godeps file which describes the dependency state
# when the program was created
go run helper.go generate_deps_helper.go > Godeps
../bin/johnny_deps

# Remove the compiled package again
rm -rf $GOPATH/pkg/github.com/pote/johnny-deps-testing-package

# Confirm that the dependency state is v5.0 again
assert "go run go_code.go" "v5.0"

# Clean up
rm helper.go Godeps

assert_end generate_deps
