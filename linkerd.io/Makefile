production-build:
	npm install sass@1.97.3
	hugo \
	--cleanDestinationDir \
	--minify

preview-build:
	npm install sass@1.97.3
	hugo \
	--baseURL $(DEPLOY_PRIME_URL) \
	--buildDrafts \
	--buildFuture \
	--cleanDestinationDir \
	--minify
