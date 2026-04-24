production-build:
	npm install --save-dev sass-embedded
	PATH="$(CURDIR)/node_modules/.bin:$$PATH" hugo \
	--cleanDestinationDir \
	--minify

preview-build:
	npm install --save-dev sass-embedded
	PATH="$(CURDIR)/node_modules/.bin:$$PATH" hugo \
	--baseURL $(DEPLOY_PRIME_URL) \
	--buildDrafts \
	--buildFuture \
	--cleanDestinationDir \
	--minify
