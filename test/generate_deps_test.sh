. assert.sh

echo "github.com/pote/johnny-deps-testing-package v5.0" > Godeps
../bin/johnny_deps
../bin/generate_deps > helper.go

echo "github.com/pote/johnny-deps-testing-package v5.1" > Godeps
../bin/johnny_deps
rm -rf $GOPATH/pkg/github.com/pote/johnny-deps-testing-package
assert "go run go_code.go" "v5.1"

go run helper.go generate_deps_helper.go > Godeps
../bin/johnny_deps
rm -rf $GOPATH/pkg/github.com/pote/johnny-deps-testing-package
assert "go run go_code.go" "v5.0"

rm helper.go Godeps

assert_end generate_deps
