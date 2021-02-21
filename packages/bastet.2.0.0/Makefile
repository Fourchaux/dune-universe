all: clean default-switch build copy-docs

.PHONY: clean-bs
clean-bs:
	yarn bsb -clean-world

.PHONY: clean-native
clean-native:
	opam exec -- dune clean

.PHONY: clean-docs
clean-docs:
	rm -rf docs/**

.PHONY: clean-coverage
clean-coverage:
	rm -rf _coverage *.coverage
	rm -f coverage.json

.PHONY: clean
clean: clean-bs clean-native clean-docs clean-coverage

.PHONY: build-bs
build-bs:
	yarn bsb -make-world

.PHONY: build-native
build-native:
	opam exec -- dune build @all

.PHONY: build
build: build-bs build-native

.PHONY: fmt
fmt:
	opam exec -- dune build @fmt --auto-promote

.PHONY: docs-template
docs-template:
	cat bastet/src/index.mld.template | \
		sed -e 's/{{:/{ {:/g' | \
		opam exec -- dune exec examples/docs_template.exe | \
		sed -e 's/{ {:/{{:/g' > bastet/src/index.mld

.PHONY: docs
docs: clean-docs docs-template
	opam exec -- dune build @doc

.PHONY: copy-docs
copy-docs: docs
	cp -r _build/default/_doc/_html/** docs/

.PHONY: open-docs
open-docs: copy-docs
	xdg-open docs/index.html

.PHONY: test-bs
test-bs: build-bs
	yarn test

.PHONY: test-native
test-native: build-native
	opam exec -- dune runtest --no-buffer

.PHONY: test
test: test-bs test-native

.PHONY: bisect-bs
bisect-bs:
	BISECT_ENABLE=yes make test-bs

.PHONY: bisect
bisect:
	BISECT_ENABLE=yes make test

.PHONY: bisect-html
bisect-html: bisect
	opam exec -- bisect-ppx-report html

# NOTE: the git property in the json file needs to be set to show coverage status
.PHONY: coveralls-json
coveralls-json: bisect
	opam exec -- bisect-ppx-report coveralls --repo-token ${COVERALLS_TOKEN} coverage.json

# Useful for sending report to coveralls outside of CI
.PHONY: coveralls-send-api
coveralls-send-api:
	curl -L -F json_file=@./coverage.json https://coveralls.io/api/v1/jobs

.PHONY: coveralls-api
coveralls-api: coveralls-json coveralls-send-api

.PHONY: coveralls
coveralls:
	opam exec -- bisect-ppx-report send-to Coveralls

.PHONY: watch-native
watch-native:
	opam exec -- dune build @all -w

.PHONY: watch-bs
watch-bs:
	yarn bsb -make-world -w

.PHONY: watch-test-bs
watch-test-bs:
	yarn run watch-test

.PHONY: watch-test-native
watch-test:
	opam exec -- dune runtest --no-buffer -w

.PHONY: utop
utop:
	opam exec -- dune utop .

.PHONY: remove-switch
remove-switch:
	opam switch remove -y . || true

.PHONY: dev-tools
dev-tools:
	opam install -y merlin ocamlformat utop

.PHONY: create-4.08-switch
create-4.08-switch:
	opam switch create -y . 4.08.1 -t -d

.PHONY: 4.08-switch
4.08-switch: remove-switch create-4.08-switch dev-tools
	eval $(opam env)

.PHONY: create-default-switch
create-default-switch:
	opam switch create -y . -t -d

.PHONY: default-switch
default-switch: remove-switch create-default-switch dev-tools
	eval $(opam env)
