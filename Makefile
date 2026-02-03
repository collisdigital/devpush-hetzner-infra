.PHONY: all init check-env validate lint setup-ssh connect

all: check-env validate lint

init:
	./scripts/init.sh

check-env:
	./scripts/check_envars.sh

validate:
	./scripts/validate.sh

lint:
	./scripts/lint.sh

setup-ssh:
	./scripts/ssh_setup.sh

connect: setup-ssh
	ssh devpush
