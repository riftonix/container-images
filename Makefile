SHELL := /bin/sh
.ONESHELL:

COMMAND_TARGETS := help check-image-component check-publish-input changed-components verify publish publish-dry-run
COMMAND_ARGS := $(filter-out $(COMMAND_TARGETS),$(MAKECMDGOALS))
SELECTED_COMPONENT := $(firstword $(COMMAND_ARGS))

DAGGER_ENV ?= DAGGER_NO_NAG=1 DO_NOT_TRACK=1 DAGGER_NO_UPDATE_CHECK=1
GIT_MODULE ?= github.com/riftonix/daggerverse/modules/git@modules/git/v1.0.1
CONTAINER_IMAGES_SCENARIO ?= github.com/riftonix/daggerverse/scenarios/container-images@scenarios/container-images/v0.1.2
BASE_REF ?= origin/master
HEAD_REF ?= HEAD
SHARED_PATHS ?=
REGISTRY_ADDRESS ?= ghcr.io
REGISTRY_USERNAME ?=
REGISTRY_PASSWORD_ENV ?= GITHUB_TOKEN
GIT_HOST ?= github.com
GIT_USERNAME ?= x-access-token
GIT_TOKEN_ENV ?= GITHUB_TOKEN

.PHONY: help check-image-component check-publish-input changed-components verify publish publish-dry-run $(COMMAND_ARGS)

help:
	@printf '%s\n' \
		'Targets:' \
		'  make changed-components [BASE_REF=<ref>] [HEAD_REF=<ref>] [SHARED_PATHS="<path> ..."]' \
		'  make verify docker/<image>           Build and verify one Bake image target' \
		'  make publish docker/<image>          Publish one Bake image target and push its release tag' \
		'  make publish-dry-run docker/<image>  Build and validate publication without pushing'

check-image-component:
	@if [ -z '$(SELECTED_COMPONENT)' ] || [ '$(words $(COMMAND_ARGS))' -ne 1 ]; then \
		printf 'Usage: make %s docker/<image>\n' '$(firstword $(MAKECMDGOALS))' >&2; \
		exit 2; \
	fi
	@if [ ! -f '$(SELECTED_COMPONENT)/docker-bake.json' ]; then \
		printf 'Image component has no Bake manifest: %s\n' '$(SELECTED_COMPONENT)' >&2; \
		exit 2; \
	fi

changed-components:
	@$(DAGGER_ENV) dagger -m $(GIT_MODULE) call --progress=plain --json --source=. \
		get-changed-components \
		--base-ref='$(BASE_REF)' \
		--head-ref='$(HEAD_REF)' \
		--component-roots='docker/*' \
		$(foreach path,$(SHARED_PATHS),--shared-paths='$(path)')

verify: check-image-component
	$(DAGGER_ENV) dagger -m $(CONTAINER_IMAGES_SCENARIO) call --progress=plain verify-bake-target \
		--source=. \
		--bake-path='$(SELECTED_COMPONENT)/docker-bake.json'

check-publish-input:
	@if [ -z '$(REGISTRY_USERNAME)' ]; then \
		printf 'Set REGISTRY_USERNAME before publishing\n' >&2; \
		exit 2; \
	fi
	@if ! printenv '$(REGISTRY_PASSWORD_ENV)' >/dev/null; then \
		printf 'Set registry password environment variable: %s\n' '$(REGISTRY_PASSWORD_ENV)' >&2; \
		exit 2; \
	fi
	@if ! printenv '$(GIT_TOKEN_ENV)' >/dev/null; then \
		printf 'Set Git token environment variable: %s\n' '$(GIT_TOKEN_ENV)' >&2; \
		exit 2; \
	fi

publish: check-image-component check-publish-input
	$(DAGGER_ENV) dagger <<'EOF'
	$(CONTAINER_IMAGES_SCENARIO) |
	  with-registry-auth \
	    --address='$(REGISTRY_ADDRESS)' \
	    --username='$(REGISTRY_USERNAME)' \
	    --password=env://$(REGISTRY_PASSWORD_ENV) |
	  publish-bake-target \
	    --source=. \
	    --bake-path='$(SELECTED_COMPONENT)/docker-bake.json'
	tag=$$(
	  $(CONTAINER_IMAGES_SCENARIO) |
	    get-bake-release-tag \
	      --source=. \
	      --bake-path='$(SELECTED_COMPONENT)/docker-bake.json' \
	      --component-path='$(SELECTED_COMPONENT)'
	)
	$(GIT_MODULE) --source=. |
	  with-https-token-auth \
	    --host='$(GIT_HOST)' \
	    --username='$(GIT_USERNAME)' \
	    --token=env://$(GIT_TOKEN_ENV) |
	  ensure-pushed-tag --tag="$$tag"
	EOF

publish-dry-run: check-image-component
	$(DAGGER_ENV) dagger -m $(CONTAINER_IMAGES_SCENARIO) call --progress=plain publish-bake-target \
		--source=. \
		--bake-path='$(SELECTED_COMPONENT)/docker-bake.json' \
		--publish-dry-run=true

$(COMMAND_ARGS):
	@:
