
export PROJECT ?= linkerd-site
RELEASE_URL = https://github.com/linkerd/linkerd2/releases
export L5D2_LATEST_VERSION ?= $(shell curl -Ls -o /dev/null -w %{url_effective} $(RELEASE_URL)/latest | awk '{split($$0,a,"/v"); print a[2]}')
ROOT_DOMAIN = linkerd.io
DOMAIN = $(shell echo "v$$(echo $(L5D2_LATEST_VERSION) | tr . -).docs.linkerd.io")

define upload_public
	gsutil -m rsync \
		-d -r -c $(if $(DRY_RUN),-n,) \
		tmp/$(1)/public gs://$(2)
endef

HAS_GSUTIL := $(shell command -v gsutil;)
HAS_FLARECTL := $(shell command -v flarectl;)
HAS_SASS := $(shell command -v /usr/local/bin/sass;)
HAS_HUGO := $(shell command -v hugo;)

.PHONY: release
release: create-bucket setup-dns publish
	@# Release a new version of sites

.PHONY: publish
publish: update-version build-linkerd.io deploy
	@# Publish a new version of the sites

.PHONY: create-bucket
create-bucket: has-env-L5D2_LATEST_VERSION
	@# Create a new bucket for old versions.
	@# Options:
	@#
	@#     PROJECT                            :: ${PROJECT}
	@#     L5D2_LATEST_VERSION                :: ${L5D2_LATEST_VERSION}
	@#     DRY_RUN                            :: ${DRY_RUN}
ifndef DRY_RUN
ifndef HAS_GSUTIL
	@printf "Install gsutil first. See https://cloud.google.com/sdk/docs/downloads-interactive\n"; exit 1
endif
	gsutil mb -p $(PROJECT) gs://$(DOMAIN)
	gsutil logging set on \
		-b gs://linkerd2-access-logs \
		-o $$(echo $(DOMAIN) | tr . -) \
		gs://$(DOMAIN)
	gsutil web set \
		-m index.html \
		-e 404.html \
		gs://$(DOMAIN)
	gsutil acl ch \
		-u allUsers:R \
		gs://$(DOMAIN)
endif

.PHONY: setup-dns
setup-dns: has-env-L5D2_LATEST_VERSION has-env-CF_API_KEY has-env-CF_API_EMAIL
	@# Setup the DNS for a new bucket
	@# Options:
	@#
	@#     L5D2_LATEST_VERSION                :: ${L5D2_LATEST_VERSION}
	@#     CF_API_EMAIL                       :: ${CF_API_EMAIL}
	@#     CF_API_KEY                         :: ${CF_API_KEY}
	@#     DRY_RUN                            :: ${DRY_RUN}
ifndef DRY_RUN
ifndef HAS_FLARECTL
	go get -u github.com/cloudflare/cloudflare-go/...
endif
	flarectl dns create \
		--zone $(ROOT_DOMAIN) \
		--name $(DOMAIN) \
		--type CNAME \
		--content c.storage.googleapis.com \
		--proxy
endif

.PHONY: update-version
update-version: replace-env-L5D2_LATEST_VERSION
	@# Update the version for the %* site

.PHONY: deploy-%
deploy-%: tmp/%*/public
	@# Upload a site to the correct bucket.
	@# Options:
	@#
	@#     DRY_RUN                            :: ${DRY_RUN}
	$(call upload_public,$*,$*)

.PHONY: deploy-$(DOMAIN)
deploy-$(DOMAIN): tmp/linkerd.io/public
	@# Upload to the archive for a specific version
	@# Options:
	@#
	@#     DRY_RUN                            :: ${DRY_RUN}
	$(call upload_public,linkerd.io,$(DOMAIN))

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
build-linkerd.io: tmp/linkerd.io
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

.PHONY: replace-env-%
replace-env-%: has-env-% tmp-sites
	@# Replace vars in files from the environment.
	@grep -rnl '$*' tmp >/dev/null || \
		( \
			printf "There are no instaces of $*, maybe you've already updated them?\n" && \
			exit 1 \
		)

	for fname in $$(grep -rnl '$*' tmp); do \
		sed -i '' 's/$*/$($*)/g' $$fname; \
	done

.PHONY: has-env-%
has-env-%:
	@if [ ! $${$*:-} ]; then printf "You must define: $*\n" && exit 1; fi

.PHONY: has-release
has-release: has-env-L5D2_LATEST_VERSION
	@curl -o /dev/null -L --fail $(RELEASE_URL)/tag/v$(L5D2_LATEST_VERSION) &>/dev/null || \
		( \
			printf "The release for $(L5D2_LATEST_VERSION) does not exist yet. Create it first." && \
			exit 1 \
		)

.PHONY: clean
clean:
	rm -rf tmp
