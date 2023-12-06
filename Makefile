
export PROJECT ?= linkerd-site
RELEASE_URL = https://github.com/linkerd/linkerd2/releases

# Version values will be replaced by `get-versions` target.
export L5D2_STABLE_VERSION ?= "stable-X.X.X"
export L5D2_EDGE_VERSION ?= "edge-X.X.X"

GIT_BRANCH = $(shell git rev-parse --abbrev-ref HEAD)
GIT_HASH = $(shell git log --pretty=format:'%h' -n 1)

define upload_public
	gsutil -m rsync \
		-d -r -c $(if $(DRY_RUN),-n,) \
		tmp/$(1)/public gs://$(2)
endef

HAS_GSUTIL := $(shell command -v gsutil;)
HAS_FLARECTL := $(shell command -v flarectl;)
HAS_HUGO := $(shell command -v hugo;)
HAS_HTMLTEST := $(shell command -v htmltest;)
HAS_MDLINT := $(shell command -v markdownlint;)

.PHONY: publish
publish: get-versions build-linkerd.io deploy
	@# Publish a new version of the sites

.PHONY: get-versions
get-versions:
	@# Update the version for the %* site
	@. ./bin/export-channel-versions; \
	$(MAKE) replace-env-L5D2_STABLE_VERSION replace-env-L5D2_EDGE_VERSION

deploy-%: tmp/%/public
	@# Upload a site to the correct bucket.
	@# Options:
	@#
	@#     DRY_RUN                            :: ${DRY_RUN}
	$(call upload_public,$*,$*)

nocache-%:
	gsutil -m setmeta -h "Cache-Control:no-cache,max-age=0" -r gs://$*/

deploy: deploy-linkerd.io deploy-run.linkerd.io deploy-versioncheck.linkerd.io nocache-run.linkerd.io nocache-versioncheck.linkerd.io
	@# Deploy l5d2 related sites

tmp:
	mkdir -p tmp

tmp/%:
	@printf "Missing tmp/$*. Run\n\n\tmake tmp-sites\n\n"; exit 1

tmp/%/public:
	@printf "Missing tmp/$*/public. Run:\n\n\tmake build-$*\n\n"; exit 1

.PHONY: tmp-sites
tmp-sites: clean tmp
	cp -R *linkerd.io tmp/

.PHONY: lint
lint:
	@# lint the markdown for linkerd.io
ifndef HAS_MDLINT
	@printf "Install markdownlint first, run npm install -g markdownlint-cli\n"; exit 1
endif
	markdownlint -c linkerd.io/.markdownlint.yaml \
		-i linkerd.io/content/blog \
		-i linkerd.io/content/dashboard \
		linkerd.io/content
	markdownlint -c linkerd.io/.markdownlint.blog.yaml \
		linkerd.io/content/blog \
		linkerd.io/content/dashboard

.PHONY: check
check: build-linkerd.io
	@# Check linkerd.io for valid links and standards
ifndef HAS_HTMLTEST
	@printf "Install htmltest first. curl --proto '=https' --tlsv1.2 -sSfL https://htmltest.wjdp.uk | bash\n"; exit 1
endif
	cd tmp/linkerd.io && htmltest

.PHONY: shellcheck
shellcheck:
	@# lint the install scripts
	shellcheck run.linkerd.io/public/install* \
		api.linkerd.io/build \
		linkerd.io/build \
		linkerd.io/release-next-version

.PHONY: test-ci
test-ci:
	@# Test CI configuration without constant commits to config.yml
ifndef CIRCLE_TOKEN
	@printf "Create a personal CircleCI token first (CIRCLE_TOKEN). See https://circleci.com/docs/2.0/managing-api-tokens/#creating-a-personal-api-token\n"; exit 1
endif
	curl --user $(CIRCLE_TOKEN): \
		--request POST \
		--form revision=$(GIT_HASH) \
		--form config=@.circleci/config.yml \
		--form notify=false \
			https://circleci.com/api/v1.1/project/github/linkerd/website/tree/$(GIT_BRANCH)

serve-%: build-%
	@# Serve the built files locally
	cd tmp/$*/public \
		&& python3 -m http.server 9999

.PHONY: serve-api.linkerd.io
serve-api.linkerd.io: build-api.linkerd.io
	@# Serve the built files locally
	cd api.linkerd.io/public \
		&& python3 -m http.server 9999

.PHONY: build-linkerd.io
build-linkerd.io: build-release-matrix get-versions tmp/linkerd.io
	@# Build linkerd.io
ifndef HAS_HUGO
	@printf "Install hugo first. For OSX: brew install hugo\n"; exit 1
endif
	cd tmp/linkerd.io && ./build

.PHONY: build-api.linkerd.io
build-api.linkerd.io:
	@# Build api.linkerd.io
	cd api.linkerd.io && ./build

.PHONY: build-%
build-%: get-versions
	@# Build *.linkerd.io

.PHONY: replace-env-%
replace-env-%: has-env-% tmp-sites
	@# Replace vars in files from the environment.
	@grep -rnl '$*' tmp >/dev/null || \
		( \
			printf "There are no instances of $*, maybe you've already updated them?\n" && \
			exit 1 \
		)
	for fname in $$(grep -rnl '$*' tmp); do \
		sed 's/$*/$($*)/g' < $$fname > /tmp/__sed && mv /tmp/__sed $$fname; \
	done

.PHONY: build-release-matrix
build-release-matrix:
	@# Build release matrix
	./bin/generate_release_matrix.py --release_type=stable --format=json > linkerd.io/data/releases/release_matrix.json
	./bin/generate_release_matrix.py --release_type=stable --format=yaml > linkerd.io/content/releases/release_matrix.yaml
	cp linkerd.io/data/releases/release_matrix.json linkerd.io/content/releases/release_matrix.json


.PHONY: has-env-%
has-env-%:
	@if [ ! $${$*:-} ]; then printf "You must define: $*\n" && exit 1; fi

.PHONY: clean
clean:
	rm -rf tmp


