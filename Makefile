
export PROJECT ?= linkerd-site
RELEASE_URL = https://github.com/linkerd/linkerd2/releases
export L5D2_STABLE_VERSION ?= stable-2.0.0
export L5D2_EDGE_VERSION ?= edge-18.10.3

define upload_public
	gsutil -m rsync \
		-d -r -c $(if $(DRY_RUN),-n,) \
		tmp/$(1)/public gs://$(2)
endef

HAS_GSUTIL := $(shell command -v gsutil;)
HAS_FLARECTL := $(shell command -v flarectl;)
HAS_SASS := $(shell command -v /usr/local/bin/sass;)
HAS_HUGO := $(shell command -v hugo;)

.PHONY: publish
publish: update-version build-linkerd.io deploy
	@# Publish a new version of the sites

.PHONY: update-version
update-version: replace-env-L5D2_STABLE_VERSION replace-env-L5D2_EDGE_VERSION
	@# Update the version for the %* site

.PHONY: deploy-%
deploy-%: tmp/%*/public
	@# Upload a site to the correct bucket.
	@# Options:
	@#
	@#     DRY_RUN                            :: ${DRY_RUN}
	$(call upload_public,$*,$*)

deploy: deploy-linkerd.io deploy-run.linkerd.io deploy-versioncheck.linkerd.io
	@# Deploy l5d2 related sites

tmp:
	mkdir -p tmp

tmp/%:
	@printf "Missing tmp/$*. Run\n\n\tmake tmp-sites\n\n"; exit 1

tmp/%/public:
	@printf "Missing tmp/$*/public. Run:\n\n\tmake build-$*\n\n"; exit 1

.PHONY: tmp-sites
tmp-sites: tmp
	cp -R *linkerd.io tmp/

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
build-linkerd.io: update-version tmp/linkerd.io
	@# Build linkerd.io
ifndef HAS_SASS
	@printf "Install sass first. For OSX: brew install sass/sass/sass\n"; exit 1
endif
ifndef HAS_HUGO
	@printf "Install hugo first. For OSX: brew install hugo\n"; exit 1
endif
	cd tmp/linkerd.io && ./build

.PHONY: build-api.linkerd.io
build-api.linkerd.io:
	@# Build api.linkerd.io
	cd api.linkerd.io && ./build

.PHONY: build-%
build-%: update-version
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
		sed -i '' 's/$*/$($*)/g' $$fname; \
	done

.PHONY: has-env-%
has-env-%:
	@if [ ! $${$*:-} ]; then printf "You must define: $*\n" && exit 1; fi

.PHONY: clean
clean:
	rm -rf tmp
