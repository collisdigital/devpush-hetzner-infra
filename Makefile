.PHONY: all init validate lint setup-ssh connect

all: validate lint

init:
	./scripts/init.sh

validate:
	./scripts/validate.sh

lint:
	./scripts/lint.sh

setup-ssh:
	./scripts/ssh_setup.sh

connect: setup-ssh
	ssh devpush
