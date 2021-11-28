.PHONY: build release test examples docs

BIN_DIR = "bin"
build:
	shards build
release:
	shards build --release
test:
	crystal spec -v

examples:
	install -d ${BIN_DIR}
	crystal build examples/prog1.cr -o ${BIN_DIR}/prog1
	crystal build examples/prog2.cr -o ${BIN_DIR}/prog2

docs:
	mkdocs build
#	crystal docs
