.PHONY: shards test docs examples

BIN_DIR = "bin"

shards:
	shards install
test:
	crystal spec -v
examples:
	install -d ${BIN_DIR}
	crystal build examples/prog1.cr -o ${BIN_DIR}/prog1
	crystal build examples/prog2.cr -o ${BIN_DIR}/prog2
	crystal build examples/prog1-config.cr -o ${BIN_DIR}/prog1-config
docs:
	mkdocs build
serve:
	mkdocs serve

