.PHONY: all validate lint setup-ssh connect

all: validate lint

validate:
	./scripts/validate.sh

lint:
	./scripts/lint.sh

setup-ssh:
	./scripts/ssh_setup.sh

connect: setup-ssh
	ssh devpush
